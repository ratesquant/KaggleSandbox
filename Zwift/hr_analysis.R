rm(list = ls())

library(zoo)
library(chron)
library(foreach)
library(ggplot2)
library(plyr)
library(leaps)
library(gvlma)

#user settings
max_hr = 185
mass = 95 #kg

#constants
mph_to_ms = 0.44704 # mph to m/s
ft_to_m = 0.3048    # feet to meter
km_to_mile = 0.621371    # km to miles
ffg = 9.8 #free fall acceleration (g) m/s2

#assumptions about drag and roll
c_roll = 0.005
c_drag = 0.228130598


#read data
folder = "C:\\Dev\\Polar\\Data"
files = list.files(folder, pattern = glob2rx("*.csv"), full.names = TRUE)

env <- foreach:::.foreachGlobals
rm(list = ls(name = env), pos = env)

df <- foreach(k = 1:length(files), .inorder = FALSE, .combine=rbind) %do% {
  df = read.csv(files[k], skip = 2, colClasses = c('numeric', 'character', 'numeric', 'numeric', 'character', 'numeric', 'numeric','numeric','numeric','numeric','numeric'))
  names(df) <- c('sample', 'time', 'hr', 'speed', 'pace', 'cadence', 'altitude', 'stride', 'distance', 'temperature', 'power')
  df = df[,c('time', 'hr', 'speed', 'altitude', 'distance')]
  df$file = unlist(strsplit(basename(files[k]),'\\.|\\_'))[3]
  df$sec = seq(0, dim(df)[1] - 1)
  return (df)
}

#define new factors
df$file = as.factor(df$file)
df$speed_z = cut(df$speed, seq(0, 30, 2))
df$hr_z1 = cut(df$hr, seq(80, 180, 10))
df$hr_z2 = cut(df$hr, max_hr * 0.01 * c(0, seq(50, 100, by = 10)))
df$hr_ef = pmax(0, 2 * df$hr / max_hr - 1.0)
df$ctime = chron::times(df$time)

#moving averages
smoothing_window = 11
df$alt = ave(df$altitude, df$file, FUN = function(x) rollmean(x, k= smoothing_window, fill = NA))
df$avg_speed = ave(df$speed, df$file, FUN = function(x) rollmeanr(x, k= 2, fill = NA))

###########################
# Estmate Average Power for the time interval from t-1 to t 
# Power(t) - is average power from t-1 to t
###########################
df$alt_prev = ave(df$alt, df$file, FUN = function(x) return(c(NA, x[1:length(x)-1])))
df$speed_prev = ave(df$speed, df$file, FUN = function(x) return(c(NA, x[1:length(x)-1])))
df$ds = ft_to_m * ave(df$distance, df$file, FUN = function(x) return(c(NA,diff(x))))
df$ascend =  df$alt- df$alt_prev

df$kinetic_energy = 0.5 * mass * (df$speed^2 - df$speed_prev^2) * mph_to_ms^2
df$roll_energy = mass * ffg * df$avg_speed * mph_to_ms * c_roll
df$drag_energy = c_drag * (mph_to_ms * df$avg_speed)^3
df$climb_energy =  mass * ffg * (df$alt- df$alt_prev) * ft_to_m
df$power = pmax(0, df$kinetic_energy + df$roll_energy + df$drag_energy + df$climb_energy)
df$power[is.na(df$power)] = 0

df$power10  = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width =  10, fill = NA, FUN = mean))
df$power20  = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width =  20, fill = NA, FUN = mean))
df$power30  = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width =  30, fill = NA, FUN = mean))
df$power60  = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width =  60, fill = NA, FUN = mean))
df$power90  = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width =  90, fill = NA, FUN = mean))
df$power120 = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width = 120, fill = NA, FUN = mean))
df$power300 = ave(df$power, df$file, FUN = function(x) rollapplyr(x, width = 300, fill = NA, FUN = mean))
df$energy   = ave(df$power, df$file, FUN = function(x) (1e-3/4.2)*cumsum(x))


