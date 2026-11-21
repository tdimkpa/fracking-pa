# Step 1: Load our packages:
library(tidycensus)
library(tidyverse)
library(sf)
library(RColorBrewer)
library(classInt)
library(ggspatial)
library(sfhotspot)
library(patchwork)
library(osrm)

# Step 2: Set working directory 


# Step 3: Read-in data 

# fracking wells .shp
fracking <- st_read("fracking_wells.shp")

class(fracking)
head(fracking)
st_crs(fracking)
ggplot() +
  geom_sf(data = fracking) 
#Features in fracking_wells: 23379 features and 3 fields
#Name and ESPG code:Projected CRS: NAD83(NSRS2007) / Pennsylvania North (ftUS)/ EPSG: 3650
#CRS metric unit: ftUS

# PA counties .shp
pa_county <- st_read("PA_county.shp")

class(pa_county)
head(pa_county)
st_crs(pa_county)
ggplot() +
  geom_sf(data = pa_county)
#Features in pa_county: 67 features and 7 fields
#Name and ESPG code:Projected CRS: NAD83(NSRS2007) / Pennsylvania North (ftUS)/ EPSG: 3650
#CRS metric unit: ftUS

#Question 2: Create KDE for fracking_wells
# Add a reference map with {ggspatial}
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) + # adds a reference map
  geom_sf(data = fracking,
          fill = NA,
          color = "darkred",
          linewidth = .5,
          linetype = 2) + 
  geom_sf(data = pa_county,
          size = 1,
          alpha = .5)

#### Kernel Density Maps with {sfhotspot} ----
fracking |> 
  hotspot_kde(cell_size = 20000,
              grid_type = "hex",
              bandwidth_adjust = 1.5) |>
  st_intersection(pa_county) -> kde

summary(kde)
hist(kde$kde)

# Add our color palette and breaks 
display.brewer.all(type = "div")

# Natural breaks (Jenks)
jenks_breaks <- classIntervals(kde$kde, n = 5, style = "jenks")$brks

# Map it
# Final KDE Map with Fracking Wells and Base Map
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +  # Light basemap
  geom_sf(data = fracking,
          fill = NA,
          color = "darkred",
          linewidth = 0.5,
          linetype = 3) +  # Outline of fracking sites
  geom_sf(data = kde,
          aes(fill = kde),
          col = "white",
          alpha = 0.7) +  # KDE heatmap layer
  scale_fill_fermenter(type = "div",
                       palette = "Spectral",
                       breaks = jenks_breaks,
                       labels = c("0", "3.3", "8.1", "13.7", "19.5", "28"),
                       guide = guide_colorbar(barwidth = 1.5,  # Wider for clarity
                                              barheight = 8)) +  # Taller legend

  theme_void() +
  labs(title = "Kernel Density of Fracking Wells in PA Counties",
       subtitle = "Kernel Density Estimates",
       caption = "Tobechi Dimkpa\nSource: Fractracker.org\nDate: March 2nd, 2025",
       fill = "Density") + 
  theme(
    plot.title = element_text(size = 13, family = "Avenir", hjust = 0.5),
    plot.subtitle = element_text(size = 11, family = "Avenir", face = "italic", hjust = 0.5),
    legend.position = c(0.9, 0.4),  
    plot.caption = element_text(colour = "grey20", size = 9, vjust = 2, hjust = 0)  # Move author name left
  ) +
  
  annotation_north_arrow(location = "br",
                         height = unit(.8, "cm"),
                         width = unit(.6, "cm"),
                         pad_x = unit(0.1, "in"), 
                         pad_y = unit(0.15, "in"),
                         style = north_arrow_minimal) +
  annotation_scale(location = "br",
                   style = "ticks",
                   pad_x = unit(0.4, "in"),
                   pad_y = unit(.2, "in"),
                   unit_category = "imperial",
                   width_hint = .15) 


# Export and submit as part of midterm
ggsave(plot = last_plot(),
       filename = "kde_fracking.jpg",
       width = 6,
       height = 5)

#Hotspot analysis using Getis-ord GI
fracking |> 
  hotspot_gistar(cell_size = 20000,
                 grid_type = "hex") -> hotspot


# filter out non-significant gi* values 
fracking |> 
  hotspot_gistar(cell_size = 20000,
                 grid_type = "hex") |> 
  filter(gistar > 0 & pvalue < 0.05)  -> hotspot


