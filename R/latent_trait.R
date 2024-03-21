#' Performs the latent trait analysis
#'
#' This function performs the latent trait analysis of the datasets/problems after fitting a continuous IRT model.
#' It fits a smoothing spline to the points to compute the latent trait. The autoplot function plots the latent trait
#' and the performance.
#'
#' @inheritParams cirtmodel
#' @param paras The parameters from fitting \code{cirtmodel}.
#' @param epsilon A value defining good algorithm performance. If \code{epsilon = 0}, then only
#' the best algorithm is considered. A default
#' @param object For autoplot: the output of the function latent_trait_analysis.
#' @param xlab For autoplot: the xlabel.
#' @param ylab For autoplot: the ylabel.
#' @param plottype For autoplot: plottype = 1 for all algorithm performances in a single plot, plottype = 2
#' for using facet_wrap to plot individual algorithms, plottype = 3 to plot the smoothing splines and
#' plottype = 4 to plot strengths and weaknesses.
#' @param nrow For autoplot: If \code{plottype = 2}, the number of rows for facet_wrap.
#' @param se For autoplot: for plotting splines with standard errors.
#' @param ratio For autoplot: for plotting strengths and weaknesses, ratio between x and y axis.
#' @param ...  Other arguments currently ignored.
#'
#'
#' @return A list with the following components:
#' \item{\code{crmtheta}}{The problem trait output computed from the R package EstCRM.}
#' \item{\code{strengths}}{The strengths of each algorithm and positions on the latent trait that they performs well. }
#' \item{\code{longdf}}{The dataset in long format of latent trait occupancy.}
#' \item{\code{plt}}{The ggplot object showing the fitted smoothing splines.}
#' \item{\code{widedf}}{The dataset in wide format with latent trait.}
#' \item{\code{thetas}}{The easiness of the problem set instances.}
#' \item{\code{weakness}}{The weaknesses of each algorithm and positions on the latent trait that they performs poorly.}
#'
#'@examples
#' # This is a dummy example.
#'set.seed(1)
#'x1 <- runif(200)
#'x2 <- 2*x1 + rnorm(200, mean=0, sd=0.1)
#'x3 <- 1 - x1 + rnorm(200, mean=0, sd=0.1)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(max(x1, x2, x3),3)
#'min_item <- rep(min(x1, x2, x3),3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- latent_trait_analysis(X, min.item= min_item, max.item = max_item, paras = mod$model$param)
#'out
#' # To plot performance against the problem difficulty
#'autoplot(out)
#'# To plot individual panels
#'autoplot(out, plottype = 2)
#'# To plot smoothing splines
#'autoplot(out, plottype = 3)
#' # To plot strengths and weaknesses
#'autoplot(out, plottype = 4)
#'
#' @importFrom rlang .data
#' @importFrom magrittr  %>%
#' @importFrom tibble as_tibble
#' @importFrom dplyr mutate filter rename group_by summarize n left_join arrange desc select
#' @importFrom graphics hist
#' @export
latent_trait_analysis <- function(df, scale = FALSE, scale.method = NULL, max.item=1 , min.item=0,  paras, epsilon = 0.01){

  out <- check_prepare_data(df, scale, scale.method, max.item, min.item)
  df <- out$df
  max.item <- out$max.item
  min.item <- out$min.item

  oo <- EstCRM::EstCRMperson(df, paras, min.item = min.item ,max.item = max.item)
  # UPDATE START: updated latent trait to dataset difficulty = multiply by -1
  oo$thetas[, 2] <- -1*oo$thetas[, 2]
  # UPDATE END
  id_ord <- order(oo$thetas[ ,2])
  df3 <- df[id_ord, ]

  df3 <- cbind.data.frame(oo$thetas[id_ord, 2], df3)
  colnames(df3)[1] <- "Latent_Trait"

  df4 <- cbind.data.frame(1:nrow(df3), df3)
  colnames(df4)[1] <- "Latent_Trait_Order"

  dfl <- tidyr::pivot_longer(df4, 3:dim(df4)[2])
  colnames(dfl)[3] <- "Algorithm"


  g2 <- ggplot2::ggplot(dfl,  ggplot2::aes(.data$Latent_Trait, .data$value)) +
    ggplot2::geom_smooth( ggplot2::aes(color=.data$Algorithm), method = "gam", formula = y ~s(x, bs="cs"))+
    ggplot2::xlab("Latent Trait (Dataset Easiness)") +  ggplot2::ylab("Performance")  +
    ggplot2::theme_bw()
  out1 <- latent_length(g2, dfl$Algorithm, oo$thetas, epsilon, good = TRUE)
  out2 <- latent_length(g2, dfl$Algorithm, oo$thetas, epsilon, good = FALSE)

  out <- list()
  structure(list(
    crmtheta = oo,
    strengths = out1,
    longdf = dfl,
    plt = g2,
    widedf = df3,
    thetas = oo$thetas,
    weakness = out2,
    epsilon = epsilon,
    call = match.call()
  ), class='latenttrait')
}


