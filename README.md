
<!-- README.md is generated from README.Rmd. Please edit that file -->

# lfe2fixest

<!-- badges: start -->
<!-- badges: end -->

The goal of **lfe2fixest** is to take R scripts that rely on the
`felm()` function from the [**lfe**](https://github.com/sgaure/lfe)
package and convert them to the `feols()` equivalent from
[**fixest**](https://github.com/lrberge/fixest) package.

## Installation

Install the package from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("grantmcdermott/lfe2fixest")
```

## Example

Let’s create a (deliberately messy) **lfe**-based R script.

``` r
lfe_string =
  "library(lfe)

    aq = airquality
    names(aq) = c('y', 'x1', 'x2', 'x3', 'mnth', 'dy')

   mod1 = felm(y ~ x1 + x2, aq)

   mod2 = felm(y ~ x1 + x2 |
     dy |
     0 |
     mnth, aq)

   mod3 = felm(y ~ x1 + x2 |
     0 |
     0 |
     dy + mnth,
     aq)

   mod4 = felm(y ~ 1 |
     dy |
     (x1 ~ x3) |
     mnth,
     weights = aq$x2,
     cmethod = 'reghdfe',
     exactDOF = TRUE,
     data = aq
     )"
writeLines(lfe_string, 'lfe_script.R')
```

We can convert it to something that is **fixest** friendly using the
package’s main (only!) function, `lfe2fixest::lfe2fixest()`.

``` r
library(lfe2fixest)

## If no output file provided, it will print to screen
lfe2fixest('lfe_script.R')
#> library(fixest)
#> 
#>      aq = airquality
#>      names(aq) = c('y', 'x1', 'x2', 'x3', 'mnth', 'dy')
#> 
#>    mod1 = feols(y ~ x1 + x2,  data = aq)
#> 
#>    mod2 = feols(y ~ x1 + x2 | dy, cluster = ~mnth,  data = aq)
#> 
#>    mod3 = feols(y ~ x1 + x2, cluster = ~dy + mnth,  data =      aq)
#> 
#>    mod4 = feols(y ~ 1 | dy | x1 ~ x3, cluster = ~mnth, weights = aq$x2, data = aq      )

## Looks good, let's write it to disk by supplying the output file
lfe2fixest('lfe_script.R', 'fixest_script.R')
```

Note that the `lfe2fixest()` is a pure conversion function. It never
actually runs anything from the input or output scripts. That being,
said, here’s a quick comparison of resulting regressions (i.e. what we
get if we do actually run the scripts) using the excellent
**modelsummary** package.

``` r
library(modelsummary)

## First the lfe version
source('lfe_script.R')
#> Loading required package: Matrix
msummary(list(mod1, mod2, mod3, mod4), gof_omit = 'Psuedo|Log|IC',
                 output = 'markdown')
```

|              | Model 1 | Model 2 |  Model 3  | Model 4 |
|:-------------|:-------:|:-------:|:---------:|:-------:|
| (Intercept)  | 77.246  |         |  77.246   |         |
|              | (9.068) |         | (14.365)  |         |
| x1           |  0.100  |  0.099  |   0.100   |         |
|              | (0.026) | (0.031) |  (0.041)  |         |
| x2           | -5.402  | -5.577  |  -5.402   |         |
|              | (0.673) | (1.100) |  (1.171)  |         |
| `x1(fit)`    |         |         |           |  0.733  |
|              |         |         |           | (0.254) |
| Num.Obs.     |   111   |   111   |    111    |   111   |
| R2           |  0.449  |  0.665  |   0.449   | -2.658  |
| R2 Adj.      |  0.439  |  0.527  |   0.439   | -4.093  |
| Cluster vars |         |  mnth   | dy + mnth |  mnth   |
| FE: dy       |         |    X    |           |    X    |

``` r
## Then the fixest conversion
source('fixest_script.R')
#> NOTE: 42 observations removed because of NA values (LHS: 37, RHS: 7).
#> NOTE: 42 observations removed because of NA values (LHS: 37, RHS: 7).
#> NOTE: 42 observations removed because of NA values (LHS: 37, RHS: 7).
#> NOTE: 42 observations removed because of NA values (LHS: 37, IV: 7/0).
msummary(list(mod1, mod2, mod3, mod4), gof_omit = 'Psuedo|Log|IC',
                 output = 'markdown')
```

|             | Model 1  |     Model 2      |       Model 3       |     Model 4      |
|:------------|:--------:|:----------------:|:-------------------:|:----------------:|
| (Intercept) |  77.246  |                  |       77.246        |                  |
|             | (9.068)  |                  |      (14.304)       |                  |
| x1          |  0.100   |      0.099       |        0.100        |                  |
|             | (0.026)  |     (0.031)      |       (0.041)       |                  |
| x2          |  -5.402  |      -5.577      |       -5.402        |                  |
|             | (0.673)  |     (1.100)      |       (1.154)       |                  |
| fit\_x1     |          |                  |                     |      0.733       |
|             |          |                  |                     |     (0.254)      |
| Num.Obs.    |   111    |       111        |         111         |       111        |
| R2          |  0.449   |      0.665       |        0.449        |      -2.658      |
| R2 Adj.     |  0.439   |      0.527       |        0.439        |      -4.093      |
| R2 Pseudo   |          |                  |                     |                  |
| R2 Within   |          |      0.496       |                     |      -3.968      |
| FE: dy      |          |        X         |                     |        X         |
| Std. errors | Standard | Clustered (mnth) | Two-way (dy & mnth) | Clustered (mnth) |

Finally, clean up.

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
-   Comments inside the `felm()` model call are liable to mess things
    up.

I’ll try to address these as time allows. PRs are most welcome.
