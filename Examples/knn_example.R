library(data.table)
library(ggplot2)
library(caret)
library(gridExtra)
library(plyr)
library(stringi)

#working_folder = 'C:/Dev/Kaggle/'
#working_folder = 'F:/Github/KaggleSandbox/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')
source(file.path(working_folder, '/Utils/common.R'))

options(na.action='na.pass')

### Load and Check Data -------------
df = data.table(diamonds)

df = df[sample.int(nrow(df), nrow(df)),]

df[, price:= as.numeric(price) ]

obj_var = 'price'
actual = df[[obj_var]]

df[, xy_ratio:= pmin(x,y)/pmax(x, y) ]
df[is.na(xy_ratio), xy_ratio:= NA ]


### Prepare variables -------------

exclude_vars = c('x', 'y', 'z') 
all_vars = names(df) %!in_set% c(exclude_vars)
all_vars = c('carat','cut','clarity', 'color')

### USE CARET KNN-------------
set.seed(132140937)

formula.knn    = formula(stri_join( 'price', ' ~ ', stri_join(unique(all_vars), collapse = ' + ')))

control = trainControl(method = "repeatedcv",
                       number = 10,
                       repeats = 3)

system.time(model.knn <- train(formula.knn, data = df[1:10000, all.vars(formula.knn), with = FALSE], 
                               method = "knn", #kknn
                               trControl = control,
                               tuneGrid = data.frame(k = seq(1,13,2)), #use instead of tuneLength
                               tuneLength = 10,
                               metric = "Rsquared"))
model.knn
plot(model.knn)

pred.knn = predict(model.knn, df, type = 'raw')

ggplot(data.frame(actual, model = pred.knn), aes(model, actual)) + geom_point() + geom_abline(slope = 1, color = 'red')
summary( lm(actual ~ model, data.frame(actual, model = pred.knn)) ) #0.9535

profile_plots = llply(names(df), function(vname){
  plot_profile(pred.knn, df$price, df[[vname]])+ ggtitle(vname)
})
marrangeGrob(profile_plots, nrow = 3, ncol = 4, top = NULL) 

### USE CARET kknn-------------
set.seed(132140937)

formula.kknn    = formula(stri_join( 'price', ' ~ ', stri_join(unique(all_vars), collapse = ' + ')))

control = trainControl(method = "repeatedcv",
                       number = 10,
                       repeats = 3)

#kmax, distance, kernel
system.time(model.kknn <- train(formula.kknn, data = df[1:5000, all.vars(formula.knn), with = FALSE], 
                               method = "kknn", #kknn
                               trControl = control,
                               tuneGrid = expand.grid(kmax = c(3,7,21), distance = c(2),kernel =c('optimal')), #use instead of tuneLength
                               tuneLength = 10,
                               metric = "Rsquared"))
model.kknn
plot(model.kknn)

pred.kknn = predict(model.kknn, df, type = 'raw')

ggplot(data.frame(actual, model = pred.kknn), aes(model, actual)) + geom_point() + geom_abline(slope = 1, color = 'red')
summary( lm(actual ~ model, data.frame(actual, model = pred.kknn)) ) #0.9202

profile_plots = llply(names(df), function(vname){
  plot_profile(pred.kknn, df$price, df[[vname]])+ ggtitle(vname)
})
marrangeGrob(profile_plots, nrow = 3, ncol = 4, top = NULL) 

