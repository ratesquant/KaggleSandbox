library(gbm)
library(data.table)
library(plyr)
library(ggplot2)
library(gridExtra)

working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox')
source(file.path(working_folder, '/Utils/common.R'))

set.seed(1234354)
n = 1000
x1 = rnorm(n)
x2 = rnorm(n) 

df = data.table(y = x1 + x2, x1, x2)

id_vars = c('y')

cat_vars = names(df)[which(sapply(df, is.character))] %!in_set% id_vars
df[,(cat_vars):=lapply(.SD, factor), .SDcols = cat_vars]

con_vars = names(df)[which(sapply(df, is.numeric))] %!in_set% id_vars
df[,(con_vars):=lapply(.SD, function(x) ecdf_norm(x, normal = FALSE) ), .SDcols = con_vars]

myformula = formula('y ~ x1 + x2')

ggplot(df, aes(x2, y)) + geom_point()
ggplot(dfi, aes(x1, x2)) + geom_point()

round_to_quantile<-function(x, n_level = 2){
  return ( round(n_level * ecdf(x)(x))/n_level )
}

run_hboost <- function(myformula, dfs, n_levels = 3){
  
  model.gbm = NULL
  
  shrinkage = 0.1
  max_it = 1000
  error_dist =  'gaussian'
  cv_folds = 4
  depth = 1
  
  myformula_withoffset = update(myformula,    '~ . +offset(yp)') 
  
  con_vars = names(dfs)[which(sapply(dfs, is.numeric))] %!in_set% id_vars
  
  yp = rep(mean(dfs$y), nrow(dfs))
  
  for(i_level in seq(n_levels)) {
    
    print(i_level)
      
    dfi = copy(dfs)
    
    dfi[,(con_vars):=lapply(.SD, function(x) round_to_quantile(x, 2^i_level )), .SDcols = con_vars]
    
    dfi[,yp:=yp]
    
    model.gbm = gbm(myformula, 
                    data = dfi,
                    distribution = error_dist,
                    n.trees = max_it,
                    shrinkage = shrinkage, 
                    bag.fraction = 0.9,
                    interaction.depth = depth,
                    cv.folds = cv_folds,
                    train.fraction = 1.0,
                    n.cores = 4,
                    verbose = FALSE)
    #plot_gbmiterations(model.gbm)
    best_it  = gbm.perf(model.gbm, plot.it = F)
    pred.gbm = predict(model.gbm, n.trees = best_it, newdata = dfi)# + yp
    
    #print(summary(lm(actual ~ model, data.frame(actual = dfi$y, model = pred.gbm))))
    
    print(sprintf('%d, r2 = %f',best_it, summary(lm(actual ~ model, data.frame(actual = dfi$y, model = pred.gbm)))$r.squared))
    
    #plots = plot_gbmpartial(model.gbm, best_it, c('x1', 'x2'), output_type = 'link')
    #marrangeGrob(plots, nrow = 1, ncol = 2, top = NULL)
    #plot_profile(pred.gbm, dfi$y, dfi$x1, bucket_count = 10, min_obs = 10, error_band ='normal')
    #plot_profile(pred.gbm, dfs$y, dfs$x1, bucket_count = 10, min_obs = 10, error_band ='normal')
    yp = pred.gbm
  }
  return ( list(model = model.gbm, offset = yp, best_it = best_it) )
}

results = run_hboost(myformula, df, n_levels = 10)

pred.gbm = predict(results$model, n.trees = results$best_it, newdata = df)
plot_profile(pred.gbm, df$y, df$x1, bucket_count = 20, min_obs = 3, error_band ='normal')
plot_profile(pred.gbm, df$y, df$x2, bucket_count = 20, min_obs = 3, error_band ='normal')
plot_profile(pred.gbm-results$offset, pred.gbm-results$offset, df$x2, bucket_count = 10, min_obs = 3, error_band ='normal')

plots = plot_gbmpartial(results$model, results$best_it, c('x1', 'x2'), output_type = 'link')
marrangeGrob(plots, nrow = 1, ncol = 2, top = NULL)
