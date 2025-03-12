library(tidyverse)
library(sf)
library(hdf5r)  
library(purrr)
library(readr)

ig_dir <- "tests/data/IG"
ar_dir <- "tests/data/AR"

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
  
  matched %>% 
    select(h5_path, gpkg_path, h5_key)  # Add h5_key to output
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

calculate_stats <- function(data) {
  data %>%
    st_drop_geometry() %>%  # Remove spatial data before summarizing
    summarize(
      n = n(),
      mean_ig = mean(biwf_ig, na.rm = TRUE),
      ig_median = median(biwf_ig, na.rm = TRUE),
      ig_min = min(biwf_ig, na.rm = TRUE),
      ig_max = max(biwf_ig, na.rm = TRUE),
      mean_ar = mean(biwf_ar, na.rm = TRUE),
      ar_median = median(biwf_ar, na.rm = TRUE),
      ar_min = min(biwf_ar, na.rm = TRUE),
      ar_max = max(biwf_ar, na.rm = TRUE),
      cor = cor(biwf_ig, biwf_ar, use = "complete.obs"),
      rmse = sqrt(mean((biwf_ig - biwf_ar)^2, na.rm = TRUE)),
      bias = mean(biwf_ar - biwf_ig, na.rm = TRUE)
    ) %>%
    mutate(key = unique(data$key), .before = 1)
}

plot_data <- function(joined_data, key) {
  ggplot(joined_data, aes(x = biwf_ig, y = biwf_ar)) +
    geom_point(alpha = 0.5, size = .1) +  # Smaller points
    geom_abline(slope = 1, intercept = 0, 
                color = "red", linetype = "dashed", linewidth = 0.8) +
    coord_equal(xlim = c(0, 200), ylim = c(0, 200)) +
    labs(
      x = "BIWF IG", 
      y = "BIWF AR",
      title = paste("LVIS Model Comparison, File:", key),
      caption = "Red dashed line = 1:1 relationship"
    ) +
    theme_classic() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      aspect.ratio = 1,
      panel.grid.major = element_line(color = "grey90")
    )
}

main <- function(h5_dir, gpkg_dir, output_dir = "outputs") {
  # Create output directory
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  matched <- get_matched_files(h5_dir, gpkg_dir)
  
  # Process files sequentially
  results <- matched %>% 
    pmap(function(h5_path, gpkg_path, h5_key) {
      # Read and process data
      h5_data <- read_h5_file(h5_path)
      gpkg_data <- read_gpkg_file(gpkg_path)
      joined <- join_data(h5_data, gpkg_data) %>% 
        mutate(key = h5_key, .before = 1)  # Add key column
      
      # Generate outputs
      list(
        plot = plot_data(joined, h5_key),
        stats = calculate_stats(joined)
      )
    })
  
  # Combine statistics and save
  stats_df <- map_dfr(results, "stats")
  write_csv(stats_df, file.path(output_dir, "biwf_comparison_stats.csv"))
  
  # Save plots
  walk2(
    map(results, "plot"), matched$h5_key,
    ~ ggsave(
      file.path(output_dir, paste0(.y, "_comparison.png")),
      plot = .x,
      width = 8, height = 6, dpi = 300
    )
  )
  
  invisible(list(plots = map(results, "plot"), stats = stats_df))
}
