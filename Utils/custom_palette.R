library(ggplot2)
library(data.table)
library(car)
library(imager)
library(plyr)
library(gridExtra)


working_folder = 'D:/Github/KaggleSandbox'

source(file.path(working_folder, 'Utils/common.R'))

## ALL COLORS -------------
crgb <- col2rgb(cc <- colors())
colnames(crgb) <- cc
t(crgb)  # The whole table


## My Palette -----------
#p1   = c("#000080","#0000ff","#0080ff", "#00ffff", "#80ff80", "#ffff00","#ff8000","#ff0000", "#800000") #JET
#p1   = c("#000080","#0000ff","#0080ff", "#00ffff", "#808080", "#ffff00","#ff8000","#ff0000", "#800000") #rainbow - diverging
#p1   = c("#0000FF","#00FFFF", "#00FF00", "#FFFF00", "#FF0000") #rainbow
#p1   = c("#3333FF","#33FFFF", "#33FF33", "#FFFF33", "#FF3333") #rainbow - less saturated
p1 = hsv(seq(0, 1, by = 0.1),  seq(1.0, 0, by = -0.1), seq(0, 1.0, by = 0.1))
p1 = hsv( seq(0.7,0, length.out = 10),  seq(1.0, 0, length.out = 10), seq(0, 1.0, length.out = 10))
#hsv(0.5, 1, 1)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(p1)(256))

ggplot(df, aes(x, y, fill = z2)) + geom_tile() + 
  scale_fill_gradientn(colours = colorRampPalette(c("#000080","#0000ff","#ffffff", "#ff0000", "#800000"))(256))


df = data.table(faithfuld)
names(df) <-c('x', 'y', 'z1')
df[, z2 := x]

#ggplot(df, aes(x, y)) + geom_tile( fill = hsv(0.9, 1, 1))
plots = llply(names(custom_palettes), function(palette_name){
  ggplot(df, aes(x, y, fill = z1)) + geom_tile() + scale_fill_custom(palette_name, discrete = FALSE) + ggtitle(palette_name) + theme_light()
})
marrangeGrob(plots, nrow = 4, ncol = 4, top = NULL)


ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('jet', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('mixed', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('rainbow', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('rainbow_muted', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_custom('cubehelix', discrete = FALSE)
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(p1)(256))
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan",
                                                                                                  "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))(256))

## show palette --------
my_pal = colorRampPalette(p1, space = "rgb")(256)
df_pal = data.table(t(col2rgb(my_pal)), t(rgb2hsv(col2rgb(my_pal))) )
df_pal[, i := seq(.N)]
ggplot(df_pal) + geom_line(aes(i, red), color = 'red') + geom_line(aes(i, green), color = 'green') +  geom_line(aes(i, blue), color = 'blue')

#scatter3d(df_pal$r, df_pal$g, df_pal$b, surface = FALSE, bg.col= "black")

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


# Read image file ----------------

reduce_image_colors<-function(input_image, n_colors){
  
  df_rgb = data.table(as.data.frame(input_image, wide = 'c'))
  df_rgb[, c('x', 'y', 'c.4'):=NULL]
  setnames(df_rgb, c('c.1', 'c.2', 'c.3'), c('r', 'g', 'b'))
  
  cl <- kmeans(df_rgb, n_colors, nstart = 10)
  df_rgb[, cluster := cl$cluster]
  df_clusters = data.table(cl$centers, cluster = seq(nrow(cl$centers)))
  
  df_rgb[df_clusters, rc:=i.r, on=.(cluster)]
  df_rgb[df_clusters, gc:=i.g, on=.(cluster)]
  df_rgb[df_clusters, bc:=i.b, on=.(cluster)]
  
  output_image = as.cimg(unlist(df_rgb[,.(rc, gc, bc)]),x=width(input_image),y=height(input_image),cc=3)
  
  return (output_image)
}

plot(as.cimg(rep(1:100,3),x=10,y=10,cc=3)) #10x10 RGB

test_image = load.image(file.path(working_folder, 'data/USA.PNG'))

par(mfrow=c(1,2))
plot(test_image)
plot(reduce_image_colors(test_image, 7))
par(mfrow=c(1,1))

df_image = data.table(as.data.frame(test_image, wide = 'c'))
df_image[, c('x', 'y', 'c.4'):=NULL]
setnames(df_image, c('c.1', 'c.2', 'c.3'), c('r', 'g', 'b'))

ggplot(df_image, aes(r)) + geom_histogram()
ggplot(df_image, aes(r, b)) + geom_point()

cl_res = ldply(seq(10), function(i){
  res = kmeans(df_image, i)
  return (c('n' = i, 'totss'=res$totss, 'tot.withinss'=res$tot.withinss, 'betweenss' = res$betweenss))
})
ggplot(cl_res, aes(n, tot.withinss/totss)) + geom_line() + geom_point()
ggplot(cl_res, aes(n, betweenss/totss)) + geom_line()+ geom_point()

#cluster and contruct palette
cl <- kmeans(df_image, 7, nstart = 25)
p1 = apply(cl$centers, 1, function(x) rgb(x[1], x[2], x[3]))
p1 = rev(c("#EE87AD","#E86555","#EBE156","#FDFDFD", "#62AF68", "#82B1D5", "#666BA9"))
ggplot(df, aes(x, y, fill = z2)) + geom_tile() + scale_fill_gradientn(colours = colorRampPalette(p1)(256))
ggplot(df, aes(x, y, fill = z1)) + geom_tile() + scale_fill_custom('yb', discrete = FALSE)


## contour plots
volcano_long <- data.frame(
  x = as.vector(col(volcano)),
  y = as.vector(row(volcano)),
  z = as.vector(volcano)
)
ggplot(volcano_long, aes(x, y, z = z)) + 
  geom_polygon(aes(fill = stat(level)), alpha = 0.5, stat = "contour") + 
  guides(fill = "legend")

ggplot(volcano_long, aes(x, y, z = z)) + 
  geom_contour_filled(aes(fill = stat(level)), alpha = 0.5)

ggplot(volcano_long, aes(x, y, z = z)) + 
  geom_contour_filled(aes(fill = stat(level))) + 
  guides(fill = guide_colorsteps(barheight = unit(10, "cm")))

huron <- data.frame(year = 1875:1972, level = as.vector(LakeHuron))
ggplot(huron) + geom_ribbon(aes(year, ymin = level - 10, ymax = level + 10), fill = "grey", colour = "black")

