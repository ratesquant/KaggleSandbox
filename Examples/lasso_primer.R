library(glmnet)
library(ggplot2)
library(data.table)
library(plyr)

get_all_coefs<-function(glmnet_obj){
  res = ldply(glmnet_obj$lambda, function(lambda){
    temp = data.matrix(coef(glmnet_obj,s=lambda))
    data.frame(var_name = rownames(temp), coef = as.numeric(temp), lambda)
  })
  return(res)
}

# Linear Regression with 10 variables (Gaussian)
n_vars = 10
n_obs = 1000
x=matrix(rnorm(n_obs*n_vars),n_obs,n_vars)
y=rnorm(n_obs)
fit1=glmnet(x,y, family="gaussian")
print(fit1)
plot(fit1, type.coef="2norm")
coef(fit1,s=0.01) # extract coefficients at a single value of lambda
predict(fit1,newx=x[1:10,],s=c(0.01,0.005)) # make predictions for different values of lambda

#number of variables with non zero coefficients vs lambda
ggplot(data.frame(lambda = fit1$lambda, n_vars = fit1$df), aes(lambda, n_vars)) + geom_line()

lasso_coefs = melt(data.table(t(as.matrix(fit1$beta)), intercept = fit1$a0, lambda = fit1$lambda), id.vars = 'lambda')
ggplot(lasso_coefs, aes(lambda, value, group = variable, color = variable)) + geom_line()

#compare with linear regression 
summary(lm(y ~ x))

#Does 10-fold cross-validation for glmnet (to choose optimal lambda) --------
cvob3=cv.glmnet(x, y,family="gaussian",nfolds = 10)
plot(cvob3)

ggplot(data.frame(mse = cvob3$cvm, mse_hi = cvob3$cvup, mse_lo = cvob3$cvlo, lambda = log(cvob3$lambda)) , aes(lambda, mse) ) + geom_line() + 
  geom_ribbon(aes(ymin = mse_lo, ymax = mse_hi), fill = 'blue', alpha = 0.3) +
  geom_vline(xintercept =  log(cvob3$lambda.min)) + 
  ggtitle(sprintf('Best MSE %.5f', cvob3$cvm[which(cvob3$lambda == cvob3$lambda.min)]))

coef_path = data.table(get_all_coefs(cvob3))
imp_vars = as.character(unique( subset(coef_path,lambda > cvob3$lambda.min & abs(coef) >0)$var_name))
ggplot(coef_path[var_name %in% imp_vars, ], aes(log(lambda), coef, group = var_name, color = var_name )) + geom_line() + 
  geom_vline(xintercept = log(cvob3$lambda.min), linetype = 'dashed')
