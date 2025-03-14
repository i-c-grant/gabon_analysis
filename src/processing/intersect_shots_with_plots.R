library(sf)
library(tidyverse)

# Read the input files
shots <- st_read("data/combined_gabon_site_output.gpkg", quiet = TRUE)
plots <- st_read("data/boundaries/plots/plots.gpkg", quiet = TRUE)

shots_in_plots <- st_join(plots, shots, join = st_intersects, left = FALSE)

# Create CSV with all shots in plots (without geometry)
shots_df <- st_drop_geometry(shots_in_plots)

shots_df <- 
  shots_df %>%
  select(areacode, studysite, shot_number, beam, time, l4_agbd, l4_agbd_se, biwf, hse, k_allom) %>%
  as_tibble()

write.csv(shots_df, "data/shots_in_plots.csv", row.names = FALSE)

# Calculate average BIWF per plot
plot_averages <- shots_df %>%
  group_by(areacode) %>%
  summarise(
    mean_biwf = mean(biwf, na.rm = TRUE),
    mean_l4_agbd = mean(l4_agbd, na.rm = TRUE),
    n_shots = n()
  )
write.csv(plot_averages, "data/plot_average_biwf.csv", row.names = FALSE)
