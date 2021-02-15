rbf_linear_kernel <- function(x) x
rbf_cauchy_kernel <- function(x) 1/(1 + x)
rbf_cubic_kernel <- function(x) x*x*x
rbf_p5_kernel <- function(x) x^5
rbf_gauss_kernel <- function(x) exp(- x * x)
rbf_bump_kernel <- function(x) ifelse(x<1.0, exp(-1/(1-x*x)), 0)
rbf_mquad_kernel <- function(x) sqrt(1+x*x)
rbf_imquad_kernel <- function(x) 1/sqrt(1+x*x)
rbf_iquad_kernel <- function(x) 1/(1+x*x)
rbf_tp_kernel <- function(x) x * log(x^x)     #x^2 * log(x)
rbf_tp2_kernel <- function(x) x*x*x*log(x^x)  #x^4 * log(x)
rbf_iquad_kernel <- function(x) 1/(1+x*x)
rbf_acq_kernel <- function(x) sqrt(1+x*x) / (1 + x)

rbf.create <- function(X, Y, nodes, kernel_fun = rbf_linear_kernel, dist_fun = 'L1' ){
  M = cbind(1, kernel_fun(dist(X, nodes, method = dist_fun)) ) 
  w = ginv(t(M) %*% M) %*% t(M) %*% Y 
  
  return ( list(weights = w, nodes = nodes, kernel_fun = kernel_fun, dist_fun = dist_fun) )
}

rbf.predict <- function(model, X){
  
  nodes          = model$nodes
  weights        = model$weights
  dist_fun       = model$dist_fun
  kernel_params  = model$kernel_params
  kernel_fun     = model$kernel_fun
  
  M = kernel_fun(dist(X, nodes, method = dist_fun))
  pred = weights[1] + M %*% weights[-1]
  return ( as.numeric(pred) )
}
#bootstrap RBF regressions 
rbf_boot.create <- function(X, Y, n_nodes, n_runs = 10, kernel_fun = rbf_linear_kernel, dist_fun = 'L2', sample_prob = NULL ){
  model_list = llply(seq(n_runs), function(run_id) {
    rbf.create(X, Y, as.matrix(X[sample.int(nrow(X), n_nodes, prob = sample_prob),]), kernel_fun = kernel_fun, dist_fun = dist_fun )
  })
}

rbf_boot.predict <-function(models, X) {
  res = ldply(seq(length(models)), function(run_id) {
    y_pred = as.numeric(rbf.predict(models[[run_id]], X))
    data.frame(run_id, y_pred, id = seq(length(y_pred)))
  })
  return (res)
}

rbf_boot.create_cv <- function(X, Y, n_nodes, n_runs = 10, nfolds =10, kernel_fun = rbf_linear_kernel, dist_fun = 'L2' ){
  
  cv_index = create_cv_index(nrow(X), nfolds)
  
  cv_errors = rep(0, nfolds)
  for (cv_fold in 1:nfolds){
    
    start_time <- Sys.time()
    
    model_list = rbf_boot.create(X[cv_index != cv_fold,], Y[cv_index != cv_fold], n_nodes = n_nodes, n_runs = n_runs, kernel_fun = kernel_fun, dist_fun = dist_fun)
    res  = rbf_boot.predict(model_list, X)
    
    setDT(res)
    res_agg = res[, .(y_pred = mean(y_pred)), by =.(id)]
    setorder(res_agg, id)
    
    error_in  = rms(Y[cv_index != cv_fold], res_agg$y_pred[cv_index != cv_fold])
    error_out = rms(Y[cv_index == cv_fold], res_agg$y_pred[cv_index == cv_fold])
    
    elapsed = as.numeric(difftime(Sys.time(),start_time,units="secs"))/60
    
    print(sprintf('cv: %d, error (in/out): %f / %f, elapsed: %f min', cv_fold, error_in, error_out, elapsed) )
    
    cv_errors[cv_fold] = error_out
  }
  
  print(sprintf('cv-error: %f, sigma: %f, nodes: %d, runs: %d', mean(cv_errors), sd(cv_errors), n_nodes, n_runs) )
  
  return (cv_errors)
}

rbf_boost.create <- function(X, Y, max_nodes = 20, n_runs = 10, max_it = 20, growth_rate =2.0, kernel_fun = rbf_linear_kernel, dist_fun = 'L1', adaptive = FALSE ){
  
  n_nodes = ncol(X)
  current_objective = Y
  
  sample_prob = NULL
  
  all_models = list()
  
  for(it in 1:max_it)
  {
    start_time <- Sys.time()
    
    model_list = rbf_boot.create(X, current_objective, n_nodes, n_runs = n_runs, kernel_fun = kernel_fun, dist_fun = dist_fun, sample_prob)
    res = rbf_boot.predict(model_list, X)
    
    setDT(res)
    res_agg = res[, .(y_pred = mean(y_pred)), by =.(id)]
    setorder(res_agg, id)
    
    elapsed = as.numeric(difftime(Sys.time(),start_time,units="secs"))/60
    
    print(sprintf('it: %d, nodes: %d, error: %f, elapsed: %f', it, n_nodes, rms(current_objective, res_agg$y_pred), elapsed ))
    
    if(adaptive) sample_prob = abs(current_objective - res_agg$y_pred)
    
    current_objective = current_objective - res_agg$y_pred
    
    all_models[[it]] = model_list    
    
    n_nodes = pmax(round(growth_rate * n_nodes), n_nodes + 1) 
    
    if(n_nodes >= nrow(X) | n_nodes > max_nodes)
      break
  }
  return (all_models)
}

