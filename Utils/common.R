
## misc utils ----------

'%!in%' <- function(x,y)!('%in%'(x,y))
'%!in_set%' <- function(x,y)(x[!'%in%'(x,y)])
'%in_set%' <- function(x,y)(x['%in%'(x,y)])

rms_log <-function(y, x) {
  return ( sqrt( mean ( (log(y+1) - log(x+1))^2 )))
} 

logistic <- function(x){
  return (1.0 / (1.0 + exp(-x)))
}
logit <- function(x){
  return ( log(x/(1-x)))
}

rms <-function(y1, y2) sqrt( mean( (y1 - y2)^2 ))

#https://en.wikipedia.org/wiki/Design_effect#Effective_sample_size
effective_size <- function(w){
  #sum(w)^2 / sum(w*w)
  length(w) * mean(w)^2 / (mean(w*w))
}

effective_size_rho <- function(w, rho = 0){
  neff = effective_size(w)
  neff / (1 + (neff-1)*rho)
}


to_prob <-function(x, train_index){
  xt = x[train_index]
  ecdf(xt)(x) - 0.5/length(xt)
}

to_normal_prob <-function(x, train_index){
  max_sigma = pnorm(-5) #2.866516e-07
  qnorm(pmin(1-max_sigma,pmax(max_sigma, to_prob(x, train_index)  )) )
}

# expand_dublicates - the same x values will produce different y values 
ecdf_norm<-function(x, normal = TRUE, expand_dublicates = FALSE) {
  n = length(x)
  
  if(expand_dublicates){
    y = (seq(n)-0.5)/n
    y[order(x)] = y
  }else{
    y = ecdf(x)(x) -0.5/n
}
  
  if(normal){
    y = qnorm(y)
  }
  return (y)
}

periodogram <-function(y){
  N = length(y)
  xPerZp <- (1/N)*abs(fft(y)^2)
  fzp    <- seq(0,1.0-1/N,by=1/N)
  return (data.frame(freq = fzp[2:ceiling((N-1)/2+1)], y = xPerZp[2:ceiling((N-1)/2+1)]))
}


normalize_data <- function(x){
  #x = data.frame(c1 = rnorm(10), c2 = rnorm(10), c3 = sample(LETTERS[1:4], 10, replace = TRUE) )
  sapply(x, function (col) { ecdf_norm(col) })
}

#Platt calibration
platt_scaling <- function(actual, model, model_pred) {
  
  n_event0 = sum(actual==0)
  n_event1 = length(actual) - n_event0
  
  target = actual
  target[target != 0] = (n_event1 + 1)/(n_event1 + 2)
  target[target == 0] = 1/(n_event0 + 2)
  
  platt_obj <- function(x) {
    prob = 1.0 / (1.0 + exp(x[1] * model + x[2]))
    return ( -sum(target * log(prob) + (1-target) * log(1-prob)) )
  }
  
  res = optim(c(-1,log((n_event0+1)/(n_event1+1))), platt_obj)
  
  return (1.0 / (1.0 + exp(res$par[1] * model_pred + res$par[2])))
}

# Create function to handle missing Current UPBs in the last record by setting them to the record prior
na.lomf <- function(x) {
  
  na.lomf.0 <- function(x) {
    non.na.idx <- intersect(which(!is.na(x)),which(x>0))
    if (is.na(x[1L]) || x[1L]==0) {
      non.na.idx <- c(1L, non.na.idx)
    }
    rep.int(x[non.na.idx], diff(c(non.na.idx, length(x) + 1L)))
  }
  
  dim.len <- length(dim(x))
  
  if (dim.len == 0L) {
    na.lomf.0(x)
  } else {
    apply(x, dim.len, na.lomf.0)
  }
}

na.lomf_L <- function(x) {
  
  non.na.idx <- intersect(which(!is.na(x)),which(x[length(x)-1]>0))
  if (is.na(x[length(x)]) || x[length(x)]==0) {
    XX<-c(x[1:length(x)-1], rep.int(x[length(x)-1], 1))
  } else {
    XX<-x
  }
  
}


.ls.objects <- function (pos = 1, pattern, order.by,
                         decreasing=FALSE, head=FALSE, n=5) {
  napply <- function(names, fn) sapply(names, function(x)
    fn(get(x, pos = pos)))
  names <- ls(pos = pos, pattern = pattern)
  obj.class <- napply(names, function(x) as.character(class(x))[1])
  obj.mode <- napply(names, mode)
  obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
  obj.prettysize <- napply(names, function(x) {
    format(utils::object.size(x), units = "auto") })
  obj.size <- napply(names, object.size)
  obj.dim <- t(napply(names, function(x)
    as.numeric(dim(x))[1:2]))
  vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
  obj.dim[vec, 1] <- napply(names, length)[vec]
  out <- data.frame(obj.type, obj.size, obj.prettysize, obj.dim)
  names(out) <- c("Type", "Size", "PrettySize", "Length/Rows", "Columns")
  if (!missing(order.by))
    out <- out[order(out[[order.by]], decreasing=decreasing), ]
  if (head)
    out <- head(out, n)
  out
}

# shorthand
lsos <- function(..., n=10) {
  .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
}


