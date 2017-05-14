

gbm_interactions <- function(gbm_model, data, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, plotit=FALSE)
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  all_combinations = combn(as.vector(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    data.frame(vars = paste(all_combinations[,i], collapse = '-'), 
               interaction_score = interact.gbm(gbm_model, data, all_combinations[,i])) 
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}

plot_gbminteractions <- function(x){
  ggplot(x, aes(x = reorder(vars, -interaction_score), y = interaction_score))  + geom_bar(stat = 'identity') + 
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}


plot_gbmpartial <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response'){
  plots <- llply(variables, function(vname){
    plot_data = plot(gbm_model, i.var = vname, n.trees = iter, type = output_type, continuous.resolution = resolution, return.grid = TRUE)
    names(plot_data) <- c('x', 'y')
    
    plot_result <- ggplot() + geom_blank() 
    
    if(is.factor(plot_data$x)){
      plot_result = ggplot(plot_data, aes(x, y, group = 1)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.text.x = element_text(angle = 90, hjust = 1), axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    }else{
      plot_result = ggplot(plot_data, aes(x, y)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    }
    return (plot_result)
  })
  return (plots)
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