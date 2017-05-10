

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