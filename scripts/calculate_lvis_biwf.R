# Load required packages
library(terra)
library(future)
library(future.apply)

# Set up parallel processing (adjust plan as needed)
plan(multisession)

# Read points from the geopackage (make sure it’s in EPSG:4326)
points <- vect("data/lvis_2016_merged.gpkg")

# Compute the study extent from the points
ext_points <- ext(points)

# Define the approximate cell resolution (~50 m in degrees)
tile_resolution <- 0.0005

# Create a template raster covering the full extent
template_raster <- rast(ext_points, resolution = tile_resolution)

# Create tiles that match the template resolution using makeTiles
tile_blocks <- makeTiles(template_raster, template_raster, filename="")
tiles <- lapply(tile_blocks, function(t) list(extent = ext(t)))

# Process each tile in parallel to create raster tiles
tile_rasters <- future_lapply(tiles, function(tile) {
  # Crop points to the tile extent
  pts_tile <- crop(points, tile$extent)
  
  # Create empty raster for this tile
  tile_raster <- crop(template_raster, tile$extent)
  
  if (nrow(pts_tile) == 0) {
    values(tile_raster) <- NA  # Set entire tile to NA if no points
  } else {
    # Rasterize points to calculate mean biwf for each cell
    tile_raster <- rasterize(pts_tile, tile_raster, field = "biwf", fun = mean, na.rm = TRUE)
  }
  return(tile_raster)
})

# Merge all tile rasters into final mosaic
final_raster <- do.call(mosaic, c(tile_rasters, fun = "mean"))

# Write the final stitched raster to disk
writeRaster(final_raster, "path/to/output_raster.tif", overwrite = TRUE)