# Base-map 
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = hotspot,
          fill = "red",
          col = "blue",
          alpha = .7) +
  geom_sf(data = pa_county,
          fill = NA,
          color = "darkred",
          linewidth = .5,
          linetype = 2) +
  theme_void() 

# filter out non-significant gi* values 
fracking |> 
  hotspot_gistar(cell_size = 20000,
                 grid_type = "hex") |> 
  filter(gistar > 0 & pvalue < 0.05) |> 
  st_union() -> hotspot


# Base-map 
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = hotspot,
          fill = "red",
          col = "blue",
          alpha = .7) +
  geom_sf(data = pa_county,
          fill = NA,
          color = "darkred",
          linewidth = .5,
          linetype = 2) +
  theme_void() 

# Map it 
ggplot() +
  annotation_map_tile(type = "cartolight", zoomin = 0) +
  geom_sf(data = hotspot,
          fill = "red",
          col = "white",
          alpha = .7) +
  geom_sf(data = pa_county,
          fill = NA,
          color = "darkred",
          linewidth = .8,
          linetype = 2) +
  theme_void() +
  labs(title = "Fracking Well Hot Spots in PA Counties",
       subtitle = "Statistically Significant Clusters ",
       caption = "Tobechi Dimkpa \nSources: Fractracker.org \nDate: March 2,2025") +
  theme(plot.title = element_text(size = 13,
                                  family  = "Avenir"),
        plot.subtitle = element_text(size = 11,
                                     family  = "Avenir",
                                     face = "italic"),
        legend.position = "none",
        plot.caption = element_text(colour = "grey20",
                                    size = 8,
                                    vjust = 1)) + 
  # Move North Arrow to TOP-LEFT
  annotation_north_arrow(
    location = "tr",  
    height = unit(1.2, "cm"),  # Slightly larger
    width = unit(1, "cm"), 
    pad_x = unit(0.5, "in"),  
    pad_y = unit(0.5, "in"),
    style = north_arrow_fancy_orienteering
  ) +
  
  # Move Scale Bar to BOTTOM-CENTER
  annotation_scale(
    location = "tr",
    style = "ticks",
    pad_x = unit(0, "in"),  # Centered horizontally
    pad_y = unit(0.3, "in"),  # Moves up slightly
    unit_category = "imperial",
    width_hint = 0.2  # Makes it smaller for a cleaner look
  )

##Section 4: Social Vulnerability
# READ DATA
pa_vulnerability <- read_csv("PA_vulnerability.csv")
st_write(pa_vulnerability, "pa_vulnerability.shp")

# Ensure data is in the same projection (CRS)
pa_county <- st_transform(pa_county, crs = st_crs(pa_county))

# Merge vulnerability data with county shapefile
pa_vulnerability <- pa_county %>%
  left_join(pa_vulnerability, by = c("NAME" = "COUNTY" ))
class(pa_vulnerability)


# Choropleth map 
ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = SES), # fill color based on `ses`
          color = "black",
          linewidth = 0.2) +
  theme_void()


# Explore color scales
display.brewer.all(type = "seq")

# Adding a color palette with `scale_fill_fermenter()`
ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = SES),
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Blues") +
  theme_void()


# Data classification 
breaks <- classIntervals(pa_vulnerability$SES, n = 4, style = "quantile")$brks
print(breaks)

# Add quantile breaks 
ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = SES),,
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Blues",
                       guide = "legend",  # you can also use "colorbar"
                       breaks = breaks) +  # breaks the distribution as specified above
  guides(fill = guide_legend(reverse = TRUE)) +  # Reverse legend order
  theme_void()
# Scale bar and north arrow 
ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = SES),,
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Blues",
                       guide = "legend",
                       breaks = breaks) +  
  guides(fill = guide_legend(reverse = TRUE)) + 
  theme_void() +
  labs(title = "Socioeconomic Status")+  # add our title, subtitles, and source 
  annotation_scale(pad_x = unit(0.4, "in"), # adjust x position
                   pad_y = unit(0.1, "in")) + # adjust y position  
  annotation_north_arrow(location = "bl", which_north = "true", # north arrow and adjust size and position 
                         height = unit(.8, "cm"), # adjust size
                         width = unit(1, "cm"),   # adjust size
                         pad_x = unit(0, "in"), # adjust x position
                         pad_y = unit(0, "in"), # adjust y position
                         style = north_arrow_fancy_orienteering) 


