library(reshape2)
library(ggplot2)
library(Hmisc)
library(plyr)
library(gridExtra)

library(gbm)
library(np)
library(earth) 
library(rpart)
library(party)
library(caret)
library(randomForest)
library(nnet)
library(e1071)
library(MASS)

rm(list = ls())

r_sqr <-function(y, x) {
  return( summary(lm(y ~ x))$r.squared )
}

rms_log <-function(y, x) {
  return ( sqrt( mean(log(y+1) - log(x+1))^2 ))
}



# READ DATA ---- 

random_seed = 12345678

#working_folder = 'C:/Dev/Kaggle/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')

source(file.path(working_folder, 'Utils/common.R'))

train <- read.csv(file.path(working_folder,'SberbankHousing/train.csv'))
test  <- read.csv(file.path(working_folder,'SberbankHousing/test.csv')) # 1459   80
test$price_doc <- NA
df = rbind(train, test)
df$price_doc = 1e-3 * df$price_doc
test_index = is.na(df$price_doc)
train_index = !test_index

# Variables  ---- 

df$price_log =  log( df$price_doc + 1)


cat_vars = c()
con_vars = c()


# Regression  ---- 
allvars = union ( cat_vars , con_vars) 
allvars = names(df) %!in_set% c('price_log', 'price_doc', 'id', 'timestamp')
formula.all = formula (paste( 'price_log ~', paste(allvars, collapse = '+')) )

var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
#var.monotone[allvars %in% c()] =  1
#var.monotone[allvars %in% c()] = -1

max_it = 64*1024 #64k is for s=0.001, 
set.seed(random_seed)
model.gbm = gbm(formula.all, 
                data = df[train_index, all.vars(formula.all)], 
                distribution = 'gaussian',
                n.trees = max_it,
                shrinkage = 0.001, #0.001
                bag.fraction = 0.5,
                interaction.depth = 2,
                cv.folds = 10,
                train.fraction = 1.0,
                var.monotone = var.monotone,
                n.cores = 4,
                verbose = FALSE)
#model.gbm <- gbm.more(model.gbm,max_it)

#show best iteration
best_it = gbm.perf(model.gbm, method = 'cv')
print(best_it)
grid()
pred.gbm = exp(predict(model.gbm, n.trees = best_it, newdata = df)) - 1.0

#show importance
vars.importance = summary(model.gbm, n.trees = best_it, plotit=FALSE) # influence
plot_gbminfluence(vars.importance)
print(vars.importance)

