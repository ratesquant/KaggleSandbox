library(TSP)
library(ggplot2)
library(plyr)
library(reshape2)
library(data.table)
library(zoo)
library(gridExtra)
library(ggvoronoi)
library(deldir)

working_folder = 'F:/Github/KaggleSandbox'
source(file.path(working_folder, '/Utils/common.R'))


gen_greedy_tour <- function(df){
  
  tour = c(1)
  
  node_ids = seq(nrow(df))
  
  for(i in 1:(nrow(df)-1)){
    s_node = tour[i]
    
    dx = df$x[-tour] - df$x[s_node]
    dy = df$y[-tour] - df$y[s_node]
    
    temp = data.frame(id = node_ids[-tour], dist = sqrt(dx*dx + dy*dy))
    tour = c(tour, temp$id[order(temp$dist)[1]])
  }
  return( c(tour,1) )
}


tour_len <- function(df, tour){
  
  x_c = df$x[tour]
  y_c = df$y[tour]
  
  dx = diff(x_c)
  dy = diff(y_c)
  
  dist = sum( sqrt(dx * dx + dy * dy) )
  
  return( dist )
}

random_indexes <- function(n)
{
  m <- sort(1+sample.int(n-2, size = 2))
  return(m)
}

modify_tour <- function(m, tour)
{
  #to choose two cities on the tour randomly, and then reverse the portion of the tour that lies between them
  m_tour <- tour
  i = m[1]
  j = m[2]
  m_tour[i:j] <- rev(tour[i:j])
  return(m_tour)
}

#to choose two cities on the tour randomly, and then reverse the portion of the tour that lies between them
random_tour_1 <- function(tour)
{
  m_tour <- tour
  n <- length(tour)
  m <- sort(1+sample.int(n-2, size = 2))
  i = m[1]
  j = m[2]
  m_tour[i:j] <- rev(tour[i:j])
  return(m_tour)
}

#to choose two cities on the tour randomly, and then swap them
#not a complete shuffle
random_tour_2 <- function(tour)
{
  m_tour <- tour
  n <- length(tour)
  m <- 1+sample.int(n-2, size = 2)#[2, n-1]
  i = m[1]
  j = m[2]
  m_tour[i] <- tour[j]
  m_tour[j] <- tour[i]
  return(m_tour)
}
#temp = ldply(seq(1024), function(i)random_tour_2(c(1,2,3,4,5,1)))
#temp = ldply(seq(1024), function(i)random_tour_2(r_tour))

#to choose one city on the tour randomly, and move its position
random_tour_3 <- function(tour)
{
  n <- length(tour)
  m <- 1+sample.int(n-2, size = 2) #[2, n-1]
  i = m[1] #i moved to j position
  j = m[2]
  
  m_tour <- append(tour[-i],tour[i], after = ifelse(i<j, j-2, j-1) ) 
  
  return(m_tour)
}
#temp = ldply(seq(1024*16), function(i)random_tour_3(c(seq(16),1)))
#temp = ldply(seq(1024*16), function(i)random_tour_3(r_tour))

#move random section 
random_tour_4 <- function(tour)
{
  n <- length(tour)
  m <- sort(1+sample.int(n-2, size = 2)) #[2, n-1]
  sec_len = 1 + m[2]- m[1]
  
  ms = sample.int(n-sec_len-1, size = 1)
  node_id = m[1]:m[2]
  m_tour <- append(tour[-node_id],tour[node_id], after = ms ) 
  
  return(m_tour)
}
#random_tour_4(c(1,2,3,4,5,1))
#temp = ldply(seq(1024*16), function(i)random_tour_4(c(seq(16),1)))
#temp = ldply(seq(1024*16), function(i)random_tour_3(r_tour))


#move a single node to neighbour (uses global nn_index)
random_tour_5 <- function(tour)
{
  n <- length(tour)
  m <- 1+sample.int(n-2, size = 1) #[2, n-1]
  
  close_nodes = subset(nn_index, ind1==m | ind2 == m)
  candidate_list = unique(c(close_nodes$ind1, close_nodes$ind2)) %!in_set% c(m, n-1)
  node_id = sample(candidate_list, 1)
  
  node_id = ifelse(node_id > m, node_id - 1, node_id)
  
  m_tour <- append(tour[-m],tour[m], after = node_id) 
  
  return(m_tour)
}
#temp = ldply(seq(1024*16), function(i)random_tour_5(c(seq(16),1)))
#temp = ldply(seq(1024*16), function(i)random_tour_5(r_tour))

n = 256
set.seed(1234)

#df = expand.grid(x = seq(10), y = seq(10))
df = data.frame(x = runif(n), y = runif(n))

#compute triangulation
dxy1 = deldir(df$x, df$y, plotit = FALSE)
nn_index = dxy1[['delsgs']][,c('ind1', 'ind2')]
n_len = sqrt( (df$x[nn_index$ind1] - df$x[nn_index$ind2])^2 + (df$y[nn_index$ind1] - df$y[nn_index$ind2])^2 )
mean(n_len)

