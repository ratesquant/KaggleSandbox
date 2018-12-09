library(rBayesianOptimization)
# Example 1: Optimization
## Set Pred = 0, as placeholder
Test_Fun <- function(x) {
  list(Score = exp(-(x - 2)^2) + 0.1*rnorm(1),
       Pred = 0)
}
## Set larger init_points and n_iter for better optimization result
OPT_Res <- BayesianOptimization(Test_Fun,
                                bounds = list(x = c(1, 3)),
                                init_points = 2, n_iter = 20,
                                acq = "ei", #ucb, ei, poi
                                kappa = 2.576, eps = 0.0,
                                verbose = TRUE)

fr <- function(x) {
  (Test_Fun(x))$Score
}
optimize(fr, c(-6, 6), maximum = TRUE) #2.000866