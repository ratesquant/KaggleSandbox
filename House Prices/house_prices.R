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
library(corrplot)

rm(list = ls())

r_sqr <-function(y, x) {
  return( summary(lm(y ~ x))$r.squared )
}


# READ DATA ---- 

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
df$X3rdFlrRatio = 1.0 - (df$X1stFlrSF + df$X2ndFlrSF)/df$GrLivArea
df$BsmtFinRatio = df$BsmtFinSF1/df$GrLivArea
df$TotalBsmtRatio = df$TotalBsmtSF/df$GrLivArea
df$GarageAreaRatio = df$GarageArea/df$GrLivArea
df$MasVnrAreaRatio = df$MasVnrArea/df$GrLivArea
df$MasVnrAreaLog = log(df$MasVnrArea + 1)
df$GarageAreaNorm = ifelse(df$GarageCars > 0,  df$GarageArea/ df$GarageCars, 0)
df$GarageAreaLog = log(df$GarageArea + 1)
df$GarageAreaNormLog = log(df$GarageAreaNorm + 1)
df$LotAreaLog = log(df$LotArea) 
df$GrLivAreaLog = log(df$GrLivArea) 
df$LotFrontageRatio = df$LotFrontage/sqrt(df$LotArea)
df$SalePriceNorm = df$SalePrice/df$GrLivArea
df$SalePriceLog = log(df$SalePrice + 1)
df$SalePriceLogNorm = log(df$SalePrice + 1) - log(df$GrLivArea + 1)

df$GarageYrBltPrior1980 = factor(df$GarageYrBlt<1980)
df$YearBuiltPrior1970 = factor(df$YearBuilt<1970)
df$RemodAge = df$YrSold - df$YearRemodAdd
df$GarageAge = df$YrSold - df$GarageYrBlt
df$HouseAge = df$YrSold - df$YearBuilt
df$RemodAgeRatio = df$RemodAge/df$HouseAge
df$GarageAgeRatio = df$GarageAge/df$HouseAge
df$GarageAgeRel = df$HouseAge - df$GarageAge
df$OpenPorchSFRatio = df$OpenPorchSF/df$GrLivArea
df$WoodDeckSFRatio = df$WoodDeckSF/df$GrLivArea
df$ScreenPorchRatio = df$ScreenPorch/df$GrLivArea
df$LowQualFinSFRatio = df$LowQualFinSF/df$GrLivArea
df$LowQualFinSFLog = log(df$LowQualFinSF + 1)

df$RoomAvgArea =  df$GrLivArea / df$TotRmsAbvGrd

ggplot(df, aes(sample = log(SalePrice/GrLivArea) )) + stat_qq()
ggplot(df, aes(sample = RoomAvgArea )) + stat_qq()
ggplot(df, aes(sample = GrLivAreaLog )) + stat_qq()
ggplot(df, aes(sample = OpenPorchSF )) + stat_qq()

ggplot(df, aes(x = log(SalePrice/GrLivArea)  )) + stat_ecdf()

ggplot(df, aes(sample = LotFrontage )) + stat_qq()
ggplot(df, aes(sample = LotFrontage/sqrt(LotArea) )) + stat_qq()
ggplot(df, aes(sample = GarageArea )) + stat_qq()
ggplot(df, aes(sample = MasVnrArea )) + stat_qq()
ggplot(df, aes(SalePriceNorm, MasVnrAreaRatio)) + geom_point() + geom_smooth(method = 'loess', span = 0.2)
ggplot(df, aes(sqrt(LotArea), LotFrontage/sqrt(LotArea))) + geom_point() + geom_smooth(method = 'loess', span = 0.2)
ggplot(df, aes(LotFrontage, sqrt(LotArea))) + geom_point()
ggplot(df, aes(GarageAreaNorm, GarageCars )) + geom_point()
ggplot(df, aes(LowQualFinSF/GrLivArea, GrLivArea )) + geom_point()

ggplot(df, aes(GrLivArea, SalePriceNorm)) + geom_point()
ggplot(df, aes(YrSold - YearRemodAdd, residual)) + geom_point()
ggplot(df, aes(GarageAgeRel, GarageAge)) + geom_point()
ggplot(df, aes(HouseAge, HouseAge - RemodAge)) + geom_point()


