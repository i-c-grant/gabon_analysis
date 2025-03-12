library(tidyverse)
library(sf)
library(rhdf5)
library(purrr)

get_matched_files <- function(h5_dir, gpkg_dir) {
  # Get file lists and extract matching keys
  h5_files <- list.files(h5_dir, pattern = "\\.h5$", full.names = TRUE)
  gpkg_files <- list.files(gpkg_dir, pattern = "\\.gpkg$", full.names = TRUE)
  
  # Extract final 3 elements from H5 filenames
  h5_keys <- h5_files %>% 
    map_chr(~ str_remove(basename(.x), "\\.h5$") %>% 
              str_split("_") %>% 
              pluck(1) %>% 
              tail(3) %>% 
              str_c(collapse = "_"))
  
  # Extract entire filename (without extension) for gpkg files
  gpkg_keys <- gpkg_files %>% 
    map_chr(~ str_remove(basename(.x), "\\.gpkg$"))
  
  # Create matched pairs tibble
  tibble(h5_path = h5_files, h5_key = h5_keys) %>% 
    inner_join(tibble(gpkg_path = gpkg_files, gpkg_key = gpkg_keys),
               by = c("h5_key" = "gpkg_key")) %>% 
    select(h5_path, gpkg_path)
}

read_h5_file <- function(path) {
  # Read all first-level datasets from H5 file
  h5f <- H5Fopen(path)
  datasets <- h5ls(h5f, recursive = FALSE)$name
  
  tbl <- map_dfc(datasets, ~ {
    data <- h5read(h5f, .x)
    # Convert array data to vector if needed
    if (length(dim(data)) > 0) data <- as.vector(data)
    tibble(!!.x := data)
  })
  
  H5Fclose(h5f)
  tbl
}

read_gpkg_file <- function(path) {
  # Simple GPKG read with geometry preservation
  st_read(path, quiet = TRUE) %>% 
    as_tibble()
}

join_data <- function(h5_data, gpkg_data) {
  # Placeholder for join logic
  message("Joining data - implement custom join logic here")
  bind_cols(h5_data, gpkg_data)
}

plot_data <- function(joined_data) {
  # Placeholder for plotting logic
  message("Plotting data - implement custom plotting here")
}

main <- function(h5_dir, gpkg_dir) {
  matched <- get_matched_files(h5_dir, gpkg_dir)
  
  matched %>% 
    pmap(function(h5_path, gpkg_path) {
      h5_data <- read_h5_file(h5_path)
      gpkg_data <- read_gpkg_file(gpkg_path)
      joined <- join_data(h5_data, gpkg_data)
      plot_data(joined)
      joined
    })
}