#' @rdname latent_trait_analysis
#' @export
autoplot.latenttrait <- function(object,
                                xlab = 'Problem Difficulty',
                                ylab = 'Performance',
                                plottype = 1,
                                nrow = 2,
                                se = TRUE,
                                ratio = 3,
                                ...){

  latenttrait <- Latent_Trait <- value <- Algorithm <- NULL

  dfl <- object$longdf
  if(plottype == 1){
    # algorithm performance vs latent trait
    g1 <- ggplot(dfl, aes(Latent_Trait, value)) +
      geom_point(aes(color=Algorithm)) +
      xlab(xlab) +
      ylab(ylab) +
      theme_bw()
  }else if(plottype == 2){
    # individual algorithm performance vs latent trait
    g1 <- ggplot(dfl, aes(Latent_Trait, value)) +
      geom_point(aes(color=Algorithm)) +
      facet_wrap(~Algorithm, nrow=2, scales = 'free') +
      xlab(xlab) +
      ylab(ylab)  +
      theme_bw()
  }else if(plottype == 3){
    # splines plot
    g1 <- ggplot(dfl, aes(Latent_Trait, value)) +
      geom_smooth(aes(color=Algorithm), se = se, method = "gam", formula = y ~s(x, bs="cs")) +
      xlab(xlab) +
      ylab(ylab) +
      theme_bw() +
      theme(legend.position="bottom", legend.box = "horizontal")
  }else{
    # strengths and weaknesses plot
    lto_eps1 <- object$strengths$proportions

    # Strengths
    latenttr <- object$strengths$multilatent
    dfl2 <- tidyr::pivot_longer(latenttr, cols = 2:dim(latenttr)[2])
    colnames(dfl2)[2] <- "Algorithm"
    dfl2 <- dfl2[dfl2$value!=0, ]
    if(object$epsilon == 0){
      dfl2$value <- 0
    }else{
      dfl2$value <- dfl2$value*0.1
    }

    # Weaknesses
    latenttr2 <- object$weakness$multilatent
    dfl3 <- tidyr::pivot_longer(latenttr2, cols = 2:dim(latenttr)[2])
    colnames(dfl3)[2] <- "Algorithm"
    dfl3 <- dfl3[dfl3$value!=0, ]
    if(object$epsilon == 0){
      dfl3$value <- 0
    }else{
      dfl3$value <- dfl3$value*0.1
    }


    dfl21 <- dfl2 %>% mutate(type = "Strengths")
    dfl31 <- dfl3 %>% mutate(type = "Weaknesses")

    dflall <- dplyr::bind_rows(dfl21, dfl31)
    num_algos <- length(unique(dflall$Algorithm))
    colrs <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, "Dark2"))(num_algos)

    g1 <- ggplot(dflall, aes(x = latenttrait, y =value, fill = Algorithm)) +
      geom_tile() +
      facet_wrap(type ~.,  nrow = 1) +
      theme(axis.title.y=element_blank(), axis.text.y=element_blank(),axis.ticks.y=element_blank())  +
      scale_fill_manual(values = colrs) +
      xlab(xlab) +
      coord_fixed(ratio = ratio)
   }
  g1
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

