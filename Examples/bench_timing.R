

library(plyr)
library(ggplot2)

n = 2000
my_bench <- function(n){
  m = matrix(rnorm(n*n), ncol=n, nrow=n)
  svd_decom = svd(m)
  return (max(svd_decom$d)/min(svd_decom$d))
}


stime = Sys.time()

res = ldply(seq(200), function(i) {
  ctime = Sys.time()
  bench = system.time ( my_bench(n) )
  r = data.frame(i, ctime, wall_clock = as.numeric(difftime(Sys.time(), ctime), units = "secs"), user=bench[1], system=bench[2], elapsed = bench[3])
  #r = data.frame(i)
  return (r)
})


ggplot(res, aes(i, user)) + geom_point() + geom_smooth()
ggplot(res, aes(i, elapsed)) + geom_point() + geom_smooth()
ggplot(res, aes(i, system)) + geom_point() + geom_smooth()

