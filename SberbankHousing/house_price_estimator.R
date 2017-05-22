library(reshape2)
library(ggplot2)
library(Hmisc)
library(plyr)
library(gridExtra)
library(corrplot)

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
library(lubridate)


rm(list = ls())

r_sqr <-function(y, x) {
  return( summary(lm(y ~ x))$r.squared )
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

df$sample =  factor(ifelse(train_index, 'train', 'test'))
df$price_log =  log( df$price_doc + 1)
df$full_sq_log = log(df$full_sq + 1)
df$area_m_log = log(df$area_m + 1)
df$max_floor_adj = pmax(df$max_floor, df$floor)
df$floor_diff = df$max_floor_adj - df$floor 
df$sale_year = year(as.Date(as.character(df$timestamp)))
df$sale_month = month(as.Date(as.character(df$timestamp)))
df$state_adj = pmin(df$state, 4)

#filter out outliers
train_index = train_index & df$full_sq <= max(df$full_sq[test_index])
train_index = train_index & (df$num_room <= 10  | is.na(df$num_room))
train_index = train_index & (df$max_floor <= 60 | is.na(df$max_floor))
train_index = train_index & (df$floor <= 50 | is.na(df$floor))

#green_zone_km, railroad_km, mosque_km, kindergarten_km 

ggplot(df[train_index,], aes(log(area_m), price_log)) + geom_point() + geom_smooth()
ggplot(df, aes(kindergarten_km, color = sample)) + geom_density()
ggplot(df, aes(metro_min_avto, metro_min_walk, color = sample)) + geom_point()
ggplot(df[train_index,], aes(floor, price_log)) + geom_point() + geom_smooth()
ggplot(df[train_index,], aes(metro_min_avto)) + stat_ecdf()
ggplot(df, aes(build_count_brick, color = sample)) + stat_ecdf()

summary(df[train_index,'sport_count_5000'])
summary(df[test_index,'sport_count_5000'])

#timestamp: date of transaction
#full_sq: total area in square meters, including loggias, balconies and other non-residential areas
#life_sq: living area in square meters, excluding loggias, balconies and other non-residential areas
#floor: for apartments, floor of the building
#max_floor: number of floors in the building
#material: wall material
#build_year: year built
#num_room: number of living rooms
#kitch_sq: kitchen area
#state: apartment condition
#product_type: owner-occupier purchase or investment
#sub_area: name of the district


#candidates
can_vars = c('full_sq_log', 'num_room', 'cafe_count_5000_price_2500', 'sport_count_3000',
'num_room', 'cafe_count_5000_price_2500', 'cafe_count_5000_price_high', 'sport_count_3000','cafe_count_2000','build_year','ttk_km','theater_km','museum_km','catering_km','exhibition_km',
'metro_min_avto','cafe_count_5000','cafe_count_3000','floor',
'max_floor','metro_km_avto','mosque_km','public_healthcare_km','state',
'green_zone_km','bulvar_ring_km','mkad_km','kindergarten_km','life_sq','nuclear_reactor_km','cafe_count_2000_price_2500',
'railroad_km','big_road2_km', 'product_type','green_part_5000','power_transmission_line_km','indust_part','sadovoe_km','swim_pool_km','hospice_morgue_km','workplaces_km','office_sqm_1500',
'exhibition_km','trc_sqm_5000','kitch_sq','trc_count_1500', 'max_floor_adj', 'sale_year', 'sale_month','area_m_log', 'exhibition_km', 'sub_area')

#checked and have very little influence (<0.1)
dum_vars = c('big_market_raion', 'incineration_raion', 'oil_chemistry_raion', 'railroad_terminal_raion', 'thermal_power_plant_raion','nuclear_reactor_raion','radiation_raion')

cat_vars = c('product_type', 'state_adj', 
             'detention_facility_raion', 'ecology')

con_vars = c('full_sq_log', 'num_room', 'cafe_count_5000_price_2500', 'sport_count_3000', 'floor', 'max_floor_adj', 
             'mkad_km', 'metro_min_avto', 'green_zone_km', 'railroad_km', 'mosque_km','kindergarten_km', 'sale_year', 'sale_month', 
             'cafe_count_5000_price_high', 'build_count_brick','green_part_5000', 'area_m_log','exhibition_km', 'kitch_sq', 'prom_part_3000', 'cafe_sum_500_max_price_avg')
non_vars = c('price_log', 'price_doc', 'id', 'timestamp', 'sample')

#corr_matrix = cor(df[,con_vars], use="complete.obs")
#corrplot(corr_matrix, method="number")

# Regression  ---- 
allvars = union ( cat_vars , con_vars) 
#allvars = names(df) %!in_set% non_vars
formula.all = formula (paste( 'price_log ~', paste(allvars, collapse = '+')) )

var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
var.monotone[allvars %in% c('full_sq_log', 'num_room', 'cafe_count_5000_price_2500','cafe_count_5000_price_high', 'sport_count_3000', 'mosque_km','state_adj')] =  1
var.monotone[allvars %in% c('mkad_km','metro_min_avto', 'kindergarten_km', 'green_zone_km')] = -1

max_it = 50*1024 #64k is for s=0.001, 
#set.seed(random_seed)
model.gbm = gbm(formula.all, 
                data = df[train_index, all.vars(formula.all)], 
                distribution = 'gaussian',
                n.trees = max_it,
                shrinkage = 0.001, #0.001
                bag.fraction = 0.5,
                interaction.depth = 2,
                #cv.folds = 5,
                train.fraction = 0.5,
                var.monotone = var.monotone,
                n.cores = 4,
                verbose = FALSE)
#model.gbm <- gbm.more(model.gbm,max_it)

#show best iteration
#best_it = gbm.perf(model.gbm, method = 'cv')
#gbm.perf(model.gbm, method = 'test',oobag.curve = TRUE)
best_it = gbm.perf(model.gbm, method = 'test') 
print(best_it)
grid()
pred.gbm = exp(predict(model.gbm, n.trees = best_it, newdata = df)) - 1.0

#show importance
vars.importance = summary(model.gbm, n.trees = best_it, plotit=FALSE) # influence
plot_gbminfluence(vars.importance)
print(vars.importance)

#partial dependence
plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf>=.1], output_type = 'link')
marrangeGrob(plots, nrow=5, ncol=5)

