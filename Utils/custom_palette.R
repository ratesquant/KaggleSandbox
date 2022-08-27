library(ggplot2)
library(data.table)

working_folder = 'D:/Github/KaggleSandbox'

source(file.path(working_folder, 'Utils/common.R'))

## ALL COLORS -------------
crgb <- col2rgb(cc <- colors())
colnames(crgb) <- cc
t(crgb)  # The whole table


## My Palette -----------
#p1   = c("#000080","#0000ff","#0080ff", "#00ffff", "#80ff80", "#ffff00","#ff8000","#ff0000", "#800000") #JET
p1   = c("#0000FF","#00FFFF", "#00FF00", "#FFFF00", "#FF0000") #rainbow
p1   = c("#3333FF","#33FFFF", "#33FF33", "#FFFF33", "#FF3333") #rainbow - less saturated
p1 = hsv(seq(0.66, 0, by = -0.02), 0.8, 1)
#hsv(0.5, 1, 1)

scale_fill_custom <- function(palette = "main", discrete = TRUE, reverse = FALSE, ...) {
  pal <- custom_pal(palette = palette, reverse = reverse)
  
  if (discrete) {
    discrete_scale("fill", paste0("custom_", palette), palette = pal, ...)
  } else {
    scale_fill_gradientn(colours = pal(256), ...)
  }
}


df = data.table(expand.grid(x = seq(-1, 1, 0.02), y = seq(-1, 1, 0.02)))
df[, z1 := sin(10 * x * exp(y)) + sin(x) + cos(y)]
df[, z2 := x]

#ggplot(df, aes(x, y)) + geom_tile( fill = hsv(0.9, 1, 1)) 


ggplot(df, aes(x, y, fill = z1)) + geom_tile() + scale_fill_custom('jet', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('jet', discrete = FALSE)

ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('mixed', discrete = FALSE)

ggplot(df, aes(x, y, fill = z1)) + geom_tile() + scale_fill_custom('rainbow', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('rainbow', discrete = FALSE)

ggplot(df, aes(x, y, fill = z1)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(p1)(256))
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(p1)(256))

ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan",
                                                                                                  "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(256))

## show palette --------
my_pal = colorRampPalette(p1, space = "rgb")(256)
df_pal = data.table(t(col2rgb(my_pal)), t(rgb2hsv(col2rgb(my_pal))) )
df_pal[, i := seq(.N)]
ggplot(df_pal) + geom_line(aes(i, red), color = 'red') + geom_line(aes(i, green), color = 'green') +  geom_line(aes(i, blue), color = 'blue')

df_pal_m = data.table::melt(df_pal, id.vars = 'i')
ggplot(df_pal_m[variable %in% c('red', 'green', 'blue')]) + geom_line(aes(i, value, color = variable))
#ggplot(df_pal_m[variable %in% c('red', 'green', 'blue')]) + geom_area(aes(i, value, fill = variable))
ggplot(df_pal_m[variable %in% c('h', 's', 'v')]) + geom_line(aes(i, value, color = variable))

#interpolation example
rgb.palette <- colorRampPalette(c("red", "orange", "blue"), space = "rgb")
Lab.palette <- colorRampPalette(c("red", "orange", "blue"), space = "Lab")

m <- outer(1:20,1:20,function(x,y) x)
filled.contour(m, col = colorRampPalette(p1, space = "rgb")(20))
filled.contour(m, col = rgb.palette(20))
filled.contour(m, col = Lab.palette(20))