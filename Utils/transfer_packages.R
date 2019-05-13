
filename = file.path(Sys.getenv("HOME"), 'source/installed_packages_35.rda')

# run in previous R version
tmp = installed.packages()
installedpackages = as.vector(tmp[is.na(tmp[,"Priority"]), 1])
saveRDS(installedpackages, file=filename)



# run in current R version
installedpackages = readRDS(filename)
tmp = installed.packages()
current_packages = as.vector(tmp[is.na(tmp[,"Priority"]), 1])
missing_packages = setdiff(installedpackages, current_packages) 
for (pkg in missing_packages) install.packages(pkg)


#essential 
essential_packages = setdiff(c('data.table', 'forecast','stringi','stringr',
                       'ggplot2','wesanderson','gridExtra','corrplot',
                       'Hmisc','reshape2','zoo','xgboost','dplyr','plyr','reshape2',
                       'microbenchmark','e1071','forcats','lubridate','car',
                       'gam','gbm','caret','zip'), current_packages)
for (pkg in essential_packages) install.packages(pkg)

#check that all packages load
for (pkg in current_packages) require(pkg, character.only=TRUE)

library(randomForest)
library(randomForestExplainer)

library(rBayesianOptimization)