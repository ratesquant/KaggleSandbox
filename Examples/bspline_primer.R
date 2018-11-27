library(splines)
library(ggplot2)

#flat after last right knot
x = rnorm(1024)
my_knots = c(-2, -1, 0, 2)
xs1 = bs(x, knots = my_knots, degree = 1, intercept = FALSE) #5 splines (excluding min/max 3)
xs2 = bs(x, knots = my_knots, degree = 2, intercept = FALSE) #6 splines (excluding min/max 2)

matplot(x, xs1)
matplot(x, xs2)

df1 = data.frame(x, s1 = xs1[,2], s2 = xs1[,3], s3 = xs1[,4] + xs1[,5])
ggplot(df1, aes(x, s1)) + geom_line() + geom_line(aes(x, s2)) +  geom_line(aes(x, s3)) + geom_line(aes(x, 1 - (s1 + s2 + s3) ), color = 'red') + 
  geom_vline(xintercept = my_knots, linetype = 'dashed', alpha = 0.5, color = 'blue')

df2 = data.frame(x, s1 = xs2[,3], s2 = xs2[,4] + xs2[,5] + xs2[,6])
ggplot(df2, aes(x, s1)) + geom_line() + geom_line(aes(x, s2)) + geom_line(aes(x, 1 - (s1 + s2) ), color = 'red') + 
  geom_vline(xintercept = my_knots, linetype = 'dashed', alpha = 0.5, color = 'blue')

# replicate 2nd order spline
xs_h1 = bs(x, knots = c(-2,  0, 2), degree = 1, intercept = FALSE)
xs_h2 = bs(x, knots = c(-2, -1, 2), degree = 1, intercept = FALSE)

dfm = data.frame(x, s2 = xs2[,3], s11 = xs1[,2], s12 = xs1[,3], s2ex = (xs1[,2] * xs_h1[,2] + xs1[,3] * xs_h2[,2]) )
ggplot(dfm, aes(x, s2)) + geom_line(color = 'red') + geom_line(aes(x, s11)) + geom_line(aes(x, s12)) + 
  geom_line(aes(x, s2ex), color = 'green')

xs_h1 = bs(x, knots = c(-1, 2), degree = 1, intercept = FALSE)
xs_h2 = bs(x, knots = c(-1, 0, 2), degree = 1, intercept = FALSE)

dfm = data.frame(x, s2 = xs2[,4] + xs2[,5] + xs2[,6], s11 = xs1[,3], s12 = xs1[,4] + xs1[,5], s2ex = (xs1[,3] * (xs_h1[,2] +  xs_h1[,3]) + (xs1[,4] + xs1[,5]) * (xs_h2[,2] + xs_h2[,3] + xs_h2[,4]) ))
ggplot(dfm, aes(x, s2)) + geom_line(color = 'red') + geom_line(aes(x, s11)) + geom_line(aes(x, s12)) + 
  geom_line(aes(x, s2ex), color = 'green')
