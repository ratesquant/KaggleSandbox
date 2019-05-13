library(data.table)
library(plyr)


#working_folder = 'C:/Dev/Kaggle/'
working_folder = file.path(Sys.getenv("HOME"), 'source/github/KaggleSandbox/')


source(file.path(working_folder, '/Utils/common.R'))
df = fread(file.path(working_folder,'gstore/data/train.csv'), check.names=T)

# ---- simple method 1
agg_method1 <- function(x){
  return(x[, .(.N), by = .(fullVisitorId)])
}

df[, counts := .N, by = .(fullVisitorId)]


system.time(df[, .(.N), by = .(fullVisitorId)])
system.time(agg_method1(df))

# ---- simple method 2
agg_method2 <- function(x){
  return(x[, .(visitNumber_max = max(visitNumber, na.rm = T),
               visitNumber_sum = sum(visitNumber, na.rm = T)), by = .(fullVisitorId)])
}

#155.8889 times slower
agg_method3 <- function(x){
  
  agg_function<-function(xx){
    return ( list('visitNumber_max' = max(xx$visitNumber, na.rm = T),  'visitNumber_sum' = sum(xx$visitNumber, na.rm = T)) )
  }
  return(x[, agg_function(.SD), by = .(fullVisitorId)])
}

agg_method2(df)
system.time(agg_method2(df))
system.time(agg_method3(df))

identical(agg_method2(df), agg_method3(df))

#essentially the same as method 2
agg_method4 <- function(x){

  return(x[, { list('visitNumber_max' = max(visitNumber, na.rm = T),  'visitNumber_sum' = sum(visitNumber, na.rm = T))}, by = .(fullVisitorId)])
}

df[, { agg_function(.SD)}, by = .(fullVisitorId)]

system.time(agg_method4(df))
identical(agg_method2(df), agg_method4(df))

#780 time slower
system.time ( ddply(df, .(fullVisitorId), function(x) { 
  c('visitNumber_max' = max(x$visitNumber, na.rm = T),
  'visitNumber_sum' = sum(x$visitNumber, na.rm = T)) }) )

identical(agg_method2(df), data.table(res) )
