
library(data.table)
library(microbenchmark)
working_folder = 'D:/Github/KaggleSandbox'
train <- fread(file.path(working_folder,'Amex/data/train_data.csv'), select =c("customer_ID", "P_2"), check.names = TRUE)
train_labels  <- fread(file.path(working_folder,'Amex/data/train_labels.csv'),  check.names = TRUE)

train[train_labels, target := i.target, on =.(customer_ID) ]

df = train[, .(P_2 = mean(P_2, na.rm = TRUE), target = target[1]), by =.(customer_ID)]

y_pred = 1.0 - df$P_2/max(df$P_2, na.rm = TRUE)
actual = df$target

amex_error(actual, y_pred)#0.5729004, python: 0.5729004331080327

microbenchmark(amex_error(actual, y_pred)) #88.5039

gini <-function(actual, y_pred, weight){
  
  total_pos = sum(actual * weight)
  cum_pos_found = cumsum(actual * weight)
  lorentz = cum_pos_found / total_pos
  gini = (lorentz - cumsum(weight / sum(weight))) * weight
  sum(gini)
}
gini_norm<-function(actual)
{
  sort_index = order(actual, decreasing = TRUE)
  actual_s = actual[sort_index]
  weight = ifelse(actual_s == 0, 20, 1)
  random = cumsum(weight / sum(weight))
  
  total_pos = sum(actual_s * weight)
  cum_pos_found = cumsum(actual_s * weight)
  lorentz = cum_pos_found / total_pos
  gini = (lorentz - cumsum(weight / sum(weight))) * weight
  sum(gini)
}

amex_error <- function(actual, y_pred){
  sort_index = order(y_pred, decreasing = TRUE)
  actual_s = actual[sort_index]
  y_pred_s = y_pred[sort_index] 
  weight = ifelse(actual_s == 0, 20, 1)
  
  #top_four_percent_captured
  four_pct_cutoff = floor(0.04 * sum(weight))
  cut_off_index = cumsum(weight) <= four_pct_cutoff
  top_four_percent_captured = sum(actual_s[cut_off_index] == 1) / sum(actual == 1)
  
  gini = gini(actual_s, y_pred_s, weight)/gini_norm(actual)
  
  0.5 * (gini + top_four_percent_captured)
} 
