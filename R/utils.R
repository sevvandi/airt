#' Utility function to make a dataframe from the polytomous IRTmodel
#'
#' This is a utility function to make a dataframe from the polytomous IRTmodel, which makes it easier to plot trace lines
#'
#' @param mod IRT model, either from function \code{pirtmodel} or the \code{R} package \code{mirt}.
#'
#' @return Dataframe with output probabilities from the IRT model for all algorithms.
#'
#' @examples
#' data(classification_poly)
#' mod <- pirtmodel(classification_poly)
#' dat <- prepare_for_plots_poly(mod$model)
#' head(dat)
#'
#' @export
prepare_for_plots_poly <- function(mod){
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
  return(dat)
}

#' Utility function to make a dataframe from the continuous IRTmodel
#'
#' This is a utility function to make a dataframe from the continuous IRTmodel, which makes it easier to plot the surfaces
#'
#' @param mod IRT model, either from function \code{cirtmodel} or the \code{R} package \code{EstCRM}.
#' @param thetarange The range for \code{theta}, default from -6 to 6.
#'
#' @return Dataframe with output probabilities from the IRT model for all algorithms.
#'
#' @examples
#' data(classification_cts)
#' mod <- cirtmodel(classification_cts)
#' dat <- prepare_for_plots_crm(mod$model)
#' head(dat)
#'
#' @export
#' @export
prepare_for_plots_crm <- function(mod, thetarange=c(-6,6)){
  num_algos <- dim(mod$data)[2]
  names_algos <- colnames(mod$data)
  ori_data <- mod$data
  theta <- seq(thetarange[1], thetarange[2], by=0.1)
  z <- seq(-6, 6, by=0.1)
  # theta <- seq(-6, 6, by=0.1)
  # z <- seq(6, 12, by=0.1)
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
  return(gdf)
}

get_trace <- function(mod, num=1){
  extr <- mirt::extract.item(mod, num)
  theta <- matrix(seq(-6,6, by = .1))
  traceline <- probtrace(extr, theta)
  dat <- (data.frame(Theta=theta, traceline))
  return(dat)
}
