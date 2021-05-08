library(data.table)
library(ggplot2)
library(flexmix)

n = 300



x = rnorm(n)
y = sample(c(1.5, 0.5), n, replace = TRUE) * x + 0.1*rnorm(n)
df = data.table(x, y)

model.lm = lm(y ~ x, df)

#plot(model.lm)
my_pred_lm = predict(model.lm, df)
df[, pred_lm := my_pred_lm]

ggplot(df, aes(x, y) ) + geom_point()
ggplot(df, aes(pred_lm, y) ) + geom_point()
ggplot(df, aes(pred_lm, y - pred_lm) ) + geom_point()

#flex
model.flex = flexmix(y ~ x, df, k = 2)

parameters(model.flex, component = 1, model = 1)
parameters(model.flex, component = 2, model = 1)

my_pred_flm = predict(model.flex, df)
df[, pred_flm1 := my_pred_flm$Comp.1]
df[, pred_flm2 := my_pred_flm$Comp.2]
df[, cluster := clusters(model.flex)]
df[, pred_flm := ifelse(cluster == 1, pred_flm1, pred_flm2) ]

ggplot(df, aes(pred_flm1, y, color = factor(cluster) ) ) + geom_point()
ggplot(df, aes(pred_flm2, y, color = factor(cluster) ) ) + geom_point()
ggplot(df, aes(pred_flm, y -pred_flm, color = factor(cluster) ) ) + geom_point()
ggplot(df, aes(pred_flm, y - pred_flm) ) + geom_point()
