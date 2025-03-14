library(sf)
library(ggplot2)
library(lubridate)
library(purrr)

# Function to create scatterplot from a tibble and return plot object
create_scatterplot <- function(data, title) {
  # Create scatterplot
  plot <- ggplot(data, aes(x = est_agbd, y = avg_lvis_agb_pred)) +
    geom_point(size = .01) +
    labs(title = title,
         x = "Estimated AGBD",
         y = "Average LVIS AGB Prediction") +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    coord_cartesian(xlim = c(0, 1000), ylim = c(0, 1000)) + 
    theme_classic() +
    theme(text = element_text(size = 14))

  return(plot)

}

# Function to create histogram from a tibble and return plot object
create_histogram <- function(data, title) {
  plot <- ggplot(data, aes(x = error)) +
    geom_histogram(binwidth = 8, alpha = 0.7) +
    labs(title = paste("Histogram of", title),
         x = "Error (Estimated AGBD - LVIS AGB Prediction)",
         y = "Frequency") +
    xlim(c(-500, 500)) +
    theme_classic() +
    geom_vline(xintercept = 0, color = "red", linetype = "dashed") +
    theme(text = element_text(size = 14))
  
  return(plot)
}

save_plots <- function(plots, output_dir, filenames) {
  for (i in seq_along(plots)) {
    ggsave(filename = file.path(output_dir, filenames[i]), plot = plots[[i]])
  }
}

files <- c("gedi_avg_lvis_agb_lope_25m.gpkg",
           "gedi_avg_lvis_agb_mabounie_25m.gpkg",
           "gedi_avg_lvis_agb_mondah_25m.gpkg",
           "gedi_avg_lvis_agb_rabi_25m.gpkg")

# Read data and create scatterplots for each file, storing in a list
# Read data and create scatterplots for each file, storing in a list
get_beam_type <- function(beam) {
  ifelse(grepl("^BEAM00", beam), "coverage", "power")
}

data_list <- map(files, \(x) {
  data <- st_read(x)
  data <- data %>%
    mutate(year = year(time),
           beam_type = get_beam_type(beam),
           error = est_agbd - avg_lvis_agb_pred)
}
)

# Extract site names from file names for titles
site_names <- tools::toTitleCase(gsub("gedi_avg_lvis_agb_(.*)_25m", "\\1", tools::file_path_sans_ext(basename(files))))
titles <- paste("LVIS vs. GEDI AGBD for", site_names)

plots <- map2(data_list, titles, create_scatterplot)

plots_by_year <- map(plots, function(plot) {
  plot + facet_wrap(~ year, ncol = 1)
})

plots_by_beam_type <- map(plots, function(plot) {
  plot + facet_wrap(~ beam_type, ncol = 1)})

histograms <- map2(data_list, titles, create_histogram)

# Create histograms facetted by year with 1 column
histograms_by_year <- map(histograms,
                          \(h) h + facet_wrap(vars(year), ncol = 1))

# Create histograms facetted by beam type with 1 column
histograms_by_beam_type <- map(histograms, function(plot) {
  plot + facet_wrap(~ beam_type, ncol = 1)
})

# Define output directory and filenames
output_directory <- "/home/ian/projects/gabon/figures/lvis_vs_gedi"

scatterplot_filenames <- paste0(tools::file_path_sans_ext(basename(files)), "_scatterplot.png")
histogram_filenames <- paste0(tools::file_path_sans_ext(basename(files)), "_histogram.png")

# Add filenames for plots facetted by year and beam type
scatterplot_filenames_by_year <- paste0(tools::file_path_sans_ext(basename(files)), "_scatterplot_by_year.png")
scatterplot_filenames_by_beam_type <- paste0(tools::file_path_sans_ext(basename(files)), "_scatterplot_by_beam_type.png")
histogram_filenames_by_year <- paste0(tools::file_path_sans_ext(basename(files)), "_histogram_by_year.png")
histogram_filenames_by_beam_type <- paste0(tools::file_path_sans_ext(basename(files)), "_histogram_by_beam_type.png")

# Define subdirectories for scatterplots and histograms
scatterplot_dir <- file.path(output_directory, "scatterplots")
histogram_dir <- file.path(output_directory, "histograms")

# Save the scatterplots and histograms
save_plots(plots, file.path(scatterplot_dir, "all"), scatterplot_filenames)
save_plots(plots_by_year, file.path(scatterplot_dir, "year"), scatterplot_filenames_by_year)
save_plots(plots_by_beam_type, file.path(scatterplot_dir, "beam_type"), scatterplot_filenames_by_beam_type)

save_plots(histograms, file.path(histogram_dir, "all"), histogram_filenames)
save_plots(histograms_by_year, file.path(histogram_dir, "year"), histogram_filenames_by_year)
save_plots(histograms_by_beam_type, file.path(histogram_dir, "beam_type"), histogram_filenames_by_beam_type)

# Fit a linear model with est_agbd and year as predictors
fit_model_year <- function(data) {
  data$year <- as.factor(data$year)
  model <- lm(avg_lvis_agb_pred ~ est_agbd + year, data = data)
  summary(model)
}

# Fit a linear model with est_agbd and beam_type as predictors
fit_model_beam_type <- function(data) {
  data$beam_type <- as.factor(data$beam_type)
  model <- lm(avg_lvis_agb_pred ~ est_agbd + beam_type, data = data)
  summary(model)
}
