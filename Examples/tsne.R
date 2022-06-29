library(ggplot2)
library(tsne)
library(umap)
library(Rtsne)
library(plyr)
library(data.table)
library(car)

#too SLOW
tsne_iris = tsne(iris[,1:4], perplexity=10)
ggplot(cbind(data.frame(tsne_iris),iris)) + geom_point(aes(X1, X2, color = Species ))
# compare to PCA
pca_iris = princomp(iris[,1:4])$scores[,1:2]
ggplot(cbind(data.frame(pca_iris),iris)) + geom_point(aes(Comp.1, Comp.2, color = Species ))


create_cluster_example<-function(n, type = 1, sigma = 0.1) 
{
  res = NULL
  
  if (type == 1)  {
    #cube
    nodes = expand.grid(x=c(0, 1), y = c(0, 1), z = c(0, 1))
    nodes = rbind(nodes, c(x = 0.5, y = 0.5, z = 0.5, id = 9))
    #nodes = expand.grid(x=c(0, 1), y = c(0, 1), z = c(0, 1))
    
    res = ldply(seq(nrow(nodes)), function(i){
      data.frame(x = nodes$x[i] + sigma*rnorm(n), y = nodes$y[i] + sigma*rnorm(n), z = nodes$z[i] + sigma*rnorm(n), id = i)
    })
  } else if (type == 2)  {
    #circles
    phi1 = 2*pi * runif(n)
    phi2 = 2*pi * runif(n)
    c1 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n) + cos(phi1), z =sigma*rnorm(n),  id = 1)
    c2 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n) + sin(phi1), z = sigma*rnorm(n) + cos(phi1), id = 2)
    c3 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n), z = sigma*rnorm(n) + cos(phi1), id = 3)
    res = rbind(c1, c2, c3)
  }  else if (type == 3)  {
    #circles
    phi1 = 2*pi * runif(n)
    phi2 = 2*pi * runif(n)
    c1 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n) + cos(phi1), z = sigma*rnorm(n), id = 1)
    c2 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n) + sin(phi1)-1.0, z = sigma*rnorm(n) + cos(phi1), id = 2)
    res = rbind(c1, c2)
  } else if (type == 4)  {
    #circles
    phi1 = 2*pi * runif(n)
    phi2 = 2*pi * runif(n)
    c1 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n) + cos(phi1), z =sigma*rnorm(n),  id = 1)
    c2 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n) + sin(phi1), z = sigma*rnorm(n) + cos(phi1), id = 2)
    c3 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n), z = sigma*rnorm(n) + cos(phi1), id = 3)
    c4 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n), z = sigma*rnorm(n), id = 4)
    res = rbind(c1, c2, c3, c4)
  } else if (type == 5)  {
    #circles
    phi1 = 3*2*pi * runif(n)
    c1 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n) + cos(phi1), z =phi1/3 + sigma*rnorm(n),  id = 1)
    c2 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n), z =phi1/3 + sigma*rnorm(n),  id = 2)
    
    res = rbind(c1, c2)
  } else if(type == 7)  {
    nodes = expand.grid(x=c(7, 12), y = c(7, 12))
    
    res = ldply(seq(nrow(nodes)), function(i){
      data.frame(x = nodes$x[i] + rnorm(n), y = nodes$y[i] + rnorm(n), id = i)
    })
    setDT(res)
    res[, x1 :=x * cos(x)]
    res[, x2 :=y]
    res[, x3 :=x * sin(x)] 
    res[, x  := NULL]
    res[, y  := NULL]
    names(res) <- c('id','x', 'y', 'z')
    
    scatter3d(res$x, res$y, res$z, surface = FALSE, bg.col= "black")
    
  }
  
  
  return (copy(res))
}

df <- data.table(unique(iris))
df[, id:=Species]
df <- create_cluster_example(100, type = 7, sigma = 0.01) 
setDT(df)

ggplot(df) + geom_point(aes(z, x, color = factor(id) ))

scatter3d(df$x, df$y, df$z, point.col = df$id, surface = FALSE, bg.col= "black", col = c('red', 'blue'))
scatter3d(df$x, df$y, df$z, surface = FALSE, bg.col= "black")



#% -------------- RtSNE
set.seed(1234)
#tsne_out <- Rtsne(df[,1:4],pca=FALSE, theta=0.0, perplexity = 10)
tsne_out <- Rtsne(df[,1:4],pca=FALSE, theta=0.0, perplexity = 10, num_threads = 6)
ggplot(cbind(data.frame(tsne_out$Y),df)) + geom_point(aes(X1, X2, color = factor(id) ))

#PCA
pca_iris = princomp(df[,1:3])$scores[,1:2]
ggplot(cbind(data.frame(pca_iris),df)) + geom_point(aes(Comp.1, Comp.2, color = factor(id) ))

#% -------------- UMAP
set.seed(1234)
umap.res = umap(df[,1:4])
ggplot(cbind(data.frame(umap.res$layout, df)), aes(X1, X2, group = id, color = factor(id))) + geom_point()

#perturbed.embedding = predict(umap.res, df)

# -------------------
library(gbm)

model.gbm = gbm(as.formula('x ~ z + y'), data = df,
                distribution = 'gaussian',
                n.trees = 1000,
                shrinkage = 0.01,#0.005
                interaction.depth = 2,
                cv.folds = 5,
                n.cores = 1,
                verbose =  TRUE)
gbm.perf(model.gbm, method = 'cv')

pred.gbm = predict(model.gbm, n.trees = 100, newdata = df)

ggplot(data.frame(pred.gbm, label = iris[, "Species"]), aes(X1, X2, group = label, color = label)) + geom_point()
ggplot(cbind(data.frame(pred.gbm),df)) + geom_point(aes(pred.gbm, z, color = factor(id) ))

# SWISS ROLL -------------------
df_sr <- read.table('http://people.cs.uchicago.edu/~dinoj/manifold/swissroll.dat')
setDT(df_sr)

df_sr <- create_cluster_example(100, type = 7, sigma = 0.01) 
setDT(df)


scatter3d(df_sr$V1, df_sr$V2, df_sr$V3, surface = FALSE, bg.col= "black")


tsne_out <- Rtsne(df_sr[,1:3],pca=FALSE, theta=0.0, perplexity = 10, num_threads = 6)
ggplot(cbind(data.frame(tsne_out$Y),df_sr)) + geom_point(aes(X1, X2 ))

