#' Computes the goodness of IRT model for a given algorithm.
#'
#' This function computes the goodness of the IRT model for a given algorithm for different goodness tolerances.
#'
#' @param mod A fitted \code{mirt} model using the function \code{irtmodel} or \code{R} package \code{mirt}.
#' @param num The algorithm number, for which the goodness of the IRT model is computed.
#'
#' @return  A list with the following components:
#' \item{\code{xy}}{The \code{x} values denote the goodness tolerances. The \code{y} values denote the model goodness. }
#' \item{\code{auc}}{The area under the model goodness curve. }
#'
#'@examples \donttest{
#'set.seed(1)
#'x1 <- runif(100)
#'x2 <- runif(100)
#'x3 <- runif(100)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(1,3)
#'min_item <- rep(0,3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- model_goodness_for_algo_crm(mod$model, num=1)
#'out
#'}
#'
#' @importFrom mirt fscores probtrace coef
#' @export
model_goodness_for_algo_crm <- function(mod, num=1){
  actpred <- actual_vs_predicted_crm(mod, num)
  dif_vals <- apply(actpred, 1, function(x) abs(diff(x)) )
  len <- 100
  arr <- rep(0, len)
  for(i in 1:len){
    k <- (i-1)/100
    arr[i] <- length(which(dif_vals<=k))/length(dif_vals)
  }
  x <- seq(0, 1, length.out = (len))
  y <- c(arr)
  auc <- pracma::trapz(x, y)
  mse <- mean(dif_vals^2)
  out <- list()
  out$xy <- cbind(x,y)
  out$auc <- auc
  out$mse <- mse
  return(out)
}


actual_vs_predicted_crm <- function(mod, num=1, min_item=0, max_item=1){
  # actual values
  dat <- mod$data
  algo_vals <- dat[ ,num]
  act_prd <- matrix(0, ncol=2, nrow=length(algo_vals))
  act_prd[ ,1] <- algo_vals
  colnames(act_prd) <- c("Actual", "Preds")
  paras <- mod$param
  alpha <- paras[num, 1]
  beta <- paras[num, 2]
  gamma <- paras[num, 3]
  min.item <- rep(min_item, dim(dat)[2])
  max.item <- rep(max_item, dim(dat)[2])

  persons <- EstCRM::EstCRMperson(dat,paras,min.item,max.item)
  scores <- persons$thetas[ ,2]

  z_vals <- log(algo_vals/(max_item - algo_vals))
  theta <- seq(from = min(scores), to=max(scores), by=0.01)
  # z <- seq(from = min(z_vals), to=max(z_vals), by=0.01)
  # z <- seq(from = -6, to=6, by=0.01)
  # theta_z <- expand.grid(theta, z)
  # colnames(theta_z) <- c("theta", "z")

  pdf2 <- (scores - beta)/gamma
  indsbig <- which(pdf2 > 10)
  if(length(indsbig) > 0){
    pdf2[indsbig] <- 10
  }
  act_prd[ ,2] <- max_item*exp(pdf2)/(1 + exp(pdf2))
  # pdf <- alpha*gamma/sqrt(2*pi)*exp(-alpha^2/2*(theta_z[ ,1]-beta-gamma*theta_z[ ,2])^2)
  # pdfdf <- cbind.data.frame(theta_z, pdf)
  # for(i in 1:length(scores)){
  #   ind1 <- which.min(abs(pdfdf[ ,1] - scores[i]))
  #   min_val <- pdfdf[ind1, 1]
  #   inds <- which(pdfdf[ ,1] == min_val)
  #   df2 <- pdfdf[inds, ]
  #   val <- df2[which.max(df2[, 3]) ,2]
  #   act_prd[i, 2] <- max_item*exp(val)/(1 + exp(val))
  # }

  return(act_prd)
}



#' Computes the goodness of IRT model for all algorithms.
#'
#' This function computes the goodness of the IRT model for all algorithms for different goodness tolerances.
#'
#' @inheritParams model_goodness_for_algo_crm
#'
#' @return  A list with the following components:
#' \item{\code{goodnessAUC}}{The area under the model goodness curve for each algorithm. }
#' \item{\code{curves}}{The \code{x,y} coodinates for the model goodness curves for each algorithm. }
#'
#'@examples \donttest{
#'set.seed(1)
#'x1 <- runif(100)
#'x2 <- runif(100)
#'x3 <- runif(100)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(1,3)
#'min_item <- rep(0,3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- model_goodness_crm(mod$model)
#'out
#'}
#' @export
model_goodness_crm <- function(mod){
  dd <- dim(mod$data)[2]
  mse <- acc <- matrix(0, ncol=1, nrow=dd)
  for(i in 1:dd){
    oo <- model_goodness_for_algo_crm(mod, num=i)
    acc[i, 1] <- oo$auc
    mse[i, 1] <- oo$mse
    if(i==1){
      curves <- matrix(0, ncol= (dd+1), nrow=dim(oo$xy)[1])
      curves[ ,1] <- oo$xy[ ,1]
    }
    curves[ ,(i+1)] <- oo$xy[ ,2]
  }
  colnames(curves) <- c("x", rownames(mod$param))
  rownames(acc) <-rownames(mod$param)
  out <- list()
  out$goodnessAUC <- acc
  out$mse <- mse
  out$curves <- curves
  return(out)
}
