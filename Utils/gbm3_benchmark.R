library(gbm3)
#library(gbm)
library(lubridate)
library(ggplot2)
library(profvis)

working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')
source(file.path(working_folder, 'Utils/common.R'))

profvis({
  n = 1024*4 #size of the sample 
  x1 = rnorm(n)
  x2 = rnorm(n)
  y = exp(-(x1*x1 + x2 * x2)) + 0.1*rnorm(n) # noise standard diviation is 0.1
  df = data.frame(y, x1, x2)
  
  set.seed(123456) # for reproducibility 
  
  start_time <- proc.time()
  
  if(FALSE){
  model.gbm = gbm(y ~ ., 
                  data = df, 
                  distribution = 'laplace', #gaussian laplace
                  n.trees = 10000,
                  shrinkage = 0.002, #learning rate: 0.1 - 0.001
                  bag.fraction = 0.8,
                  interaction.depth = 2,
                  cv.folds = 3, #3-10
                  train.fraction = 0.8,
                  par.details=gbmParallel(num_threads=4),
                  #n.cores = 4,
                  verbose = FALSE)
  }else {
  model.gbm = gbmt(y ~ ., 
                  data = df, 
                  distribution = gbm_dist("Laplace"), #gaussian laplace
                  train_params = training_params(
                  num_trees = 10000,
                  shrinkage = 0.002, #learning rate: 0.1 - 0.001
                  bag_fraction = 0.8,
                  interaction_depth = 2,
                  num_train = round(0.8 * nrow(df))),
                  cv_folds = 3, #3-10
                  par_details=gbmParallel(num_threads=4),
                  #n.cores = 4,
                  is_verbose = FALSE)
  }
  
  #gbm3 = 4.24699999999996S
  #plot_gbmiterations(model.gbm)
  
  elapsed = (proc.time() - start_time)[3]
  print( sprintf('elapsed: %s ( %0.1f sec | %.1f min | %.1f h)', seconds_to_period(elapsed), elapsed, elapsed/60, elapsed/(60*60)) )
})
