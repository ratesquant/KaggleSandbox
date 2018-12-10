working_folder = 'F:/Github/KaggleSandbox'

source(file.path(working_folder, '/Utils/common.R'))

df = fread(file.path(working_folder,'/Titanic/input/train.csv'))

df[,Survived := as.numeric(Survived)]

actual = df$Survived

cat_vars = c('Pclass','Sex','Embarked')
df[, (cat_vars):=lapply(.SD, as.factor), .SDcols = cat_vars]

model.glm = glm(Survived ~ Sex + Pclass + Sex * Pclass, df, family = 'binomial')

summary(model.glm)

model.pred = predict(model.glm, type = 'response')

plot_binmodel_predictions(df$Survived, model.pred)


## glm with Offset 
model.glm1 = glm(Survived ~ Sex + Pclass, df, family = 'binomial', offset = predict(model.glm, type = 'link'))
summary(model.glm1)
model.pred1 = predict(model.glm1, type = 'response')
plot_binmodel_predictions(df$Survived, model.pred1)

## gbm with Offset 
my_offset = predict(model.glm, type = 'link')
gbm.roc.area(actual, logit(my_offset) ) #0.9229753
plot_binmodel_predictions(actual, predict(model.glm, type = 'response'))

model.gbm  = gbm(Survived ~ Pclass + Sex + Age + offset(my_offset), 
                 distribution = "bernoulli",
                 n.trees = 2000,
                 cv.folds=10,
                 shrinkage = 0.01,
                 interaction.depth=3,
                 train.fraction = 1.0,
                 bag.fraction = 0.9,
                 n.cores = 4,
                 var.monotone =NULL,
                 data = df[,c('Survived', 'Sex', 'Pclass', 'Age'), with = F],
                 verbose = FALSE)
plot_gbmiterations(model.gbm)#0.84

best_it.gbm = gbm.perf(model.gbm, plot.it = F)
pred.gbm_link = predict(model.gbm, n.trees = best_it.gbm, type = 'link')
pred.gbm = logit(pred.gbm_link + my_offset)

gbm.roc.area(actual, pred.gbm) #0.9229753
plot_binmodel_predictions(actual, pred.gbm)

var_inf = summary(model.gbm, n.trees = best_it.gbm, plotit = F)
plot_gbminfluence(var_inf)

plots = plot_gbmpartial(model.gbm, best_it.gbm, as.character(var_inf$var), output_type = 'response')
marrangeGrob(plots, nrow = 2, ncol = 2, top = NULL)

var_interaction = gbm_interactions(model.gbm, df, iter = best_it.gbm, min_influence = 1, degree = 2) 
plots = plot_gbmpartial_2d(model.gbm, best_it.gbm, as.character(subset(var_interaction,interaction_score>0.1)$vars), output_type = 'link')
marrangeGrob(plots, nrow = 2, ncol = 2, top = NULL)

plots = llply(c('Pclass','Sex','Age'), function(var_name) {
  p = plot_profile(logit(my_offset), actual, df[[var_name]], error_band = 'binom') +
    ggtitle(var_name) +  theme(title =element_text(size=6))
  return( p )
})
marrangeGrob(plots, nrow = 2, ncol = 2, top = NULL)


