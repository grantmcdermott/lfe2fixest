
<!-- README.md is generated from README.Rmd. Please edit that file -->

# lfe2fixest

<!-- badges: start -->

[![R-CMD-check](https://github.com/grantmcdermott/lfe2fixest/workflows/R-CMD-check/badge.svg)](https://github.com/grantmcdermott/lfe2fixest/actions)
<!-- badges: end -->

## Installation

Install the package directly from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("grantmcdermott/lfe2fixest")
```

## Motivation

The goal of **lfe2fixest** is to take R scripts that rely on the
`felm()` function from the [**lfe**](https://github.com/sgaure/lfe)
package and convert them to their `feols()` equivalents from the
[**fixest**](https://lrberge.github.io/fixest) package.

Why would you want to do this?

Both `lfe::felm()` and `fixest::feols()` provide “fixed-effects”
estimation routines for high-dimensional data. Both methods are also
highly optimised. However, `feols()` is newer, tends to be significantly
faster, and allows for a lot more functionality (e.g. a `predict`
method). At the same time, the primary author of **lfe** has stopped
developing the package. It has since been adopted, but is now
essentially in pure maintenance mode.

The syntax between `felm()` and `feols()` is similar, albeit with one
not necessarily providing a drop-in replacement for the other. For
example, the following two lines of code are functionally equivalent
versions of the same underlying model.<sup id="a1">[1](#f1)</sup>

-   `felm(y ~ x1 + x2 | fe1 + fe2 | (x3 | x4 ~ z1 + z2) | cl1, data = dat)`
-   `feols(y ~ x1 + x2 | fe1 + fe2 | c(x3, x4) ~ z1 + z2, cluster = ~cl1, data = dat)`

The **lfe2fixest** package automates the translation between these kinds
of models. It does its best to ignoring any non-relevant arguments and
adjust for differing syntax options between `felm()` and `feols()`. The
end goal is a converted R script that will produce exactly the same
output, some minor [caveats](#caveats) notwithstanding.

## Example

A detailed example is provided in the [introductory
vignette](http://grantmcdermott.com/lfe2fixest/articles/lfe2fixest.html).
See `vignette("lfe2fixest")`.

## Caveats

While I’m confident that **lfe2fixest** will work out-of-the-box in most
(9 out of 10?) situations, there are some minor caveats to bear in mind.

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
-   Similarly, because `felm()` and `feols()` do not share all of the
    same arguments, there are cases where the conversion can yield
    different results. An example would be in the case of multiway
    clustering where the `felm()` call does not specify the right
    `cmethod` option. (More
    [here](https://github.com/sgaure/lfe/pull/26) and
    [here](https://cran.r-project.org/web/packages/fixest/vignettes/standard_errors.html).)
-   The conversion only handles (or attempts to handle) the actual model
    calls. No attempt is made to convert downstream objects or functions
    like regression table construction. Although, as demonstrated in the
    example, you should be okay if you use a modern table-generating
    package like **modelsummary**. But the same would not be true of
    **stargazer**, for example.
-   I assume that users always provide a dataset in their model calls
    (i.e.  regressions with global variables are not supported).
-   Similarly, the package only supports models that are explicitly
    written out in a script. If your models are constructed
    programatically (e.g. with `Formula()`) then the conversion probably
    won’t work.

<sup><b id="f1">1</b></sup> An IV regression with multiple endogenous
variables and fixed effects, as well as clustered standard errors. But
that’s besides the point.[↩](#a1)