## FIT MODEL ---- 
#year and month of sale, lot square footage, and number of bedrooms
cat_vars = c('Neighborhood', 'BsmtQual', 'GarageFinish', 'KitchenQual', 'FireplaceQu', 'GarageType', 'GarageQual', 'GarageCond', 'ExterQual', 'TotRmsAbvGrd', 
             'Functional', 'RoofMatl', 'OverallCond', 'SaleCondition', 'Fence', 'CentralAir','BsmtCond', 
             'LandContour', 'MoSold', 'FullBath', 'BsmtFullBath', 'Condition1', 'Foundation', 
             'LotConfig', 'ExterCond', 'Exterior1st','Exterior2nd', 'BsmtFinType1','BsmtFinType2', 'MSZoning',  'Fireplaces', 'HouseStyle')
con_vars = c('OverallQual', 'GrLivAreaLog', 'TotalBsmtRatio', 'BsmtFinRatio', 'GarageCars', 'LotAreaLog', 
             'OpenPorchSFRatio', 'ScreenPorchRatio', 'WoodDeckSFRatio', 'RemodAge', 'HouseAge', 
             'YrSold', 'LowQualFinSFLog')

#removed: LotFrontageRatio
#quesinable vars: MasVnrAreaRatio, MasVnrArea, LotFrontageRatio
#corr_matrix = cor(df[,con_vars], use="complete.obs")
#corrplot(corr_matrix, method="number")

allvars = union ( cat_vars , con_vars) 
#allvars = names(df) %!in% c('SalePrice')
formula.all = formula (paste( 'SalePriceLog ~', paste(allvars, collapse = '+')) )

var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
var.monotone[allvars %in% c('OverallQual','OverallCond', 'GarageCars', 'ScreenPorch', 'LotAreaLog', 'GrLivAreaLog',
                            'BsmtFullBath','WoodDeckSFRatio', 'OpenPorchSFRatio', 'ScreenPorchRatio', 'TotRmsAbvGrd', 'BsmtFinRatio', 'MasVnrAreaLog')] = 1
var.monotone[allvars %in% c('RemodAge', 'HouseAge', 'GarageAge', 'GarageAgeRel')] = -1

max_it = 40 * 1000 #64k is for s=0.001, 
#set.seed(random_seed)
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
pred.gbm = predict(model.gbm, n.trees = best_it, newdata = df)
pred.gbm = exp(pred.gbm) - 1

#show importance
vars.importance = summary(model.gbm, n.trees = best_it, plotit=FALSE) # influence
plot_gbminfluence(vars.importance)
print(vars.importance)
#write.clipboard(vars.importance, sep = '\t')

#plot interactions
#level2_interactions = gbm_interactions(model.gbm,  df[train_index, all.vars(formula.all)], iter = best_it, 1, 2)
#plot_gbminteractions(level2_interactions)

plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf>.1], output_type = 'link')
marrangeGrob(plots, nrow=5, ncol=5)

#vars to remove
plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf<=.1], output_type = 'link')
marrangeGrob(plots, nrow=4, ncol=4)

#correlation for model vars
df_num = df[train_index, !sapply(df, is.factor )]
df_num = df_num[,names(df_num) %in% all.vars(formula.all)]
df_num$Residual = df_num$SalePrice - pred.gbm[train_index]  
corr_matrix = cor(df_num, use="complete.obs")
corrplot(corr_matrix, type="lower", order ="hclust",  addrect=3)

#correlation for non-model vars
df_num = df[train_index, !sapply(df, is.factor )]
df_num = df_num[,names(df_num) %!in% all.vars(formula.all)]
df_num$Residual = df_num$SalePrice - pred.gbm[train_index]  
corr_matrix = cor(df_num, use="complete.obs")
corrplot(corr_matrix, type="lower", order ="hclust", addrect=3)

#fit model to residuals
df_res = df[train_index,]
df_res$Residual = log(pred.gbm[train_index]+1) - log(df$SalePrice[train_index]+1)
formula.res = formula (paste( 'Residual ~', paste(names(df_res) %!in_set% c('Id', 'SalePrice', 'SalePriceLogNorm', 'Residual', 'SalePriceNorm', all.vars(formula.all)), collapse = '+')) )
res_it = 20*1024
model.gbm.res = gbm(formula.res, 
                data = df_res[,all.vars(formula.res)], 
                distribution = 'gaussian',
                n.trees = res_it,
                shrinkage = 0.001, #0.001
                bag.fraction = 0.5,
                interaction.depth = 2,
                train.fraction = 1.0,
                n.cores = 4,
                verbose = FALSE)

vars.importance.res = summary(model.gbm.res, n.trees = res_it, plotit=FALSE) # influence
plot_gbminfluence(vars.importance.res)
print(vars.importance.res)

