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
library(stringi)

#working_folder = 'C:/Dev/Kaggle/'
#working_folder = 'F:/Github/KaggleSandbox/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')
source(file.path(working_folder, '/Utils/common.R'))

options(na.action='na.pass')

### Prepare Data -------------
n = 4*1024
df = data.table(cat1 = sample(LETTERS, n, TRUE), 
                cat2 = sample(LETTERS, n, TRUE), 
                cat3 = sample(LETTERS, n, TRUE), 
                cat4 = sample(LETTERS, n, TRUE), 
                cat5 = sample(LETTERS, n, TRUE))

df[, obj_var:= runif(n)]
df[cat1 == 'S', obj_var:= 1]

obj_var = 'obj_var'
actual = df[[obj_var]]
### Prepare variables -------------

#convert strings to numerical variables, otherwise use one-hot
cat_vars = names(df)[which(sapply(df, is.character))]
fac_vars = stri_join(cat_vars, '_factor')
df[, (fac_vars):=lapply(.SD, function(x) factor(x)), .SDcols = cat_vars]

all_vars = names(df) %!in_set% c(cat_vars, obj_var)

train_index = sample.int(nrow(df), 0.5*nrow(df))
df_all <- data.matrix(df[,all_vars, with = F]) #stats::model.matrix\
df_train <- df_all[  train_index,] #stats::model.matrix
df_test  <- df_all[ -train_index,]  #stats::model.matrix
#df_train <- sparse.model.matrix(obj_var ~ ., data = df[,all_vars, with = F])[,-1] #stats::model.matrix

### Train Model -------------

dtrain <- xgb.DMatrix(df_train, label = actual[train_index] )
dtest  <- xgb.DMatrix(df_test, label = actual[-train_index] )

my_params <- list(max_depth = 10, 
                  eta = 0.01, 
                  nthread = 1,
                  subsample = 0.9,
                  min_child_weight = 10,
                  gamma = 0.1,
                  objective = "reg:linear",
                  eval_metric = "rmse",
                  base_score = mean(actual[train_index]),
                  monotone_constraints = var.monotone)

model.xgb <- xgb.train(my_params, data = dtrain, 
                       watchlist = list(train = dtrain, eval = dtest),
                       nrounds = 5000, 
                       verbose = 1, 
                       print_every_n = 100,
                       early_stopping_rounds = 100)

pred.xgb <- predict(model.xgb, df_all )
plot_profile(pred.xgb, actual, factor(df[['cat1_factor']]), error_band = 'norm')
plot_profile(pred.xgb[-train_index], actual[-train_index], factor(df[['cat1_factor']][-train_index]), error_band = 'norm')

ggplot(model.xgb$evaluation_log, aes(iter, train_rmse)) + geom_line() + geom_line(aes(iter, eval_rmse), color = 'red')

summary(lm(actual ~ pred.xgb))

ggplot(data.frame(actual, model = pred.xgb), aes(model, actual)) + geom_point() + geom_abline(slope = 1, color = 'red')

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