# comparison of morrow mtn
index = (df$file == '2016-07-09' | df$file == '2016-08-20')
ggplot(df[index,], aes(1e-3 * km_to_mile * ft_to_m * distance, power120, color = file, group = file)) + geom_line()
ggplot(df[index,], aes(1e-3 * km_to_mile * ft_to_m * distance, speed, color = file, group = file)) + geom_line()
ggplot(df[index,], aes(hr, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(90, 180, 10))
ggplot(df[index,], aes(power60, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(00, 600, 100))


## HR model regression
subsets = regsubsets(hr~., data = df[,c('hr', 'power10', 'power20', 'power30', 'power60','power90', 'power120', 'power360')], nvmax = 6)
plot(subsets, scale = 'adjr2')

hr_model1 = lm(hr ~  power60 + power360, data = df)
hr_model2 = lm(hr ~  I(sqrt(power60)) + power300, data = df)
summary(hr_model2)
#plotmo(hr_model1, pt.col=1, grid.col=TRUE, ngrid1 = 100, npoints = 1000)
#plotmo(hr_model2, pt.col=1, grid.col=TRUE, ngrid1 = 100, npoints = 1000)
#summary(gvlma(hr_model2))
#crPlots(hr_model2)
#durbinWatsonTest(hr_model2)

# MARS model
# sample = df[!(is.na(df$hr) | is.na(df$power60) | is.na(df$power300)), ]
# hr_model.mars = earth(hr ~  power60 + power300, data = sample, degree = 1)
# plotmo(hr_model.mars, pt.col=1, grid.col=TRUE, ngrid1 = 100, npoints = 1000)

#hr_model = lm(hr ~  ., data = df[,c('hr', 'speed', 'power30', 'power60',  'power120', 'power360')])
#step(hr_model, data = df)
df$hr_estimate1 = predict(hr_model1, newdata = df)
df$hr_estimate2 = predict(hr_model2, newdata = df)
plot(df$hr, df$hr_estimate2)

index = (df$file == '2016-07-09' | df$file == '2016-08-20')
ggplot(df[index,], aes(hr, power60, color = file)) + geom_point(size = 0.2) + 
  geom_smooth(method = 'loess', span = 0.3, color = 'black') +
  facet_grid(.~file)

ggplot(df[index,], aes(hr_estimate1, hr, color = file)) + geom_point(size = 0.2) + 
  geom_smooth(method = 'loess', span = 0.3, color = 'black') +
  facet_grid(.~file)

ggplot(df[index,], aes(time, hr_estimate1 - hr, color = file)) + geom_point(size = 0.2) + 
  facet_grid(.~file)



#par(mfrow = c(3, 1))
#plot(df$power[800:1024], type = 'l')
#plot(df$power60[800:1024], type = 'l', col = 'red')
#plot(df$alt[800:1024], type = 'l', col = 'red')

#plot(ft_to_m * (df$distance[2:10024] - df$distance[1:10023]), mph_to_ms * df$avg_speed[1:10023], type = 'p')
#grid()
#lines(mph_to_ms * 0.5*(df$speed[1:10023] + df$speed[2:10024]), type = 'l', col = 'red')

#plot(df$pow[800:1024], type = 'l')
#lines(df$pow1m[800:1024], type = 'l', col = 'red')

#compute averages
ddply(df, .(file), function(x) {
  c(avg_hr = mean(x$hr, na.rm = TRUE),
    max_hr = max(x$hr, na.rm = TRUE),
    avg_efford = mean(x$hr_ef, na.rm = TRUE),
    avg_speed = mean(x$speed, na.rm = TRUE),
    avg_power = mean(x$power, na.rm = TRUE),
    power60_99 = quantile(x$power60, 0.99, names = FALSE, na.rm = TRUE),
    power300_99 = quantile(x$power300, 0.99, names = FALSE, na.rm = TRUE),
    avg_fitness = mean(x$power, na.rm = TRUE) / mean(x$hr, na.rm = TRUE),
    dist = km_to_mile * ft_to_m * 1e-3 * max(x$distance, na.rm = TRUE),
    ascend = sum(pmax(0, x$ascend), na.rm = TRUE),
    kCal = 5 * max(x$energy, na.rm = TRUE),
    hr_alpha = coef(lm(x$hr ~ x$power60 + x$power360))[1],
    hr_beta = coef(lm(x$hr ~ x$power60+ x$power360))[2]
    )
})

#plot ECDF
ggplot(df, aes(hr_ef, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(0, 1, 0.1))
ggplot(df, aes(hr, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(80, 180, 10)) + scale_y_continuous(breaks = seq(0,1,0.1))
ggplot(df, aes(speed, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(0, 30, 5)) + scale_y_continuous(breaks = seq(0,1,0.1))
ggplot(df, aes(power30, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(0, 400, 50)) + scale_y_continuous(breaks = seq(0,1,0.1))

ggplot(df, aes(power60/hr, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(0, 400, 50)) + scale_y_continuous(breaks = seq(0,1,0.1))

#plot averages
ggplot(df, aes(hr, speed, color = file, group = file)) + 
  geom_point(stat = 'summary', fun.y = mean) + 
  stat_summary(fun.y = mean, geom = 'line') + 
  scale_x_continuous(breaks = seq(80, 180, 10))


ggplot(df, aes(hr, power120, color = file, group = file)) + 
  geom_point(stat = 'summary', fun.y = mean) + 
  stat_summary(fun.y = mean, geom = 'line') + 
  scale_x_continuous(breaks = seq(80, 180, 10))

ggplot(df, aes(hr, power60, color = file, group = file)) + 
  geom_point(stat = 'summary', fun.y = mean) + 
  stat_summary(fun.y = mean, geom = 'line') + 
  scale_x_continuous(breaks = seq(80, 180, 10)) + 
  facet_grid(.~file)


ggplot(df, aes(hr_z2, power120, color = file, group = file)) + 
  geom_point(stat = 'summary', fun.y = mean) + 
  stat_summary(fun.y = mean, geom = 'line')

#plot scatter
ggplot(df, aes(power60, hr, color = file, group = file)) +  geom_point() + geom_smooth(color = 'black') + facet_grid(file~.)
ggplot(df, aes(hr, pow1m, color = file, group = file)) +  geom_smooth(method = 'loess', span = 0.3)
ggplot(df, aes(hr, hr_estimate, color = file, group = file)) +  geom_point() + geom_smooth(color = 'black') + facet_grid(.~file)
ggplot(df, aes(power120, hr, color = file, group = file)) +  geom_smooth(method = 'lm')


#plot time series
ggplot(df, aes(sec, altitude, color = file)) + geom_line() + facet_grid(.~file)
ggplot(df, aes(ctime, hr, color = file)) + geom_line() + scale_x_chron(format = "%H:%M") + facet_grid(file~.)
ggplot(df, aes(ctime, speed, color = file)) + geom_line() + scale_x_chron(format = "%H:%M") + facet_grid(file~.)
ggplot(df, aes(ctime, power, color = file)) + geom_line() + scale_x_chron(format = "%H:%M") + facet_grid(file~.)
ggplot(df, aes(ctime, energy, color = file)) + geom_line() + scale_x_chron(format = "%H:%M") + facet_grid(file~.)

#HR dynamics
lag = 60 
df$hrlag  = ave(df$hr, df$file, FUN = function(x) c(rep(0, lag), diff(x, lag)))
df$hrlag_inc = pmax(0, df$hrlag)
df$hrlag_dec = pmin(0, df$hrlag)

df1 = df[df$file == '2016-08-20' | df$file == '2016-08-21',]
ggplot(df1, aes(hrlag, color = file)) + stat_ecdf() + scale_x_continuous(breaks = seq(-20, 20, 10)) + scale_y_continuous(breaks = seq(0,1,0.1))
ggplot(df1, aes(sample = hrlag, color = file)) + stat_qq()
ggplot(df, aes(hrlag, color = file)) + geom_density(size = 2) + facet_grid(file~.)
ggplot(df1, aes(hr, hrlag_dec, color = file)) + geom_point()

hrdf = ddply(df, .(file), function(x) {
  c(avg_hr = mean(x$hr, na.rm = TRUE),
    avg_power = mean(x$power, na.rm = TRUE),
    hr_dec80 = quantile(x$hrlag_dec, probs = c(0.1), na.rm = TRUE, names = FALSE),
    hr_inc80 = quantile(x$hrlag_inc, probs = c(0.9), na.rm = TRUE, names = FALSE)
  )
})
ggplot(hrdf, aes(file, avg_hr, group = 1)) + geom_line(size = 1)
ggplot(hrdf, aes(file, avg_power, group = 1)) + geom_line(size = 1)
ggplot(hrdf, aes(file, avg_power/(avg_hr - 60), group = 1)) + geom_line(size = 1)

ggplot(hrdf, aes(file, hr_dec80, group = 1)) + geom_line(size = 1)


lines(df$hr[600:1024], type = 'l')
plot(df$hr10[600:1024])

#HR fft
x = seq(0, 20, by =0.01)
y = sin(x) + 0.0*rnorm(length(x))
plot(x, y, type = 'l')

lag = 100
dy = c(rep(0, lag), diff(y, lag))
plot(x, dy, type = 'l')
plot(ecdf(dy))
grid()