plots = plot_gbmpartial(model.gbm.res, res_it, as.character(vars.importance.res$var)[vars.importance.res$rel.inf>2], output_type = 'link')
marrangeGrob(plots, nrow=5, ncol=5)

# PREDICT ----
#pred.gbm = box_cox_fun_inv(predict(model.gbm, n.trees = best_it, newdata = df), boxcox_lambda)

#profiles with respect to model vars (should match well)
plots <- llply(all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, vname], bucket_count = 20, min_obs = 3, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles with respect to model vars (norm) (should match well)
plots <- llply(all.vars(formula.all), function(vname){
  plot_result = plot_profile(log(pred.gbm[train_index]+1), log(df$SalePrice[train_index]+1), df[train_index, vname], bucket_count = 20, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, 'LotFrontage'], bucket_count = 10, min_obs = 3, error_band ='normal')
plot_profile(pred.gbm[train_index]/df$GrLivArea[train_index], df$SalePrice[train_index]/df$GrLivArea[train_index], df[train_index, 'LotFrontage'], bucket_count = 10, min_obs = 3, error_band ='normal')
plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, 'MasVnrArea'], bucket_count = 16, min_obs = 3, error_band ='normal')
plot_profile(pred.gbm[train_index]/df$GrLivArea[train_index], df$SalePrice[train_index]/df$GrLivArea[train_index], df[train_index, 'MasVnrAreaRatio'], bucket_count = 16, min_obs = 3, error_band ='normal')

#profiles with respect to extra vars
plots <- llply(names(df)[-1] %!in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[train_index], df$SalePrice[train_index], df[train_index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles (norm) with respect to extra vars
plots <- llply(names(df)[-1] %!in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(log(pred.gbm[train_index]+1), log(df$SalePrice[train_index]+1), df[train_index, vname], bucket_count = 20, min_obs = 3, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)


#residual profiles with respect to extra vars
plots <- llply(names(df)[-1] %!in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[train_index]-df$SalePrice[train_index], 0*df$SalePrice[train_index], df[train_index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles for large sale prices 
index_jumbo = df$SalePrice > 200 & !is.na(df$SalePrice)
plots <- llply(names(df)[-1] %!in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[index_jumbo], df$SalePrice[index_jumbo], df[index_jumbo, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles for large errors 
index_error = abs(df$SalePrice - pred.gbm)> 25 & !is.na(df$SalePrice)
plots <- llply(names(df)[-1] %!in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[index_error], df$SalePrice[index_error], df[index_error, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#profiles for large errors (model vars)
#write.clipboard(df[abs(log(df$SalePrice+1) - log(pred.gbm+1))> 0.2 & !is.na(df$SalePrice), ])
index_error = abs(df$SalePrice - pred.gbm)> 25 & !is.na(df$SalePrice)
plots <- llply(all.vars(formula.all), function(vname){
  plot_result = plot_profile(pred.gbm[index_error], df$SalePrice[index_error], df[index_error, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)


#compare residuals
plot_df = data.frame(actual = pred.gbm[train_index], model = df$SalePrice[train_index], size = df$GrLivArea[train_index])
plot_df$error = plot_df$actual - plot_df$model
p1 = ggplot(plot_df, aes(model, actual)) + geom_point() + geom_smooth(method = 'loess', span = 0.2) + geom_abline(slope = 1, color = 'red')
p2 = ggplot(plot_df, aes(log(model+1), log(actual+1))) + geom_point() + geom_smooth(method = 'loess', span = 0.2) + geom_abline(slope = 1, color = 'red')
p3 = ggplot(plot_df, aes(model, abs(error)/sd(error))) + geom_point() + geom_smooth(method = 'loess', span = 0.2)
p4 = ggplot(plot_df, aes(model, error)) + geom_point() + geom_smooth(method = 'loess', span = 0.2)
grid.arrange(p1, p2, p3, p4)
#ggplot(plot_df, aes(abs(error))) + stat_ecdf()

## SAVE SOLUTION ----
results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(rms_log = rms_log(df$SalePrice[train_index],  x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res) #0.9419065 (non-mon), 0.9535332 (full)
#0.09507986
#0.12558 - best so far
#0.12644, 0.12643, 0.12667,  0.12672, 0.12810


## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(Id = as.integer( as.numeric(df$Id[test_index]) ), SalePrice = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$Id),]
  file = file.path(working_folder, sprintf("House Prices/my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  #zip(paste(file, '.zip', sep = ''), file, flags = "-9jX")
  print(file)
}

