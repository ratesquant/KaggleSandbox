library(xgboost)
library(data.table)
library(Matrix)
library(vip)
library(pdp)
library(rBayesianOptimization)
library(vtreat)
library(ggplot2)
library(gridExtra)
library(corrplot)
library(plyr)

#working_folder = 'C:/Dev/Kaggle/'
#working_folder = 'F:/Github/KaggleSandbox/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')
source(file.path(working_folder, '/Utils/common.R'))

options(na.action='na.pass')

### Load and Check Data -------------
df = data.table(diamonds)

df[, price:= as.numeric(price) ]

obj_var = 'price'
actual = df[[obj_var]]

df[, xy_ratio:= pmin(x,y)/pmax(x, y) ]
df[is.na(xy_ratio), xy_ratio:= NA ]

ggplot(df[1:1000,], aes(depth, 2*z/(x+y) )) + geom_point() # depth = 2*z/(y + x)

### Prepare variables -------------

exclude_vars = c('x', 'y', 'z') 
all_vars = names(df) %!in_set% c(exclude_vars)

mon_inc_vars = c('carat')
mon_dec_vars = c('')


var.monotone = rep(0, length(all_vars))
var.unconst = var.monotone
var.monotone[all_vars %in% mon_inc_vars]  =  1
var.monotone[all_vars %in% mon_dec_vars]  = -1

#convert strings to numerical variables, otherwise use one-hot
df_train <- subset(data.matrix(df[,all_vars, with = F]), select = -price) #stats::model.matrix
df_train <- sparse.model.matrix(price ~ ., data = df[,all_vars, with = F])[,-1] #stats::model.matrix

#num_vars  = model_vars %in_set% names(which(sapply(df, is.numeric)))
corr_matrix = cor(as.matrix(df_train), use="complete.obs")
corrplot(corr_matrix, method="number", number.cex = .7)
corrplot(corr_matrix, method="circle", order="hclust")

### Do Cross Validation -------------
set.seed(132140937)

xgb_cv <- xgboost::xgb.cv(
  data = df_train, label = actual, 
  verbose = 1, objective = "reg:linear",eval_metric = 'rmse',
  nrounds = 1000, 
  max_depth = 13, 
  subsample = 0.7,
  eta = 0.0335, 
  #monotone_constraints = var.monotone,
  gamma = 0, 
  nfold = 5,  
  nthread = 4, 
  print_every_n = 10,
  early_stopping_rounds = 30)

ggplot(xgb_cv$evaluation_log, aes(iter, train_rmse_mean)) + geom_line() + geom_line(aes(iter, test_rmse_mean), color = 'red') +
  geom_ribbon(aes(ymin = test_rmse_mean - test_rmse_std, ymax = test_rmse_mean + test_rmse_std), fill = 'red', alpha = 0.2) + 
  geom_vline(xintercept = xgb_cv$best_iteration) + 
  ggtitle(sprintf('cv: %.3f (%d)',xgb_cv$evaluation_log$test_rmse_mean[xgb_cv$best_iteration], xgb_cv$best_iteration))

### Train Model -------------

model.xgb <- xgboost(data = df_train,label = actual,
                     nrounds = 208, 
                     verbose = 1, 
                     print_every_n = 10,
                     early_stopping_rounds = 30,
                     max_depth = 13, 
                     eta = 0.0335, 
                     nthread = 4,
                     subsample = 0.7,
                     #monotone_constraints = var.monotone,
                     objective = "reg:linear",eval_metric = 'rmse')

pred.xgb <- predict(model.xgb, df_train )

ggplot(data.frame(actual, model = pred.xgb), aes(model, actual)) + geom_point() + geom_abline(slope = 1, color = 'red')
summary( lm(actual ~ model, data.frame(actual, model = pred.xgb)) )

ggplot(cbind(df, error = actual - pred.xgb), aes(x*z*y, error)) + geom_point()

#feature importance
vip(model.xgb) 

importance_matrix <- xgb.importance(model = model.xgb)
print(importance_matrix)
xgb.ggplot.importance(importance_matrix = importance_matrix)
xgb.ggplot.deepness(model.xgb, which = '2x1')
xgb.ggplot.deepness(model.xgb, which = 'max.depth')
xgb.ggplot.deepness(model.xgb, which = 'med.depth')
xgb.ggplot.deepness(model.xgb, which = 'med.weight')

#sharp profiles, takes a long time to compute
xgb.plot.shap(df_train, model = model.xgb, top_n = 4, n_col = 2)

pd_plots = llply(importance_matrix$Feature, function(vname){
  temp = partial(model.xgb, pred.var = vname, train = df_train, prob = FALSE)
  names(temp) = make.names(names(temp))
  ggplot(temp, aes_string(make.names(vname), 'yhat')) + geom_line()
})
marrangeGrob(pd_plots, nrow = 3, ncol = 4, top = NULL)

#partial(model.xgb, pred.var = "carat", ice = TRUE, center = TRUE, 
#        plot = TRUE, rug = TRUE, alpha = 0.1, plot.engine = "ggplot2", train = df_train)

