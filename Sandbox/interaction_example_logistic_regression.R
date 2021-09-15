library(data.table)
library(ggplot2)
library(gridExtra)
library(plyr)
library(earth)

working_folder = 'D:/Github/KaggleSandbox'
source(file.path(working_folder, 'Utils/common.R'))

logit_inv<-function(x) 1 / (1 + exp(-x)) 

#this is functional form for probability z 
df_x0 = data.frame(x0 = seq(10), xinf = seq(4, 6, length.out = 10) )
df = data.table(expand.grid(x0 = seq(10), t = seq(36)  ))

df[df_x0, xinf := i.xinf, on =.(x0)]

df[, x := xinf + (x0 - xinf) * exp(-t/12) ]
#df[, p := 1-logit_inv(0.5*x)]
df[, x_sp0 := x0 *  pmax(0,  t - 13)]
df[, x_sp1 := x0 *  pmax(0, 13 -  t)]
df[, t_sp0 := pmax(0,  t - 13)]
df[, t_sp1 := pmax(0, 13 -  t)]


#df[, z := x * (y/12) ]
#df[, x_sp := x * pmin(y, 9) ]
#df[, y_sp := pmin(y, 9) ]
#df[, xy := x*exp(-y/36) ]

ggplot(df, aes(t, x, group = x0, color = factor(x0) )) + geom_line()
ggplot(df, aes(t, p, group = x0, color = factor(x0) )) + geom_line()
ggplot(df, aes(x0, p, group = t, color = factor(t) )) + geom_line()

#ggplot(df, aes(x, y, fill = z)) + geom_tile()
#ggplot(df, aes(exp(-x / y) / y, z)) + geom_point()

model.lm = lm(x ~  x0 + x_sp0 + x_sp1 + t_sp0 + t_sp1, df)
#model.lm = gam(x ~ x_sp0 + x_sp1, df, family = gaussian)
model.lm = earth(x ~ x0 +  t, data = df, degree = 2)
summary(model.lm, style = 'pmax')
#plotmo(model.lm)
#plot(model.lm)

df[, x_pred := predict(model.lm)]

ggplot(df, aes(t, x, group = x0)) + geom_point() + geom_line(aes(t, x_pred, group = x0), color = 'red')
ggplot(df, aes(t, x, group = x0)) + geom_point() + geom_line(aes(t, x_pred, group = x0), color = 'red') + facet_wrap(~x0, scales = 'free_y')

ggplot(df, aes(t, t_sp0)) + geom_point()
ggplot(df, aes(t, t_sp1)) + geom_point()


#  Distribution smooth --------
#1. define charge off probability function

df = data.table(x = seq(1, 100))
df[, p:=logit_inv(-x/20)]
ggplot(df, aes(x, p)) + geom_line()

res = ldply(seq(12), function(t){
 for(i in 1:nrow(df)){
   
 }
})











# Generate binary events ---------------
n = 100000

x = runif(n, 0, 10)
y = sample(seq(9),n, replace = TRUE)
p = 0.1*exp(-x/y)/y

df_b = data.table(x, y, z = as.numeric(runif(n)<p) )
df_b[, x_sp := x * pmin(y, 9) ]
df_b[, y_sp := pmin(y, 9) ]

model.glm = glm(z ~ x + y_sp + x_sp , family = binomial(link = "logit"), data = df_b)
summary(model.glm)

df_b[, z_pred := predict(model.glm, type = 'response')]

plot_profile(df_b$z_pred, df_b$z, df_b$x, error_band = 'binom')
plot_profile(df_b$z_pred, df_b$z, df_b$y, error_band = 'binom')

plots = llply(unique(df_b$y), function(my_y){
  plot_profile(df_b[y == my_y,z_pred], df_b[y == my_y,z], df_b[y == my_y,x], error_band = 'binom') + ggtitle(my_y)
})
marrangeGrob(plots, nrow = 3, ncol = 3, top = NULL)

plot_binmodel_predictions(df_b$z, df_b$z_pred)

df[, z_pred := predict(model.glm, type = 'response', df)]
ggplot(df, aes(x, z_pred, group = y)) + geom_line(color = 'red') + geom_line( aes(x, z, group = y), color = 'black') + facet_wrap(~y)
ggplot(df, aes(x, z_pred, group = y, color = factor(y) )) + geom_line()
ggplot(df, aes(x, z, group = y, color = factor(y) )) + geom_line()
