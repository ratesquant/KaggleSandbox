library(data.table)
library(ggplot2)

library(umap)
library(Rtsne)
#library(uwot) #installation fails, devtools::install_github("jlmelville/uwot")


#PCA (linear)
#t-SNE (non-parametric/ nonlinear)
#UMAP(non-parametric/ nonlinear)
#Sammon mapping (nonlinear)
#Isomap (nonlinear)
#LLE (nonlinear)
#CCA (nonlinear)
#SNE (nonlinear)
#MVU (nonlinear)
#Laplacian Eigenmaps (nonlinear)
#working_folder = 'D:/Github/KaggleSandbox'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')

df = fread(file.path(working_folder,'Titanic/input/train.csv'))

## ------------ TITANIC DATA [umap]  --------------

m_data = data.matrix(df[!is.na(Age), .(Age, SibSp, Parch, Sex=factor(Sex))])

tmap = umap(m_data)

ggplot(data.frame(tmap$layout, label = factor(df[!is.na(Age), ][['Age']]) ), aes(X1, X2, group = label, color = label)) + geom_point()

## ------------ IRIS DATA [umap]  --------------
iris.umap = umap(iris[,1:4])
#iris.umap$layout

ggplot(data.frame(iris.umap$layout, label = iris[, "Species"]), aes(X1, X2, group = label, color = label)) + geom_point()

## ------------ TITANIC DATA [Rtsne]  --------------

tsne <- Rtsne(m_data, check_duplicates = FALSE)

ggplot(data.frame(tsne$Y, label = factor(df[!is.na(Age), ][['Age']]) ), aes(X1, X2, group = label, color = label)) + geom_point()

## ------------ IRIS DATA [Rtsne]  --------------
## Executing the algorithm on curated data
tsne <- Rtsne(iris[,1:4], check_duplicates = FALSE)

ggplot(data.frame(tsne$Y, label = iris[, "Species"]), aes(X1, X2, group = label, color = label)) + geom_point()

