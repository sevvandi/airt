#' @export
irtmodel <- function(dat, options=NULL){
  # CHECK IF DATA IS IN A DATA FRAME OR MATRIX
  if(!(is.data.frame(dat)|is.matrix(dat))){
    stop("Data needs to be a matrix or a dataframe!")
  }
  # CHECK FOR NAs, NANs
  na_sums <- sum(apply(dat, 2, function(x) sum(is.na(x))))
  nan_sums <- sum(apply(dat, 2, function(x) sum(is.nan(x))))
  if(na_sums > 0 ){
    stop("Data contains NA. Please fix!")
  }
  if(nan_sums>0){
    stop("Data contains NaN. Please fix!")
  }

  # CHECK IF NUMBER OF UNIQUE VALUES IS TOO HIGH
  unique_vals <- length(unique(as.vector(dat)))
  if(unique_vals > 10){
    stop("Data contains more than 10 levels for polytomous IRT. Please fix!")
  }

  # CHECK IF ALL ARE INTEGERS
  int_cols <- apply(dat, 2, function(x) all.equal(x, as.integer(x)))
  if(sum(int_cols=="TRUE") < dim(dat)[2]){
    stop("Data contains non-integer values. Please fix!")
  }

  # CHECK FOR COLUMN NAMES
  if(is.null(colnames(dat))){
    stop("Column names are empty! Please fix!")
  }

  # DATA IS GOOD FOR A mirt POLYTOMOUS MODEL
  if(is.null(options)){
    mod <- mirt::mirt(dat, 1, itemtype = 'gpcm', verbose = TRUE)
  }else if(options==1){
    mod <- mirt::mirt(dat, 1, itemtype = 'gpcm', verbose = TRUE, technical=list(NCYCLES=2000))
  }


  a_vals <- coef(mod, IRTpars = TRUE, simplify=TRUE)$items[ ,1]
  flipped <- sign(a_vals)
  stability <- max(ceiling(abs(a_vals))) - abs(a_vals)
  out <- list()
  out$model <- mod
  out$flipped <- flipped
  out$stability <- stability
  return(out)
}
