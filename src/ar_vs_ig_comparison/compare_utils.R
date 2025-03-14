suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(hdf5r)
  library(purrr)
})

get_matched_files <- function(h5_dir, gpkg_dir) {
  # Get file lists
  h5_files <- list.files(h5_dir,
                         pattern = "\\.h5$",
                         full.names = TRUE,
                         recursive = TRUE)
  
  gpkg_files <- list.files(gpkg_dir,
                           pattern = "\\.gpkg$",
                           full.names = TRUE,
                           recursive = TRUE)
  
  # Extract second-to-last element for H5 files
  h5_keys <- h5_files %>% 
    map_chr(~ {
      base_name <- tools::file_path_sans_ext(basename(.x))
      parts <- str_split(base_name, "_")[[1]]
      if(length(parts) < 2) {
        warning("Invalid H5 filename format: ", base_name)
        return(NA_character_)
      }
      parts[length(parts) - 1]  # Second-to-last element
    })
  
  # Extract last element for GPKG files
  gpkg_keys <- gpkg_files %>% 
    map_chr(~ {
      base_name <- tools::file_path_sans_ext(basename(.x))
      parts <- str_split(base_name, "_")[[1]]
      parts[length(parts)]  # Last element
    })
  
  # Create matched pairs with validity checks
  matched <- tibble(h5_path = h5_files, h5_key = h5_keys) %>% 
    inner_join(tibble(gpkg_path = gpkg_files, gpkg_key = gpkg_keys),
               by = c("h5_key" = "gpkg_key")) %>% 
    filter(!is.na(h5_key))  # Remove invalid H5 files
  
  # Check for multiple H5 matches per GPKG
  multi_matches <- matched %>% 
    group_by(gpkg_path) %>% 
    filter(n() > 1) %>% 
    ungroup()
  
  if(nrow(multi_matches) > 0) {
    warning("Multiple H5 files match GPKG files:\n",
            paste("-", multi_matches$h5_path, collapse = "\n"))
  }
  
  # Check for unmatched GPKG files
  unmatched_gpkg <- setdiff(gpkg_keys, h5_keys)
  if(length(unmatched_gpkg) > 0) {
    warning("No H5 matches found for GPKG keys:\n",
            paste(unmatched_gpkg, collapse = ", "))
  }
  
  # Add status message
  message("[Status] Found ", nrow(matched), " matching file pairs")
  if(length(unmatched_gpkg) > 0) {
    message("[Warning] ", length(unmatched_gpkg), 
            " GPKG files had no H5 matches")
  }
  
  matched %>% 
    select(h5_path, gpkg_path, h5_key)
}

read_h5_file <- function(path) {
  h5f <- H5File$new(path, mode = "r")
  
  # Get all datasets using hdf5r's listing functionality
  obj_info <- h5f$ls(recursive = FALSE)
  
  # Filter to only datasets (not groups)
  datasets <- obj_info %>%
    filter(obj_type == "H5I_DATASET") %>%
    pull(name)
  
  # Handle case with no datasets
  if(length(datasets) == 0) {
    warning("No datasets found in: ", path)
    return(tibble())
  }
  
  tbl <- map_dfc(datasets, ~ {
    ds <- h5f[[.x]]
    data <- ds$read()
    
    # Convert arrays/matrices to vectors
    if(is(data, "array") || is.data.frame(data) || is.matrix(data)) {
      data <- as.numeric(data)
    }
    
    tibble(!!.x := data)
  })
  
  h5f$close_all()

  # Clean column names
  tbl %>%
    rename_with(tolower) %>%
    rename(shot_number = shotnumber)
}

read_gpkg_file <- function(path) {
  # Simple GPKG read with geometry preservation
  st_read(path, quiet = TRUE) %>% 
    as_tibble()
}

join_data <- function(h5_data, gpkg_data) {
  # Rename BIWF columns and perform join
  h5_clean <- h5_data %>%
    select(shot_number, biwf_ar = biwf)
  
  gpkg_clean <- gpkg_data %>%
    rename(biwf_ig = biwf)
  
  # Left join to preserve all spatial features from GPKG
  joined <- gpkg_clean %>%
    left_join(h5_clean, by = "shot_number")
  
  # Select final columns (keeping geometry)
  joined %>%
    select(shot_number, biwf_ig, biwf_ar, hse, rh_100, geom) %>%
    st_as_sf
}
