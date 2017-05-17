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

cat_vars = c()
con_vars = c()


# Regression  ---- 
allvars = union ( cat_vars , con_vars) 
allvars = names(df) %!in_set% c('price_log', 'price_doc', 'id', 'timestamp', 'sub_area')
formula.all = formula (paste( 'price_log ~', paste(allvars, collapse = '+')) )

var.monotone = rep(0, length(allvars)) #1-increasing, -1 - decreasing, 0: any
#var.monotone[allvars %in% c()] =  1
#var.monotone[allvars %in% c()] = -1

max_it = 500*1024 #64k is for s=0.001, 
set.seed(random_seed)
model.gbm = gbm(formula.all, 
                data = df[train_index, all.vars(formula.all)], 
                distribution = 'gaussian',
                n.trees = max_it,
                shrinkage = 0.001, #0.001
                bag.fraction = 0.5,
                interaction.depth = 2,
                cv.folds = 5,
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

plots = plot_gbmpartial(model.gbm, best_it, as.character(vars.importance$var)[vars.importance$rel.inf>.1], output_type = 'link')
marrangeGrob(plots, nrow=5, ncol=5)



# Solution  ---- 
results = list()
results$gbm = pred.gbm

res = ldply(results, .id = 'model', function(x) {
  c(r2 = r_sqr(df$price_doc[train_index],  x[train_index]),
    rms_log = rms_log(1e3*df$price_doc[train_index],  1e3*x[train_index]),
    na_count = sum(is.na(x[test_index])))
})
print(res)

## print solution ---- 
for (model_name in names(results) ){
  submit <- data.frame(id = as.integer( as.numeric(df$id[test_index]) ), price_doc = 1e3*results[[model_name]][test_index])
  submit = submit[order(submit$id),]
  file = file.path(working_folder, sprintf("SberbankHousing/my_solution_%s.csv", model_name))
  write.csv(submit, file = file, row.names = FALSE)
  #zip(paste(file, '.zip', sep = ''), file, flags = "-9jX")
  print(file)
}

