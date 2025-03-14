library(sf)
library(tidyverse)

csv_paths <- list.files("/home/ian/projects/gabon/data/lvis/biomass", full.names = TRUE)

names(csv_paths) <- map_chr(csv_paths, function(path) {
  # Get base filename without path
  base_name <- basename(path)
  # Remove file extension
  no_ext <- tools::file_path_sans_ext(base_name)
  # Split by underscore and get 3rd element
  parts <- str_split(no_ext, "_")[[1]]
  parts[3]
})

site_dfs <- map(csv_paths, read_csv)

## Mondah CRS: 32632
## Others: 32732

# Convert each dataframe to sf object with correct CRS
site_sf <- map2(site_dfs, names(site_dfs), function(df, site) {
  # Assign CRS based on site name
  crs <- ifelse(site == "mondah", 32632, 32732)
  
  # Create sf object from UTM coordinates
  st_as_sf(df, 
           coords = c("UTMX", "UTMY"), 
           crs = crs)  # Use the CRS we determined above
})


# Create output directory next to biomass dir
output_dir <- file.path("/home/ian/projects/gabon/data/lvis/gpkgs")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Write each sf object to GeoPackage
walk2(site_sf, names(site_sf), function(sf_obj, site_name) {
  output_path <- file.path(output_dir, paste0(site_name, ".gpkg"))
  st_write(sf_obj, output_path, layer = site_name, delete_layer = TRUE)
})
