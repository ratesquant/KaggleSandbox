knitr::opts_chunk$set(echo = TRUE)

library(data.table)
library(proxy)
library(MASS)
library(ggplot2)
library(plyr)
library(dplyr)
library(stringi)


working_folder = 'D:/Github/KaggleSandbox'

source(file.path(working_folder, 'Utils/common.R'))
source(file.path(working_folder, 'Utils/rbf_utils.R'))

rms <-function(y1, y2) sqrt( mean( (y1 - y2)^2 ))


train <- fread(file.path(working_folder,'Playground/Feb2021/data/train.csv'), check.names = TRUE)
test  <- fread(file.path(working_folder,'Playground/Feb2021/data/test.csv'),  check.names = TRUE) # 1459   80
test[, target:=NA]
df = rbind(train, test)

gc(reset=TRUE)

test_index = is.na(df$target)
train_index = !test_index

obj_var = 'target'
all_vars = names(df) %!in_set% c('id', obj_var) #14 variables
all_vars = all_vars[grep('^(cont|cat)', all_vars)]
cat_vars = all_vars[grep('^(cat)', all_vars)]
con_vars = all_vars[grep('^(cont)', all_vars)]

## ------------- Boot CV ------
convert_to_prob <-function(x, train_index){
  if(is.character(x) )x = as.numeric(as.factor(x))
  ecdf(x[train_index])(x)
}
p_vars = stri_join('p_', all_vars)
df[, (p_vars):=lapply(.SD, function(x) convert_to_prob(x, train_index)), .SDcols = all_vars]


my_index = sample( which(train_index), 0.1*sum(train_index))

rbf_kernels = list('rbf_linear_kernel' = rbf_linear_kernel, 'rbf_cauchy_kernel' = rbf_cauchy_kernel, 'rbf_cubic_kernel' = rbf_cubic_kernel, 
                   'rbf_gauss_kernel' = rbf_gauss_kernel, 'rbf_bump_kernel' = rbf_bump_kernel, 'rbf_mquad_kernel' = rbf_mquad_kernel, 'rbf_imquad_kernel' = rbf_imquad_kernel,
                   'rbf_tp_kernel' = rbf_tp_kernel, 'rbf_iquad_kernel' = rbf_iquad_kernel)

#%% boost runs ----------------
#10 runs with 500 nodes - 4 min
run_cases = expand.grid(nodes = c(516), runs = c(10, 30), growth_rate = c(1.5, 2.0), dist_fun = c('L1'), kernel_scale = c(1, 10), 
                        rbf_kernel = c('rbf_linear_kernel', 'rbf_mquad_kernel'),#names(rbf_kernels),
                        stringsAsFactors = FALSE )

dfs = data.matrix(df[my_index,p_vars, with = FALSE])
target = df$target[my_index]

cv_res = ldply(seq(nrow(run_cases)), function(run_id){
  kernel_fun = function(x) rbf_kernels[[run_cases$rbf_kernel[run_id]]](x * run_cases$kernel_scale[run_id])
  
  cv_res = rbf_boost.create_cv(dfs, target, max_nodes = run_cases$nodes[run_id], n_runs = run_cases$runs[run_id], max_it = 20, growth_rate = run_cases$growth_rate[run_id], nfolds = 5, 
                               kernel_fun = kernel_fun, dist_fun =run_cases$dist_fun[run_id] )
  
  data.frame(run_id, cv_it =seq(nrow(cv_res)),  cv_error = rowMeans(cv_res), cv_sigma = apply(cv_res, 1, sd), n_nodes = run_cases$nodes[run_id], n_runs = run_cases$runs[run_id], growth_rate = run_cases$growth_rate[run_id],
             dist_fun = run_cases$dist_fun[run_id], 
             kernel_fun   = run_cases$rbf_kernel[run_id],
             kernel_scale = run_cases$kernel_scale[run_id])
})
setDT(cv_res)

null_rms = rms(target, mean(target) )

#0.84310/null_rms, 0.9504698

cv_res[, cv_error_norm := cv_error/null_rms]
cv_res[, tag := stri_join('runs:',n_runs,', scale:',  kernel_scale)]

cv_res[order(cv_error)]

ggplot(cv_res, aes(cv_it, cv_error_norm, group = tag, color = tag )) + geom_line() + facet_grid(growth_rate ~kernel_fun)
ggplot(cv_res, aes(cv_it, cv_error, group = tag, color = tag )) + geom_line(size = 1) + facet_grid(growth_rate ~kernel_fun) + 
  geom_hline(yintercept = min(cv_res$cv_error), linetype = 'dashed' )

ggplot(cv_res, aes(n_nodes, cv_error, group = n_runs, color = factor(n_runs) )) + geom_line() + facet_grid(growth_rate ~kernel_fun)

#ggplot(cv_res, aes(n_nodes, cv_error, group = n_runs, color = factor(n_runs) )) + geom_line() + facet_grid(dist_fun~kernel_fun)
#ggplot(cv_res, aes(n_nodes, cv_error, group = n_runs, color = factor(n_runs) )) + geom_line() + facet_grid(kernel_fun~dist_fun)

#get results  ----------------
cv_res = rbf_boost.create_cv(dfs, target, max_nodes = 3000, n_runs = 30, max_it = 20, growth_rate = 1.5, nfolds = 10,    kernel_fun = rbf_mquad_kernel, dist_fun ='L1' )
#boost_models = rbf_boost.create(dfs, target, max_nodes = 2000, n_runs = 30, max_it = 20, growth_rate = 1.5,  kernel_fun = rbf_mquad_kernel, dist_fun = 'L1')

