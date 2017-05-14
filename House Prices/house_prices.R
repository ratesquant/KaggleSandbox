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

box_cox_fun <-function(x, lambda) {
  if(lambda == 0)
    return ( log(x) )
  else
    return( (x^lambda - 1) / lambda )
}

# Read Data ---- 

random_seed = 12345678

#working_folder = 'C:/Dev/Kaggle/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')

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
df$X2ndFlrRatio = df$X2ndFlrSF/df$GrLivArea
#df$nfloors = as.numeric(df$X2ndFlrSF>0) + as.numeric(df$X1stFlrSF>0)
df$BsmtFinRatio = df$BsmtFinSF1/df$GrLivArea
df$TotalBsmtRatio = df$TotalBsmtSF/df$GrLivArea
df$GarageAreaRatio = df$GarageArea/df$GrLivArea
df$MasVnrAreaRatio = df$MasVnrArea/df$GrLivArea
df$GarageAreaNorm = df$GarageArea/ ((df$GarageCars + 1) * df$GrLivArea)
df$LotAreaLog = log(df$LotArea) 
df$LotFrontageRatio = df$LotFrontage/sqrt(df$LotArea)
df$SalePriceLog = log(df$SalePrice)

ggplot(df, aes(sample = log(SalePrice) )) + stat_qq()
ggplot(df, aes(sample = LotFrontage/sqrt(LotArea) )) + stat_qq()
ggplot(df, aes(sample = GarageArea )) + stat_qq()
ggplot(df, aes(sample = GarageArea/ ((GarageCars + 1) * GrLivArea) )) + stat_qq()
ggplot(df, aes(GarageYrBlt, SalePrice)) + geom_point()


#boxcox(SalePrice ~ OverallQual + GrLivArea, data = df, lambda = seq(-0.5, 0.5, length = 10))


## GBM ---- 
#year and month of sale, lot square footage, and number of bedrooms
cat_vars = c('Neighborhood', 'BsmtQual', 'GarageFinish', 'KitchenQual', 'FireplaceQu', 'GarageType', 'ExterQual', 'MasVnrType', 'TotRmsAbvGrd', 'Functional', 'ScreenPorch', 'RoofMatl', 'LandSlope')
con_vars = c('OverallQual', 'GrLivArea', 'TotalBsmtRatio', 'BsmtFinRatio', 'GarageCars', 'X1stFlrRatio', 'X2ndFlrRatio', 'LotAreaLog', 'MasVnrAreaRatio', 'LotFrontageRatio', 'GarageAreaNorm')

allvars = union ( cat_vars , con_vars) 
#allvars = names(df)[!(names(df) %in% c('SalePrice'))]
formula.all = formula (paste( 'SalePriceLog ~', paste(allvars, collapse = '+')) )

#0.15061
var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
var.monotone[allvars %in% c('OverallQual', 'GrLivArea','LotAreaLog', 'GarageCars', 'TotalBsmtRatio', 'BsmtFinRatio')] = 1
max_it = 32 * 1024
set.seed(random_seed)
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
                    n.cores = 4,
                    verbose = FALSE)

#show best iteration
best_it = gbm.perf(model.gbm, method = 'cv')
print(best_it)
grid()

#show importance
vars.importance = summary(model.gbm, n.trees = best_it, plotit=FALSE) # influence
plot_gbminfluence(vars.importance)
print(vars.importance)
#write.clipboard(vars.importance, sep = '\t')

#plot interactions
level2_interactions = gbm_interactions(model.gbm,  df[train_index, all.vars(formula.all)], iter = best_it, 1, 2)
plot_gbminteractions(level2_interactions)

plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf>.1], output_type = 'link')
marrangeGrob(plots, nrow=4, ncol=4)

#predict
pred.gbm = exp(predict(model.gbm, n.trees = best_it, newdata = df))

#profiles with respect to model vars (should match)
plots <- llply(all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, vname], error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles with respect to extra vars
plots <- llply(names(df)[-1][!(names(df)[-1] %in% all.vars(formula.all))], function(vname){
  plot_result = plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, vname], bucket_count = 16, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)


#compare residuals
plot_df = data.frame(actual = pred.gbm[train_index], model = df$SalePrice[train_index])
plot_df$error = plot_df$actual - plot_df$model
ggplot(plot_df, aes(model, actual)) + geom_point() + geom_smooth() + geom_abline(slope = 1, color = 'red')
ggplot(plot_df, aes(model, abs(error)/sd(error))) + geom_point() + geom_smooth()

results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(r2 = r_sqr(df$SalePrice[train_index],  x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res) #0.9382799 (15), 0.9535332 (full)
#0.15115


## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(Id = as.integer( as.numeric(df$Id[test_index]) ), SalePrice = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$Id),]
  file = file.path(working_folder, sprintf("House Prices/my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  print(file)
}

