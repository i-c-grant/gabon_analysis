
# Define paths
plot_path <- "/home/ian/Documents/projects/gabon_analysis/data/boundaries/plots/plots.gpkg"
base_path <- "/home/ian/Documents/projects/gabon_analysis/data/model_output"
model_paths <- c(
  file.path(base_path, "combined_gabon_output_1_15.gpkg"),
  file.path(base_path, "combined_gabon_output_1_35.gpkg"),
  file.path(base_path, "combined_gabon_output_1_68.gpkg")
)

# Example usage:
# For exact containment:
joined_dfs_within <- map(model_paths, ~join_model_to_plots(.x, plot_path, join_type = "within"))
names(joined_dfs_within) <- c("conf_15", "conf_35", "conf_68")

# For points within 100 meters:
joined_dfs_distance <- map(model_paths, ~join_model_to_plots(.x, plot_path, join_type = "distance", distance_m = 100))
names(joined_dfs_distance) <- c("conf_15", "conf_35", "conf_68")