# Adjust text and position of text
# Data classification 
breaks <- classIntervals(pa_vulnerability$SES, n = 4, style = "quantile")$brks
print(breaks)
map1 <- ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = SES),
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Blues",
                       guide = "legend",
                       breaks = breaks) +  
  guides(fill = guide_legend(reverse = TRUE)) +   
  theme_void() +
  labs(title = "Socioeconomic Status", fill = "Vulnerability Score") +
  theme(plot.title = element_text(face = "bold", # adjustments to our title 
                                  size = 11,
                                  family  = "sans",
                                  hjust = 0.5),
        plot.title.position = "panel",  # changing title position 
        plot.caption = element_text(colour = "grey50", # adjustments to our caption
                                    size = 6,
                                    vjust = 19)) # adjust legend position 
print(map1)
#Map 2: Household Composition & Disability
# Data classification 
breaks <- classIntervals(pa_vulnerability$household, n = 4, style = "quantile")$brks
print(breaks)
map2 <- ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = household),
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Greens",
                       guide = "legend",
                       breaks = breaks) +  
  guides(fill = guide_legend(reverse = TRUE)) +   
  theme_void() +
  labs(title = "Household Composition & Disability", fill = "Vulnerability Score") +
  theme(plot.title = element_text(face = "bold", # adjustments to our title 
                                  size = 11,
                                  family  = "sans",
                                  hjust = 0.5),
        plot.title.position = "panel",  # changing title position 
        plot.caption = element_text(colour = "grey50", # adjustments to our caption
                                    size = 6,
                                    vjust = 19)) 
print(map2)

#Map 3: Minority Status and Language
# Data classification 
breaks <- classIntervals(pa_vulnerability$minority, n = 4, style = "quantile")$brks
print(breaks)
map3 <- ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = minority),
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Reds",
                       guide = "legend",
                       breaks = breaks) +  
  guides(fill = guide_legend(reverse = TRUE)) +   
  theme_void() +
  labs(title = "Minority Status and Language", fill = "Vulnerability Score") +
  theme(plot.title = element_text(face = "bold", # adjustments to our title 
                                  size = 11,
                                  family  = "sans",
                                  hjust = 0.5),
        plot.title.position = "panel",  # changing title position 
        plot.caption = element_text(colour = "grey50", # adjustments to our caption
                                    size = 6,
                                    vjust = 19)) 
print(map3)

#Map 4: Housing Type and Transportation
# Data classification 
breaks <- classIntervals(pa_vulnerability$housing, n = 4, style = "quantile")$brks
print(breaks)
map4 <- ggplot() +
  geom_sf(data = pa_vulnerability,
          aes(fill = housing),
          color = "black",
          linewidth = 0.2) +
  scale_fill_fermenter(direction = 1,
                       palette = "Purples",
                       guide = "legend",
                       breaks = breaks) +  
  guides(fill = guide_legend(reverse = TRUE)) +   
  theme_void() +
  labs(title = "Housing Type and Transportation", fill = "Vulnerability Score") +
  theme(plot.title = element_text(face = "bold", # adjustments to our title 
                                  size = 11,
                                  family  = "sans",
                                  hjust = 0.5),
        plot.title.position = "panel",  # changing title position 
        plot.caption = element_text(colour = "grey50", # adjustments to our caption
                                    size = 6,
                                    vjust = 19)) 
print(map4)

map1 + map2 + map3+ map4 -> combined_plot

combined_plot +
  plot_annotation(title = "Spatial Vulnerability across Socioeconomic Status, Household Composition & Disability, 
                  Minority Status & Language, and Housing Type & Transportation ",
                  subtitle = "  in Pennsylvania 2020",  
                  theme = theme(
                    plot.title = element_text(family = "Arial", 
                                              size = 13,  # Increase size to emphasize boldness
                                              face = "bold",  # ✅ Makes title bold
                                              hjust = 0.5),  # ✅ Centers the title
                    plot.subtitle = element_text(family = "Arial", 
                                                 size = 11,  
                                                 face = "bold",  # ✅ Makes subtitle bold
                                                 hjust = 0.5)  # ✅ Centers the subtitle
                  )
  )
      