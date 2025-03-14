library(DBI)
library(RPostgres)
library(tidyverse)
library(ggplot2)
library(cowplot)

con <- dbConnect(RPostgres::Postgres(),
                 host = "127.0.0.1",
                 port = 5432,
                 dbname = "nmbim_results",
                 user = "ian",
                 password = "grant")

tables <- c("lvis_gedi_stats_lope_with_rh",
            "lvis_gedi_stats_mondah_with_rh",
            "lvis_gedi_stats_rabi_with_rh",
            "lvis_gedi_stats_mabounie_with_rh")

## Extract site names from table names
site_names <- str_extract(tables, "(?<=lvis_gedi_stats_).*(?=_with_rh)") %>%
  str_to_title()

## Read in tables and combine into a single dataframe
df_combined <- map2_dfr(tables, site_names, function(table_name, site_name) {
  dbReadTable(con, table_name) %>%
    tibble() %>%
    mutate(
      site = site_name,
      year = year(time),
      beam_type = ifelse(str_starts(beam, "BEAM00"), "coverage", "power")
    )
})

## Helper function to format y-axis labels
format_y_label <- function(y_col) {
  y_lab <- y_col %>%
    gsub("lvis_", "LVIS ", .) %>%
    gsub("_", " ", .) %>%
    gsub("rh100", "RH100", .)
  
  # Add units (m) if not already present
  if (!grepl("\\(m\\)$", y_lab)) {
    y_lab <- paste0(y_lab, " (m)")
  }
  
  return(y_lab)
}

## Create base theme for all plots
plot_theme <- theme_bw() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    strip.background = element_rect(fill = "lightgrey"),
    strip.text = element_text(face = "bold", size = 14),
    axis.title = element_text(size = 12),
    legend.position = "none"
  )

# Create plots by site (no facets)
median_by_site <- ggplot(df_combined, aes(x = rh_100, y = lvis_median_rh100)) +
  geom_point(size = 0.075, alpha = 0.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_wrap(~ site, ncol = 2) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_median_rh100"),
    title = "GEDI RH100 vs LVIS Median RH100 by Site"
  ) +
  plot_theme

max_by_site <- ggplot(df_combined, aes(x = rh_100, y = lvis_max_rh100)) +
  geom_point(size = 0.075, alpha = 0.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_wrap(~ site, ncol = 2) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_max_rh100"),
    title = "GEDI RH100 vs LVIS Max RH100 by Site"
  ) +
  plot_theme

# Create plots by site and year
median_by_year <- ggplot(df_combined, aes(x = rh_100, y = lvis_median_rh100)) +
  geom_point(size = 0.075, alpha = 0.3) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_grid(year ~ site) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_median_rh100"),
    title = "GEDI RH100 vs LVIS Median RH100 by Year and Site"
  ) +
  plot_theme

max_by_year <- ggplot(df_combined, aes(x = rh_100, y = lvis_max_rh100)) +
  geom_point(size = 0.075, alpha = 0.3) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_grid(year ~ site) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_max_rh100"),
    title = "GEDI RH100 vs LVIS Max RH100 by Year and Site"
  ) +
  plot_theme

# Create plots by site and beam type
median_by_beam <- ggplot(df_combined, aes(x = rh_100, y = lvis_median_rh100)) +
  geom_point(size = 0.075, alpha = 0.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_grid(beam_type ~ site, labeller = labeller(beam_type = str_to_title)) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_median_rh100"),
    title = "GEDI RH100 vs LVIS Median RH100 by Beam Type and Site"
  ) +
  plot_theme

max_by_beam <- ggplot(df_combined, aes(x = rh_100, y = lvis_max_rh100)) +
  geom_point(size = 0.075, alpha = 0.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  facet_grid(beam_type ~ site, labeller = labeller(beam_type = str_to_title)) +
  coord_equal() +
  labs(
    x = "GEDI RH100 (m)",
    y = format_y_label("lvis_max_rh100"),
    title = "GEDI RH100 vs LVIS Max RH100 by Beam Type and Site"
  ) +
  plot_theme

# Function to save all plots to an output directory
save_plot_grids <- function(output_dir) {
  # Create directory if it doesn't exist
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Save all six plots
  ggsave(file.path(output_dir, "median_rh100_by_site.png"), 
         plot = median_by_site,
         width = 10, height = 8, dpi = 300)
  
  ggsave(file.path(output_dir, "max_rh100_by_site.png"), 
         plot = max_by_site,
         width = 10, height = 8, dpi = 300)
  
  ggsave(file.path(output_dir, "median_rh100_by_year.png"), 
         plot = median_by_year,
         width = 12, height = 10, dpi = 300)
  
  ggsave(file.path(output_dir, "median_rh100_by_beam_type.png"), 
         plot = median_by_beam,
         width = 10, height = 8, dpi = 300)
  
  ggsave(file.path(output_dir, "max_rh100_by_year.png"), 
         plot = max_by_year,
         width = 12, height = 10, dpi = 300)
  
  ggsave(file.path(output_dir, "max_rh100_by_beam_type.png"), 
         plot = max_by_beam,
         width = 10, height = 8, dpi = 300)
  
  cat("All 6 plots saved to", output_dir, "\n")
}

save_plot_grids("/home/ian/projects/gabon/figures/rh_comparison")

# Display plots
print(median_by_site)
print(max_by_site)
print(median_by_year)
print(median_by_beam)
print(max_by_year)
print(max_by_beam)

# Example usage:
# save_plot_grids("results/plots")
