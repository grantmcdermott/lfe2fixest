
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
faster, and allows for additional functionality (e.g. a `predict`
method). At the time writing this conversion package, **lfe** has also
been (temporarily) removed from CRAN after a period of stasis, leading
to downstream issues.

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
            cmethod = 'reghdfe', ## Also the same as feols
            exactDOF = TRUE,     ## Irrelevant option for feols (should be ignored)
            aq)

## IV reg with weights
mod4 = felm(y ~ 1 |
              dy |
              (x1 ~ x3) |
              mnth,
            weights = aq$x2,
            data = aq
            )

## Multiple IV
mod5 = felm(y ~ 1 |
              0 |
              (x1|x2 ~ x3 + dy + mnth) |
              dy,
            data = aq
            )

## Regression table
mods = list(mod1, mod2, mod3, mod4, mod5)
msummary(mods, gof_omit = 'Pseudo|Within|Log|IC', output = 'markdown')
"
writeLines(lfe_string, 'lfe_script.R')
```

We can now convert this script to the **fixest** equivalent using the
package’s main function, `lfe2fixest()` (or its alias, `felm2feols()`).

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
#> mod3 = feols(y ~ x1 + x2 | dy, cluster = ~dy + mnth,  data =
#>             aq)
#> 
#> ## IV reg with weights
#> mod4 = feols(y ~ 1 | dy | x1 ~ x3, cluster = ~mnth, weights = aq$x2, data = aq )
#> 
#> ## Multiple IV
#> mod5 = feols(y ~ 1 | x1 + x2 ~ x3 + dy + mnth, cluster = ~dy, data = aq )
#> 
#> ## Regression table
#> mods = list(mod1, mod2, mod3, mod4, mod5)
#> msummary(mods, gof_omit = 'Pseudo|Within|Log|IC', output = 'markdown')
```

Looks good. Note that the `feols` (`felm`) model syntax has been cleaned
up, with comments removed and everything collapsed onto a single line.
Let’s write it to disk by supplying an output file this time.

``` r
lfe2fixest(infile = 'lfe_script.R', outfile = 'fixest_script.R')
```

Note that the `lfe2fixest()` is a pure conversion function. It never
actually runs anything from either the input or output files. That
being, said here’s a quick comparison of the resulting regressions —
i.e. what we get if we actually *do* run the scripts. As an aside, my
scripts make use of the excellent
[**modelsummary**](https://vincentarelbundock.github.io/modelsummary/index.html)
package to generate the simple regression tables that you see below,
although we’re really not showing off its functionality here.

First, the original **lfe** version:

``` r
source('lfe_script.R', print.eval = TRUE)
#> 
#> 
#> |             | Model 1 | Model 2 |  Model 3  | Model 4 | Model 5  |
#> |:------------|:-------:|:-------:|:---------:|:-------:|:--------:|
#> |(Intercept)  | 77.246  |         |           |         |  93.452  |
#> |             | (9.068) |         |           |         | (65.757) |
#> |x1           |  0.100  |  0.099  |   0.099   |         |          |
#> |             | (0.026) | (0.031) |  (0.029)  |         |          |
#> |x2           | -5.402  | -5.577  |  -5.577   |         |          |
#> |             | (0.673) | (1.100) |  (1.053)  |         |          |
#> |`x1(fit)`    |         |         |           |  0.733  |  0.236   |
#> |             |         |         |           | (0.254) | (0.179)  |
#> |`x2(fit)`    |         |         |           |         |  -9.558  |
#> |             |         |         |           |         | (3.510)  |
#> |Num.Obs.     |   111   |   111   |    111    |   111   |   111    |
#> |R2           |  0.449  |  0.665  |   0.665   | -2.658  |  0.071   |
#> |R2 Adj.      |  0.439  |  0.527  |   0.527   | -4.093  |  0.054   |
#> |Cluster vars |         |  mnth   | dy + mnth |  mnth   |    dy    |
#> |FE:  dy      |         |    X    |     X     |    X    |          |
```

Second, the **fixest** conversion:

``` r
source('fixest_script.R', print.eval = TRUE)
#> 
#> 
#> |            | Model 1  |     Model 2      |       Model 3       |     Model 4      |    Model 5     |
#> |:-----------|:--------:|:----------------:|:-------------------:|:----------------:|:--------------:|
#> |(Intercept) |  77.246  |                  |                     |                  |     93.452     |
#> |            | (9.068)  |                  |                     |                  |    (65.757)    |
#> |x1          |  0.100   |      0.099       |        0.099        |                  |                |
#> |            | (0.026)  |     (0.031)      |       (0.029)       |                  |                |
#> |x2          |  -5.402  |      -5.577      |       -5.577        |                  |                |
#> |            | (0.673)  |     (1.100)      |       (1.053)       |                  |                |
#> |fit_x1      |          |                  |                     |      0.733       |     0.236      |
#> |            |          |                  |                     |     (0.254)      |    (0.179)     |
#> |fit_x2      |          |                  |                     |                  |     -9.558     |
#> |            |          |                  |                     |                  |    (3.510)     |
#> |Num.Obs.    |   111    |       111        |         111         |       111        |      111       |
#> |R2          |  0.449   |      0.665       |        0.665        |      -2.658      |     0.071      |
#> |R2 Adj.     |  0.439   |      0.527       |        0.527        |      -4.093      |     0.054      |
#> |FE: dy      |          |        X         |          X          |        X         |                |
#> |Std. errors | Standard | Clustered (mnth) | Two-way (dy & mnth) | Clustered (mnth) | Clustered (dy) |
```

Some minor formatting differences aside, looks like it worked and we get
the exact same results from both scripts. Great!

Let’s clean up before closing.

``` r
file.remove(c('lfe_script.R', 'fixest_script.R'))
#> [1] TRUE TRUE
```

## Caveats

Current limitations include:

-   `feols()` offers a variety of optimised features and syntax for
    things like [varying
    slopes](https://cran.r-project.org/web/packages/fixest/vignettes/fixest_walkthrough.html#31_Varying_slopes),
    [multiple
    estimation](https://cran.r-project.org/web/packages/fixest/vignettes/multiple_estimations.html),
    etc. that go beyond the standard R syntax (although the latter still
    works). **lfe2fixest** doesn’t try to exploit any of these
    specialised features. It’s more or less a literal translation of the
    `felm()` formula. The goal is to get you up and running with as
    little pain as possible, rather than eking every extra bit out of
    `feols()`’s already eye-watering performance.
-   The conversion only handles (or attempts to handle) the actual model
    calls. No attempt is made to convert downstream objects or functions
    like regression table construction. Although, as demonstrated in the
    example, you should be okay if you use a modern table-generating
    package like **modelsummary**. The same will not be true of
    **stargazer**, for example.
-   We assume that users always provide a dataset in their model calls
    (i.e.  regressions with global variables are not supported).
-   Similarly, the package only supports models that are explicitly
    written out in a script. If your models are constructed
    programatically (e.g. with `Formula()`) then the conversion probably
    won’t work.