#res2 <- cor.mtest(mtcars,0.99)
#corrplot(M, p.mat = res1[[1]], sig.level=0.2)
#correlation conf interval
cor.mtest <- function(mat, conf.level = 0.95){
  mat <- as.matrix(mat)
  n <- ncol(mat)
  p.mat <- lowCI.mat <- uppCI.mat <- matrix(NA, n, n)
  diag(p.mat) <- 0
  diag(lowCI.mat) <- diag(uppCI.mat) <- 1
  for(i in 1:(n-1)){
    for(j in (i+1):n){
      tmp <- cor.test(mat[,i], mat[,j], conf.level = conf.level)
      p.mat[i,j] <- p.mat[j,i] <- tmp$p.value
      lowCI.mat[i,j] <- lowCI.mat[j,i] <- tmp$conf.int[1]
      uppCI.mat[i,j] <- uppCI.mat[j,i] <- tmp$conf.int[2]
    }
  }
  return(list(p.mat, lowCI.mat, uppCI.mat))
}

cutq <- function(x, probs = seq(0, 1, 0.1), na.rm = TRUE, include.lowest = TRUE){
  res = cut(x, breaks = unique(quantile(x,probs = probs, na.rm = na.rm)),include.lowest = include.lowest)
  return(res)
}

## GGPLOT Colors ----------
custom_colors <- c(
  `red`        = "#d11141",
  `green`      = "#00b159",
  `blue`       = "#00aedb",
  `orange`     = "#f37735",
  `yellow`     = "#ffc425",
  `light grey` = "#cccccc",
  `dark grey`  = "#8c8c8c")

custom_cols <- function(...) {
  cols <- c(...)
  
  if (is.null(cols))
    return (custom_colors)
  
  custom_colors[cols]
}
#https://www.kennethmoreland.com/color-maps/
#https://jiffyclub.github.io/palettable/cubehelix/
#http://www.mrao.cam.ac.uk/~dag/CUBEHELIX/
#https://github.com/jrwrigh/cfdpost_colormaps

custom_palettes <- list(
  `main`  = custom_cols("blue", "green", "yellow"),
  `cool`  = custom_cols("blue", "green"),
  `hot`   = custom_cols("yellow", "orange", "red"),
  `mixed` = custom_cols("blue", "green", "yellow", "orange", "red"),
  `grey`  = custom_cols("light grey", "dark grey"),
  `jet`   = c("#000080","#0000ff","#0080ff", "#00ffff", "#80ff80", "#ffff00","#ff8000","#ff0000", "#800000"),
  `div`   = c("#5548C1","#DDDDDD", "#B10127"),
  `rainbow` =  c("#0000FF","#00FFFF","#00FF00","#FFFF00","#FF0000"),
  `rainbow_muted` = c("#3333FF","#33FFFF","#33FF33","#FFFF33","#FF3333"),
  `div2`   = c("#EBA569", "#FCFCFC", "#7296B0"),
  `div3`   = rev(c("#EE87AD","#E86555","#EBE156","#FDFDFD", "#62AF68", "#82B1D5", "#666BA9")),
  `seq`    = c("#7098B2","#E8DF57","#EA707C","#FCFCFC"),
  `seq2`  = c("#FDFCFD","#7CA3CE","#607E74","#ED727D","#E9E057"),
  `yb`    = c("#E8DF57", "#7098B2"),
  `rb`    = c("#000080","#0000ff","#ffffff","#ff0000","#800000"),
  `cubehelix`     = c('#000000','#160c1f','#1a213e','#163d4e','#175a49','#2b6f39','#54792f','#877a3a','#b5795e','#d07e93','#d490c6','#caabe8','#c1caf3','#c8e4f0','#e0f5f0','#ffffff'), #default start=0.5, rot=-1.5, hue=1, gamma=1
  `cubehelix_hue` = c('#000000','#180926','#17204d','#07425b','#01654c','#177d2b','#4b8313','#907c1b','#cc7149','#eb7190','#e882d4','#d1a3fe','#bcc9ff','#bee8fa','#d9f8f0','#ffffff')  #more hue start=0.5, rot=-1.5, hue=1.5, gamma=1
)

custom_pal <- function(palette = "main", reverse = FALSE, ...) {
  pal <- custom_palettes[[palette]]
  
  if (reverse) pal <- rev(pal)
  
  colorRampPalette(pal, ...)
}

scale_color_custom <- function(palette = "main", discrete = TRUE, reverse = FALSE, ...) {
  pal <- custom_pal(palette = palette, reverse = reverse)
  
  if (discrete) {
    discrete_scale("colour", paste0("drsimonj_", palette), palette = pal, ...)
  } else {
    scale_color_gradientn(colours = pal(256), ...)
  }
}

scale_fill_custom <- function(palette = "main", discrete = TRUE, reverse = FALSE, ...) {
  pal <- custom_pal(palette = palette, reverse = reverse)
  
  if (discrete) {
    discrete_scale("fill", paste0("custom_", palette), palette = pal, ...)
  } else {
    scale_fill_gradientn(colours = pal(256), ...)
  }
}

## Models util functions ----------

winsoraze<-function(x, x_train, alpha = 0.05) {
  q_bounds = quantile(x_train, c(alpha/2, 1- alpha/2))
  x = pmax(pmin(x, q_bounds[2]), q_bounds[1])
  return (x)
}

