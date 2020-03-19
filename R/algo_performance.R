#' Computes the goodness of model.
#'
#' This function computes the goodness of the IRT model for different goodness tolerances.
#'
#' @param mod A trained \code{mirt} model.
#' @param num The algorithm number, for which the goodness of the IRT model gets computed.
#'
#' @return  A list with the following components:
#' \item{\code{xy}}{The \code{x} values denote the goodness tolerances. The \code{y} values denote the model goodness. }
#' \item{\code{auc}}{The area under the model goodness curve. }
#'
#' @importFrom mirt fscores probtrace coef
#' @export
model_goodness <- function(mod, num=1){
  actpred <- actual_vs_predicted(mod, num)
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
  out <- list()
  out$xy <- cbind(x,y)
  out$auc <- auc
  return(out)
}


actual_vs_predicted <- function(mod, num=1){
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