rbf_boost.predict <- function(models, X, combine_boots = TRUE){
  
  res = NULL
  
  if(combine_boots){
    res = ldply(seq(length(models)), function(model_id1) {
      
      boot_models = models[[model_id1]]
      
      temp = ldply(seq(length(boot_models)), function(model_id2) {
        y_pred = as.numeric(rbf.predict(boot_models[[model_id2]], X))
        data.frame(model_id1, model_id2, y_pred, id = seq(length(y_pred)) )
      })
      
      setDT(temp)
      
      return (temp[, .(.N, y_pred = mean(y_pred, na.rm = TRUE), y_pred_sigma = sd(y_pred, na.rm = TRUE)), by =.(id, model_id1)])
    })
    
    setDT(res)
    res = res[order(model_id1), y_pred_cum := cumsum(y_pred), by =.(id)]
    
  }else{
    res = ldply(seq(length(models)), function(model_id1) {
      
      boot_models = models[[model_id1]]
      
      ldply(seq(length(boot_models)), function(model_id2) {
        y_pred = as.numeric(rbf.predict(boot_models[[model_id2]], X))
        data.frame(model_id1, model_id2, y_pred, id = seq(length(y_pred)) )
      })
    })
  }
  return (res)
}

create_cv_index <- function(n, nfolds){
  index = c(rep(seq(nfolds), n %/% nfolds), sample(seq(nfolds), n%%nfolds))
  return( sample(index, n) )
}


rbf_boost.create_cv <- function(X, Y, max_nodes, n_runs = 10, max_it = 20, growth_rate = 2.0, nfolds =10, kernel_fun = rbf_linear_kernel, dist_fun = 'L1', adaptive = FALSE ){
  
  n_nodes = ncol(X)
  
  objective_list = llply(seq(nfolds), function(i) Y)
  
  cv_index = create_cv_index(nrow(X), nfolds)
  
  res_cv = matrix(0, max_it, nfolds)
  
  sample_prob = NULL
  
  prev_cv_error = Inf 
  
  for(it in 1:max_it)
  {
    cv_errors = rep(0, nfolds)
    for (cv_fold in 1:nfolds){
      
      start_time <- Sys.time()
      
      current_objective = objective_list[[cv_fold]]
      
      model_list = rbf_boot.create(X[cv_index != cv_fold,], current_objective[cv_index != cv_fold], n_nodes = n_nodes, n_runs = n_runs, kernel_fun = kernel_fun, dist_fun = dist_fun, sample_prob)
      res  = rbf_boot.predict(model_list, X)
      
      setDT(res)
      res_agg = res[, .(y_pred = mean(y_pred)), by =.(id)]
      setorder(res_agg, id)
      
      if(adaptive) sample_prob = abs(current_objective[cv_index != cv_fold] - res_agg$y_pred[cv_index != cv_fold])
      
      error_in  = rms(current_objective[cv_index != cv_fold], res_agg$y_pred[cv_index != cv_fold])
      error_out = rms(current_objective[cv_index == cv_fold], res_agg$y_pred[cv_index == cv_fold])
      
      
      elapsed = as.numeric(difftime(Sys.time(),start_time,units="secs"))/60
      
      print(sprintf('it: %d, nodes: %d, cv: %d, error (in/out): %f / %f, elapsed: %f', it, n_nodes, cv_fold, error_in, error_out, elapsed) )
      
      objective_list[[cv_fold]] = current_objective - res_agg$y_pred
      cv_errors[cv_fold] = error_out
    }
    
    print(sprintf('it: %d, nodes: %d, cv-error: %f, sigma: %f', it, n_nodes, mean(cv_errors), sd(cv_errors)) )
    
    res_cv[it,] = cv_errors
    
    curr_cv_error = mean(cv_errors, na.rm = TRUE)
    
    if(curr_cv_error > prev_cv_error) break;
    
    prev_cv_error = curr_cv_error
    
    n_nodes = pmax(round(growth_rate * n_nodes), n_nodes + 1)
    
    if( n_nodes > nrow(X) * (nfolds - 1) / nfolds | n_nodes > max_nodes) break
  }
  #return ( res_cv)
  return ( res_cv[res_cv[,1]>0,] )
}
