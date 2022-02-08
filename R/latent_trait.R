#' Performs the latent trait analysis
#'
#' This function performs the latent trait analysis of the datasets/problems after fitting a continuous IRT model. It fits a smoothing spline to the points to compute the latent trait.
#'
#' @param df The performance data in a matrix or dataframe.
#' @param paras The parameters from fitting \code{cirtmodel}.
#' @param max_item A vector with the maximum performance value for each algorithm.
#' @param min_item A vector with the minimum performance value for each algorithm.
#' @param epsilon A value defining good algorithm performance. If \code{epsilon = 0}, then only the best algorithm is considered. A default
#'
#' @return A list with the following components:
#' \item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
#' \item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
#' \item{\code{strengths}}{The strengths of each algorithm and positions on the latent trait that they performs well. }
#' \item{\code{dfl}}{The dataset in a long format of latent trait occupancy.}
#' \item{\code{plt}}{The ggplot object showing the fitted smoothing splines.}
#' \item{\code{thetas}}{The easiness of the problem set instances.}
#' \item{\code{weakness}}{The weaknesses of each algorithm and positions on the latent trait that they performs poorly.}
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
#' @importFrom magrittr  %>%
#' @importFrom tibble as_tibble
#' @importFrom dplyr mutate filter rename group_by summarize n left_join arrange desc select
#' @importFrom graphics hist
#' @export
latent_trait_analysis <- function(df, paras, min_item=0, max_item=1, epsilon = 0.01){
  oo <- EstCRM::EstCRMperson(df, paras, min_item ,max_item)
  id_ord <- order(oo$thetas[ ,2])
  df3 <- df[id_ord, ]

  df3 <- cbind.data.frame(oo$thetas[id_ord, 2], df3)
  colnames(df3)[1] <- "Latent_Trait"

  df4 <- cbind.data.frame(1:nrow(df3), df3)
  colnames(df4)[1] <- "Latent_Trait_Order"

  dfl <- tidyr::pivot_longer(df4, 3:dim(df4)[2])
  colnames(dfl)[3] <- "Algorithm"


  g2 <- ggplot2::ggplot(dfl,  ggplot2::aes(.data$Latent_Trait, .data$value)) +   ggplot2::geom_smooth( ggplot2::aes(color=.data$Algorithm), method = "gam", formula = y ~s(x, bs="cs"))+   ggplot2::xlab("Latent Trait (Dataset Easiness)") +  ggplot2::ylab("Performance")  +  ggplot2::theme_bw()
  out1 <- latent_length(g2, dfl$Algorithm, oo$thetas, epsilon, good = TRUE)
  out2 <- latent_length(g2, dfl$Algorithm, oo$thetas, epsilon, good = FALSE)

  out <- list()
  out$crmtheta <- oo
  out$strengths <- out1
  out$longdf <- dfl
  out$plt <- g2
  out$widedf <- df3
  out$thetas <- oo$thetas
  out$weakness <- out2
  return(out)
}



latent_length <- function(gplot, group_names, thetas, epsilon, good = TRUE){
  # Considers the latent trait - not the order
  # gplot is ggplot object from plotting graphs
  # group_names has the names of the groups

  g <- ggplot2::ggplot_build(gplot)
  df <- g$data[[1]]
  grp_ord <- sort(unique(group_names))
  df2 <- df[ ,c('x', 'y', 'group')]
  group_colour <-unique(df[ ,c('group', 'colour')])
  df_wide <- tidyr::pivot_wider(df2, names_from=.data$group, values_from=.data$y)
  dfy <- df_wide[ ,-1]
  if(good){
    algo <- which_good(dfy, eps = epsilon)
  }else{
    algo <- which_poor(dfy, eps = epsilon)
  }

  sorthedtheta <- sort(thetas[ ,2])
  xvals <- df_wide[ ,1]
  deltax <- diff(xvals$x)[1]
  xvals2 <- c(min(xvals) - deltax, dplyr::pull(xvals,.data$x), max(xvals) + deltax)
  xvals3 <- xvals2[-length(xvals2)] + diff(xvals2)/2
  res <- hist(sorthedtheta, breaks = xvals3, plot = FALSE)
  algodf <- as_tibble(algo) %>% mutate(count = res$counts) %>% tidyr::uncount(.data$count) %>% select(-.data$count)
  algos <- as_tibble(as.vector(as.matrix(algodf))) %>% filter(.data$value > 0) %>% rename(algo = .data$value)
  # updated to NROW(thetas) because when epsilon > 0, the total props is > 1
  props <- algos %>% group_by(algo) %>% summarize(prop = n()/NROW(thetas) )
  algorithm <- grp_ord[props$algo]
  df11 <- props %>% mutate(algorithm = algorithm) %>% rename(Proportion = .data$prop, group = algo) %>% left_join(group_colour) %>% arrange(desc(.data$Proportion))
  multilatent <- cbind.data.frame(df_wide[, 1], algo)
  colnames(multilatent) <- c("latenttrait", grp_ord)
  df2 <- df_wide[, 1]

  out <- list()
  out$proportions <- df11
  out$latent <- df2
  out$multilatent <- multilatent
  return(out)
}


which_good <- function(X, eps){
  maxes <- apply(X, 1, max)
  goodthresh <- maxes - eps
  XX <- X >= goodthresh
  mat <- matrix(rep(1:dim(X)[2], each = dim(X)[1]), ncol=dim(X)[2])
  mat[!XX] <- 0
  mat

}

which_poor <- function(X, eps){
  mins <- apply(X, 1, min)
  poorthresh <- mins + eps
  XX <- X <= poorthresh
  mat <- matrix(rep(1:dim(X)[2], each = dim(X)[1]), ncol=dim(X)[2])
  mat[!XX] <- 0
  mat

}

