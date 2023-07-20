#' Function to produce heatmaps from a continuous IRTmodel
#'
#' This function makes a dataframe from the continuous IRTmodel the autoplot function
#' produces the heatmaps.
#'
#' @param model Output from the function \code{cirtmodel}.
#' @param thetarange The range for \code{theta}, default from -6 to 6.
#' @param object For autoplot: output of heatmaps_crm function.
#' @param xlab For autoplot: xlabel.
#' @param nrow For autoplot: number of rows of heatmaps to plot.
#' @param ratio For autoplot: ratio for coord_fixed in ggplot.
#' @param col_scheme For autoplot: the color scheme for heatmaps. Default value is plasma.
#' @param ... Other arguments currently ignored.
#'
#' @return Dataframe with output probabilities from the IRT model for all algorithms, an object
#' of class heatmapcrm.
#'
#' @examples
#' data(classification_cts)
#' model <- cirtmodel(classification_cts)
#' obj <- heatmaps_crm(model)
#' head(obj$df)
#' autoplot(obj)
#'
#' @export
heatmaps_crm <- function(model, thetarange = c(-6,6)){
  mod <- model$model
  num_algos <- dim(mod$data)[2]
  names_algos <- colnames(mod$data)
  ori_data <- mod$data
  theta <- seq(thetarange[1], thetarange[2], by=0.1)
  z <- seq(-6, 6, by=0.1)
  theta_z <- expand.grid(theta, z)
  colnames(theta_z) <- c("theta", "z")

  for(i in 1:num_algos){
    Algorithm <- rownames(mod$param)[i]
    alpha <- mod$param[i, 1]
    beta <- mod$param[i, 2]
    gamma <- mod$param[i, 3]
    pdf <- alpha*gamma/sqrt(2*pi)*exp(-alpha^2/2*(theta_z[ ,1]-beta-gamma*theta_z[ ,2])^2)
    df <- cbind.data.frame(theta_z, pdf, rep(Algorithm, dim(theta_z)[1]))
    colnames(df)[4] <- "Algorithm"
    if(i==1){
      gdf <- df
    }else{
      gdf <- rbind.data.frame(gdf, df)
    }
  }
  structure(list(
    df = gdf,
    call = match.call()
  ), class='heatmapcrm')

}

#' @rdname heatmaps_crm
#' @export
autoplot.heatmapcrm <- function(object,
                                xlab = "Theta",
                                nrow = 2,
                                ratio = 1,
                                col_scheme = 'plasma',
                                ...){


  gdf <- object$df
  theta <- z <- pdf <- Algorithm <- NULL

  ggplot(gdf, aes(theta, z)) +
    geom_raster(aes(fill=pdf))  +
    xlab(xlab) +
    facet_wrap(~Algorithm, nrow=nrow) +
    coord_fixed(ratio=ratio) +
    theme_bw()  +
    scale_fill_viridis_c(option = col_scheme)

}
