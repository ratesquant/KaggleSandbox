# example producing the pdf reports
library(ggplot2)
library(gridExtra)
library(plyr)

working_folder = file.path(Sys.getenv("HOME"), 'Downloads/')

plots = llply(seq(12*10), function(i){
  n = 256
  p = ggplot(data.frame(x=rnorm(n), y=rnorm(n)), aes(x, y)) + geom_point() + ggtitle(paste(i))
  return (p)
})

ggsave(filename = file.path(working_folder,"example1.pdf"), plot = marrangeGrob(plots, nrow=3, ncol=4),
       device = 'pdf', width = 11, height = 8.5, dpi = 96)

gplots = lapply(plots, ggplotGrob)
ggsave(filename = file.path(working_folder,"example2.pdf"), plot = marrangeGrob(gplots, nrow=3, ncol=4),
       device = 'pdf', width = 11, height = 8.5, dpi = 360)


## ----------- check pdf performance ----

save_pdf_test <- function(filename_pdf, n_pages, n_points, dpi ){
  
  start_time <- Sys.time()
  
  plots = llply(seq(12 * n_pages), function(i){
    p = ggplot(data.frame(x=rnorm(n_points), y=rnorm(n_points)), aes(x, y)) + geom_point() + ggtitle(paste(i))
    return (p)
  })
  
  gplots = lapply(plots, ggplotGrob)
  ggsave(filename = filename_pdf, plot = marrangeGrob(gplots, nrow=3, ncol=4),
         device = 'pdf', width = 11, height = 8.5, dpi = dpi)
  
  file.info(filename_pdf)$size / 1024
  
  return(as.numeric(Sys.time() - start_time))
}

filename_pdf = file.path(working_folder,"example_bench.pdf")

params = expand.grid(n_pages = seq(5), n_points = c(64, 256, 1024), dpi = c(120, 240, 300, 360))
#params = expand.grid(n_pages = c(1), n_points = c(64, 256, 1024), dpi = c(120))

res = ldply(seq(nrow(params)), function(i){
  
  elapsed = save_pdf_test(filename_pdf, params$n_pages[i], params$n_points[i], params$dpi[i])
  
  file.info(filename_pdf)$size / 1024
  
  return (cbind(data.frame(i, elapsed, fsize = file.info(filename_pdf)$size / 1024),params[i,]) )
})

ggplot(res, aes(n_pages, fsize, group = n_points, color = factor(n_points) )) + geom_line() +  geom_point() + facet_wrap(~dpi)

ggplot(res, aes(n_pages, elapsed, group = n_points, color = factor(n_points) )) + geom_line() + geom_point() + facet_wrap(~dpi)

summary(lm(elapsed ~ n_pages + n_points + dpi, res)) #time mostly depends on number of pages, 1 sec per page
summary(lm(fsize   ~ n_pages + n_points + dpi, res)) #file size depend on number of pages and number of points