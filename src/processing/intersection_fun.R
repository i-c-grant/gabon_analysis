library(tidyverse)
library(sf)

join_model_to_plots <- function(model_path, plot_path, join_type = "within", distance_m = NULL) {
  # Input validation
  if (join_type == "distance" && is.null(distance_m)) {
    stop("When join_type is 'distance', distance_m must be specified")
  }
  
  # Read input data
  plots <- st_read(plot_path) %>%
    st_transform(5223)  # Transform plots to EPSG:5223
    
  model_output <- st_read(model_path) %>%
    st_transform(5223)  # Transform model output to EPSG:5223
  
  # Perform spatial join based on join_type
  joined_data <- if (join_type == "within") {
    st_join(
      model_output,
      plots,
      join = st_within,
      left = FALSE
    )
  } else if (join_type == "distance") {
    st_join(
      model_output,
      plots,
      join = st_is_within_distance,
      dist = distance_m,
      left = FALSE
    )
  }
  
  # Process results
  joined_data <- joined_data %>%
    st_as_sf() %>%
    st_transform(st_crs(st_read(model_path)))  # Transform back to original CRS
    
  return(joined_data)
}