#vars to remove
plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf<.1], output_type = 'link')
marrangeGrob(plots, nrow=5, ncol=5)


#profiles (norm) with respect to model vars
plots <- llply(names(df) %in_set% all.vars(formula.all), function(vname){
  plot_result = plot_profile(log(pred.gbm[train_index]+1), log(df$price_doc[train_index]+1), df[train_index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)
#str(df[train_index,all.vars(formula.all)])

#profiles (norm) with respect to candidate vars
plots <- llply(can_vars %!in_set% c(all.vars(formula.all), non_vars), function(vname){
  plot_result = plot_profile(log(pred.gbm[train_index]+1), log(df$price_doc[train_index]+1), df[train_index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)
plot_profile(log(pred.gbm[train_index]+1), log(df$price_doc[train_index]+1), df[train_index, 'sub_area'], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle('sub_area')


#profiles (norm) with respect to candidate vars for low price
index = train_index & (!is.na(df$price_doc) | log(df$price_doc+1) < 9) 
plots <- llply(can_vars %!in_set% c(all.vars(formula.all), non_vars), function(vname){
  plot_result = plot_profile(log(pred.gbm[index]+1), log(df$price_doc[index]+1), df[index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)


#profiles (res) with respect to candidate vars
plots <- llply(can_vars %!in_set% c(all.vars(formula.all), non_vars), function(vname){
  plot_result = plot_profile(log(pred.gbm[train_index]+1)-log(df$price_doc[train_index]+1), 0*df$price_doc[train_index], df[train_index, vname], bucket_count = 10, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=4, ncol=4)

#compare residuals
plot_df = data.frame(actual = df$price_doc[train_index], model = pred.gbm[train_index])
plot_df$error = plot_df$actual - plot_df$model
p1 = ggplot(plot_df, aes(model, actual)) + geom_point(size = 0.2) + geom_smooth() + geom_abline(slope = 1, color = 'red')
p2 = ggplot(plot_df, aes(log(model+1), log(actual+1))) + geom_point(size = 0.2) + geom_smooth() + geom_abline(slope = 1, color = 'red')
grid.arrange(p1, p2)


# Solution  ---- 
results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(r2 = r_sqr(df$price_doc[train_index],  x[train_index]),
    rms_log = rms_log(1e3*df$price_doc[train_index],  1e3*x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res)
#
#

## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(id = as.integer( as.numeric(df$id[test_index]) ), price_doc = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$id),]
  file = file.path(working_folder, sprintf("SberbankHousing/my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  #zip(paste(file, '.zip', sep = ''), file, flags = "-9jX")
  print(file)
}


###  Fit residuals to remaining vars ---- 
formula.res = formula (paste( 'price_log_res ~', paste(names(df) %!in_set% c(all.vars(formula.all), non_vars), collapse = '+')) )
df.res = df[train_index,]
df.res$price_log_res = log(pred.gbm[train_index]+1)-log(df$price_doc[train_index]+1)
#write.clipboard(df.res[log(df$price_doc[train_index]+1)<8,])

max_it = 10*1000 #80 sec for 1k it

model.gbm.res = gbm(formula.res, 
                data = df.res[, all.vars(formula.res)], 
                distribution = 'gaussian',
                n.trees = max_it,
                shrinkage = 0.001, #0.001
                bag.fraction = 0.5,
                interaction.depth = 2,
                train.fraction = 0.5,
                n.cores = 4,
                verbose = FALSE)

best_it_res = gbm.perf(model.gbm.res, method = 'test') 
print(best_it_res)
grid()

#show importance
vars.importance.res = summary(model.gbm.res, n.trees = best_it_res, plotit=FALSE) # influence
plot_gbminfluence(vars.importance.res)
print(vars.importance.res)