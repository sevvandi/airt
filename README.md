
<!-- README.md is generated from README.Rmd. Please edit that file -->

# airt <img src='man/figures/logo.png' align="right" height="138.5" />

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/sevvandi/airt.svg?branch=master)](https://travis-ci.org/sevvandi/airt)
<!-- badges: end -->

The goal of *airt* is to evaluate algorithm performances using Item
Response Theory (IRT). We evaluate the performance of a group of
algorithms on a collection of test instances. We use the R package
**mirt** to fit the IRT model.

## Installation

You can install the released version of airt from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("airt")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("sevvandi/airt")
```

## Example

This example is on classification algorithms. The data *classification*
has performance data from

``` r
library(airt)
library(ggplot2)
data("classification")
modout <- irtmodel(classification, vpara=FALSE)

gdf <- prepare_for_plots(modout)
ggplot(gdf, aes(Theta, value)) + geom_line(aes(color=Level)) + facet_wrap(.~Algorithm) + ylab("Probability") + ggtitle("Classification Algorithm Trace Lines") + theme_bw()
```

<img src="man/figures/README-example-1.png" width="100%" />
