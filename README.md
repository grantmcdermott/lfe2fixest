
<!-- README.md is generated from README.Rmd. Please edit that file -->

# lfe2fixest

<!-- badges: start -->
<!-- badges: end -->

The goal of **lfe2fixest** is to take R scripts that rely on the
`felm()` function from the [**lfe**](https://github.com/sgaure/lfe)
package and convert them to their `feols()` equivalents from the
[**fixest**](https://github.com/lrberge/fixest) package.

Why would you want to do this?

Both `lfe::felm()` and `fixest::feols()` provide “fixed-effects”
estimation routines for high-dimensional data. Both methods are also
highly optimised. However, `feols()` is newer, tends to be significantly
faster and allows for additional functionality (e.g. a `predict`
method). At the time writing this conversion package, **lfe** has also
been (temporarily) removed from CRAN after a period of stasis, leading
to downstream problems.

The syntax between `lfe::felm()` and `fixest::feols()` is similar, if
not quite offering a drop-in replacement. This package therefore aims to
automate the conversion process; ignoring non-relevant arguments and
differing options between the two, while doing its best to ensure that
the resulting scripts will produce the same output.

## Installation

Install the package from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("grantmcdermott/lfe2fixest")
```

## Example

Start by loading the package.

``` r
library(lfe2fixest)
```

Let’s create a **lfe**-based R script, that’s deliberately messy
(inconsistent formatting, etc.)

``` r
lfe_string = "
library(lfe)
library(modelsummary)

## Our toy dataset
aq = airquality
names(aq) = c('y', 'x1', 'x2', 'x3', 'mnth', 'dy')

## Simple OLS (no FEs)
mod1 = felm(y ~ x1 + x2, aq)

## Add a FE and cluster variable
mod2 = felm(y ~ x1 + x2 |
              dy |
              0 |
              mnth, aq)

## Add a second cluster variable and some estimation options
mod3 = felm(y ~ x1 + x2 |
              dy |
              0 |
              dy + mnth,
            cmethod = 'reghdfe',
            exactDOF = TRUE,
            aq)

## IV reg with weights
mod4 = felm(y ~ 1 |
              dy |
              (x1 ~ x3) |
              mnth,
            weights = aq$x2,
            data = aq
            )

## Regression table
mods = list(mod1, mod2, mod3, mod4)
msummary(mods, gof_omit = 'Pseudo|Within|Log|IC', output = 'markdown')
"
writeLines(lfe_string, 'lfe_script.R')
```

We can convert it to something that is **fixest**-friendly using the
package’s main (only!) function, `lfe2fixest::lfe2fixest()`.

While the function accepts several arguments, the most important (and
only required) one is an input file. Similarly, if no output file
argument is provided, then it will just print the conversion results to
screen.

``` r
lfe2fixest('lfe_script.R')
#> 
#> library(fixest)
#> library(modelsummary)
#> 
#> ## Our toy dataset
#> aq = airquality
#> names(aq) = c('y', 'x1', 'x2', 'x3', 'mnth', 'dy')
#> 
#> ## Simple OLS (no FEs)
#> mod1 = feols(y ~ x1 + x2,  data = aq)
#> 
#> ## Add a FE and cluster variable
#> mod2 = feols(y ~ x1 + x2 | dy, cluster = ~mnth,  data = aq)
#> 
#> ## Add a second cluster variable and some estimation options
#> mod3 = feols(y ~ x1 + x2 | dy, cluster = ~dy + mnth,  data =             aq)
#> 
#> ## IV reg with weights
#> mod4 = feols(y ~ 1 | dy | x1 ~ x3, cluster = ~mnth, weights = aq$x2, data = aq             )
#> 
#> ## Regression table
#> mods = list(mod1, mod2, mod3, mod4)
#> msummary(mods, gof_omit = 'Pseudo|Within|Log|IC', output = 'markdown')
```

Looks good, let’s write it to disk by supplying an output file this
time.

``` r
lfe2fixest(infile = 'lfe_script.R', outfile = 'fixest_script.R')
```

Note that the `lfe2fixest()` is a pure conversion function. It never
actually runs anything from either the input or output files. That
being, said here’s a quick comparison of the resulting regressions —
i.e. what we get if we actually *do* run the scripts. Note that my
scripts make use of the excellent
[**modelsummary**](https://vincentarelbundock.github.io/modelsummary/index.html)
package to generate the simple regression tables that you see below,
although we’re really (really) not showing off its functionality here.

First the lfe version:

``` r
source('lfe_script.R', print.eval = TRUE)
#> 
#> 
#> |             | Model 1 | Model 2 |  Model 3  | Model 4 |
#> |:------------|:-------:|:-------:|:---------:|:-------:|
#> |(Intercept)  | 77.246  |         |           |         |
#> |             | (9.068) |         |           |         |
#> |x1           |  0.100  |  0.099  |   0.099   |         |
#> |             | (0.026) | (0.031) |  (0.029)  |         |
#> |x2           | -5.402  | -5.577  |  -5.577   |         |
#> |             | (0.673) | (1.100) |  (1.053)  |         |
#> |`x1(fit)`    |         |         |           |  0.733  |
#> |             |         |         |           | (0.254) |
#> |Num.Obs.     |   111   |   111   |    111    |   111   |
#> |R2           |  0.449  |  0.665  |   0.665   | -2.658  |
#> |R2 Adj.      |  0.439  |  0.527  |   0.527   | -4.093  |
#> |Cluster vars |         |  mnth   | dy + mnth |  mnth   |
#> |FE:  dy      |         |    X    |     X     |    X    |
```

Then the fixest conversion:

``` r
source('fixest_script.R', print.eval = TRUE)
#> 
#> 
#> |            | Model 1  |     Model 2      |       Model 3       |     Model 4      |
#> |:-----------|:--------:|:----------------:|:-------------------:|:----------------:|
#> |(Intercept) |  77.246  |                  |                     |                  |
#> |            | (9.068)  |                  |                     |                  |
#> |x1          |  0.100   |      0.099       |        0.099        |                  |
#> |            | (0.026)  |     (0.031)      |       (0.029)       |                  |
#> |x2          |  -5.402  |      -5.577      |       -5.577        |                  |
#> |            | (0.673)  |     (1.100)      |       (1.053)       |                  |
#> |fit_x1      |          |                  |                     |      0.733       |
#> |            |          |                  |                     |     (0.254)      |
#> |Num.Obs.    |   111    |       111        |         111         |       111        |
#> |R2          |  0.449   |      0.665       |        0.665        |      -2.658      |
#> |R2 Adj.     |  0.439   |      0.527       |        0.527        |      -4.093      |
#> |FE: dy      |          |        X         |          X          |        X         |
#> |Std. errors | Standard | Clustered (mnth) | Two-way (dy & mnth) | Clustered (mnth) |
```

Some minor formatting differences aside, looks like it worked and we get
the exact same results from both scripts. Great!

Let’s clean up before continuing.

``` r
file.remove(c('lfe_script.R', 'fixest_script.R'))
#> [1] TRUE TRUE
```

## Caveats

This package was thrown together pretty quickly. Current limitations
include:

-   `lfe2fixest()` assumes that users provide a dataset in their model
    calls (i.e.  regressions with global variables are not supported).
-   `lfe2fixest()` does not yet handle multiple IV regression.
-   Comments inside the original `felm()` model call are liable to mess
    things up.
-   It only supports models that are explicitly written out in the
    script. If your models are constructed programatically (e.g. with
    `Formula()`) then it probably won’t work.

I’ll try to address these as time allows. PRs are most welcome.
