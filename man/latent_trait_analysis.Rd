% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/latent_trait.R
\name{latent_trait_analysis}
\alias{latent_trait_analysis}
\alias{autoplot.latenttrait}
\title{Performs the latent trait analysis}
\usage{
latent_trait_analysis(
  df,
  scale = FALSE,
  scale.method = NULL,
  max.item = 1,
  min.item = 0,
  paras,
  epsilon = 0.01
)

\method{autoplot}{latenttrait}(
  object,
  xlab = "Problem Difficulty",
  ylab = "Performance",
  plottype = 1,
  nrow = 2,
  se = TRUE,
  ratio = 3,
  ...
)
}
\arguments{
\item{df}{The performance data in a matrix or dataframe with good performances having
high values and poor performances having low values.}

\item{scale}{If \code{TRUE}, the performance data is scaled to 0-1. The default is \code{FALSE}.}

\item{scale.method}{The method to scale the data. The default is \code{NULL}. If set to
\code{"single"}, it scales the data to 0-1 for the full dataset. If set to \code{"multiple"}
it scales each column/algorithm separately to 0-1. If \code{scale} is \code{FALSE}, the
data is not scaled.}

\item{max.item}{A vector with the maximum performance value for each algorithm.
This can be used to inform the maximum performance value for each algorithm.
Only will be used if scale is \code{FALSE}. Default is 1.}

\item{min.item}{A vector with the minimum performance value for each algorithm.
This can be used to inform the minimum performance value for each algorithm.
Only will be used if scale is \code{FALSE}. Default is 0.}

\item{paras}{The parameters from fitting \code{cirtmodel}.}

\item{epsilon}{A value defining good algorithm performance. If \code{epsilon = 0}, then only
the best algorithm is considered. A default}

\item{object}{For autoplot: the output of the function latent_trait_analysis.}

\item{xlab}{For autoplot: the xlabel.}

\item{ylab}{For autoplot: the ylabel.}

\item{plottype}{For autoplot: plottype = 1 for all algorithm performances in a single plot, plottype = 2
for using facet_wrap to plot individual algorithms, plottype = 3 to plot the smoothing splines and
plottype = 4 to plot strengths and weaknesses.}

\item{nrow}{For autoplot: If \code{plottype = 2}, the number of rows for facet_wrap.}

\item{se}{For autoplot: for plotting splines with standard errors.}

\item{ratio}{For autoplot: for plotting strengths and weaknesses, ratio between x and y axis.}

\item{...}{Other arguments currently ignored.}
}
\value{
A list with the following components:
\item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
\item{\code{strengths}}{The strengths of each algorithm and positions on the latent trait that they performs well. }
\item{\code{longdf}}{The dataset in long format of latent trait occupancy.}
\item{\code{plt}}{The ggplot object showing the fitted smoothing splines.}
\item{\code{widedf}}{The dataset in wide format with latent trait.}
\item{\code{thetas}}{The easiness of the problem set instances.}
\item{\code{weakness}}{The weaknesses of each algorithm and positions on the latent trait that they performs poorly.}
}
\description{
This function performs the latent trait analysis of the datasets/problems after fitting a continuous IRT model.
It fits a smoothing spline to the points to compute the latent trait. The autoplot function plots the latent trait
and the performance.
}
\examples{
# This is a dummy example.
set.seed(1)
x1 <- runif(200)
x2 <- 2*x1 + rnorm(200, mean=0, sd=0.1)
x3 <- 1 - x1 + rnorm(200, mean=0, sd=0.1)
X <- cbind.data.frame(x1, x2, x3)
max_item <- rep(max(x1, x2, x3),3)
min_item <- rep(min(x1, x2, x3),3)
mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
out <- latent_trait_analysis(X, min.item= min_item, max.item = max_item, paras = mod$model$param)
out
# To plot performance against the problem difficulty
autoplot(out)
# To plot individual panels
autoplot(out, plottype = 2)
# To plot smoothing splines
autoplot(out, plottype = 3)
# To plot strengths and weaknesses
autoplot(out, plottype = 4)

}
