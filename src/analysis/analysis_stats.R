library(tidyverse)
library(cowplot)  # For combining plots

# Load statistics data
stats_df <- read_csv("gabon_comparison/biwf_comparison_stats.csv")

# Create output directories
dir.create("stat_plots", showWarnings = FALSE)

# Define comparison pairs with clean labels
comparisons <- list(
  c("mean_ig", "mean_ar", "mean comparison"),
  c("ig_median", "ar_median", "median comparison"),
  c("ig_max", "ar_max", "maximum comparison"),
  c("ig_min", "ar_min", "minimum comparison")
)

# Generate comparison plots
plots <- map(comparisons, ~{
  x_var <- .x[1]
  y_var <- .x[2]
  title <- .x[3]
  
  ggplot(stats_df, aes(x = .data[[x_var]], y = .data[[y_var]])) +
    geom_point(color = "darkblue", alpha = 0.7) +
    geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
    geom_smooth(method = "lm", se = FALSE, color = "darkgreen") +
    labs(title = title,
         x = "IG Values",
         y = "AR Values") +
    coord_fixed(ratio = 1, xlim = c(0, max(stats_df[c(x_var, y_var)])), 
               ylim = c(0, max(stats_df[c(x_var, y_var)]))) +
    theme_bw()
})

# Save individual plots
walk2(plots, comparisons, ~{
  ggsave(file.path("stat_plots", paste0(gsub(" ", "_", .y[3]), ".png")),
         plot = .x, width = 8, height = 6, dpi = 300)
})

# Create and save combined plot
combined_plot <- plot_grid(
  plotlist = plots,
  ncol = 2,
  labels = "AUTO",
  label_size = 12,
  align = "hv",
  axis = "lrtb"
)

title_gg <- ggdraw() + 
  draw_label(
    "BIWF Metric Comparisons Across All Files",
    fontface = "bold",
    size = 14,
    x = 0.5,
    hjust = 0.5
  )

final_plot <- plot_grid(
  title_gg,
  combined_plot,
  ncol = 1,
  rel_heights = c(0.1, 1)
)

ggsave("stat_plots/combined_comparisons.png", final_plot, 
       width = 16, height = 12, dpi = 300)

# Calculate overall means
overall_means <- stats_df %>%
  summarise(across(c(mean_ig, mean_ar, ig_median, ar_median,
                    ig_max, ar_max, ig_min, ar_min, cor, rmse, bias),
            list(mean = mean, sd = sd),
            .groups = "drop"))

# Save overall statistics
write_csv(overall_means, "overall_summary_stats.csv")

# Print summary
message("\nAnalysis complete!")
message("- Saved ", length(plots), " individual comparison plots")
message("- Saved combined comparison plot")
message("- Saved overall summary statistics to overall_summary_stats.csv")
