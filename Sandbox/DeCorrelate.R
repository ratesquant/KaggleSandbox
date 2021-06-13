library(data.table)
library(ggplot2)

n = 2000

df = data.table(x = rnorm(n), y = rnorm(n))
#df[,x := x - mean(x)]
#df[,y := y - mean(y)]

ggplot(df, aes(x, y)) + geom_point()


#Correlate DATA (assuming zero mean)
cor_mat = matrix(c(1, 0.6, 0.6, 1), nrow  = 2)
cor_mat_chol = chol(cor_mat)

df_cor = data.table(as.matrix(df) %*% cor_mat_chol )
names(df_cor) <- c('x', 'y')

#summary(df$x * 0.6 + sqrt(1-0.6*0.6) * df$y - df_cor$y)

ggplot(df_cor, aes(x, y)) + geom_point()
cor(df)
cor(df_cor)
summary(df - df_cor)

#UN-correlate data
cor_mat_chol = chol(cor(df_cor))
cor_mat_chol_inv = solve(cor_mat_chol)

df_decor <- data.table( as.matrix(df_cor) %*% cor_mat_chol_inv  ) 
names(df_decor) <- c('x', 'y')

summary(df - df_decor) #we should recover original matrix - if we use the same covariance 

ggplot(df_decor, aes(x, y)) + geom_point()
cor(df)
cor(df_cor)
cor(df_decor)