partialPlot <- function(obj, pred.data, xname, n.pt = 19, discrete.x = FALSE, 
                        subsample = pmin(1, n.pt * 100 / nrow(pred.data)), which.class = NULL,
                        xlab = deparse(substitute(xname)), ylab = "", type = if (discrete.x) "p" else "b",
                        main = "", rug = TRUE, seed = NULL, ...) {
  stopifnot(dim(pred.data) >= 1)
  
  if (subsample < 1) {
    if (!is.null(seed)) {
      set.seed(seed)
    } 
    n <- nrow(pred.data)
    picked <- sample(n, trunc(subsample * n))
    pred.data <- pred.data[picked, , drop = FALSE]
  }
  xv <- pred.data[, xname]
  
  if (discrete.x) {
    x <- unique(xv)
  } else {
    x <- quantile(xv, seq(0.03, 0.97, length.out = n.pt), names = FALSE, na.rm = TRUE)
  }
  y <- numeric(length(x))
  
  isRanger <- inherits(obj, "ranger")
  isLm <- inherits(obj, "lm") | inherits(obj, "lmrob") | inherits(obj, "lmerMod")
  
  for (i in seq_along(x)) {
    pred.data[, xname] <- x[i]
    
    if (isRanger) {
      if (!is.null(which.class)) {
        if (obj$treetype != "Probability estimation") {
          stop("Choose probability = TRUE when fitting ranger multiclass model") 
        }
        preds <- predict(obj, pred.data)$predictions[, which.class]
      }
      else {
        preds <- predict(obj, pred.data)$predictions
      }
    } else if (isLm) {
      preds <- predict(obj, pred.data) 
    } else {
      if (!is.null(which.class)) {
        preds <- predict(obj, pred.data, reshape = TRUE)[, which.class + 1] 
      } else {
        preds <- predict(obj, pred.data)
      }
    }
    
    y[i] <- mean(preds)
  }
  
  #plot(x, y, xlab = xlab, ylab = ylab, main = main, type = type, ...)
  data.frame(x = x, y = y)
}

plot_cormat <- function(df_in, show_diagonal = TRUE){
corr_matrix = cor(data.matrix(df_in), use="pairwise.complete.obs")
corr_matrix_df = data.table(reshape2::melt(corr_matrix))

if(!show_diagonal) corr_matrix_df[Var1==Var2, value := NA]

p = ggplot(corr_matrix_df, aes(Var1, Var2, fill = value)) + geom_tile() + 
  theme(axis.text.x = element_text(angle = 90, size = 8), axis.text.y = element_text(size = 8), axis.title.x = element_blank(), axis.title.y = element_blank()) + 
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0)
return (p)
}


## GBM plotting functions ----------

gbm_interactions <- function(gbm_model, data, iter, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, n.trees = iter, plotit=FALSE)
  vars = gbm_summary$var[gbm_summary$rel.inf > min_influence]
  
  all_combinations = combn(as.character(vars), degree, simplify = TRUE)
  
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    interaction_score = try( interact.gbm(gbm_model, data, all_combinations[,i], n.trees = iter))
    if(!is.numeric(interaction_score)) 
      interaction_score = NA
    data.frame(vars = paste(all_combinations[,i], collapse = '|'), interaction_score = interaction_score)
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}

#special version for gbm3
gbm3_interactions <- function(gbm_model, data, iter, min_influence = 1, degree = 2){
  gbm_summary = summary(gbm_model, num_trees = iter, plot_it=FALSE)
  vars = gbm_summary$var[gbm_summary$rel_inf > min_influence]
  all_combinations = combn(as.character(vars), degree, simplify = TRUE)
  df = ldply(seq(dim(all_combinations)[2]), function(i) {
    interaction_score = try( interact(gbm_model, data, all_combinations[,i], num_trees = iter))
    if(!is.numeric(interaction_score)) 
      interaction_score = NA
    data.frame(vars = paste(all_combinations[,i], collapse = '|'), interaction_score = interaction_score)
  })
  return ( df[order(df$interaction_score, decreasing = TRUE),] )
}

plot_gbminteractions <- function(x){
  ggplot(x, aes(x = reorder(vars, interaction_score), y = interaction_score))  + geom_bar(stat = 'identity') + coord_flip() + geom_hline(yintercept = 0.1, color = 'red') +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_gbminfluence <- function(x){
  ggplot(x, aes(x = reorder(var, rel.inf), y = rel.inf, fill = cut(rel.inf, c(0, 0.01, 0.1, 1, 10, 100), include.lowest = TRUE,ordered_result = TRUE )))  + 
    geom_bar(stat = 'identity') + coord_flip() + 
    geom_hline(yintercept = 1.0, color = 'red', linetype="dashed") +
    #scale_fill_brewer(palette = 'Spectral', drop = FALSE) +
    scale_fill_custom('mixed', drop = FALSE) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1), axis.title.x = element_blank(), legend.position = 'none')
}

