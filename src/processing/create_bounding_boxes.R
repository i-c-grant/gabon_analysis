library(sf)
library(units)
library(purrr)

# List all .gpkg files in the directory
input_dir <- "/home/ian/projects/gabon/data/boundaries/plots/"
gpkg_files <- list.files(input_dir, pattern = "\\.gpkg$", full.names = TRUE)

# Function to create buffered bounding box
create_buffered_bbox <- function(file_path) {
  # Read the input file
  polygons <- st_read(file_path, quiet = TRUE)
  
  # Ensure CRS is 4326
  if (st_crs(polygons) != 4326) {
    polygons <- st_transform(polygons, 4326)
  }

  # Transform to Gabon projection for accurate buffer distance
  polygons_utm <- st_transform(polygons, 5223)
  
  # Get bounding box and buffer
  bbox <- st_as_sfc(st_bbox(polygons_utm))
  bbox_buffered <- st_buffer(bbox, dist = 100)
  
  # Transform back to 4326
  bbox_buffered_4326 <- st_transform(bbox_buffered, 4326)
  
  # Create output filename
  base_name <- tools::file_path_sans_ext(basename(file_path))
  output_file <- file.path(input_dir, paste0(base_name, "_bounding_box.gpkg"))
  
  # Write to file
  st_write(bbox_buffered_4326, output_file, quiet = TRUE, delete_layer = TRUE)
}

# Apply function to all files using walk
walk(gpkg_files, create_buffered_bbox)
