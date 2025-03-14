library(ggplot2)
library(dplyr)

# Create histogram of AGBD with legend in upper left
p_hist <- 
sf_results %>% 
  ggplot() + 
  geom_histogram(bins = 100, aes(x = est_agbd, fill = beam_type)) + 
  xlim(c(0, 1000)) + 
  theme_classic() + 
  labs(fill = "Beam type", x = "Estimated AGBD (Mg/ha)", y = "Count") +
  theme(
    legend.position = c(0.45, 0.85),  # x,y position (0-1 scale)
    legend.justification = c(0, 1),   # anchor point of legend
    legend.background = element_rect(fill = alpha("white", 0.8))  # semi-transparent background
  )

ggsave("coverage_vs_agbd.png", p_hist, width = 6, height = 4)


