#' Performs the latent trait analysis
#'
#' This function performs the latent trait analysis of the datasets/problems after fitting a continuous IRT model. It fits a smoothing spline to the points to compute the latent trait.
#'
#' @param df The performance data in a matrix or dataframe.
#' @param paras The parameters from fitting \code{cirtmodel}.
#' @param max_item A vector with the maximum performance value for each algorithm.
#' @param min_item A vector with the minimum performance value for each algorithm.
#'
#' @return A list with the following components:
#' \item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
#' \item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
#' \item{\code{latent}}{Thelatent trait occupancy of each algorithm.}
#' \item{\code{dfl}}{The dataset in a long format of latent trait occupancy.}
#' \item{\code{plt}}{The ggplot object showing the fitted smoothing splines.}
#'
#'@examples
#'set.seed(1)
#'x1 <- runif(100)
#'x2 <- runif(100)
#'x3 <- runif(100)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(1,3)
#'min_item <- rep(0,3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- latent_trait_analysis(X, mod$model$param, min_item= min_item, max_item = max_item)
#'out
#'
#' @importFrom rlang .data
#' @export
latent_trait_analysis <- function(df, paras, min_item=0, max_item=1){
  oo <- EstCRM::EstCRMperson(df, paras, min_item ,max_item)
  id_ord <- order(oo$thetas[ ,2])
  df3 <- df[id_ord, ]

  df3 <- cbind.data.frame(oo$thetas[id_ord, 2], df3)
  colnames(df3)[1] <- "Latent_Trait"

  dfl <- tidyr::pivot_longer(df3, 2:dim(df3)[2])
  colnames(dfl)[2] <- "Algorithm"


  g2 <- ggplot2::ggplot(dfl,  ggplot2::aes(.data$Latent_Trait, .data$value)) +   ggplot2::geom_smooth( ggplot2::aes(color=.data$Algorithm), method = "gam", formula = y ~s(x, bs="cs"))+   ggplot2::xlab("Latent Trait (Dataset Easiness)") +  ggplot2::ylab("Performance")  +  ggplot2::theme_bw()

  out1 <- latent_length(g2, dfl$Algorithm)

  out <- list()
  out$crmtheta <- oo
  out$latent <- out1
  out$longdf <- dfl
  out$plt <- g2
  return(out)
}




latent_length <- function(gplot, group_names){
  # gplot is ggplot object from plotting graphs
  # group_names has the names of the groups

  g <- ggplot2::ggplot_build(gplot)
  df <- g$data[[1]]
  grp_ord <- sort(unique(group_names))
  df2 <- df[ ,c('x', 'y', 'group')]
  group_colour <-unique(df[ ,c('group', 'colour')])
  df_wide <- tidyr::pivot_wider(df2, names_from=.data$group, values_from=.data$y)
  dfy <- df_wide[ ,-1]
  algo_ind <- apply(dfy, 1, which.max)
  props <- as.data.frame(table(algo_ind)/dim(dfy)[1])
  algorithm <- grp_ord[as.numeric(paste(props[ ,1]))]
  df1 <- cbind.data.frame(algorithm, props)
  colnames(df1)[c(2,3)] <- c("group","Proportion")
  df11 <-  merge(df1, group_colour, by="group")

  df2 <- cbind.data.frame(df_wide[ ,1], grp_ord[as.numeric(paste(algo_ind))] )
  colnames(df2)[2] <- "Algorithm"
  out <- list()
  out$proportions <- df11
  out$latent <- df2
  return(out)
}

