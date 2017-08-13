library(gbm)
library(ggplot2)
library(plyr)
library(gridExtra)

### Utils functions ------

plot_gbminteractions <- function(x){
  ggplot(x, aes(x = reorder(vars, interaction_score), y = interaction_score))  + geom_bar(stat = 'identity') + coord_flip() + geom_hline(yintercept = 0.1, color = 'red') +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_gbmiterations <- function(gbm_model) {
  
  it_data = data.frame(it = seq(gbm_model$n.trees), cv_error = gbm_model$cv.error, tr_error = gbm_model$train.error)
  it_data_melt = melt(it_data, id = 'it', variable.name = "error_type", value.name = "error")
  
  plot = ggplot(it_data_melt, aes(it, error, group = error_type, color = error_type)) + geom_line() + 
    geom_vline(xintercept = min(which(it_data$cv_error == min(it_data$cv_error))), color = 'blue') +
    geom_vline(xintercept = min(which(it_data$cv_error < 1.001*min(it_data$cv_error))), color = 'blue', alpha = 0.5) + 
    geom_hline(yintercept = min(it_data$cv_error), color = 'blue', alpha = 0.5, linetype = "dashed") + 
    ggtitle(paste('min cv error: ', round(min(it_data$cv_error),6) ,sep = ''))
  
  return (plot)
}

plot_gbmpartial <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response', add_rug = TRUE, max_run_points = 1024){
  plots <- llply(variables, function(vname){
    plot_data = plot(gbm_model, i.var = vname, n.trees = iter, type = output_type, continuous.resolution = resolution, return.grid = TRUE)
    names(plot_data) <- c('x', 'y')
    
    plot_result <- ggplot() + geom_blank() 
    
    if(is.factor(plot_data$x)){
      plot_result = ggplot(plot_data, aes(reorder(x, y), y, group = 1)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.text.x = element_text(angle = 90, hjust = 1), axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    }else{
      plot_result = ggplot(plot_data, aes(x, y)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
      
      if(add_rug){
        vname_index = match(vname, gbm_model$var.names)
        size_per_var = length(gbm_model$data$x) / length(gbm_model$var.names)
        xdata = gbm_model$data$x[1:size_per_var + (vname_index - 1) * size_per_var]
        
        rug_index = sample.int(size_per_var, min(max_run_points, size_per_var))
        
        plot_result = plot_result + 
          geom_rug(data = data.frame(x = xdata[rug_index]), aes(x), sides = 'b', alpha = 0.2, size = 0.2, inherit.aes = FALSE) +
          geom_rug(data = data.frame(x = quantile(xdata, seq(0, 1, by = 0.25), names = FALSE, na.rm = TRUE)), aes(x), sides = 'b', alpha = 0.8, size = 0.5, inherit.aes = FALSE, color = 'red')
        
      }
    }
    return (plot_result)
  })
  return (plots)
}

plot_gbmpartial_2d <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response', add_rug = TRUE, max_run_points = 1024){
  plots <- llply(variables, function(vname){
    
    var_pair = strsplit(as.character(vname),'|', fixed = T)[[1]]
    plot_data = plot(gbm_model, i.var = var_pair, n.trees = iter, type = output_type, continuous.resolution = resolution, return.grid = TRUE)
    names(plot_data) <- c('x1', 'x2', 'y')
    
    plot_result = ggplot(plot_data, aes(x1, x2, z = y, fill = y)) + geom_raster() + scale_fill_distiller(palette = 'Spectral') +
      theme(axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    
    if(add_rug)
    {
      vname_index1 = match(var_pair[1], gbm_model$var.names)
      vname_index2 = match(var_pair[2], gbm_model$var.names)
      size_per_var = length(gbm_model$data$x) / length(gbm_model$var.names)
      
      xdata = gbm_model$data$x[1:size_per_var + (vname_index1 - 1) * size_per_var]
      ydata = gbm_model$data$x[1:size_per_var + (vname_index2 - 1) * size_per_var]
      
      rug_index = sample.int(size_per_var, min(max_run_points, size_per_var))
      
      plot_result = plot_result + geom_point(data = data.frame(x = xdata[rug_index], y = ydata[rug_index]), aes(x, y), alpha = 0.2, size = 0.2, inherit.aes = FALSE, color = 'black')
    }
    
    return (plot_result)
  })
  return (plots)
}

gbm_interactions <- function(gbm_model, data, iter, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, plotit=FALSE)
  if(is.null(gbm_summary$rel.inf)) gbm_summary$rel.inf = gbm_summary$rel_inf
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  all_combinations = combn(as.vector(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    data.frame(vars = paste(all_combinations[,i], collapse = '|'), 
               interaction_score = interact.gbm(gbm_model, data, all_combinations[,i], n.trees = iter)) 
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}


plot_gbminfluence <- function(x){
  ggplot(x, aes(x = reorder(var, rel.inf), y = rel.inf, fill = cut(rel.inf, c(0, 0.01, 0.1, 1, 10, 100), include.lowest = TRUE,ordered_result = TRUE )))  + 
    geom_bar(stat = 'identity') + coord_flip() + 
    geom_hline(yintercept = 1.0, color = 'red') +
    #geom_hline(yintercept = 0.1, color = 'red', linetype="dashed") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_profile <- function(mod, act, profile, bucket_count = 10, min_obs = 30, error_band = c('normal', 'binom'), conf_level = 0.95){
  plot_result = ggplot() + geom_blank()
  
  factor_plot = FALSE
  
  if( !is.numeric(profile)){
    buckets = factor(profile)
    factor_plot = TRUE
  }else{
    breaks = quantile(profile, seq(0, bucket_count, 1)/bucket_count, na.rm = TRUE)
    breaks = unique(breaks)
    if(length(breaks)>2) {
      buckets = cut(profile, breaks, ordered_result = TRUE, include.lowest = TRUE)
    }else
    {
      buckets = factor(profile)
      factor_plot = TRUE
    }
  }
  
  index = complete.cases(act, mod)
  
  res = ddply(data.frame(buckets = buckets[index], actual = act[index], model = mod[index], profile = profile[index]), .(buckets), function(x) {
    ns = length(x$actual)
    model_mean = mean(x$model)
    actual_mean = mean(x$actual)
    actual_std = sd(x$actual)
    
    if(error_band == 'binom' & ns >= 1 )
    {
      conf_int = binom.test(sum(x$actual!=0), ns, p = model_mean, alternative = 'two.sided', conf.level = conf_level)$conf.int
    }else if(error_band == 'normal' & ns >= 2 & actual_std > 1e-12 ){
      conf_int = t.test(x$actual, y = NULL, alternative = c('two.sided'), conf.level = conf_level)$conf.int
    }else{
      conf_int = c(actual_mean, actual_mean)
    }
    
    conf_break = model_mean < conf_int[1] | model_mean > conf_int[2]
    
    res = c(actual = actual_mean,
            model = model_mean,
            actual_std = actual_std,
            count = ns,
            profile = ifelse(factor_plot, NA, mean(x$profile, na.rm = TRUE)),
            actual_min = conf_int[1],
            actual_max = conf_int[2],
            confidence_break = conf_break,
            actual_min_break = ifelse(conf_break, conf_int[1], actual_mean),
            actual_max_break = ifelse(conf_break, conf_int[2], actual_mean))
    return ( res )
  })
  
  res = subset(res, count >= min_obs)
  
  y_min = min(res$actual, res$model)
  y_max = max(res$actual, res$model)
  
  if(nrow(res) > 0 )
  {
    if(factor_plot){
      res$buckets = factor(res$buckets)
      xlabels = levels(res$buckets)
      
      plot_result = ggplot(res, aes(buckets, actual, group = 1)) + geom_point(color = 'black') + geom_line(color = 'black', size = 1) +
        geom_point(aes(buckets, model), color = 'red') + geom_line(aes(buckets, model), color = 'red', size = 1) +
        ylab('actual (bk) vs model (rd)') + theme(legend.position = 'none', axis.title.x = element_blank(), axis.text.x = element_text(angle = 90, hjust = 1)) +
        scale_x_discrete(breaks = xlabels) +
        geom_ribbon(aes(ymax = actual_max, ymin = actual_min), fill = 'blue', alpha = 0.05) +
        geom_errorbar(aes(ymax = actual_max_break, ymin = actual_min_break), width = 0.0, color = 'blue', alpha = 0.3) +
        coord_cartesian(ylim = c(y_min, y_max)) 
      
    }else{
      plot_result = ggplot(res, aes(profile, actual)) + geom_point(color = 'black') + geom_line(color = 'black', size = 1) +
        geom_point(aes(profile, model), color = 'red') + geom_line(aes(profile, model), color = 'red', size = 1) +
        ylab('actual (bk) vs model (rd)') + theme(legend.position = 'none', axis.title.x = element_blank()) + 
        geom_ribbon(aes(ymax = actual_max, ymin = actual_min), fill = 'blue', alpha = 0.05) +
        geom_errorbar(aes(ymax = actual_max_break, ymin = actual_min_break), width = 0.0, color = 'blue', alpha = 0.3) +
        coord_cartesian(ylim = c(y_min, y_max)) 
    }
    
  }
  return (plot_result)
}

#### Start of example ------------------

#create a 2d problem with y = exp(-x1^2 - x2^2), non linear with 2 way interactions 
n = 1024 #size of the sample 
x1 = rnorm(n)
x2 = rnorm(n)
y = exp(-(x1*x1 + x2 * x2)) + 0.1*rnorm(n) # noise standard diviation is 0.1
df = data.frame(y, x1, x2)


#fit the GBM model
set.seed(123456) # for reproducibility 
model.gbm = gbm(y ~ ., 
                  data = df, 
                  distribution = 'gaussian',
                  n.trees = 70000,
                  shrinkage = 0.002, #learning rate: 0.1 - 0.001
                  bag.fraction = 0.8,
                  interaction.depth = 2,
                  cv.folds = 3, #3-10
                  train.fraction = 1.0,
                  n.cores = 4,
                  verbose = TRUE)

it_min_cv = gbm.perf(model.gbm, method = 'cv') #iterations that corresponds to the minimum of cross validation error (shoud be about 0.1 for this example)
model.gbm$cv.error[it_min_cv]

plot_gbmiterations(model.gbm)

#plot partial dependance, red markers show quantiles 
plots = plot_gbmpartial(model.gbm, it_min_cv, mdl.cv$var.names, output_type = 'link')
marrangeGrob(plots, nrow=1, ncol=2)

#run the model and compare with actuals
pred.gbm = predict(model.gbm, n.trees = it_min_cv, newdata = df)
ggplot(data.frame(actual = df$y, model = pred.gbm), aes(actual, model)) + geom_point() + geom_smooth() + geom_abline(slope = 1, color = 'red')
summary(lm( df$y ~ pred.gbm )) # regression r2

#variable importance
vars.importance = summary(model.gbm, n.trees = it_min_cv, plotit=FALSE) # influence
plot_gbminfluence(vars.importance)
print(vars.importance) # both equally important in this case

#interactions between variables (>0.1 are significant)
interactions = gbm_interactions(model.gbm,  df, iter = it_min_cv, 1, 2)
plot_gbminteractions(interactions)

#plot 2d partials 
plots = plot_gbmpartial_2d(model.gbm, it_min_cv, as.character(interactions$vars), output_type = 'link')
marrangeGrob(plots, nrow=1, ncol=1)


#plot profiles
plots <- llply(as.character(vars.importance$var), function(vname){
  plot_result = plot_profile(pred.gbm, df$y, df[, vname], bucket_count = 20, min_obs = 10, error_band ='normal') + ggtitle(vname)
  return (plot_result)
})
marrangeGrob(plots, nrow=1, ncol=2)


### Timing --------------

run_gbm <- function(df, iterations,  cv_folds = 0, cores = NULL){
  model.gbm = gbm(y ~ ., 
                  data = df, 
                  distribution = 'gaussian',
                  n.trees = iterations,
                  shrinkage = 0.002, #learning rate: 0.1 - 0.001
                  bag.fraction = 0.8,
                  interaction.depth = 2,
                  cv.folds = cv_folds, #3-10
                  train.fraction = 1.0,
                  n.cores = cores)
}

system.time(run_gbm(df, 5000, 0))
system.time(run_gbm(df, 5000, 2))
system.time(run_gbm(df, 5000, 3))

system.time(run_gbm(df, 5000, 0, 4))
system.time(run_gbm(df, 5000, 2, 4))
system.time(run_gbm(df, 5000, 3, 4))
system.time(run_gbm(df, 5000, 3, 8))

set.seed(123456) 
model.gbm = gbm(y ~ ., 
                data = df, 
                distribution = 'gaussian',
                n.trees = 100,
                shrinkage = 0.002, #learning rate: 0.1 - 0.001
                bag.fraction = 0.8,
                interaction.depth = 2,
                cv.folds = 3, #3-10
                train.fraction = 0.8,
                verbose = TRUE)
