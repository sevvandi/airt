#' Computes the goodness of the IRT model fit for a given algorithm.
#'
#' This function computes the goodness of the IRT model fit for a given algorithm using the empirical cumulative distribution function of errors.
#'
#' @param mod A fitted \code{mirt} model using the function \code{irtmodel} or \code{R} package \code{mirt}.
#' @param num The algorithm number
#'
#' @return  A list with the following components:
#' \item{\code{xy}}{The \code{x} values denote the error tolerances. The \code{y} values denotes its empirical cumulative distribution function. }
#' \item{\code{auc}}{The area under the CDF. }
#' \item{\code{mse}}{The mean squared error. }
#'
#'@examples
#'set.seed(1)
#'x1 <- sample(1:5, 100, replace = TRUE)
#'x2 <- sample(1:5, 100, replace = TRUE)
#'x3 <- sample(1:5, 100, replace = TRUE)
#'X <- cbind.data.frame(x1, x2, x3)
#'mod <- pirtmodel(X)
#'out <- model_goodness_for_algo_poly(mod$model, num=1)
#'out
#'
#' @importFrom mirt fscores probtrace coef
#' @export
model_goodness_for_algo_poly <- function(mod, num=1){
  actpred <- actual_vs_predicted_poly(mod, num)
  dif_vals <- apply(actpred, 1, function(x) abs(diff(x)) )
  levels <- dim(coef(mod, IRTpars = TRUE, simplify=TRUE)$items)[2]
  len <- levels
  arr <- rep(0, len)
  for(i in 1:len){
    k <- i-1
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


actual_vs_predicted_poly <- function(mod, num=1){
  # actual values
  dat <- mod@Data$data
  algo_vals <- dat[ ,num]
  act_prd <- matrix(0, ncol=2, nrow=length(algo_vals))
  colnames(act_prd) <- c("Actual", "Preds")

  scores <- fscores(mod)
  theta <- seq(from = -6, to=6, length.out = 6*length(scores))
  probs <- probtrace(mod@ParObjects$pars[[num]], theta)
  max_curve <- apply(probs, 1, which.max)
  max_curve_ori <- max_curve

  # this is where you need to fix this !
  unique_max_curve <- sort(unique(max_curve))
  unique_actual <- sort(unique(as.vector(dat[, num])))
  condition <- sum(unique_max_curve %in% unique_actual)==length(unique_max_curve)
  # condition checks if a relabling has happened in mirt
  if(!condition){
    for(ll in 1:length(unique_max_curve)){
      inds <- which(max_curve_ori == unique_max_curve[ll])
      max_curve[inds] <- unique_actual[ll]

    }
  }

  for(jj in 1:length(unique(as.vector(dat)))){
    inds2 <- which(max_curve==jj)
    if(length(inds2) > 0){
      min_j <- min(theta[inds2])
      max_j <- max(theta[inds2])
      instance_inds <- which( (scores >= min_j) & (scores <= max_j) )
      act_prd[instance_inds, 1] <- algo_vals[instance_inds]
      act_prd[instance_inds, 2] <- jj
    }
  }

  # DO THE ZEROS
  preds <- act_prd[ ,2]
  zero_inds <- which(preds==0)
  if(length(zero_inds) >0){
    zero_ind_scores <- scores[zero_inds]
    for(i in 1:length(zero_inds)){
      act_prd[zero_inds[i], 2] <- max_curve[which.min(abs(theta-zero_ind_scores[i]))]
    }
  }
  return(act_prd)
}

#' Computes the goodness of IRT model for all algorithms.
#'
#' This function computes the goodness of the IRT model for all algorithms using the empirical cumulative distribution function of errors.
#'
#' @inheritParams model_goodness_for_algo_poly
#'
#' @return  A list with the following components:
#' \item{\code{goodnessAUC}}{The area under the model goodness curve for each algorithm. }
#' \item{\code{mse}}{The mean squared error. }
#' \item{\code{curves}}{The \code{x,y} coodinates for the model goodness curves for each algorithm. }
#'
#'@examples
#'set.seed(1)
#'x1 <- sample(1:5, 100, replace = TRUE)
#'x2 <- sample(1:5, 100, replace = TRUE)
#'x3 <- sample(1:5, 100, replace = TRUE)
#'X <- cbind.data.frame(x1, x2, x3)
#'mod <- pirtmodel(X)
#'out <- model_goodness_poly(mod$model)
#'out
#' @export
model_goodness_poly <- function(mod){
  dd <- dim(coef(mod, IRTpars = TRUE, simplify=TRUE)$item)[1]
  mse <- acc <- matrix(0, ncol=1, nrow=dd)
  for(i in 1:dd){
    oo <- model_goodness_for_algo_poly(mod, num=i)
    acc[i, 1] <- oo$auc
    mse[i, 1] <- oo$mse
    if(i==1){
      curves <- matrix(0, ncol= (dd+1), nrow=dim(oo$xy)[1])
      curves[ ,1] <- oo$xy[ ,1]
    }
    curves[ ,(i+1)] <- oo$xy[ ,2]
  }
  colnames(curves) <- c("x", rownames(coef(mod, simplify=TRUE)$items))
  rownames(acc) <- rownames(coef(mod, simplify=TRUE)$items)
  out <- list()
  out$goodnessAUC <- acc
  out$mse <- mse
  out$curves <- curves
  return(out)
}
