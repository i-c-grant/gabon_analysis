library(sf)
library(ggplot2)
library(tidyverse)
library(scales)
library(cowplot)

# Calculate counts per year for annotations
year_counts <- gabon %>%
  group_by(year) %>%
  summarize(count = n())

p_gabon_biwf <- ggplot(gabon) + 
  geom_histogram(aes(x = biwf), bins = 100) +
  labs(x = "BIWF", y = NULL, title = "BIWF by Year") +
  facet_wrap(vars(year), ncol = 1) +
  scale_y_continuous(labels = scales::scientific) +
  xlim(c(0, 200)) +
  theme(axis.ticks.y = element_blank(), axis.text.y = element_blank()) +
  geom_text(data = year_counts, 
            aes(x = 150, y = Inf, label = paste("n =", comma(count))), 
            vjust = 1.5, hjust = 0.5, size = 3)

p_gabon_l4a <- ggplot(gabon) + 
  geom_histogram(aes(x = l4_agbd), bins = 100) +
  labs(x = "L4A AGBD (Mg/ha)", y = NULL, title = "L4A AGBD by Year") +
  facet_wrap(vars(year), ncol = 1) +
  scale_y_continuous(labels = scales::scientific) +
  xlim(c(0, 750)) +
  theme(axis.ticks.y = element_blank(), axis.text.y = element_blank()) +
  geom_text(data = year_counts, 
            aes(x = 500, y = Inf, label = paste("n =", comma(count))), 
            vjust = 1.5, hjust = 0.5, size = 3)

p_gabon_est_agbd <- ggplot(gabon) + 
  geom_histogram(aes(x = est_agbd), bins = 100) +
  labs(x = "BIWF AGBD (Mg/ha)", y = NULL, title = "Estimated AGBD by Year") +
  facet_wrap(vars(year), ncol = 1) +
  scale_y_continuous(labels = scales::scientific) +
  xlim(c(0, 750)) +
  theme(axis.ticks.y = element_blank(), axis.text.y = element_blank()) +
  geom_text(data = year_counts, 
            aes(x = 500, y = Inf, label = paste("n =", comma(count))), 
            vjust = 1.5, hjust = 0.5, size = 3)

plot_grid(p_gabon_biwf, p_gabon_l4a, p_gabon_est_agbd, nrow = 1)
