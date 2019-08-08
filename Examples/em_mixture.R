library(data.table)
library(ggplot2)

n = 1024*8

p_id = sample(seq(from = 1, to = 3), n , replace = TRUE, prob = c(0.3, 0.5, 0.2))
x_avg = c(1, 2, 3)
x_sig = 0.2*c(1, 2, 1)
df = data.table(p_id, x = rnorm(n)*x_sig[p_id] + x_avg[p_id] )

ggplot(df, aes(x)) + geom_density(adjust = 0.2) 

params = fit_em(3, df$x)

ggplot(df, aes(x)) + geom_density(adjust = 0.2) + 
  geom_line(data = data.frame(sx = sort(df$x) , mp = rowSums(mixture_prob(sort(df$x), params)) ), aes(sx, mp), color = 'red')


mixture_prob<-function(x, params){
  nx = length(x)
  k  = length( params$wt )
  gamma = matrix(rep(0, nx * k), nrow = nx, ncol = k)
  for(i in 1:k){
    gamma[,i] = params$wt[i] * dnorm(x, params$mu[i], params$sm[i])
  }
  #gamma = gamma / rowSums(gamma)
  return (gamma)
}

## fit parameters 
fit_em<-function(k, x){
  nx = length(x)
  mu_est = sample(x, k)
  sm_est = rep(sd(x), k)
  wt_est = rep(1, k)/k
  gamma = matrix(rep(0, nx * k), nrow = nx, ncol = k)
  
  if (k == 1)
    mu_est = mean(x)
  else if (k == 2)
    mu_est = c(min(x), max(x))
  else
    mu_est = seq(from = min(x), to = max(x), length.out = k)
  
  prev_log_like = NA
  
  for(it in 1:100){
    #E-step
    for(i in 1:k){
      gamma[,i] = wt_est[i] * dnorm(x, mu_est[i], sm_est[i])
    }
    likehood = rowSums(gamma)
    log_like = sum(log(likehood))
    gamma = gamma / likehood
    
    #M-step, estimate mu_est, sm_est
    for(i in 1:k){
      gamma_sum = sum(gamma[,i])
      mu_est[i] = sum(gamma[,i] * x)/gamma_sum
      sm_est[i] = sqrt( sum(gamma[,i] * (x - mu_est[i])^2 )/gamma_sum )
      wt_est[i] = gamma_sum / nx
    }
    if (!is.na(prev_log_like) & abs(prev_log_like - log_like)<1e-3){
      break
    }
    prev_log_like = log_like
    #print(log_like)
  }
  return( list('mu' = mu_est, 'sm' = sm_est, 'wt' = wt_est, 'it' = it, 'log_like' = log_like, 'error' = prev_log_like - log_like) )
}
