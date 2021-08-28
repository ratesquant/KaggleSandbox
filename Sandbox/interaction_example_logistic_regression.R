library(data.table)
library(ggplot2)
library(gridExtra)
library(plyr)

working_folder = 'D:/Github/KaggleSandbox'
source(file.path(working_folder, 'Utils/common.R'))

#this is functional form for probability z 
df = data.table(expand.grid(x = seq(0, 10, length.out = 100), y = seq(12)  ))
df[, z := 0.1*exp(-x/y)/y ]
df[, x_sp := x * pmin(y, 9) ]
df[, y_sp := pmin(y, 9) ]

#ggplot(df, aes(x, y, fill = z)) + geom_tile()

ggplot(df, aes(x, z, group = y, color = factor(y) )) + geom_line()

model.lm = lm(z ~ x + y + x*y, df)
summary(model.lm)

df[, z_pred := predict(model.lm)]


ggplot(df, aes(x, z_pred, group = y, color = factor(y) )) + geom_line() + geom_point( aes(x, z, group = y, color = factor(y) ), alpha = 0.2)

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
