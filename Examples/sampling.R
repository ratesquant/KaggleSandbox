
library(data.table)
library(ggplot2)
library(gbm)
library(np)
library(plyr)

working_folder = 'C:/Dev/Kaggle/'
source(file.path(working_folder, 'Utils/common.R'))

n = 1024*16
x1 = rnorm(n)
x2 = rnorm(n) + 1
df = rbind(data.table(x=x1, c = 0), data.table(x=x2, c = 1))

ggplot(df, aes(x, group = c, fill = factor(c) )) + 
  geom_histogram(binwidth = 0.1, alpha = 0.5,  position = "identity")

model = glm(c ~ x, data = df, family = binomial(link = "logit") )

prob = predict(model, type = 'response')
plot_binmodel_percentiles(df$c, prob)

p = plot_profile(prob, df$c, df$x, 50)
p + geom_line(data = data.table(x = x1, p = dnorm(x1-1)/(dnorm(x1) + dnorm(x1-1))), aes(x, p), alpha = 0.5)

pt = prob[df$c == 0]
probs = pt/(1-pt)

sample_index = sample.int(n, n, replace = TRUE, prob = probs/sum(probs))

ggplot(rbind(data.table(x=x1[sample_index], c = 0), data.table(x=x2, c = 1)), aes(x, group = c, fill = factor(c) )) + 
  geom_histogram(binwidth = 0.1, alpha = 0.5,  position = "identity")

#theoretical
xt = rnorm(n)
pt =  dnorm(xt-1)/(dnorm(xt) + dnorm(xt-1))
probs = pt/(1-pt)

plot(xt, probs/sum(probs) )

sample_index = sample.int(n, n, replace = TRUE, prob = probs/sum(probs))

ggplot(rbind(data.table(x = xt, cl = 0),  data.table(x = xt[sample_index], cl = 1)), aes(x, group = cl, fill = cl))+ 
  geom_density(alpha = 0.2)
