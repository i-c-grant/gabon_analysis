library(sf)
library(tidyverse)
library(ggplot2)
library(cowplot)

# Define file paths
gedi_avg_files <- c(
  lope = "/home/ian/projects/gabon/data/gedi_avg_agb_lvis/gedi_avg_lvis_agb_lope_25m.gpkg",
  mabounie = "/home/ian/projects/gabon/data/gedi_avg_agb_lvis/gedi_avg_lvis_agb_mabounie_25m.gpkg",
  mondah = "/home/ian/projects/gabon/data/gedi_avg_agb_lvis/gedi_avg_lvis_agb_mondah_25m.gpkg",
  rabi = "/home/ian/projects/gabon/data/gedi_avg_agb_lvis/gedi_avg_lvis_agb_rabi_25m.gpkg"
)

# Load all GEDI average AGB files
gedi_avg_data <- map(gedi_avg_files, st_read)

gedi_avg_data <- map(gedi_avg_data, \(df) df %>% mutate(year = year(time)))

# Create scatterplots comparing est_agbd to avg_lvis_agbd_pred for each site
labels <- labs(y = "LVIS AGBD (Mg/ha)", x = "GEDI AGBD (Mg/ha)")
        
points <- geom_point(size = .01, alpha = .25)
one_to_one_line <- geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed")

p_lope <- gedi_avg_data$lope %>%
  ggplot(aes(x = est_agbd, y = avg_lvis_agb_pred)) +
  points +
  labs(title = "Lope") +
  theme_classic() +
  xlim(c(0, 500)) +
  ylim(c(0, 500)) +
  labels +
  one_to_one_line

p_mabounie <- gedi_avg_data$mabounie %>%
  ggplot(aes(x = est_agbd, y = avg_lvis_agb_pred)) +
  points +
  labs(title = "Mabounie") +
  theme_classic() +
  xlim(c(0, 500)) +
  ylim(c(0, 500)) +
  labels +
  one_to_one_line

p_mondah <- gedi_avg_data$mondah %>%
  ggplot(aes(x = est_agbd, y = avg_lvis_agb_pred)) +
  points +
  labs(title = "Mondah") +
  theme_classic() +
  xlim(c(0, 500)) +
  ylim(c(0, 500)) +
  labels +
  one_to_one_line

p_rabi <- gedi_avg_data$rabi %>%
  ggplot(aes(x = est_agbd, y = avg_lvis_agb_pred)) +
  points +
  labs(title = "Rabi") +
  theme_classic() +
  xlim(c(0, 500)) +
  ylim(c(0, 500)) +
  labels +
  one_to_one_line

## Combine the plots
plot_grid(p_lope, p_mabounie, p_mondah, p_rabi, ncol = 2, nrow = 2)

ggsave("/home/ian/projects/gabon/visualization/gedi_avg_agb_lvis/gedi_avg_agb_lvis_scatterplots.png", width = 6, height = 6, units = "in", dpi = 400)

# Calculate RMSE and R^2 for each site using complete cases only
calculate_metrics <- function(df) {
  complete_cases <- df[complete.cases(df$est_agbd, df$avg_lvis_agb_pred), ]
  rmse <- sqrt(mean((complete_cases$est_agbd - complete_cases$avg_lvis_agb_pred)^2))
  r2 <- cor(complete_cases$est_agbd, complete_cases$avg_lvis_agb_pred)^2
  return(tibble(rmse = rmse, r2 = r2))
}

site_metrics <- map_dfr(gedi_avg_data, calculate_metrics, .id = "site")

# Round all numeric columns to 2 decimal places
site_metrics <- site_metrics %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)))

print(site_metrics)

write_csv(site_metrics, "lvis_gedi_comparison.csv")

# Add metrics to plots
p_lope <- p_lope + 
  annotate("text", x = 400, y = 50, 
           label = paste0("RMSE: ", round(site_metrics$rmse[1], 1), "\nR²: ", round(site_metrics$r2[1], 2)))

p_mabounie <- p_mabounie + 
  annotate("text", x = 400, y = 50, 
           label = paste0("RMSE: ", round(site_metrics$rmse[2], 1), "\nR²: ", round(site_metrics$r2[2], 2)))

p_mondah <- p_mondah + 
  annotate("text", x = 400, y = 50, 
           label = paste0("RMSE: ", round(site_metrics$rmse[3], 1), "\nR²: ", round(site_metrics$r2[3], 2)))

p_rabi <- p_rabi + 
  annotate("text", x = 400, y = 50, 
           label = paste0("RMSE: ", round(site_metrics$rmse[4], 1), "\nR²: ", round(site_metrics$r2[4], 2)))

# Re-save plots with metrics
plot_grid(p_lope, p_mabounie, p_mondah, p_rabi, ncol = 2, nrow = 2)
ggsave("/home/ian/projects/gabon/visualization/gedi_avg_agb_lvis/gedi_avg_agb_lvis_scatterplots.png", 
       width = 6, height = 6, units = "in", dpi = 400)
