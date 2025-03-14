library(sf)
library(tidyverse)
library(terra)

# Load wood density raster and convert to EPSG:4326
wd_raster <- rast("data/wood_density/wd-to-share/yang/wd_avg_1km_xgboost.tif") %>%
  project("EPSG:4326")

# Load GEDI shots and convert to SpatVector
gedi_shots <- st_read("results/gabon_finetuned_2-14/lope_finetuned_2-14.gpkg")
gedi_vect <- vect(gedi_shots)

# Load Gabon boundary and calculate mean wood density
gabon_boundary <- st_read("data/boundaries/gabon_boundary.gpkg")
gabon_vect <- vect(gabon_boundary)

# Calculate mean wood density for entire country
mean_wd <- global(
  mask(wd_raster, gabon_vect), 
  mean, 
  na.rm = TRUE
)[1,1]

# Extract wood density values at GEDI shot locations
wd_values <- extract(wd_raster, gedi_vect)
gedi_shots$wd <- wd_values[,2]

gedi_shots <- 
  gedi_shots %>%
  mutate(wd = ifelse(wd == 0, mean_wd, wd))

# Calculate AGBD using the model: 6.76 * (biwf * wd) + 25.57
gedi_shots <- gedi_shots %>%
  mutate(est_agbd = 6.76 * (biwf * wd) + 25.57)

# Save results
st_write(gedi_shots, "results/gabon_finetuned_2-14/gabon_finetuned_2_14_with_agb_est.gpkg", append = FALSE)

# Create comparison histograms
library(ggplot2)
library(cowplot)

# Create single overlaid histogram
combined_hist <- 
  gedi_shots %>%
  ## filter(num_modes > 1) %>%
  ggplot() +
  geom_histogram(aes(x = est_agbd, fill = "BIWF AGBD"), 
                 bins = 100, alpha = 0.5, position = "identity") +
  geom_histogram(aes(x = l4_agbd, fill = "L4 AGBD"), 
                 bins = 100, alpha = 0.5, position = "identity") +
  scale_fill_manual(values = c("BIWF AGBD" = "steelblue", 
                              "L4 AGBD" = "darkorange")) +
  labs(title = NULL,
       x = "AGBD (Mg/ha)", 
       y = "Count",
       fill = NULL) +
  xlim(c(0, 1000)) +
  theme_classic() +
  theme(legend.position = c(0.45, 0.65),  # Position legend inside plot
        legend.background = element_rect(fill = "white", color = "black"),
        axis.text = element_text(size = 12),  # Increase axis text size
        axis.title = element_text(size = 14)) # Increase axis title size

# Save plot
final_plot <- combined_hist

# Save plot
ggsave("agbd_comparison_histograms_n_modes_gt_1.png", final_plot, width = 10, height = 5)
