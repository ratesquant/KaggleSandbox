install.packages('devtools')
devtools::install_url('https://github.com/catboost/catboost/releases/download/v1.1.1/catboost-R-Windows-1.1.1.tgz', INSTALL_opts = c("--no-multiarch"))

#%% Test -----

library(catboost)

features <- data.frame(feature1 = c(1, 2, 3), feature2 = factor(c('A', 'B', 'C')) )
labels <- c(0, 0, 1)
train_pool <- catboost.load_pool(data = features, label = labels)

model <- catboost.train(train_pool,  NULL,
                        params = list(loss_function = 'Logloss',
                                      iterations = 100, metric_period=10))


real_data <- data.frame(feature1 = c(2, 1, 3), feature2 = factor(c('D', 'B', 'C')) )
real_pool <- catboost.load_pool(real_data)

prediction <- catboost.predict(model, real_pool)
print(prediction)

catboost.get_model_params(model)
catboost.get_plain_params(model)


sessionInfo()


