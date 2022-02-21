library(data.table)
library(ggplot)
library(grid)
library(foreach)
library(gganimate)
library(gifski)
library(deSolve)

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
  }
  else if (type == 3)  {
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
  }
  else if (type == 5)  {
    #circles
    phi1 = 3*2*pi * runif(n)
    c1 = data.frame(x = sigma*rnorm(n) + sin(phi1), y = sigma*rnorm(n) + cos(phi1), z =phi1/3 + sigma*rnorm(n),  id = 1)
    c2 = data.frame(x = sigma*rnorm(n), y = sigma*rnorm(n), z =phi1/3 + sigma*rnorm(n),  id = 2)
    
    res = rbind(c1, c2)
  }
  
    
  return (res)
}

#df <- data.table(unique(iris))
#df[, id:=Species]

df <- create_cluster_example(100, 5, sigma = 0.01) 
setDT(df)
scatter3d(df$x, df$y, df$z, surface = FALSE, bg.col= "black")

# manual projection algorithm ODE45 ---------
orig_dist = as.matrix(dist(df[,1:3]))
df_proj = data.table(x1 = rnorm(nrow(df)), x2 = rnorm(nrow(df)))
#df_proj = data.table(princomp(df[,1:3])$scores[,1:2])
names(df_proj) <- c('x1', 'x2')

df_proj[, v1:=0]
df_proj[, v2:=0]

ode_rhs <- function(t, x, parms, input){
  n = as.list(c(params))$n
  x1 = x[      (1:n)]
  x2 = x[1*n + (1:n)]
  v1 = x[2*n + (1:n)]
  v2 = x[3*n + (1:n)]
  proj_dist = as.matrix( dist(data.frame(x1, x2)))
  
  f1 = rep(0, n)
  f2 = rep(0, n)
  
  for(j in seq(n)){
    scale = proj_dist[j,]/orig_dist[j, ] - 1
    f1[j] = -sum( (2*as.numeric(x1[j] > x1[-j]) - 1) *  scale[-j] )
    f2[j] = -sum( (2*as.numeric(x2[j] > x2[-j]) - 1) *  scale[-j] )
  }
  
  dx1 = v1
  dx2 = v2
  dv1 = f1  - 2 * v1
  dv2 = f2  - 2 * v2
  
  res <- c(dx1, dx2, dv1, dv2)
  list(res)
}

params <- c(n = nrow(df_proj))

out <- ode(y = c(df_proj$x1, df_proj$x2, df_proj$v1, df_proj$v2), times = seq(0, 10), method  = "ode45", func = ode_rhs, params)

df_proj = ldply(seq(nrow(out)), function(i){ 
  n = as.list(c(params))$n
  x1 = out[i,       (1:n)+1]
  x2 = out[i, 1*n + (1:n)+1]
  v1 = out[i, 2*n + (1:n)+1]
  v2 = out[i, 3*n + (1:n)+1]
  data.frame(it = i, x1, x2, v1, v2) })
setDT(df_proj)

ggplot(cbind(df_proj[it == max(it)], df), aes(x1, x2, group = id, color = factor(id) )) + geom_point()
ggplot(df_proj, aes(x1, x2)) + geom_point() + facet_wrap(~it)
ggplot(df_proj[,.(vm = sqrt(sum(v1 * v1 + v2 * v2)) ),by=.(it)], aes(it, vm)) + geom_line()

# manual projection algorithm EULER ---------
df_proj = data.table(x1 = runif(nrow(df)), x2 = runif(nrow(df)))
dt = 0.01
n_it = 500
df_proj[, f1:=0]
df_proj[, f2:=0]
df_proj[, v1:=0]
df_proj[, v2:=0]

df_it = data.frame(it = seq(n_it), v = rep(0, n_it), f = rep(0, n_it))
for(i in df_it$it){
  
  proj_dist = as.matrix( dist(df_proj[,1:2]) )
  
  n = nrow(df_proj)
   for(j in seq(n)){
    scale = proj_dist[j,]/orig_dist[j, ] - 1
    df_proj$f1[j] = -sum( (2*as.numeric(df_proj$x1[j] > df_proj$x1[-j]) - 1) *  scale[-j] )
    df_proj$f2[j] = -sum( (2*as.numeric(df_proj$x2[j] > df_proj$x2[-j]) - 1) *  scale[-j] )
  }
  df_proj[, v1:=v1 + f1 * dt - 2 * v1 * dt]
  df_proj[, v2:=v2 + f2 * dt - 2 * v2 * dt]
  df_proj[, x1:=x1 + v1 * dt]
  df_proj[, x2:=x2 + v2 * dt]
  df_it$v[i] = df_proj[, mean(sqrt(v1 * v1 + v2 * v2))]
}

