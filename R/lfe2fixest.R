#' @title Converts `lfe::felm()` commands into their `fixest::feols()` equivalents.
#'
#' @description Takes an R script with `lfe::felm()` commands, converts them
#'   into their `fixest::feols` equivalents, and then exports the resulting
#'   script to disk. Conversion is the only thing it does. Neither the input
#'   not output script are run.
#' @param infile An R script containing `lfe::felm()` commands.
#' @param outfile File or connection to write the resulting R script (i.e. with
#'   `fixest::feols()` conversion) to. Can be the same as the input script, in which case the
#'   the latter will obviously be overwritten. Can also be left blank in which
#'   case nothing will be written to disk and the output will simply be printed
#'   to screen.
#' @param verbose Logical. Should the result be printed to screen. Defaults to
#'   `FALSE` unless `outfile` above is left blank.
#' @param robust Logical. By default, iid errors will be used unless cluster
#'   variables have been specified in the `felm()` formula(s). If users would
#'   like HC-robust standard errors, they should specify `TRUE`. Will be ignored
#'   if the `felm` formula contains cluster variables, since the errors will
#'   then default to cluster-robust.
#' @details Both `lfe::felm()` and `fixest::feols()` provide estimation routines
#'   for high-dimensional data. Both methods are highly optimised, although
#'   `feols()` is newer and tends to be quite a bit faster. The syntax between
#'   these two methods is similar, if not quite offering drop-in replacement.
#'   This function aims to automate the conversion process, ignoring non-relevant
#'   arguments and options between the two.
#'
#'   Note that the conversion only handles (or attempts to handle) the actual
#'   model calls. No attempt is made to convert downstream objects or functions
#'   like regression table construction. Although, you will probably be okay if
#'   you use a modern table-generating package like `modesummary`.
#'
#'   Other limitations include: (1) `lfe2fixest()` assumes that users provide a
#'   dataset in their model calls (i.e. regressions with global variables are
#'   not supported). (2) `lfe2fixest()` does not yet handle multiple IV
#'   regression. (3) Comments inside the `felm()` model call are liable to mess
#'   things up. I'll try to address these as time allows.
#' @seealso \code{\link[lfe]{felm}}, \code{\link[fixest]{feols}},
#'   \code{\link[modelsummary]{modelsummary}}.
#' @return An R script.
#' @export
#' @examples
#' \dontrun{
#' ## Write a (deliberately messy) lfe script
#' lfe_string =
#'   "library(lfe)
#'
#'   	aq = airquality
#'   	names(aq) = c('y', 'x1', 'x2', 'x3', 'mnth', 'dy')
#'
#'    mod1 = felm(y ~ x1 + x2, aq)
#'
#'    mod2 = felm(y ~ x1 + x2 |
#'      dy |
#'      0 |
#'      mnth, aq)
#'
#'    mod3 = felm(y ~ x1 + x2 |
#'      0 |
#'      0 |
#'      dy + mnth,
#'      aq)
#'
#'    mod4 = felm(y ~ 1 |
#'      dy |
#'      (x1 ~ x3) |
#'      mnth,
#'      weights = aq$x2,
#'      cmethod = 'reghdfe',
#'      exactDOF = TRUE,
#'      data = aq
#'      )"
#' writeLines(lfe_string, 'lfe_script.R')
#'
#' ## Covert to fixest equivalents
#' lfe2fixest('lfe_script.R') ## no output file provided, will print to screen
#' lfe2fixest('lfe_script.R', 'fixest_script.R') ## write converted script to disk
#'
#' ## Check equivalence with regression tables
#' library(modelsummary)
#'
#' ## First the lfe version
#' source('lfe_script.R')
#' msummary(list(mod1, mod2, mod3, mod4), gof_omit = 'Psuedo|Log|IC'))
#'
#' ## Then the fixest conversion
#' source('fixest_script.R')
#' msummary(list(mod1, mod2, mod3, mod4), gof_omit = 'Psuedo|Log|IC')
#'
#' ## Clean up
#' file.remove(c('lfe_script.R', 'fixest_script.R'))
#' }
lfe2fixest =
	function(infile, outfile = NULL, verbose = FALSE, robust = FALSE) {

		lfe_script = readLines(infile)

		start_felm_lines = grep('felm', lfe_script)
		end_felm_lines = start_felm_lines

		sapply(seq_along(end_felm_lines), function(i) {
			while(!endsWith(lfe_script[end_felm_lines[i]], ')')) {
				end_felm_lines[i] <<- end_felm_lines[i] + 1
			}
		})

		fixest_fmls =
			sapply(
				seq_along(start_felm_lines),
				function(i, ...) {

					felm_call = paste0(lfe_script[start_felm_lines[i]:end_felm_lines[i]], collapse = ' ')
					felm_call = gsub('\t', '', felm_call)

					pref = gsub('felm\\(.*', 'felm\\(', felm_call)

					fml = gsub(',.*', '', felm_call)
					fml = gsub(pref, '', fml, fixed = TRUE)

					suff = gsub(paste0(pref, fml), '', felm_call,	fixed = TRUE)

					fml_split = strsplit(fml, '\\|')[[1]]

					main = trimws(fml_split[1])
					add_fes = FALSE
					add_iv = FALSE
					add_cluster = FALSE

					if (length(fml_split) >= 2) {
						fes = trimws(fml_split[2])
						add_fes = fes!='0'
					}
					if (length(fml_split) >= 3) {
						iv = gsub('\\(|\\)', '', trimws(fml_split[3]))
						add_iv = iv!='0'
					}
					if (length(fml_split) >= 4) {
						cluster_vars = paste0('~', trimws(fml_split[4]))
						add_cluster = TRUE
					}

					fixest_fml = main
					if (add_fes) fixest_fml = paste0(fixest_fml, ' | ', fes)
					if (add_iv) fixest_fml = paste0(fixest_fml, ' | ', iv)

					fixest_pref = gsub('felm', 'feols', pref)

					fixest_suff = suff
					## Catch if 'data' arg not specified explicitly
					if (!grepl('data', fixest_suff)) {
						data_part = gsub('.*,', 'data =', fixest_suff)
					} else {
						data_part = ''
					}
					fixest_suff = strsplit(fixest_suff, ',')[[1]]
					fixest_suff = paste(trimws(fixest_suff)[grepl('data|subset|weights', fixest_suff)],
															collapse = ', ')
					fixest_suff = paste(',', fixest_suff, data_part)

					if (add_cluster) {
						fixest_suff = paste0(', cluster = ', cluster_vars, fixest_suff)
					} else if (robust) {
						fixest_suff = paste0('se = hetero', fixest_suff)
					}

					fixest_replacement = paste0(fixest_pref, fixest_fml, trimws(fixest_suff))

					return(fixest_replacement)

				}
			)

		felm_lines = sapply(seq_along(start_felm_lines), function (i) {
			seq(from = start_felm_lines[i], to = end_felm_lines[i])
		})


		fixest_script = lfe_script

		invisible(sapply(seq_along(felm_lines),
										 function(i) {
										 	adj = length(lfe_script) - length(fixest_script)
										 	pre = fixest_script[1:(start_felm_lines[i]-1-adj)]
										 	post = fixest_script[(end_felm_lines[i]+1-adj):length(fixest_script)]
										 	if ((end_felm_lines[i]+1-adj) > length(fixest_script)) post = ''
										 	mid = fixest_fmls[i]
										 	fixest_script <<- c(pre, mid, post)
										 }))

		fixest_script = gsub('library(lfe)', 'library(fixest)', fixest_script, fixed = TRUE)

		if (is.null(outfile) | verbose) cat(paste(fixest_script, collapse = '\n'))
		if (!is.null(outfile)) writeLines(fixest_script, outfile)

	}
