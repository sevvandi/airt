#' Computes the actual and predicted effectiveness of the collection of algorithms.
#'
#' This function computes the actual and predicted effectiveness of the collection of algorithms for different tolerance values.
#'
#' @param mod A fitted \code{mirt} model using the function \code{irtmodel} or \code{R} package \code{mirt}.
#'
#' @return  A list with the following components:
#' \item{\code{effectivenessAUC}}{The area under the actual and predicted effectiveness curves. }
#' \item{\code{actcurves}}{The \code{x,y} coodinates for the actual  effectiveness curves for each algorithm. }
#' #' \item{\code{prdcurves}}{The \code{x,y} coodinates for the predicted  effectiveness curves for each algorithm. }
#'
#'@examples
#'set.seed(1)
#'x1 <- runif(100)
#'x2 <- runif(100)
#'x3 <- runif(100)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(1,3)
#'min_item <- rep(0,3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- effectiveness_crm(mod$model)
#'out
#' @export
effectiveness_crm <-  function(mod){
  dd <- dim(mod$data)[2]
  rel <- matrix(0, ncol=2, nrow=dd)
  colnames(rel) <- c("Actual", "Predicted")
  curves <- list()
  for(i in 1:dd){
    oo <- algo_effectiveness_crm(mod, num=i)
    rel[i, 1] <- oo$actualEff
    rel[i, 2] <- oo$predictedEff
    if(i==1){
      actcurves <- matrix(0, ncol= (dd+1), nrow=dim(oo$effective)[1])
      prdcurves <- matrix(0, ncol= (dd+1), nrow=dim(oo$effective)[1])
      prdcurves[ ,1] <- oo$effective[ ,1]
      actcurves[ ,1] <- oo$effective[ ,1]
    }
    actcurves[ ,(i+1)] <- oo$effective[ ,2]
    prdcurves[ ,(i+1)] <- oo$effective[ ,3]

  }
  colnames(prdcurves) <- colnames(actcurves) <- c("x", rownames(mod$param))
  rownames(rel) <- rownames(mod$param)
  out <- list()
  out$effectivenessAUC <- rel
  out$actcurves <- actcurves
  out$prdcurves <- prdcurves
  return(out)
}


#' Computes the actual and predicted effectiveness of a given algorithm.
#'
#' This function computes the actual and predicted effectiveness of a given algorithm for different tolerance values.
#'
#' @inheritParams model_goodness_for_algo_crm
#'
#' @return  A list with the following components:
#' \item{\code{effective}}{The \code{x,y} coodinates for the actual and predicted effectiveness curves for algorithm \code{num}. }
#' \item{\code{predictedEff}}{The area under the predicted effectiveness curve. }
#' \item{\code{actualEff}}{The area under the actual effectiveness curve. }
#'
#'@examples
#'set.seed(1)
#'x1 <- runif(100)
#'x2 <- runif(100)
#'x3 <- runif(100)
#'X <- cbind.data.frame(x1, x2, x3)
#'max_item <- rep(1,3)
#'min_item <- rep(0,3)
#'mod <- cirtmodel(X, max.item=max_item, min.item=min_item)
#'out <- algo_effectiveness_crm(mod$model, num=1)
#'out
#' @export
algo_effectiveness_crm <- function(mod, num=1){
  actpred <- actual_vs_predicted_crm(mod, num)
  act <- actpred[ ,1]
  preds <- actpred[ ,2]
  levels <- 100

  act_rel <- rep(0, levels)
  for(i in levels:1){
    k <- (levels - i + 1)
    ii <- i/levels
    act_rel[k] <- length(which(act >= ii))/length(act)
  }

  pred_rel <- rep(0, levels)
  for(i in levels:1){
    k <- levels - i + 1
    ii <- i/levels
    pred_rel[k] <- length(which(preds >= ii))/length(preds)
  }

  x <- seq(0, 1, by = 1/(levels-1))
  out_act <- c(act_rel)

  out <- cbind(x, out_act)
  colnames(out) <- c("x", "y")
  auc_act <- pracma::trapz(out[ ,1], out[ ,2])


  out_pred <- c(pred_rel)
  out <- cbind(x, out_pred)
  colnames(out) <- c("x", "y")
  auc_pred <- pracma::trapz(out[ ,1], out[ ,2])

  effective <- cbind(x, act_rel, pred_rel)

  out <- list()
  out$effective <- effective
  out$predictedEff <- auc_pred
  out$actualEff <- auc_act
  return(out)
}