ggplot(df, aes(x, y)) + geom_point() + stat_voronoi(geom="path")

#----- Compute tour ----

tsp <- ETSP(df)

#write_TSPLIB(ETSP(data.frame(x = 1000*df$x, y = 1000*df$y )), file.path('F:/Github/KaggleSandbox','Santa/data/random.1024.tsp'), precision = 16)

tour <- solve_TSP(tsp, two_opt = TRUE, repetitions = 1000) #tour_length(tour)

tsp_solution = as.numeric(tour)
tsp_solution = c(tsp_solution, tsp_solution[1])

tour_len(df, tsp_solution)

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_path(data = df[tsp_solution, ], aes(x, y)) + ggtitle(paste('length:', tour_len(df, tsp_solution))) + 
  stat_voronoi(geom="path", alpha = 0.1)
#condor best 3.244084 (16)
#condor best 4.92227  (32)
#condor best 12.36858  (256)
#condor best   (1024)

#----- random tour ----

maxit = 500

tsp_solver <-function(df, r_tour, maxit, scale_0, decay){
  
  shifters = c('random_tour_1', 'random_tour_2', 'random_tour_3', 'random_tour_4','random_tour_5')
  #shifters = c('random_tour_5')

  curr_len =  tour_len(df, r_tour)
  best_len =  curr_len
  r_tour_best = r_tour
  n_it = maxit * length(r_tour)
  for(i in 1:n_it){
    
    scale = scale_0*exp(-decay*i/n_it)
    
    shift_fun = sample(shifters, 1)
    
    r_tour_next = do.call(shift_fun, list(r_tour))
    
    df_t = data.frame(x = df$x + scale*rnorm(nrow(df)), y = df$y + scale*rnorm(nrow(df)) )
    r_tour_curr_len_t = tour_len(df_t, r_tour)
    r_tour_next_len_t = tour_len(df_t, r_tour_next)
    r_tour_next_len   = tour_len(df,   r_tour_next)
    
    if(r_tour_next_len<best_len){
      best_len = r_tour_next_len
      r_tour_best = r_tour_next
    }
    
    if(r_tour_next_len_t<r_tour_curr_len_t){
      print(sprintf('%6d: %f %f (%f) %s', i, best_len, r_tour_next_len, scale, shift_fun))
      r_tour = r_tour_next
    }
    
  }
  return(r_tour_best)
}
#r_tour = c(1, sample(seq(from = 2, to = nrow(df))), 1)
#r_tour = c(seq(nrow(df)), 1)
r_tour = gen_greedy_tour(df)

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_path(data = df[r_tour, ], aes(x, y)) + ggtitle(paste('length:', tour_len(df, r_tour)))

r_tour = tsp_solver(df, r_tour, maxit, 0.01, 3)

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_point(data = df[1, ], aes(x, y), size = 2) + 
  geom_path(data = df[r_tour, ], aes(x, y), size = 1) + 
  stat_voronoi(geom="path", alpha = 0.1)  +
  geom_path(data = df[tsp_solution, ], aes(x, y), color = 'blue', alpha = 0.2, size = 2)  +
  ggtitle(paste('length:', tour_len(df, r_tour))) #3.517602

ggplot(df, aes(x, y)) + 
  geom_point(color = 'red') + 
  geom_path(data = df[random_tour_2(r_tour), ], aes(x, y), color = 'blue', size = 2, alpha = 0.1) +
  geom_path(data = df[r_tour, ], aes(x, y), color = 'black') 
  
#as.numeric(subset(temp, V2 == 3)[1,])
ggplot(df, aes(x, y)) + 
  geom_point(color = 'red') + 
  geom_path(data = df[c(1,7,8,3,4,2,6,9,14,16,5,11,10,12,13,15,1), ], aes(x, y), color = 'blue', size = 2, alpha = 0.3) +
  geom_path(data = df[r_tour, ], aes(x, y), color = 'black')

#best_len =  tour_len(df, r_tour)
#res = ldply(seq(1000), function(i){  data.frame(i, len = tour_len(df, random_tour(r_tour) )- best_len) })
#ggplot(res, aes(len)) + stat_ecdf()
#sort(res$len)

#----- parametric search ----

init_tour = c(seq(nrow(df)), 1)

params = expand.grid(decay = c(3), sigma = c( 0.01, 0.02, 0.03), maxit = 1000*c(10, 20, 30, 40, 50))

res = ldply(seq(nrow(params)), function(i){
  r_tour = tsp_solver(df, init_tour, params$maxit[i], params$sigma[i], params$decay[i])
  
  cbind( data.frame(len= tour_len(df, r_tour)), params[i,])
})

ggplot(res, aes(maxit/1000, len, group = factor(sigma), color = factor(sigma))) + geom_point() + geom_line() +
  #geom_hline(yintercept = tour_len(df, tsp_solution)) +
  facet_wrap(~decay)
