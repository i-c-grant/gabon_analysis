library(sf)
library(ggplot2)
library(tidyverse)

# Calculate counts per year for annotations
year_counts <- gabon %>%
  group_by(year) %>%
  summarize(count = n())

p_gabon_biwf <- ggplot(gabon) + 
  geom_histogram(aes(x = biwf), bins = 100) + 
  facet_wrap(vars(year), ncol = 1) + 
  xlim(c(0, 200)) +
  geom_text(data = year_counts, 
            aes(x = 150, y = Inf, label = paste("n =", count)), 
            vjust = 1.5, hjust = 0.5, size = 3)

p_gabon_l4a <- ggplot(gabon) + 
  geom_histogram(aes(x = l4_agbd), bins = 100) + 
  facet_wrap(vars(year), ncol = 1) + 
  xlim(c(0, 1000)) +
  geom_text(data = year_counts, 
            aes(x = 750, y = Inf, label = paste("n =", count)), 
            vjust = 1.5, hjust = 0.5, size = 3)
