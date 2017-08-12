
## misc utils ----------

'%!in%' <- function(x,y)!('%in%'(x,y))
'%!in_set%' <- function(x,y)(x[!'%in%'(x,y)])
'%in_set%' <- function(x,y)(x['%in%'(x,y)])

rms_log <-function(y, x) {
  return ( sqrt( mean ( (log(y+1) - log(x+1))^2 )))
} 


normalize_data <- function(x){
  ecdf_norm<-function(x) {
    n = length(x)
    y = (seq(n)-0.5)/n
    y[order(x)] = y
    return (y)
  }
  
  x = data.frame(c1 = rnorm(10), c2 = rnorm(10), c3 = sample(LETTERS[1:4], 10, replace = TRUE) )
  sapply(x, function (col) { ecdf_norm(col) })
  
}



#res2 <- cor.mtest(mtcars,0.99)
#corrplot(M, p.mat = res1[[1]], sig.level=0.2)
#correlation conf interval
cor.mtest <- function(mat, conf.level = 0.95){
  mat <- as.matrix(mat)
  n <- ncol(mat)
  p.mat <- lowCI.mat <- uppCI.mat <- matrix(NA, n, n)
  diag(p.mat) <- 0
  diag(lowCI.mat) <- diag(uppCI.mat) <- 1
  for(i in 1:(n-1)){
    for(j in (i+1):n){
      tmp <- cor.test(mat[,i], mat[,j], conf.level = conf.level)
      p.mat[i,j] <- p.mat[j,i] <- tmp$p.value
      lowCI.mat[i,j] <- lowCI.mat[j,i] <- tmp$conf.int[1]
      uppCI.mat[i,j] <- uppCI.mat[j,i] <- tmp$conf.int[2]
    }
  }
  return(list(p.mat, lowCI.mat, uppCI.mat))
}

## GBM plotting functions ----------

gbm_interactions <- function(gbm_model, data, iter, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, plotit=FALSE)
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  all_combinations = combn(as.character(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    interaction_score = try( interact.gbm(gbm_model, data, all_combinations[,i], n.trees = iter))
    if(!is.numeric(interaction_score)) 
      interaction_score = NA
    data.frame(vars = paste(all_combinations[,i], collapse = '|'), interaction_score = interaction_score)
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}

plot_gbminteractions <- function(x){
  ggplot(x, aes(x = reorder(vars, interaction_score), y = interaction_score))  + geom_bar(stat = 'identity') + coord_flip() + geom_hline(yintercept = 0.1, color = 'red') +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_gbminfluence <- function(x){
  ggplot(x, aes(x = reorder(var, rel.inf), y = rel.inf, fill = cut(rel.inf, c(0, 0.01, 0.1, 1, 10, 100), include.lowest = TRUE,ordered_result = TRUE )))  + 
    geom_bar(stat = 'identity') + coord_flip() + 
    geom_hline(yintercept = 1.0, color = 'red') +
    #geom_hline(yintercept = 0.1, color = 'red', linetype="dashed") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_gbmiterations <- function(gbm_model) {
  
  plot_title = ''
  
  iteration = seq(gbm_model$n.trees)
  
  plot = ggplot(data.frame(iteration, train_error = gbm_model$train.error), aes(iteration, train_error) ) + geom_line() 
  
  #add cv
  if(!is.null(gbm_model$cv.error) & !all(is.na(gbm_model$cv.error)) ){
    
    min_cv = min(gbm_model$cv.error, na.rm = T)
    min_cv_it = min(which(gbm_model$cv.error == min_cv))
    
    plot = plot + geom_line(data = data.frame(iteration, cv_error = gbm_model$cv.error), aes(iteration, cv_error), color = 'red' ) +
      geom_hline(yintercept = min_cv, color = 'red', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_cv_it, color = 'red', alpha = 0.5)
      
    plot_title = paste(plot_title, sprintf('cv-%d(%d)=%.5f ', gbm_model$cv.folds, min_cv_it, min_cv) )
  }
  
  #add out of bag
  if(!is.null(gbm_model$oobag.improve) & !all(is.na(gbm_model$oobag.improve)) ){
    oob = gbm_model$train.error[1] - cumsum(gbm_model$oobag.improve) #this is for scaling purpose 
    min_oob = min(oob, na.rm = T)
    min_oob_it = min(which(oob == min_oob))
    
    plot = plot + geom_line(data = data.frame(iteration, oob = oob), aes(iteration, oob), color = 'gray' ) +
      geom_hline(yintercept = min_oob, color = 'gray', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_oob_it, color = 'gray', alpha = 0.5)
    
    plot_title = paste(plot_title, sprintf('oob(%d)=%.5f', min_oob_it, min_oob) )
  }
  
  #add validation
  if(!is.null(gbm_model$valid.error) & !all(is.na(gbm_model$valid.error)) ){
    val = gbm_model$valid.error #this is for scaling purpose 
    min_val = min(val, na.rm = T)
    min_val_it = min(which(val == min_val))
    
    plot = plot + geom_line(data = data.frame(iteration, val = val), aes(iteration, val), color = 'blue' ) +
      geom_hline(yintercept = min_val, color = 'blue', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_val_it, color = 'blue', alpha = 0.5)
    
    plot_title = paste(plot_title, sprintf('val(%d)=%.5f ', min_val_it, min_val) )
  }
  
  plot = plot + ggtitle(plot_title)
  
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
      xlab(var_pair[1]) + ylab(var_pair[2])
        #theme(axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    
    if(add_rug)
    {
      vname_index1 = match(var_pair[1], gbm_model$var.names)
      vname_index2 = match(var_pair[2], gbm_model$var.names)
      size_per_var = length(gbm_model$data$x) / length(gbm_model$var.names)
      
      xdata = gbm_model$data$x[1:size_per_var + (vname_index1 - 1) * size_per_var]
      ydata = gbm_model$data$x[1:size_per_var + (vname_index2 - 1) * size_per_var]
      
      if(max_run_points<=0){
        max_run_points = size_per_var
      }
      rug_index = sample.int(size_per_var, min(max_run_points, size_per_var))
      
      plot_result = plot_result + geom_point(data = data.frame(x = xdata[rug_index], y = ydata[rug_index]), aes(x, y), alpha = 0.2, size = 0.2, inherit.aes = FALSE, color = 'black')
    }
    
    return (plot_result)
  })
  return (plots)
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
  

write.xclip <- function(x, selection=c("primary", "secondary", "clipboard"), ...) {
  if (!isTRUE(file.exists(Sys.which("xclip")[1L])))  stop("Cannot find xclip")
  selection <- match.arg(selection)[1L]
  con <- pipe(paste0("xclip -i -selection ", selection), "w")
  on.exit(close(con))
  write.table(x, con, ...)
}

write.clipboard <- function(x, ...){
  write.xclip(x, "clipboard", ...)
}