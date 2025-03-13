# Load utilities and required packages
source("src/ar_ig_lvis_comparison/compare_utils.R")
suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(hdf5r)
})

calculate_file_histogram <- function(h5_path, gpkg_path, breaks) {
  # Read and join data for single file
  h5_data <- read_h5_file(h5_path)
  gpkg_data <- read_gpkg_file(gpkg_path)
  joined <- join_data(h5_data, gpkg_data)
  
  # Calculate histograms for both BIWF versions
  hist_ig <- hist(joined$biwf_ig[joined$biwf_ig <= 250], breaks = breaks, plot = FALSE)
  hist_ar <- hist(joined$biwf_ar[joined$biwf_ar <= 250], breaks = breaks, plot = FALSE)
  
  list(ig_counts = hist_ig$counts, ar_counts = hist_ar$counts)
}

main <- function(h5_dir, gpkg_dir, output_path) {
  # Create consistent bin breaks for all files
  breaks <- seq(0, 250, length.out = 51)
  
  # Get matched files (reuse from existing function)
  matched <- get_matched_files(h5_dir, gpkg_dir)
  
  # Initialize empty counts
  total_ig <- numeric(50)
  total_ar <- numeric(50)
  
  # Accumulate histogram counts
  matched %>% 
    pwalk(function(h5_path, gpkg_path, h5_key) {
      message("Processing: ", h5_key)
      counts <- calculate_file_histogram(h5_path, gpkg_path, breaks)
      total_ig <<- total_ig + counts$ig_counts
      total_ar <<- total_ar + counts$ar_counts
    })
  
  # Create plotting dataframe
  hist_df <- tibble(
    mid = breaks[-1] - diff(breaks)/2, # Use bin midpoints
    IG = total_ig,
    AR = total_ar
  ) %>% 
    pivot_longer(-mid, names_to = "source", values_to = "count")
  
  # Create plot
  p <- ggplot(hist_df, aes(x = mid, y = count, color = source)) +
    geom_line(linewidth = 0.8) +
    geom_abline(slope = 0, intercept = 0, color = "gray50") +
    scale_color_manual(values = c(IG = "#1b9e77", AR = "#7570b3")) +
    labs(
      x = "BIWF Value (≤250)",
      y = "Total Shot Count",
      title = "Aggregated BIWF Distribution Comparison",
      color = "Data Source"
    ) +
    theme_classic() +
    theme(legend.position = c(0.8, 0.8))
  
  # Save outputs
  dir.create(dirname(output_path), showWarnings = FALSE)
  ggsave(output_path, p, width = 8, height = 6, dpi = 300)
  write_csv(hist_df, sub("\\.png$", "_data.csv", output_path))
  
  message("Saved histogram to: ", output_path)
}

# Command line handling
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("
Usage: Rscript compare_ig_vs_ar_histogram.R \\
  <ig_gpkg_dir> <ar_h5_dir> <output.png>
  ")
}

main(
  gpkg_dir = args[1],
  h5_dir = args[2],
  output_path = args[3]
)