df_proj[, fm := sqrt(f1 * f1 + f2 * f2)]

ggplot(cbind(df_proj, df), aes(x1, x2, group = id, color = factor(id) )) + geom_point() + 
  geom_segment(aes(x = x1, y = x2, xend = x1 + v1 * dt, yend = x2 + v2 * dt))

ggplot(df_it, aes(it*dt, v)) + geom_line()
#ggplot(df_it, aes(v, f)) + geom_path() 
#ggplot( reshape2::melt(as.matrix( dist(df_proj[,1:2]))), aes(Var1, Var2, fill =value) ) + geom_tile()
#ggplot( reshape2::melt(as.matrix( dist(df[,1:3]))), aes(Var1, Var2, fill =value) ) + geom_tile()

# ANIMATION  ---------

orig_dist = as.matrix(dist(df[,1:3]))
#df_proj = data.table(x1 = runif(nrow(df)), x2 = runif(nrow(df)))
df_proj = data.table(princomp(df[,1:3])$scores[,1:2])
names(df_proj) <- c('x1', 'x2')

df_proj[, fx1:=0]
df_proj[, fx2:=0]
df_proj[, vx1:=0]
df_proj[, vx2:=0]
dt = 0.02

n_it = 300

df_it = data.frame(it = seq(n_it), v = rep(0, n_it), f = rep(0, n_it))

df_amin = foreach(i = df_it$it, .combine = rbind) %do% {
  
  proj_dist = as.matrix( dist(df_proj[,1:2]) )
  
  n = nrow(df_proj)
  for(j in seq(n)){
    scale = proj_dist[j,]/orig_dist[j, ] - 1
    df_proj$fx1[j] = -sum( (2*as.numeric(df_proj$x1[j] > df_proj$x1[-j]) - 1) *  scale[-j] )
    df_proj$fx2[j] = -sum( (2*as.numeric(df_proj$x2[j] > df_proj$x2[-j]) - 1) *  scale[-j] )
    
  }
  df_proj[, vx1:=vx1 + fx1 * dt - 2 * vx1 * dt]
  df_proj[, vx2:=vx2 + fx2 * dt - 2 * vx2 * dt]
  df_proj[, x1:=x1 + vx1 * dt]
  df_proj[, x2:=x2 + vx2 * dt]
  df_it$v[i] = df_proj[, mean(sqrt(vx1 * vx1 + vx2 * vx2))]
  df_it$f[i] = df_proj[, mean(sqrt(fx1 * fx1 + fx2 * fx2))]
  
  return(cbind(df_proj, df, it = i))
}

anim4 <- ggplot(df_amin, aes(x1, x2, color = factor(id) )) +
  geom_point(alpha = 0.7, show.legend = FALSE) + 
  geom_segment(aes(x = x1, y = x2, xend = x1 + vx1 * dt, yend = x2 + vx2 * dt)) + 
  labs(title = "{closest_state}")  + transition_states(it) 
#animate(anim4)
#animate(anim4, renderer = file_renderer(dir = 'C:/Users/chirokov/Pictures/r_amin', prefix = "gganim_plot", overwrite = TRUE))
#animate(anim4, renderer = gifski_renderer(file = 'C:/Users/chirokov/Pictures/r_amin.gif'))
animate(anim4, nframes = max(df_amin$it), renderer = gifski_renderer())
anim_save('C:/Users/chirokov/Pictures/temp.gif')

# dumping  ---------
x0 = 10
xc = 0

dt = 0.02
dumping = 2

df_it = data.frame(it = seq(n_it), x = rep(x0, n_it), v = rep(0, n_it), f = rep(0, n_it))

 
for(i in seq(nrow(df_it) - 1) ){
  
  df_it$v[i + 1] = df_it$v[i] - (df_it$x[i] - xc) * dt - 1.0*dumping * df_it$v[i] * dt
  df_it$x[i + 1] = df_it$x[i] +  df_it$v[i] * dt
  
}
ggplot(df_it, aes(it, x)) + geom_line()


