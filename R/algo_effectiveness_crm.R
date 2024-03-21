#' Computes the actual and predicted effectiveness of the collection of algorithms.
#'
#' This function computes the actual and predicted effectiveness of the collection of algorithms for different tolerance values.
#'
#' @param model The output of the function cirtmodel.
#' @param object For autoplot: The output of the function effectiveness_crm
#' @param plottype For autoplot: If plottype = 1, then actual effectiveness is plotted,
#' if plottype = 2, then predicted effectiveness is plotted. If plottype = 3,  area under the
#' actual effectiveness curve (AUAEC) is plotted against area under the predicted effectiveness
#' curve (AUPEC).
#' @param ...  Other arguments currently ignored.
#'
#'
#' @return  A list with the following components:
#' \item{\code{effectivenessAUC}}{The area under the actual and predicted effectiveness curves. }
#' \item{\code{actcurves}}{The \code{x,y} coodinates for the actual  effectiveness curves for each algorithm. }
#' #' \item{\code{prdcurves}}{The \code{x,y} coodinates for the predicted  effectiveness curves for each algorithm. }
#'
#'@examples
#'set.seed(1)\donttest{
#'x1 <- runif(200)
#'x2 <- 2*x1 + rnorm(200, mean=0, sd=0.1)
#'x3 <- 1 - x1 + rnorm(200, mean=0, sd=0.1)
#'X <- cbind.data.frame(x1, x2, x3)
#'mod <- cirtmodel(X, scale = TRUE, scale.method = "multiple")
#'out <- effectiveness_crm(mod)
#'out
#'# For the actual effectiveness plot
#'autoplot(out, plottype = 1)
#'# For the predicted effectivness plot
#'autoplot(out, plottype = 2)
#'# For actual and predicted effectiveness plot
#'autoplot(out, plottype = 3)
#'
#'}
#' @export
effectiveness_crm <-  function(model){
  mod <- model$model
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

  structure(list(
    effectivenessAUC = rel,
    actcurves = actcurves,
    prdcurves = prdcurves,
    call = match.call()
  ), class='effectivenesscrm')
}


#' @rdname effectiveness_crm
#' @export
autoplot.effectivenesscrm <- function(object,
                                      plottype = 1,
                                      ...){
  Predicted <- Actual <- Algorithm <- x <- value <- NULL
  num_algos <- NROW(object$effectivenessAUC)
  colrs2 <- grDevices::colorRampPalette(RColorBrewer::brewer.pal(8, "Dark2"))(num_algos)
  if(plottype == 1){
    eff_curves <- as.data.frame(object$actcurves)
    eff_df1 <- eff_curves %>%
      tidyr::pivot_longer(cols=2:dim(eff_curves)[2], names_to=c("Algorithm"))
    p <- ggplot(eff_df1, aes(x,value)) +
      geom_line(aes(color = Algorithm), size=1)  +
      ylab("Actual Effectiveness") + xlab("Effectiveness Tolerance") +
      theme_bw() +
      scale_color_manual(values = colrs2)
  }else if(plottype == 2){
    eff_curves <- as.data.frame(object$prdcurves)
    eff_df1 <- eff_curves %>%
      tidyr::pivot_longer(cols=2:dim(eff_curves)[2], names_to=c("Algorithm"))
    p <- ggplot(eff_df1, aes(x,value)) +
      geom_line(aes(color = Algorithm), size=1)  +
      ylab("Predicted Effectiveness") +
      xlab("Effectiveness Tolerance") +
      theme_bw() +
      scale_color_manual(values = colrs2)
  }else if(plottype == 3){
    df_eff <- cbind.data.frame(as.data.frame(object$effectivenessAUC), rownames(object$effectivenessAUC) )
    colnames(df_eff)[3] <- "Algorithm"
    p <- ggplot(df_eff, aes(Actual, Predicted)) +
      geom_jitter(aes(color=Algorithm), size=2) +
      geom_abline(aes(intercept=0,slope=1), linetype="dotted") +
      xlab("AUAEC") +
      ylab("AUPEC") +
      theme_bw() +
      scale_color_manual(values = colrs2) +
      ggplot2::xlim(0,1) +
      ggplot2::ylim(0,1)

  }
  p

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
#'@examples \donttest{
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
#'}
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
