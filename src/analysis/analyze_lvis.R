library(sf)
library(tidyverse)

# Define file paths
lvis_files <- c(
  lope = "/home/ian/projects/gabon/data/lvis/gpkgs/lope.gpkg",
  mabounie = "/home/ian/projects/gabon/data/lvis/gpkgs/mabounie.gpkg", 
  mondah = "/home/ian/projects/gabon/data/lvis/gpkgs/mondah.gpkg",
  rabi = "/home/ian/projects/gabon/data/lvis/gpkgs/rabi.gpkg"
)

gedi_file <- "/home/ian/projects/gabon/data/gabon_agbd_results.gpkg"

# Read all LVIS data, keeping sites separate
lvis_data <- map(lvis_files, st_read)

# Read GEDI data
gedi_data <- st_read(gedi_file)

map(lvis_data, \(df) st_crs(df))

## Mondah CRS: 32632
## CRS for all others: 32732

## Transform GEDI data to match the two CRSs
gedi_data_mondah <- st_transform(gedi_data, 32632)
gedi_data_lope <- st_transform(gedi_data, 32732)
gedi_data_mabounie <- gedi_data_lope
gedi_data_rabi <- gedi_data_lope

## Define a function to find GEDI shots within 50 m of an LVIS shot
crop_to_lvis_bbox <- function(lvis, gedi) {
  # Get bounding box of LVIS data
  lvis_bbox <- st_bbox(lvis)
  
  # Filter GEDI shots to those within the LVIS bounding box
  gedi_filtered <- st_crop(gedi, lvis_bbox)

  # Return the GEDI shots
  return(gedi_filtered)
}



## Find GEDI shots near each LVIS shot
gedi_near_lope <- find_gedi_shots(lvis_data$lope, gedi_data_lope)
gedi_near_maobunie <- find_gedi_shots(lvis_data$mabounie, gedi_data_mabounie)
gedi_near_mondah <- find_gedi_shots(lvis_data$mondah, gedi_data_mondah)
gedi_near_rabi <- find_gedi_shots(lvis_data$rabi, gedi_data_rabi)
