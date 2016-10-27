load_claim_data = function(folder, min_count = 100, max_cat_levels = 10) {
	vars_cat = 116
	vars_num = 14

	col_classes = c('numeric', rep('factor', vars_cat), rep('numeric', vars_num), 'numeric')
	
	#train <- read.csv(file.path(folder, 'train.csv'), colClasses = col_classes)
	#test  <- read.csv(file.path(folder, 'test.csv'), colClasses = col_classes[-length(col_classes)])
	#saveRDS(train, file.path(folder, 'train.rds'))
	#saveRDS(test, file.path(folder, 'test.rds'))

	train <- readRDS(file.path(folder, 'train.rds'))
	test <- readRDS(file.path(folder, 'test.rds'))


	#LIMIT the size of the TRAINING for TEST RUNS (actual size = 188319)
	#sample_size = 70000
	#sample_index = sample.int(dim(train)[1], size = sample_size)
	#train = train[sample_index,]
	#print(paste('sample_size', sample_size))

	test$loss <- NA
	train$tag = 1
	test$tag = 0

	df = rbind(train, test)

	df$log_loss = log(df$loss) 

	test_index = df$tag == 0
	train_index = df$tag == 1

  cols = names(df)
	cat_vars = cols[grep("cat", cols)] 
	
	## Convert variables with many levels to numerical	 
	cat_vars_toconvert = cat_vars[which( sapply(df[, cat_vars], FUN = function(x) length(levels(x))) >= max_cat_levels)]	
	print( sort(sapply(df[, cat_vars_toconvert], FUN = function(x) length(levels(x)))) )
	for(cv in cat_vars_toconvert){
	print(sort(table(df[, cv])))
	a = reorder(df[, cv], df[, cv], FUN = length)
	levels(a) <- seq(length(levels(a)))
	df[, cv] = as.numeric(a)
	}

	#combine rare levels for categorical variables 
	#sapply(df, class)
	#sort(table(df$75))
	tag_name = "OTHER"
	for(cn in cat_vars[!(cat_vars %in% cat_vars_toconvert)] ){
	  temp = df[,cn]
	  temp = as.character(temp)
	  small_levels = names(which(table(temp[train_index])<min_count))
	  temp[temp %in% small_levels] = tag_name
	  
	  #levels that are only present in test data, move to other 
	  new_levels = setdiff( names(which(table(temp[test_index])>0)), names(which(table(temp[train_index])>0)))
	  temp[temp %in% new_levels] = tag_name
	  
	  print(paste(cn, small_levels, new_levels))
	  
	  #spread observations among other factors 
	  other_count = sum(temp==tag_name)
	  if(other_count<min_count & other_count > 0) { 
		print(paste('randomly spreading observations for', cn, other_count))
		level_counts = table(temp[temp != tag_name])
		levels = sample(names(level_counts), other_count, replace = TRUE, prob = level_counts/sum(level_counts))
		temp[temp==tag_name] <- levels
	  }
	  
	  df[,cn] = factor(temp)
	}
	return (df)
}