plot_gbmiterations <- function(gbm_model) {
  
  plot_title = ''
  
  iteration = seq(length(gbm_model$train.error))
  
  plot = ggplot(data.frame(iteration, train_error = gbm_model$train.error), aes(iteration, train_error) ) + geom_line() 
  
  #add cv
  if(!is.null(gbm_model$cv.error) & !all(is.na(gbm_model$cv.error)) ){
    
    min_cv = min(gbm_model$cv.error, na.rm = T)
    min_cv_it = min(which(gbm_model$cv.error == min_cv))
    
    plot = plot + geom_line(data = data.frame(iteration, cv_error = gbm_model$cv.error), aes(iteration, cv_error), color = 'red' ) +
      geom_hline(yintercept = min_cv, color = 'red', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_cv_it, color = 'red', alpha = 0.5)
      
    plot_title = paste(plot_title, sprintf('cv-%d(%d)=%.5f ', gbm_model$cv.folds, min_cv_it, min_cv) )
  }
  
  #add cv (new gbm3 variable names)
  if(!is.null(gbm_model$cv_error) & !all(is.na(gbm_model$cv_error)) ){
    
    min_cv = min(gbm_model$cv_error, na.rm = T)
    min_cv_it = min(which(gbm_model$cv_error == min_cv))
    
    plot = plot + geom_line(data = data.frame(iteration, cv_error = gbm_model$cv_error), aes(iteration, cv_error), color = 'red' ) +
      geom_hline(yintercept = min_cv, color = 'red', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_cv_it, color = 'red', alpha = 0.5)
    
    plot_title = paste(plot_title, sprintf('cv-%d(%d)=%.5f ', gbm_model$cv_folds, min_cv_it, min_cv) )
  }
  
  #add out of bag
  if(!is.null(gbm_model$oobag.improve) & !all(is.na(gbm_model$oobag.improve)) ){
    oob = gbm_model$train.error[1] - cumsum(gbm_model$oobag.improve) #this is for scaling purpose 
    min_oob = min(oob, na.rm = T)
    min_oob_it = min(which(oob == min_oob))
    
    plot = plot + geom_line(data = data.frame(iteration, oob = oob), aes(iteration, oob), color = 'gray' ) +
      geom_hline(yintercept = min_oob, color = 'gray', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_oob_it, color = 'gray', alpha = 0.5)
    
    plot_title = paste(plot_title, sprintf('oob(%d)=%.5f', min_oob_it, min_oob) )
  }
  
  #add validation
  if(!is.null(gbm_model$valid.error) & !all(is.na(gbm_model$valid.error)) ){
    val = gbm_model$valid.error #this is for scaling purpose 
    min_val = min(val, na.rm = T)
    min_val_it = min(which(val == min_val))
    
    plot = plot + geom_line(data = data.frame(iteration, val = val), aes(iteration, val), color = 'blue' ) +
      geom_hline(yintercept = min_val, color = 'blue', alpha = 0.5, linetype = "dashed") + 
      geom_vline(xintercept = min_val_it, color = 'blue', alpha = 0.5)
    
    plot_title = paste(plot_title, sprintf('val(%d)=%.5f ', min_val_it, min_val) )
  }
  
  plot = plot + ggtitle(plot_title)
  
  return (plot)
}


