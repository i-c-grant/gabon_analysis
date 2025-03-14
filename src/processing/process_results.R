source("src/intersection_fun.R")

# Define paths
plot_path <- "data/boundaries/plots/plots.gpkg"
base_path <- "data/model_output"
model_paths <- c(
  file.path(base_path, "combined_gabon_output_1_15.gpkg"),
  file.path(base_path, "combined_gabon_output_1_35.gpkg"),
  file.path(base_path, "combined_gabon_output_1_68.gpkg")
)

# For exact containment:
joined_dfs_within <- map(model_paths,
                         ~join_model_to_plots(.x,
                                              plot_path,
                                              join_type = "within"))

names(joined_dfs_within) <- c("within_plot_1_15",
                              "within_plot_1_35",
                              "within_plot_1_68")

# Points within 50 meters:
joined_dfs_distance_50m <- map(model_paths, ~join_model_to_plots(.x, plot_path, join_type = "distance", distance_m = 50))

names(joined_dfs_distance_50m) <- c("distance_50m_1_15",
                                    "distance_50m_1_35",
                                    "distance_50m_1_68")

# Points within 100 meters:
joined_dfs_distance_100m <- map(model_paths, ~join_model_to_plots(.x, plot_path, join_type = "distance", distance_m = 100))

names(joined_dfs_distance_100m) <- c("distance_100m_1_15",
                                     "distance_100m_1_35",
                                     "distance_100m_1_68")


## Define function to format dfs for full output
format_result <- function(df) {
    df %>%
        st_drop_geometry() %>%
        select(areacode, shot_number, biwf, l4_agbd, everything()) %>%
        rename(plot_area_code = areacode,
               gedi_shot_number = shot_number)
}

## Define function to aggregate dfs for aggregated output
agg_result <- function(df) {
    df %>%
        st_drop_geometry() %>%
        group_by(areacode) %>%
        summarise(mean_biwf = mean(biwf),
                  mean_l4_agbd = mean(l4_agbd),
                  n_gedi_shots = n())
}

full_dfs <-
    c(joined_dfs_within, joined_dfs_distance_50m, joined_dfs_distance_100m) %>% 
    map(format_result) %>%
    map(as_tibble)

agg_dfs <-
    c(joined_dfs_within, joined_dfs_distance_50m, joined_dfs_distance_100m) %>% 
    map(agg_result) %>%
    map(as_tibble)

# add 'avg biwf' to beginning of names
names(agg_dfs) <- map(names(agg_dfs), ~str_c("avg_biwf_", .x))

## write full dfs to 'results/csv_by_shot'
walk2(full_dfs, names(full_dfs),
     ~write_csv(.x, str_c("results/csv_by_shot/", .y, ".csv")))

## write aggregated dfs to 'results/csv_by_plot'
walk2(agg_dfs, names(agg_dfs),
     ~write_csv(.x, str_c("results/csv_by_plot/", .y, ".csv")))
