library(TSP)
library(ggplot2)
library(plyr)
library(reshape2)
library(data.table)
library(zoo)
library(gridExtra)



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

random_tour <- function(tour)
{
  #to choose two cities on the tour randomly, and then reverse the portion of the tour that lies between them
  m_tour <- tour
  n <- length(tour)
  m <- sort(1+sample.int(n-2, size = 2))
  i = m[1]
  j = m[2]
  m_tour[i:j] <- rev(tour[i:j])
  return(m_tour)
}

random_tour_2 <- function(tour)
{
  #to choose two cities on the tour randomly, and then swap them
  m_tour <- tour
  n <- length(tour)
  m <- sort(1+sample.int(n-2, size = 2))
  i = m[1]
  j = m[2]
  m_tour[i] <- tour[j]
  m_tour[j] <- tour[i]
  return(m_tour)
}

random_tour_3 <- function(tour)
{
  #to choose one citiy on the tour randomly, and move its position
  n <- length(tour)
  m <- 1+sample.int(n-2, size = 2) #[2, n-1]
  i = m[1] #i moved to j position
  j = m[2]
  
  node_id = tour[i]
  
  m_tour <- append(tour[-i],node_id, after = j-1) 
  
  return(m_tour)
}

n = 256
set.seed(1234)

df = data.frame(x = runif(n), y = runif(n))

ggplot(df, aes(x, y)) + geom_point()

#----- Compute tour ----

tsp <- ETSP(df)

#write_TSPLIB(ETSP(data.frame(x = 1000*df$x, y = 1000*df$y )), file.path('F:/Github/KaggleSandbox','Santa/data/random.1024.tsp'), precision = 16)

tour <- solve_TSP(tsp, two_opt = TRUE, repetitions = 100) #tour_length(tour)

tsp_solution = as.numeric(tour)
tsp_solution = c(tsp_solution, tsp_solution[1])

tour_len(df, tsp_solution)

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_path(data = df[tsp_solution, ], aes(x, y)) + ggtitle(paste('length:', tour_len(df, tsp_solution)))
#condor best 12.68103

#----- random tour ----
r_tour = c(1, sample(seq(from = 2, to = nrow(df))), 1)

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_path(data = df[r_tour, ], aes(x, y)) + ggtitle(paste('length:', tour_len(df, r_tour)))

maxit = 100*1000

curr_len =  tour_len(df, r_tour)
best_len =  curr_len
r_tour_best = r_tour
for(i in seq(maxit)){
  
  scale = 0.005*exp(-5.0*i/maxit)
  
  r_tour_next = random_tour(r_tour)
  #r_tour_next = random_tour(r_tour_next)
  #r_tour_next = random_tour_2(r_tour_next)
  #r_tour_next = random_tour_2(r_tour)
  #r_tour_next = random_tour_3(r_tour)
  
  df_t = data.frame(x = df$x + scale*rnorm(nrow(df)), y = df$y + scale*rnorm(nrow(df)) )
  
  r_tour_next_len_t = tour_len(df_t, r_tour_next)
  r_tour_next_len   = tour_len(df, r_tour_next)
  
  if(r_tour_next_len_t<curr_len){
    print(sprintf('%d: %f -> %f (%f)', i, curr_len, r_tour_next_len, scale))
    curr_len = r_tour_next_len
    r_tour = r_tour_next
  }
  
  if(r_tour_next_len<best_len){
    best_len = r_tour_next_len
    r_tour_best = r_tour
  }
}
r_tour = r_tour_best

ggplot(df, aes(x, y)) + geom_point(color = 'red') + 
  geom_path(data = df[r_tour, ], aes(x, y)) + ggtitle(paste('length:', tour_len(df, r_tour))) #3.517602

ggplot(df, aes(x, y)) + 
  geom_point(color = 'red') + 
  geom_path(data = df[random_tour(r_tour), ], aes(x, y), color = 'blue', size = 2, alpha = 0.4) +
  geom_path(data = df[r_tour, ], aes(x, y), color = 'black')

#best_len =  tour_len(df, r_tour)
#res = ldply(seq(1000), function(i){  data.frame(i, len = tour_len(df, random_tour(r_tour) )- best_len) })
#ggplot(res, aes(len)) + stat_ecdf()
#sort(res$len)