plot_gbmpartial <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response', add_rug = TRUE, max_rug_points = 1000, derivative = FALSE){
  plots <- llply(variables, function(vname){
    plot_data = plot(gbm_model, i.var = vname, n.trees = iter, type = output_type, continuous.resolution = resolution, return.grid = TRUE)
   
    r_name = gbm_model$response.name
    
    names(plot_data) <- c('x', 'y')
    
    plot_result <- ggplot() + geom_blank() 
    
    if(is.factor(plot_data$x)){
      plot_result = ggplot(plot_data, aes(reorder(x, y), y, group = 1)) + 
        geom_line(color = 'black') +
        geom_point() +
        theme(legend.position = 'none', axis.text.x = element_text(angle = 90, hjust = 1), axis.title.y = element_blank(), axis.title.x = element_blank()) + 
        ggtitle(vname)
    }else{
      if(derivative){
        plot_result = ggplot(plot_data, aes(x, c(0, diff(y) ))) + geom_line(color = 'black') +  
          theme(legend.position = 'none', axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
      }else{
        plot_result = ggplot(plot_data, aes(x, y)) + geom_line(color = 'black') +  
          theme(legend.position = 'none', axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
      }
      
    }
    
    
    if(add_rug){
      vname_index = match(vname, gbm_model$var.names)
      size_per_var = length(gbm_model$data$x) / length(gbm_model$var.names)
      xdata = gbm_model$data$x[1:size_per_var + (vname_index - 1) * size_per_var]
      
      rug_index = sample.int(size_per_var, min(max_rug_points, size_per_var))
      
      if(is.factor(plot_data$x)){
        plot_result = plot_result + 
          geom_rug(data = data.frame(x = xdata[rug_index]), aes(x), sides = 'b', alpha = 0.1, size = 0.2, inherit.aes = FALSE)
          #position = position_jitter(width = ifelse(x_factor,0.25, 0) , height = 0)
      }else{
        plot_result = plot_result + 
          geom_rug(data = data.frame(x = xdata[rug_index]), aes(x), sides = 'b', alpha = 0.2, size = 0.2, inherit.aes = FALSE) + 
          geom_rug(data = data.frame(x = quantile(xdata, seq(0, 1, by = 0.25), names = FALSE, na.rm = TRUE)), aes(x), sides = 'b', alpha = 0.8, size = 0.5, inherit.aes = FALSE, color = 'red')
      }
    }
    return (plot_result)
  })
  return (plots)
}

plot_gbm3partial <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response', add_rug = TRUE, max_rug_points = 1024){
  plots <- llply(variables, function(vname){
    plot_data = plot(gbm_model, var_index = vname, num_trees = iter, type = output_type, continuous_resolution = resolution, return_grid = TRUE)
    names(plot_data) <- c('x', 'y')
    
    plot_result <- ggplot() + geom_blank() 
    
    if(is.factor(plot_data$x)){
      plot_result = ggplot(plot_data, aes(reorder(x, y), y, group = 1)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.text.x = element_text(angle = 90, hjust = 1), axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    }else{
      plot_result = ggplot(plot_data, aes(x, y)) + geom_line(color = 'black', size = 1) +
        theme(legend.position = 'none', axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
      
      if(add_rug){
        vname_index = match(vname, gbm_model$variables$var_names)
        size_per_var = length(gbm_model$gbm_data_obj$x) / length(gbm_model$variables$var_names)
        xdata = gbm_model$gbm_data_obj$x[1:size_per_var + (vname_index - 1) * size_per_var]
        
        rug_index = sample.int(size_per_var, min(max_rug_points, size_per_var))
        
        plot_result = plot_result + 
          geom_rug(data = data.frame(x = xdata[rug_index]), aes(x), sides = 'b', alpha = 0.2, size = 0.2, inherit.aes = FALSE) +
          geom_rug(data = data.frame(x = quantile(xdata, seq(0, 1, by = 0.25), names = FALSE, na.rm = TRUE)), aes(x), sides = 'b', alpha = 0.8, size = 0.5, inherit.aes = FALSE, color = 'red')
        
      }
    }
    return (plot_result)
  })
  return (plots)
}


plot_gbmpartial_2d <- function(gbm_model, iter, variables, resolution = 100, output_type = 'response', add_rug = TRUE, max_rug_points = 1024){
  plots <- llply(variables, function(vname){
    
    var_pair = strsplit(as.character(vname),'|', fixed = T)[[1]]
    plot_data = plot(gbm_model, i.var = var_pair, n.trees = iter, type = output_type, continuous.resolution = resolution, return.grid = TRUE)
    
    x_name = var_pair[1]
    y_name = var_pair[2]
    r_name = gbm_model$response.name
    
    names(plot_data) <- c(x_name, y_name, r_name)
    
    plot_result = ggplot() + geom_blank()
    
    if(is.factor(plot_data[,y_name])){
    plot_result = ggplot(plot_data, aes_string(x_name, r_name, group = y_name, color = y_name)) + 
      geom_line() + 
      xlab(x_name) + ylab(r_name)
    }else{
      plot_result = ggplot(plot_data, aes_string(x_name, y_name, z = r_name, fill = r_name)) + 
        geom_raster() + 
        scale_fill_distiller(palette = 'Spectral') +
        xlab(x_name) + ylab(y_name)
      
    }
        #theme(axis.title.y = element_blank(), axis.title.x = element_blank()) + ggtitle(vname)
    
    if(add_rug & !is.factor(plot_data[,x_name]) & !is.factor(plot_data[,y_name]))
    {
      vname_index1 = match(var_pair[1], gbm_model$var.names)
      vname_index2 = match(var_pair[2], gbm_model$var.names)
      size_per_var = length(gbm_model$data$x) / length(gbm_model$var.names)
      
      xdata = gbm_model$data$x[1:size_per_var + (vname_index1 - 1) * size_per_var]
      ydata = gbm_model$data$x[1:size_per_var + (vname_index2 - 1) * size_per_var]
      
      if(max_rug_points<=0){
        max_rug_points = size_per_var
      }
      rug_index = sample.int(size_per_var, min(max_rug_points, size_per_var))
      
      plot_result = plot_result + 
        geom_point(data = data.frame(x = xdata[rug_index], y = ydata[rug_index]), aes(x, y), alpha = 0.2, size = 0.2, inherit.aes = FALSE, color = 'black')
    }
    
    return (plot_result)
  })
  return (plots)
}

plot_profile <- function(mod, act, profile, bucket_count = 10, min_obs = 30, error_band = c('normal', 'binom')[1], average_value = c('mean', 'median')[1], conf_level = 0.95, map_fun = function(x) x){
  plot_result = ggplot() + geom_blank()
  
  factor_plot = FALSE
  
  if( !is.numeric(profile)){
    buckets = factor(profile)
    factor_plot = TRUE
  }else{
    breaks = quantile(profile, seq(0, bucket_count, 1)/bucket_count, na.rm = TRUE)
    breaks = unique(breaks)
    if(length(breaks)<=2) {
      breaks = unique(seq(min(profile, na.rm = T), max(profile, na.rm = T), length.out = bucket_count))
    }
    if(length(breaks)<=2) {
      factor_plot = TRUE
      buckets = factor(profile)
    }else{
      buckets = cut(profile, breaks, ordered_result = TRUE, include.lowest = TRUE)
    }
  }
  
  agg_buckets<-function(x) {
    ns = length(x$actual)
    
    if(average_value == 'mean'){
      model_mean = mean(x$model)
      actual_mean = mean(x$actual)
    }else{
      model_mean = median(x$model)
      actual_mean = median(x$actual)
    }
    actual_std = sd(x$actual)
    
    if(error_band == 'binom' & ns >= 2 )
    {
      conf_int = binom.test(sum(x$actual!=0), ns, p = model_mean, alternative = 'two.sided', conf.level = conf_level)$conf.int
    }else if(error_band == 'normal' & ns >= 2 & actual_std > 1e-12 ){
      conf_int = t.test(x$actual, y = NULL, alternative = c('two.sided'), conf.level = conf_level)$conf.int
    }else{
      conf_int = c(actual_mean, actual_mean)
    }
    
    conf_break = model_mean < conf_int[1] | model_mean > conf_int[2]
    
    res = list(actual = map_fun(actual_mean),
      model = map_fun(model_mean),
      actual_std = map_fun(actual_std),
      count = ns,
      profile = ifelse(factor_plot, NA, mean(x$profile, na.rm = TRUE)),
      actual_min = map_fun(conf_int[1]),
      actual_max = map_fun(conf_int[2]),
      confidence_break = conf_break,
      actual_min_break = map_fun(ifelse(conf_break, conf_int[1], actual_mean)),
      actual_max_break = map_fun(ifelse(conf_break, conf_int[2], actual_mean)))
    return ( res )
  }
  
  df_temp = data.table(actual = act, model = mod, bucket = buckets, profile)
  res = df_temp[complete.cases(act, mod),agg_buckets(.SD), by = .(bucket)]

  #res = res[count >= min_obs & !is.na(profile),]
  res = res[count >= min_obs,]
  
  y_min = min(res$actual, res$model)
  y_max = max(res$actual, res$model)
  
  if(nrow(res) > 0 )
  {
    if(factor_plot){
      
      date_xaxis = all(!is.na(as.Date(res$bucket, optional = TRUE)))
      
      if( date_xaxis ){
        res[,buckets := as.Date(bucket, optional = TRUE)]
      }else
      {
        res[,buckets := factor(bucket)]
        xlabels = levels(res$buckets)
      }
      
      plot_result = ggplot(res, aes(buckets, actual, group = 1)) + 
        geom_point(color = 'black') + 
        geom_line(color = 'black', size = 1) +
        #geom_point(aes(buckets, model), color = 'red') + 
        geom_line(aes(buckets, model), color = 'red', size = 1, alpha= 0.8) +
        #ylab('actual (bk) vs model (rd)') + 
        theme(legend.position = 'none', axis.title.x = element_blank()) +
        geom_ribbon(aes(ymax = actual_max, ymin = actual_min), fill = 'blue', alpha = 0.05) +
        geom_errorbar(aes(ymax = actual_max_break, ymin = actual_min_break), width = 0.0, color = 'blue', alpha = 0.3) +
        coord_cartesian(ylim = c(y_min, y_max)) 
      
      if(!date_xaxis){
        plot_result = plot_result + scale_x_discrete(breaks = xlabels) + 
          theme(axis.text.x = element_text(angle = 90, hjust = 1))
      }
      
    }else{
      plot_result = ggplot(res, aes(profile, actual)) + 
        geom_point(color = 'black') + 
        geom_line(color = 'black', size = 1) +
        #geom_point(aes(profile, model), color = 'red') + 
        geom_line(aes(profile, model), color = 'red', size = 1, alpha= 0.8) +
        #ylab('actual (bk) vs model (rd)') + 
        theme(legend.position = 'none', axis.title.x = element_blank()) + 
        geom_ribbon(aes(ymax = actual_max, ymin = actual_min), fill = 'blue', alpha = 0.05) +
        geom_errorbar(aes(ymax = actual_max_break, ymin = actual_min_break), width = 0.0, color = 'blue', alpha = 0.3) +
        coord_cartesian(ylim = c(y_min, y_max))
    }
    
    res_conf_bk = subset(res,confidence_break==1)
    if(nrow(res_conf_bk)>0)
    {
      if(factor_plot) {
        plot_result = plot_result +      
          geom_point(data = res_conf_bk, aes(buckets, model), color = 'red')
        
      }else{
        plot_result = plot_result +      
          geom_point(data = res_conf_bk, aes(profile, model), color = 'red')
      }
    }
    
  }
  return (plot_result)
}
  
#plot missing values
ggplot_missing <- function(x){
  mx = melt(is.na(x))
  ggplot(mx, aes(Var2, Var1)) + geom_raster(aes(fill = value)) +
    theme(axis.text.x  = element_text(angle=90, vjust=0.5)) + 
    scale_fill_grey(name = "", labels = c("Valid","NA")) +
    labs(x = "Variable name",   y = "Rows") + 
    ggtitle (paste('total number of missing values:',  sum(mx$value)))
}

#plot number of missing values
ggplot_missing_count <- function(x){
  mc = adply(is.na(x), 2, sum)
  names(mc) <- c('name', 'value')
  ggplot(mc, aes(name, value)) + geom_bar(stat = "identity") +
    theme(axis.text.x  = element_text(angle=90, vjust=0.5)) + 
    labs(x = "Variable name",   y = "Missing Variables")
}

write.xclip <- function(x, selection=c("primary", "secondary", "clipboard"), ...) {
  if (!isTRUE(file.exists(Sys.which("xclip")[1L])))  stop("Cannot find xclip")
  selection <- match.arg(selection)[1L]
  con <- pipe(paste0("xclip -i -selection ", selection), "w")
  on.exit(close(con))
  write.table(x, con, ...)
}

is_linux<-function(){
  return(.Platform$OS.type == "unix")
}

write.clipboard <- function(x, ...){
  write.xclip(x, "clipboard", ...)
}

#copy to clipboard, works on win
cc <- function(x,...){
  if(is_linux()){
    write.clipboard(x,...)
  }else{
    #write.table(x, "clipboard-16384", sep="\t", row.names=FALSE,...)
    write.table(x, "clipboard-1024", sep="\t", row.names=FALSE,...)
  }
}

## Binomial plot functions ----- 
#do all diagnostic plots
plot_binmodel_predictions<-function(actual, model){
  p1 = plot_binmodel_roc(actual, model)
  p2 = plot_binmodel_cdf(actual, model)
  p3 = plot_binmodel_percentiles(actual, model, 10)
  p4 = plot_binmodel_density(actual, model)
  grid.arrange(p1, p2, p3, p4, ncol=2)
}

integrate_step_function<-function(x, y){
   index = order(x)
   dx = diff(x[index])
   ys = y[index]
   return( sum(dx * ys[-length(y)]) )
}


integrate_function<-function(x, y){
  index = order(x)
  dx = diff(x[index])
  ys = y[index]
  return( sum(0.5 * dx * (ys[-1] + ys[-length(y)])) )
}

#plot ROC curve (KS is a largest distance from 1,1 line)
plot_binmodel_roc<-function(actual, model){
  non_event = actual == 0
  m1 = sort(model[!non_event])
  m0 = sort(model[ non_event])
  
  xc = sort(c(0, model, 1))
  q1 = ecdf(m1)(xc)
  q0 = ecdf(m0)(xc)
  
  res = data.table(q01 = rev(1 - q0), q11 = rev(1 - q1))
  
  auc = 1.0 - integrate_function(q0, q1) # GINI = 2 * AUC -1
  
  xb = seq(0, 1, by = 0.2)
  
  p = ggplot(res, aes(q01, q11)) +  
    geom_step() + 
    scale_x_continuous(breaks = xb, limits = c(0, 1)) +
    scale_y_continuous(breaks = xb, limits = c(0, 1)) +
    geom_abline(slope = 1, intercept = 0, colour = 'red', linetype = 2) +
    geom_ribbon(aes(ymin = q01, ymax = q11), fill = 'blue', alpha = 0.2) +
    labs(x = "false positive",   y = "true positive") +
    annotate('text', label = sprintf('AUC = %.4f', auc), x = 1, y = 0, hjust = 'right', vjust = 'bottom', color = 'gray', size = 5) +
  theme(legend.position = 'none')
  
  return(p)
}

#CAP (cummulative Accuracy Profile), aka Lift Curve, Power Curve, 
#AR is equal to GINI index
plot_binmodel_cap<-function(actual, model){
  non_event = actual == 0
  m1 = sort(model[!non_event])
  m0 = sort(model) # this is the main difference between Lift and ROC
  
  avg_prob = 1.0 - sum(!non_event)/length(actual)
  
  xc = sort(c(0, model, 1))
  q1 = ecdf(m1)(xc)
  q0 = ecdf(m0)(xc)
  
  res = data.table(q01 = rev(1 - q0), q11 = rev(1 - q1))
  
  ar = (1.0 - 2.0*integrate_function(q0, q1))/avg_prob
  
  xb = seq(0, 1, by = 0.2)
  
  p = ggplot(res, aes(q01, q11)) +  
    geom_step() + 
    scale_x_continuous(breaks = xb, limits = c(0, 1)) +
    scale_y_continuous(breaks = xb, limits = c(0, 1)) +
    geom_abline(slope = 1, intercept = 0, colour = 'red', linetype = 2) +
    geom_ribbon(aes(ymin = q01, ymax = q11), fill = 'blue', alpha = 0.2) +
    labs(x = "fraction of total",   y = "fraction of events") +
    annotate('text', label = sprintf('AR = %.4f', ar), x = 1, y = 0, hjust = 'right', vjust = 'bottom', color = 'gray', size = 5) +
    theme(legend.position = 'none')
  
  return(p)
}

#plot density of predictions 
plot_binmodel_density<-function(actual, model, n = 20){
  p = ggplot(data.frame(act = factor(actual), model), aes(model, fill = act))  + 
    geom_density(adjust = 0.25, alpha = 0.5, color = 'black') +
    scale_fill_manual(values = c('black', 'red')) +
    #scale_x_continuous(limits = c(min(model), max(model))) +
    theme(legend.position = 'none') 
  return (p)
}

plot_binmodel_histogram<-function(actual, model, n = 20){
  
  breaks = max(model, na.rm = T) * seq(0, max(model, na.rm = T), length.out = n + 1)
  p = ggplot(data.frame(actual, model), aes(model, fill = factor(actual)))  + 
    geom_histogram(breaks = breaks) +
    scale_fill_manual(values = c('black', 'red')) +
    theme(legend.position = 'none')
  return (p)
}
 
binmodel_ks<-function(actual, model){
  non_event = actual == 0
  m1 = sort(model[!non_event])
  m0 = sort(model[ non_event])
  
  #estimate difference between cdf
  xc = sort(c(0, model, 1))
  q1 = ecdf(m1)(xc)
  q0 = ecdf(m0)(xc)
  ks = 100.0 * max(abs(q1 - q0), na.rm = T)
  return (ks)
}

ecdf_ks<-function(x1, x2){
  #estimate difference between cdf
  xc = sort(c(0, x1, x2, 1))
  q1 = ecdf(x1)(xc)
  q2 = ecdf(x2)(xc)
  ks = 100.0 * max(abs(q1 - q2), na.rm = T)
  return (ks)
}
#plot cdf of predictions
plot_binmodel_cdf<-function(actual, model){
  non_event = actual == 0
  m1 = sort(model[!non_event])
  m0 = sort(model[ non_event])

  #estimate difference between cdf
  xc = sort(c(0, model, 1))
  q1 = ecdf(m1)(xc)
  q0 = ecdf(m0)(xc)
  ks = 100.0 * max(abs(q1 - q0), na.rm = T)
  
  max_prob = max(model, na.rm = T)
  max_m = min(1.0, max_prob + 1.0 / length(model))
  
  res1 = data.frame(p = c(0, m1, max_m), q = c(seq(0, length(m1))/length(m1), 1), outcome = 'act = 1')
  res2 = data.frame(p = c(0, m0, max_m), q = c(seq(0, length(m0))/length(m0), 1), outcome = 'act = 0')
  res3 = data.frame(p = xc, q = abs(q1 - q0), outcome = 'diff')
  
  res = rbind(res1, res2, res3)
  
  p = ggplot(res, aes(p, q, group = outcome, color = outcome)) + 
    geom_step(size = 1) + 
    scale_x_continuous(limits = c(0, max_m) ) + 
    scale_y_continuous(breaks = seq(0, 1, by = 0.2), limits = c(0, 1.0) ) +
  annotate("text", label = sprintf('KS = %0.2f', ks), x = 0, y = 1, hjust = 'left', vjust = 'top', color = 'gray', size = 5) +
  scale_color_manual(values = c('red', 'black', 'gray')) +
  labs(x = "probability",   y = "ecdf") + 
    theme(legend.position = 'none')
  
  return (p)
}
 
#percentile plot, model vs average actuals  
#actual - NA are excluded, model should not have NA
plot_binmodel_percentiles<-function(actual, model, n = 10, equal_count_buckets = FALSE, conf = 0.95){
  
  max_model = min(1.0, max(model, na.rm = T) + 1.0 / length(model))
  xb = max_model * seq(0, n, 1) / n
 
  if(equal_count_buckets){
      xb =  unique(quantile(model, probs = xb, names = FALSE, na.rm = TRUE))
      xb[1] = floor(n * xb[1]) / n # include zero when close
  }
  bucket = cut(model, xb, include.lowest = TRUE)
  
  agg_buckets <- function(x) {
    n = length(x$actual)
    avg_model = mean(x$model)
    n_act = sum(x$actual!=0)
    conf_int = c(NaN, NaN, NaN)
    
    if(n>3){
      test_res = binom.test(n_act, n, p = avg_model, alternative = 'two.sided')
      conf_int = c(test_res$conf.int, test_res$p.value)
    }
    
    data.table(
      avg_actual = n_act/n, 
      avg_model = avg_model,
      count = n,
      ub = conf_int[1],
      lb = conf_int[2],
      pvalue =  conf_int[3])
  }
 
  df = data.table(actual, model, bucket)
  res = df[complete.cases(actual, model),agg_buckets(.SD), by = .(bucket)]
  
  #Brier score
  bs = sqrt(sum(res$count * (res$avg_model - res$avg_actual)^2)/sum(res$count))
 
  p = ggplot(res, aes(avg_model, avg_actual)) + 
    geom_point() +  
    geom_line(color = 'gray',alpha = 0.6) +  
    geom_errorbar(aes(ymax = ub, ymin=lb), width=0, alpha = 0.6) + 
    geom_abline(slope = 1, intercept = 0, colour = 'red', linetype = 2) +
    geom_point(data = res[pvalue < 0.5 * (1.0- conf)], aes(avg_model, avg_actual), color = 'red') +
    labs(x = "model",   y = "actual") + 
    annotate("text", label = sprintf('BS = %0.4f', bs), x = 0, y = 1, hjust = 'left', vjust = 'top', color = 'gray', size = 5) +
#   geom_rug(sides = 'b', alpha = 0.2) +
    theme(legend.position = 'none')
  
  # if(!equal_count_buckets){
  #   p = p + scale_x_continuous(breaks = seq(0, 1, 0.2), limits = c(0,1)) +
  #           scale_y_continuous(breaks = seq(0, 1, 0.2), limits = c(0,1))
  # }
  return( p )
}

beta_conf <- function(mean, n, conf_int = 0.95){
    
    alpha = mean * (n) #add 2 for uniform priors
    beta = (1 - mean) * (n) #add 2 for uniform priors
    
    ci_lo = qbeta((1 - conf_int)/2, alpha, beta)
    ci_up = qbeta((1 + conf_int)/2, alpha, beta)
    
    return( c(ci_lo, ci_up) )
}

t_conf <- function(mean, sigma, n, conf_int = 0.95){

  ci_lo = mean + sigma * qt((1 - conf_int)/2, df = n - 1)/sqrt(n)
  ci_up = mean + sigma * qt((1 + conf_int)/2, df = n - 1)/sqrt(n)
  
  return( c(ci_lo, ci_up) )
}