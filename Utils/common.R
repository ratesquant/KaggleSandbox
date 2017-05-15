

gbm_interactions <- function(gbm_model, data, iter, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, plotit=FALSE)
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  all_combinations = combn(as.vector(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    data.frame(vars = paste(all_combinations[,i], collapse = '-'), 
               interaction_score = interact.gbm(gbm_model, data, all_combinations[,i], n.trees = iter)) 
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


plot_gbmpartial <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response'){
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