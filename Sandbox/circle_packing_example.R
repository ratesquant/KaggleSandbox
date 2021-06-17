library(packcircles)
library(ggplot2)
library(data.table)
library(scales)
library(wesanderson)
library(gganimate)
library(foreach)

working_folder = 'D:/Github/KaggleSandbox'
source(file.path(working_folder, 'Utils/common.R'))

#% Code --------------
frames = 9

df_frames = data.table(a_frac = 10*c(1:frames))

# Create data
df <- data.table(group=c(rep('A',50), rep('B', 50)), value = rep(1,100)) 
df = df[sample.int(nrow(df), nrow(df))]

df_plot = foreach(i = 1:nrow(df_frames),  .combine = rbind) %do% {
  df[group == 'B', value := df_frames$a_frac[i]/50]
  df[group == 'A', value := (100 - df_frames$a_frac[i])/50]
  # Generate the layout. This function return a dataframe with one line per bubble. 
  # It gives its center (x and y) and its radius, proportional of the value
  packing <- circleProgressiveLayout(df$value, sizetype='area')
  packing$radius <- 0.98*packing$radius
  
  # We can add these packing information to the initial data frame
  df <- cbind(df, packing)
  df[, id := seq(nrow(df))]
  
  # Check that radius is proportional to value. We don't want a linear relationship, since it is the AREA that must be proportionnal to the value
  # plot(data$radius, data$value)
  
  # The next step is to go from one center + a radius to the coordinates of a circle that
  # is drawn by a multitude of straight lines.
  dat.gg <- data.table( circleLayoutVertices(packing, npoints=100))
  dat.gg[df, group := i.group, on =.(id)]
  dat.gg[, t := df_frames$a_frac[i]]
  dat.gg
}

# Make the plot
ggplot() + 
  geom_polygon(data = df_plot, aes(x, y, group = id, fill = group), colour = "black", alpha = 1.0) +
  # Add text in the center of each bubble + control its size
  scale_size_continuous(range = c(1,4)) +
  theme_void() +
  scale_fill_manual(values = c('A'= "#d61042", 'B' = "#00AEDE")) + 
  #scale_fill_manual(values = wes_palette("Zissou1")[c(1, 4)]) +
  #scale_fill_manual(values = wes_palette("Darjeeling1")[c(4, 2)]) +
  #scale_fill_manual(values = wes_palette("FantasticFox1")[c(4, 5)]) +
  #scale_fill_manual(values = wes_palette("Royal1")[c(1, 2)]) +
  #scale_fill_custom() +
  theme(legend.position="none") +
  coord_equal()  + transition_states(t,  transition_length = 2, state_length = 2) + 
  labs(title = 'Red %: {closest_state}' ) +  enter_fade() + exit_fade() 

anim_save('D:/Github/relevant_anim7.gif', animation = last_animation())
