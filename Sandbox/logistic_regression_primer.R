library(data.table)
library(ggplot2)
library(gridExtra)
library(stringi)
library(MASS)
library(car)

working_folder = 'D:/Github/KaggleSandbox/'
#working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox')

source(file.path(working_folder, '/Utils/common.R'))


n = 1000
rho = 0.7
x1 = rnorm(n)
x2 = rnorm(n) * sqrt(1-rho*rho) + rho * x1
y = as.numeric(runif(n) < logit(-x1 + 2 * x2))
df = data.table(x1, x2, y)
#cor(x1, x2)

model.glm = glm('y ~ x1 + x2', family = binomial(link = "logit"), data = df)
summary(model.glm)
vif(model.glm)
pred.glm = predict(model.glm, type = 'response') 

plot_binmodel_predictions(y, pred.glm)

plot_binmodel_cap(y, pred.glm)
plot_binmodel_roc(y, pred.glm)
plot_binmodel_cdf(y, pred.glm)
plot_binmodel_percentiles(y, pred.glm)
plot_binmodel_histogram(y, pred.glm)

p1 = plot_profile(pred.glm, y, x1) + ggtitle('x1')
p2 = plot_profile(pred.glm, y, x2) + ggtitle('x2')
p3 = ggplot(df, aes(x1, x2, color = factor(y) )) + geom_point()
grid.arrange(p1, p2, p3, ncol=3)


#stepwise -----------
formula.step = formula(stri_join( 'y ~  ', stri_join(c('x1', 'x2'), collapse = ' + ')))

model.glm <- glm(y~ 1, family = binomial(link = "logit"), data = df)
summary(model.glm)
model.glm.step <- stepAIC(model.glm, formula.step, direction = 'forward', trace = TRUE)
model.glm.step <- stepAIC(model.glm, formula.step, direction = 'both',    trace = TRUE)
model.glm.step$anova

pred.glm_step    = as.numeric(predict(model.glm.step, newdata = df, type = 'response'))
