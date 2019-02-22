library(data.table)

library(compiler)
f <- function(n, x) for (i in 1:n) x = (1 + x)^(-1)
g <- cmpfun(f)

n = 4000
trial_prob = 0.2
n_trials = 10
x = rbinom(n, n_trials, trial_prob) #population size 10, probability 20%

my_binom_test <- Vectorize(function(x, n) binom.test(x, n)$conf.int[1:2],  vectorize.args = c("x", "n"))

my_binom_test_dt <-function(x, n){
  res = t(my_binom_test(x, n))
  split(res, rep(1:ncol(res), each = nrow(res)))
}

#binom.test(x[1], n_trials, trial_prob)$conf.int[1:2]
#binom.test(x[1:2], n_trials, trial_prob)$conf.int[1:2]

conf_names = c('conf_lo', 'conf_hi')

df = data.table(x, n)
df[, c('conf_lo', 'conf_hi'):=my_binom_test_dt(x, n)]
df[, eval(conf_names):=my_binom_test_dt(x, n)]

df[, conf_lo_ex:=binom.test(x, n)$conf.int[1], by = 1:nrow(df)]
df[, conf_hi_ex:=binom.test(x, n)$conf.int[2], by = 1:nrow(df)]

system.time(df[, conf_lo_ex:=binom.test(x, n)$conf.int[1], by = 1:nrow(df)])
system.time(df[, c('conf_lo', 'conf_hi'):=my_binom_test_dt(x, n)])