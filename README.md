
<!-- README.md is generated from README.Rmd. Please edit that file -->

# algorithmirt <img src='man/figures/logo.png' align="right" height="137.5" />

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/sevvandi/algorithmirt.svg?branch=master)](https://travis-ci.org/sevvandi/algorithmirt)
<!-- badges: end -->

The goal of *algorithmirt* is to evaluate algorithm performances using
Item Response Theory (IRT). We evaluate the performance of a group of
algorithms on a collection of test instances. We use the R package
**mirt** to fit the IRT model.

## Installation

You can install the released version of algorithmirt from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("algorithmirt")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("sevvandi/algorithmirt")
```

## Example

This example is on classification algorithms. The data *classification*
has performance data from

``` r
library(algorithmirt)
library(ggplot2)
data("classification")
modout <- irtmodel(classification, vpara=FALSE)

gdf <- prepare_for_plots(modout)
ggplot(gdf, aes(Theta, value)) + geom_line(aes(color=Level)) + facet_wrap(.~Algorithm) + ylab("Probability") + ggtitle("Classification Algorithm Trace Lines") + theme_bw()
```

<img src="man/figures/README-example-1.png" width="100%" />
