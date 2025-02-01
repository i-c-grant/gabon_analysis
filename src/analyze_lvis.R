library(sf)
library(tidyverse)

# Read CSV and convert to sf object with UTM coordinates
biomass_data <-
  read_csv("/home/ian/projects/gabon/data/lvis/biomass/biomass_estimates_lope.csv") %>%
  st_as_sf(coords = c("UTMX", "UTMY"), crs = 32733)  # Assuming UTM zone 33S for Gabon

# Write out as GeoPackage
st_write(biomass_data, "/home/ian/projects/gabon/data/lvis/biomass/biomass_estimates_lope.gpkg")
