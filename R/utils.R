#' Utility function to make a dataframe from the IRTmodel
#'
#' This is a utility function to make a dataframe from the IRTmodel, which makes it easier to plot trace lines
#'
#' @param mod IRT model, either from function \code{irtmodel} or the \code{R} package \code{mirt}.
#'
#' @return Dataframe with output probabilities from the IRT model for all algorithms.
#'
#' @examples
#' data(classification)
#' mod <- irtmodel(classification)
#' dat <- prepare_for_plots(mod)
#' head(dat)
#'
#' @export
prepare_for_plots <- function(mod){
  # mod is the trained model
  num_algos <- dim(mod$model@Data$data)[2]
  names_algos <- colnames(mod$model@Data$data)
  ori_data <- mod$model@Data$data

  for(i in 1:num_algos){
    df1 <- get_trace(mod$model, num=i)
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
  return(dat)
}

get_trace <- function(mod, num=1){
  extr <- mirt::extract.item(mod, num)
  theta <- matrix(seq(-6,6, by = .1))
  traceline <- probtrace(extr, theta)
  dat <- (data.frame(Theta=theta, traceline))
  return(dat)
}
