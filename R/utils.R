get_trace <- function(mod, num=1){
  extr <- mirt::extract.item(mod, num)
  theta <- matrix(seq(-6,6, by = .1))
  traceline <- probtrace(extr, theta)
  dat <- (data.frame(Theta=theta, traceline))
  return(dat)
}
