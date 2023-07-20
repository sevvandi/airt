#' Function to plot tracelines from a polytomous IRTmodel
#'
#' This function makes a dataframe from the polytomous IRTmodel. The autoplot function
#' can be used to plot trace lines
#'
#' @param model Output from the function \code{pirtmodel}.
#' @param object For autoplot: output of tracelines_poly function.
#' @param xlab For autoplot: xlabel.
#' @param ylab For autoplot: ylabel.
#' @param nrow For autoplot: number of rows of heatmaps to plot.
#' @param title For autoplot: the title for the plot.
#' @param ... Other arguments currently ignored.
#'
#' @return Dataframe with output probabilities from the IRT model for all algorithms, an object of
#' the class  tracelinespoly.
#'
#' @examples
#' data(classification_poly)
#' mod <- pirtmodel(classification_poly)
#' obj <- tracelines_poly(mod)
#' head(obj$df)
#' autoplot(obj)
#'
#' @export
tracelines_poly <- function(model){
  mod <- model$mod
  # mod is the trained model
  num_algos <- dim(mod@Data$data)[2]
  names_algos <- colnames(mod@Data$data)
  ori_data <- mod@Data$data

  for(i in 1:num_algos){
    df1 <- get_trace(mod, num=i)
    nn <- dim(df1)[2]
    colnames(df1)[2:nn] <- paste("P", sort(unique(ori_data[ ,i])), sep="")
    df <- cbind.data.frame(df1, rep(names_algos[i], dim(df1)[1]))
    dd <- dim(df)[2]
    colnames(df)[dd] <- "Algorithm"
    out <- tidyr::pivot_longer(df, cols=2:(dd-1), names_to="Level")
    if(i==1){
      dat <- out
    }else{
      dat <- rbind.data.frame(dat, out)
    }
  }
  structure(list(
    df = dat,
    call = match.call()
  ), class='tracelinespoly')

}

#' @rdname tracelines_poly
#' @export
autoplot.tracelinespoly <- function(object,
                                xlab = "Theta",
                                ylab = "Probability",
                                nrow = 2,
                                title = "Tracelines",
                                ...){


  gdf <- object$df
  Theta <- value <- Algorithm <- Level <- NULL

  ggplot(gdf, aes(Theta, value)) +
    geom_line(aes(color=Level)) +
    facet_wrap(.~Algorithm, nrow = nrow,) +
    ylab("ylab") +
    ggtitle(title) +
    theme_bw()

}
