library(gbm)
library(rpart)
library(data.table)
library(tree)
library(plyr)
library(randomForest)

library(ggplot2)
library(gridExtra)

source('C:/Dev/Kaggle/Utils/common.R')

df = fread('C:/Dev/Kaggle/Titanic/input/train.csv')

df[,Pclass := factor(Pclass)]
df[,Sex := factor(Sex)]

actual = df$Survived

## Logistic ------ 
model.glm = glm('Survived ~ Pclass + Sex', family = binomial(link = "logit"), data = df)
summary(model.glm)

pred.glm = predict(model.glm, data = df, type = 'response')

ggplot(data.frame(actual, model), aes(model, group = factor(actual == 0) )) + stat_ecdf()

plot_binmodel_predictions(actual, pred.glm)
plot_binmodel_percentiles(actual, pred.glm, n = 20, equal_count_buckets = T)
plot_binmodel_cdf(actual, pred.glm)

## Tree -------------
model.tree = tree('Survived ~ Pclass + Sex',  data = df)
summary(model.tree)
plot(model.tree)
text(model.tree, pretty = 0)

pred.tree = predict(model.tree, newdata = df, type = 'vector')
plot_binmodel_percentiles(actual, pred.tree, n = 20, equal_count_buckets = F)
plot_binmodel_cdf(actual, pred.tree)


## Random forest ------ 
set.seed(101)
model.rf = randomForest(as.factor(Survived) ~ Pclass + Sex,  data = df, ntree=5000, importance=TRUE)
summary(model.rf)
importance(model.rf)
plot(model.rf)

ggplot(data.table(model.rf$err.rate), aes(seq_along(OOB),OOB)) + geom_point()

pred.rf = predict(model.rf, data = df, type = 'prob')[,2]

plot_binmodel_percentiles(actual, pred.rf, n = 10, equal_count_buckets = T)
plot_binmodel_cdf(actual, pred.rf)


## Random forest ------ 

model.ct = ctree(as.factor(Survived) ~ Pclass + Sex + age, data=df)

##  GBM ------ 
set.seed(101)
formula.gbm = formula(Survived ~ Pclass + Sex + Age)
model.gbm  = gbm(formula.gbm, 
                            distribution = "bernoulli",
                            n.trees = 1000,
                            cv.folds=5,
                            shrinkage = 0.001,
                            interaction.depth=2,
                 train.fraction = 1.0,
                 bag.fraction = 0.7,
                 n.cores = 2,
                 data = df[,all.vars(formula.gbm), with = F])

plot_gbmiterations(model.gbm)
best_it.gbm = gbm.perf(model.gbm)

pred.gbm = predict(model.gbm, n.trees = best_it.gbm, newdata = df, type = 'response')

var_inf = summary(model.gbm, n.trees = best_it.gbm, plotit = F)
plot_gbminfluence(var_inf)
plot_binmodel_predictions(actual, pred.gbm)

plots = plot_gbmpartial(model.gbm, best_it.gbm, as.character(var_inf$var), output_type = 'response')
marrangeGrob(plots, nrow = 2, ncol = 2)
