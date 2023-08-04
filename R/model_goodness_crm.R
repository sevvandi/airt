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
#' \item{\code{residuals}}{The different between actual and fitted performance values.}
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
  out$residuals <- dif_vals
  return(out)
}


actual_vs_predicted_crm <- function(mod, num=1){
  # actual values
  dat <- as.data.frame(mod$data)

  max.item <- apply(dat, 2, max) + 0.00001
  min.item <- apply(dat, 2, min)
  max_item <- max.item[num]

  algo_vals <- dat[ ,num]
  act_prd <- matrix(0, ncol=2, nrow=length(algo_vals))
  act_prd[ ,1] <- algo_vals
  colnames(act_prd) <- c("Actual", "Preds")
  paras <- mod$param
  alpha <- paras[num, 1]
  beta <- paras[num, 2]
  gamma <- paras[num, 3]

  persons <- EstCRM::EstCRMperson(dat,paras, min.item, max.item)
  scores <- persons$thetas[ ,2]

  z_vals <- log(algo_vals/(max_item - algo_vals))
  theta <- seq(from = min(scores), to=max(scores), by=0.01)

  pdf2 <- (scores - beta)/gamma
  indsbig <- which(pdf2 > 10)
  if(length(indsbig) > 0){
    pdf2[indsbig] <- 10
  }
  act_prd[ ,2] <- max_item*exp(pdf2)/(1 + exp(pdf2))

  return(act_prd)
}



#' Computes the goodness of IRT model for all algorithms.
#'
#' This function computes the goodness of the IRT model for all algorithms for different goodness tolerances.
#'
#' @param model The output of function cirtmodel.
#' @param object For autoplot: The output of model_goodness_crm.
#' @param ...  Other arguments currently ignored.
#'
#' @return  A list with the following components:
#' \item{\code{goodnessAUC}}{The area under the model goodness curve for each algorithm. }
#' \item{\code{curves}}{The \code{x,y} coordinates for the model goodness curves for each algorithm. }
#' \item{\code{residuals}}{The residuals for each algorithm using the AIRT model.}
#'@examples \donttest{
#'set.seed(1)
#'x1 <- runif(200)
#'x2 <- 2*x1 + rnorm(200, mean=0, sd=0.1)
#'x3 <- 1 - x1 + rnorm(200, mean=0, sd=0.1)
#'X <- cbind.data.frame(x1, x2, x3)
#'mod <- cirtmodel(X)
#'out <- model_goodness_crm(mod)
#'out
#'autoplot(out)
#'}
#' @export
model_goodness_crm <- function(model){
  mod <- model$model
  dd <- dim(mod$data)[2]
  nn <- dim(mod$data)[1]
  mse <- acc <- matrix(0, ncol=1, nrow=dd)
  residuals <- matrix(0, ncol = dd, nrow = nn)
  for(i in 1:dd){
    oo <- model_goodness_for_algo_crm(mod, num=i)
    acc[i, 1] <- oo$auc
    mse[i, 1] <- oo$mse
    if(i==1){
      curves <- matrix(0, ncol= (dd+1), nrow=dim(oo$xy)[1])
      curves[ ,1] <- oo$xy[ ,1]
    }
    curves[ ,(i+1)] <- oo$xy[ ,2]
    residuals[ ,i] <-  oo$residuals
  }
  colnames(curves) <- c("x", rownames(mod$param))
  rownames(acc) <-rownames(mod$param)
  colnames(residuals) <- rownames(mod$param)

  structure(list(
    goodnessAUC = acc,
    mse = mse,
    curves = curves,
    residuals = residuals,
    call = match.call()
  ), class='modelgoodnesscrm')
}


#' @rdname model_goodness_crm
#' @export
autoplot.modelgoodnesscrm <- function(object,
                                      ...){
  Algorithm <- x <- value <- NULL

  num_algos <- NROW(object$goodnessAUC)
  colrs2 <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, "Dark2"))(num_algos)
  good_curves <- as.data.frame(object$curves)
  good_df <- good_curves %>%
    tidyr::pivot_longer(cols=2:dim(good_curves)[2], names_to=c("Algorithm"))
  ggplot(good_df, aes(x,value))  +
    geom_line(aes(color = Algorithm), size=1)  +
    ylab("CDF") +
    xlab("Scaled Absolute Error") +
    theme_bw() +
    scale_color_manual(values = colrs2)
}
