library(reshape2)
library(ggplot2)
library(GGally)
library(Hmisc)
library(plyr)
library(gridExtra)

library(gbm)
library(np)
library(earth) 
library(rpart)
library(randomForest)
library(nnet)
library(e1071)
library(MASS)

r_sqr <-function(y, x) {
  return( summary(lm(y ~ x))$r.squared )
}

gbm_interactions <- function(gbm_model, data, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, plotit=FALSE)
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  all_combinations = combn(as.vector(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    data.frame(vars = paste(all_combinations[,i], collapse = '-'), 
               interaction_score = interact.gbm(gbm_model, data, all_combinations[,i])) 
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}

rm(list = ls())

random_seed = 12345678

folder = 'C:/Dev/Kaggle/House Prices/'

train <- read.csv(file.path(folder, 'train.csv'))
test  <- read.csv(file.path(folder, 'test.csv')) # 1459   80
test$SalePrice <- NA
df = rbind(train, test)
df$SalePrice = 1e-3 * df$SalePrice

#new variables
df$X1stFlrRatio = df$X1stFlrSF/df$GrLivArea
df$GrLivAreaRatio = 1.0 - (df$X1stFlrSF + df$X2ndFlrSF)/df$GrLivArea
df$nfloors = as.numeric(df$X2ndFlrSF>0) + as.numeric(df$X1stFlrSF>0)
df$BsmtFinRatio = df$BsmtFinSF1/df$GrLivArea
df$TotalBsmtRatio = df$TotalBsmtSF/df$GrLivArea
df$GarageAreaRatio = df$GarageArea/df$GrLivArea

#df$SalePriceLog = log(df$SalePriceLog) 

test_index = is.na(df$SalePrice)
train_index = !test_index

#saveRDS(train, file.path(folder, 'train.rds'))
#saveRDS(test, file.path(folder, 'test.rds'))

## GBM ---- 
#year and month of sale, lot square footage, and number of bedrooms
cat_vars = c('Neighborhood', 'GarageFinish', 'KitchenQual', 'ExterQual', 'BsmtQual', 'FireplaceQu', 'GarageType', 'FullBath')
con_vars = c('OverallQual', 'GrLivArea', 'TotalBsmtRatio', 'GarageCars', 'BsmtFinRatio', 'LotArea', 'nfloors','X1stFlrRatio', 'GrLivAreaRatio', 'GarageAreaRatio')

allvars = union ( cat_vars , con_vars) 
formula.all = formula (paste( 'SalePrice ~', paste(allvars, collapse = '+')) )

#0.15061
var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
var.monotone[allvars %in% c('GrLivArea', 'GarageCars', 'LotArea', 'TotalBsmtRatio', 'BsmtFinRatio', 'LotArea')] = 1
max_it = 32 * 1024
model.gbm = gbm(formula.all, 
                    data = df[train_index, all.vars(formula.all)], 
                    distribution = 'gaussian',
                    n.trees = max_it,
                    shrinkage = 0.001, #0.005
                    bag.fraction = 0.5,
                    interaction.depth = 2,
                    cv.folds = 5,
                    train.fraction = 1.0,
                    var.monotone = var.monotone,
                    n.cores = 1,
                    verbose = FALSE)

#show best iteration
best_it = gbm.perf(model.gbm, method = 'cv')
print(best_it)
grid()

#show importance
par(mfrow = c(1,1), las = 1)
vars.importance = summary(model.gbm, n.trees = best_it) # influence
print(vars.importance)
grid()

plot.gbm(model.gbm, n.trees =best_it,  i = as.character('GrLivAreaRatio') ) #vars.importance$var[2]
grid()
gbm_interactions(model.gbm,  df[train_index, all.vars(formula.all)], 2, 2)

pred.gbm = predict(model.gbm, n.trees = best_it, newdata = df)

plot(df$SalePrice[train_index], predict(model.gbm, n.trees =best_it))
  
results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(r2 = r_sqr(df$SalePrice[train_index],  x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res) #0.9189278

## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(Id = as.integer( as.numeric(df$Id[test_index]) ), SalePrice = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$Id),]
  file = file.path(folder, sprintf("my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  print(file)
}
