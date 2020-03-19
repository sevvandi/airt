#' Converts continuous performance data to polytomous data with 5 categories.
#'
#' This function converts continous performance data to polytomous data with 5 categories
#'
#' @param df The input data in a dataframe or a matrix
#' @param method If \code{1}, then the data is an accuracy measure between 0 and 1. If \code{2}, then the performance data is possibly has a bigger range. So we divide it into 5 equal bins to make it polytomous.
#'
#' @return The polytomous data frame.
#'
#' @examples
#' set.seed(1)
#' x1 <- runif(500)
#' x2 <- runif(500)
#' x3 <- runif(500)
#' x <- cbind(x1, x2, x3)
#' xout <- make_polyIRT_data(x)
#'
#' @export make_polyIRT_data
#' @importFrom stats quantile
make_polyIRT_data <- function(df, method=1){
  if(!(is.data.frame(df)|is.matrix(df))){
    stop("Data needs to be a matrix or a data frame!")
  }
  df2 <- matrix(0, nrow=nrow(df), ncol=ncol(df))
  if(method==1){
    df <- (df - min(df))/(diff(range(df)))

    df2[df<0.2 ] <- 1
    df2[(df >= 0.2) & (df<0.4) ] <- 2
    df2[(df >= 0.4) & (df<0.6) ] <- 3
    df2[(df >= 0.6) & (df<0.8) ] <- 4
    df2[(df >= 0.8) ] <- 5
    colnames(df2) <- colnames(df)
  }else if(method==2){
    df2 <- matrix(0, nrow=nrow(df), ncol=ncol(df))
    df1 <- as.vector(unlist(df))
    ticks <- quantile(df1, c(0.2, 0.4, 0.6, 0.8))
    df2[df< ticks[1] ] <- 1
    df2[(df >= ticks[1]) & (df<ticks[2]) ] <- 2
    df2[(df >= ticks[2]) & (df<ticks[3]) ] <- 3
    df2[(df >= ticks[3]) & (df<ticks[4]) ] <- 4
    df2[(df >= ticks[4]) ] <- 5
  }
  return(df2)
}
