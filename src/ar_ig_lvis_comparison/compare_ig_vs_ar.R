# Load utilities and required packages
source("src/ar_ig_lvis_comparison/compare_utils.R")
suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(hdf5r)
  library(readr)
})


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

main <- function(h5_dir, gpkg_dir, output_dir) {
  message("\n=== Starting LVIS Comparison Analysis ===")
  message("Input directories:")
  message("- IG Geopackages: ", gpkg_dir)
  message("- AR HDF5 Files: ", h5_dir)
  message("- Output Directory: ", output_dir)
  
  # Create output directory
  if(!dir.exists(output_dir)) {
    message("Creating output directory: ", output_dir)
    dir.create(output_dir, recursive = TRUE)
  }
  
  matched <- get_matched_files(h5_dir, gpkg_dir)
  
  message("\nProcessing ", nrow(matched), " file pairs:")
  
  results <- matched %>% 
    pmap(function(h5_path, gpkg_path, h5_key) {
      message("- Processing: ", h5_key)
      
      h5_data <- read_h5_file(h5_path)
      gpkg_data <- read_gpkg_file(gpkg_path)
      joined <- join_data(h5_data, gpkg_data) %>% 
        mutate(key = h5_key, .before = 1)
      
      list(
        plot = plot_data(joined, h5_key),
        stats = calculate_stats(joined)
      )
    })
  
  message("\nSaving results:")
  message("- Writing combined statistics to CSV")
  stats_df <- map_dfr(results, "stats")
  write_csv(stats_df, file.path(output_dir, "biwf_comparison_stats.csv"))
  
  message("- Saving ", length(results), " plot files")
  walk2(
    map(results, "plot"), matched$h5_key,
    ~ {
      fpath <- file.path(output_dir, paste0(.y, "_comparison.png"))
      message("  Saved: ", fpath)
      ggsave(fpath, plot = .x, width = 8, height = 6, dpi = 300)
    }
  )
  
  message("\n=== Analysis Complete ===")
  invisible(list(plots = map(results, "plot"), stats = stats_df))
}

# Add command line argument handling
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("
Usage: Rscript compare_ig_vs_ar.R \\
  <ig_gpkg_dir> <ar_h5_dir> <output_dir>
       
Arguments:
  1. Path to IG geopackage directory
  2. Path to AR HDF5 directory  
  3. Output directory for results
  ")
}

main(
  gpkg_dir = args[1],  # IG geopackages
  h5_dir = args[2],    # AR HDF5 files
  output_dir = args[3]
)