#partial(ames_xgb, pred.var = c("carat", "Gr_Liv_Area"),
#        plot = TRUE, chull = TRUE, plot.engine = "ggplot2", train = df_train)

### Hyper Tuning -------------
set.seed(132140937)
#Best Parameters Found:  Round = 29	eta = 0.1663	max_depth = 8.0000	subsample = 1.0000	Value = -522.3625 
#Best Parameters Found:  Round = 47	eta = 0.0335	max_depth = 13.0000	subsample = 0.7085	monotone = 0.0000	Value = -518.4975 

xgb_cv_bayes <- function(eta, max_depth, subsample, monotone, min_child_weight) {
  cv <- xgb.cv(params = list(eta = eta,
                             max_depth = max_depth,
                             subsample = subsample, 
                             min_child_weight = min_child_weight,
                             monotone_constraints = ifelse(rep(monotone==1,length(var.monotone)), var.monotone, var.unconst),
                             colsample_bytree = 1.0,
                             objective = "reg:linear",
                             eval_metric = "rmse"),
               data = df_train, label = actual,
               nround = 1000,
               nfold = 5,
               early_stopping_rounds = 30,  
               verbose = 0)
  
  list(Score = -cv$evaluation_log$test_rmse_mean[cv$best_iteration], Pred = 0)
}
OPT_Res <- BayesianOptimization(xgb_cv_bayes,
                                bounds = list(
                                  eta = c(0.001, 1.0),
                                  max_depth = c(1L, 15L),
                                  subsample = c(0.5, 1.0),
                                  monotone = c(0L, 1L),
                                  min_child_weight = c(1L, 10L)),
                                init_grid_dt = NULL, init_points = 10, n_iter = 50,
                                acq = "ucb", kappa = 2.576, eps = 0.0,
                                verbose = TRUE)

### TIMING Tuning -------------

res = ldply(seq(10), function(n_cores) {
  
  set.seed(132140937)
  
  run_xgboost <- function(n_cores) {
  model.xgb <- xgboost(data = df_train,label = actual,
                       nrounds = 100, 
                       verbose = 0, 
                       print_every_n = 10,
                       early_stopping_rounds = 30,
                       max_depth = 13, 
                       eta = 0.0335, 
                       nthread = n_cores,
                       subsample = 0.7,
                       #monotone_constraints = var.monotone,
                       objective = "reg:linear",eval_metric = 'rmse')
  }
  t = system.time(run_xgboost(n_cores))
  
  return (data.frame(n_cores, user = t[1], system = t[2], elapsed = t[3]))
})

ggplot(res, aes(n_cores, elapsed)) + geom_point()
ggplot(res, aes(n_cores, (system + user)/elapsed )) + geom_point()

### Hyper Tuning: Random Search -------------
n_runs = 100
my_params = data.table(depth = sample(seq(from = 1, to = 15),n_runs, TRUE), 
                       eta = runif(n_runs, 0.001, 0.1), 
                       subsample = runif(n_runs, 0.6, 1.0), 
                       gamma = runif(n_runs, 0, 1.0), 
                       min_child_weight =sample(seq(10),n_runs, TRUE))

param_res = ldply(seq(nrow(my_params)), function(run_index){
  print(my_params[run_index,])
  
  set.seed(132140937)
  
  my_param <- list(
    max_depth = my_params$depth[run_index], 
    eta = my_params$eta[run_index], 
    subsample = my_params$subsample[run_index],
    min_child_weight = my_params$min_child_weight[run_index],
    gamma = my_params$gamma[run_index],
    objective = "reg:linear",
    eval_metric = "rmse",
    base_score = mean(actual))
  
  xgb_cv <- xgboost::xgb.cv(params = my_param,
                            data = df_train, label = actual, 
                            verbose = 1,
                            nrounds = 10000, 
                            nfold = 5,  
                            nthread = 1, 
                            print_every_n = 1000,
                            early_stopping_rounds = 50)
  gc(reset = TRUE)
  return ( data.frame(best_it = xgb_cv$best_iteration, xgb_cv$evaluation_log[xgb_cv$best_iteration,]) ) 
})
param_res = cbind(param_res, my_params)
setDT(param_res)
setorder(param_res, test_rmse_mean)
param_res[, rank:=seq(nrow(param_res))]

ggplot(param_res, aes(rank, depth, size = min_child_weight )) + geom_point()
ggplot(param_res, aes(rank, eta, size = min_child_weight )) + geom_point()

ggplot(param_res, aes(depth, test_rmse_mean, color = factor(depth), size = min_child_weight )) + geom_point() + geom_hline(yintercept = min(param_res$test_rmse_mean), alpha = 0.1)
ggplot(param_res, aes(subsample, test_rmse_mean, color = factor(depth), size = min_child_weight )) + geom_point()
ggplot(param_res, aes(eta, test_rmse_mean, color = factor(depth), size = min_child_weight )) + geom_point()
ggplot(param_res, aes(min_child_weight, test_rmse_mean, color = factor(depth), size = min_child_weight )) + geom_point()
ggplot(param_res, aes(gamma, test_rmse_mean, color = factor(depth), size = min_child_weight )) + geom_point()


