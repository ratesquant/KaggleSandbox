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

# Read Data ---- 

random_seed = 12345678

#working_folder = 'C:/Dev/Kaggle/'
working_folder = file.path(Sys.getenv("HOME"), '/source/github/KaggleSandbox/')

source(file.path(working_folder, 'Utils/common.R'))

train <- read.csv(file.path(working_folder,'House Prices/train.csv'))
test  <- read.csv(file.path(working_folder,'House Prices/test.csv')) # 1459   80
test$SalePrice <- NA
df = rbind(train, test)
df$SalePrice = 1e-3 * df$SalePrice

test_index = is.na(df$SalePrice)
train_index = !test_index

#saveRDS(train, file.path(folder, 'train.rds'))
#saveRDS(test, file.path(folder, 'test.rds'))

# new variables ----
df$X1stFlrRatio = df$X1stFlrSF/df$GrLivArea
df$GrLivAreaRatio = 1.0 - (df$X1stFlrSF + df$X2ndFlrSF)/df$GrLivArea
df$nfloors = as.numeric(df$X2ndFlrSF>0) + as.numeric(df$X1stFlrSF>0)
df$BsmtFinRatio = df$BsmtFinSF1/df$GrLivArea
df$TotalBsmtRatio = df$TotalBsmtSF/df$GrLivArea
df$GarageAreaRatio = df$GarageArea/df$GrLivArea

#df$SalePriceLog = log(df$SalePriceLog) 



## GBM ---- 
#year and month of sale, lot square footage, and number of bedrooms
cat_vars = c('Neighborhood', 'GarageFinish', 'KitchenQual', 'ExterQual', 'BsmtQual', 'FireplaceQu', 'GarageType', 'FullBath')
con_vars = c('OverallQual', 'GrLivArea', 'TotalBsmtRatio', 'GarageCars', 'BsmtFinRatio', 'LotArea', 'nfloors','X1stFlrRatio', 'GrLivAreaRatio', 'GarageAreaRatio')

allvars = union ( cat_vars , con_vars) 
allvars = names(df)[!(names(df) %in% c('SalePrice'))]
formula.all = formula (paste( 'SalePrice ~', paste(allvars, collapse = '+')) )

#0.15061
var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
var.monotone[allvars %in% c('GrLivArea', 'GarageCars', 'LotArea', 'TotalBsmtRatio', 'BsmtFinRatio')] = 1
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
#write.clipboard(vars.importance, sep = '\t')
grid()

gbm_interactions(model.gbm,  df[train_index, all.vars(formula.all)], 2, 2)
plot_gbminteractions(a)

plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf>5], output_type = 'link')
marrangeGrob(plots, nrow=2, ncol=2)

#predict
pred.gbm = predict(model.gbm, n.trees = best_it, newdata = df)

plot(df$SalePrice[train_index], predict(model.gbm, n.trees =best_it))
  
results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(r2 = r_sqr(df$SalePrice[train_index],  x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res) #0.9189278, 0.9535332


## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(Id = as.integer( as.numeric(df$Id[test_index]) ), SalePrice = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$Id),]
  file = file.path(folder, sprintf("my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  print(file)
}

