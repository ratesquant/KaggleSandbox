library(gbm)
library(rpart)
library(party)
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

cat_vars = c('Pclass','Sex','Embarked')
df[, (cat_vars):=lapply(.SD, as.factor), .SDcols = cat_vars]

factor_vars = names(df)[sapply(df, class) == 'factor']

sapply(df, function(x) any(is.na(x)))

## Logistic ------ ks = 55.23
model.glm = glm('Survived ~ Pclass + Sex + SibSp ', family = binomial(link = "logit"), data = df)
summary(model.glm)

pred.glm = predict(model.glm, data = df, type = 'response')

plot_binmodel_predictions(actual, pred.glm)

## Tree ------------- ks=63.22
model.tree = tree('Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked',  data = df)
summary(model.tree)
plot(model.tree)
text(model.tree, pretty = 0)

pred.tree = predict(model.tree, newdata = df, type = 'vector')
plot_binmodel_predictions(actual, pred.tree)


## Random forest ------ ks=63.19
#does not handle missing values
set.seed(101)
df_imp = df
df_imp$Survived = factor(df_imp$Survived)
df_imp <- rfImpute(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, df_imp)
model.rf = randomForest(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked,  
                        data = df_imp, ntree=5000, importance=TRUE, na.action = na.omit)
summary(model.rf)
importance(model.rf)
plot(model.rf)
varImpPlot(model.rf)

ggplot(data.table(model.rf$err.rate), aes(seq_along(OOB),OOB)) + geom_line()

pred.rf = predict(model.rf, data = df, type = 'prob')[,2]

plot_binmodel_predictions(actual, pred.rf)

#result <- rfcv(df_imp, df_imp$Survived, cv.fold=3)
#with(result, plot(n.var, error.cv, log="x", type="o", lwd=2))

## Random forest: utilizing conditional inference trees ----- (ks=68.94)
model.rf2 <- cforest(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare +
                 Embarked,
               data = df, 
               controls=cforest_unbiased(ntree=2000, mtry=3))
varimp(model.rf2)
varimp(model.rf2, conditional = TRUE)

res = predict(model.rf2, df, OOB=TRUE, type = "prob")
res = ldply(res, function(a) { data.frame(unlist(a))})

pred.rf2 = res[,3]
plot_binmodel_predictions(actual, pred.rf2)

## Conditional Inference Trees ------ 

model.ct = ctree(as.factor(Survived) ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, data=df)
pred.ct = predict(model.ct, df, type = "prob")
pred.ct = ldply(pred.ct, function(a) { data.frame(a[1], a[2])})[,2]
plot_binmodel_predictions(actual, pred.ct)
plot(model.ct)


##  GBM ------ 
#73.86, 0.9290 0.81427  
#67.91  0.9022 0.83416
set.seed(101)
formula.gbm = formula(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked)
model_vars = all.vars(formula.gbm) %!in_set% c('Survived')
var.monotone = rep(0, length(model_vars))
var.monotone[model_vars %in% c('Age')]  = -1
var.monotone[model_vars %in% c('')] =  1
model.gbm  = gbm(formula.gbm, 
                            distribution = "bernoulli",
                            n.trees = 1000,
                            cv.folds=10,
                            shrinkage = 0.01,
                            interaction.depth=5,
                 train.fraction = 1.0,
                 bag.fraction = 0.6,
                 n.cores = 2,
                 var.monotone = var.monotone,
                 data = df[,all.vars(formula.gbm), with = F])

plot_gbmiterations(model.gbm)
best_it.gbm = gbm.perf(model.gbm, plot.it = F)

pred.gbm = predict(model.gbm, n.trees = best_it.gbm, newdata = df, type = 'response')

var_inf = summary(model.gbm, n.trees = best_it.gbm, plotit = F)
plot_gbminfluence(var_inf)
plot_binmodel_predictions(actual, pred.gbm)

var_interaction = gbm_interactions(model.gbm, df, iter = best_it.gbm, min_influence = 1, degree = 2) 
plot_gbminteractions(var_interaction)

var_inter3 = gbm_interactions(model.gbm, df, iter = best_it.gbm, min_influence = 1, degree = 3) 

plots = plot_gbmpartial(model.gbm, best_it.gbm, as.character(var_inf$var), output_type = 'response')
marrangeGrob(plots, nrow = 3, ncol = 3, top = NULL)

plots = plot_gbmpartial_2d(model.gbm, best_it.gbm, as.character(subset(var_interaction,interaction_score>0.1)$vars), output_type = 'response')
marrangeGrob(plots, nrow = 2, ncol = 2, top = NULL)

plot_gbmpartial_2d(model.gbm, best_it.gbm, 'Age|Pclass', output_type = 'response')
plot_gbmpartial_2d(model.gbm, best_it.gbm, 'Age|Sex', output_type = 'response')

plot_profile(pred.gbm, actual,df$Age, error_band = 'binom')
plot_profile(pred.gbm, actual,df$Pclass, error_band = 'binom')

plots = llply(names(df) %!in_set% c('Survived','Ticket', 'Name', 'Cabin'), function(var_name) {
  p = plot_profile(pred.gbm, actual,df[[var_name]], error_band = 'binom') +
    ggtitle(var_name)
  return( p )
})
marrangeGrob(plots, nrow = 3, ncol = 3, top = NULL)
