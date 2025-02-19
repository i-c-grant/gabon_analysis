library(tidyverse)
library(sf)
library(cowplot)

p_l4 <- ggplot(sf_gabon, aes(x = l4_agbd)) + geom_histogram(bins = 100) + xlim(c(0, 1000)) + ylim(c(0, 3.25e5)) + labs(title = "GEDI L4A AGBD in Gabon", x = "L4 AGBD (Mg/ha)", y = "Number of GEDI footprints")

p_biwf <- ggplot(sf_gabon, aes(x = est_agbd)) + geom_histogram(bins = 100) + xlim(c(0, 1000)) + ylim(c(0, 3.25e5)) + labs(title = "BIWF AGBD in Gabon", x = "BIWF AGBD (Mg/ha)", y = "Number of GEDI footprints")

p_original_comparison <- plot_grid(p_l4, p_biwf, labels = c("A", "B"), nrow = 2)

ggsave("figures/original_comparison_finetuned.png", p_original_comparison, width = 10, height = 10, dpi = 300)

est_agbd_2_5_quant <- quantile(sf_gabon$est_agbd,.025, na.rm = TRUE) %>% unname()
l4_agbd_2_5_quant <- quantile(sf_gabon$l4_agbd,.025, na.rm = TRUE) %>% unname()

p_l4_low_end <- p_l4 + xlim(c(0, 20)) + ylim(c(0, 3e4)) + geom_vline(xintercept = l4_agbd_2_5_quant, color = "red", linetype = "dashed")

p_biwf_low_end <- p_biwf + xlim(c(25, 30)) + ylim(c(0, 3e4)) + geom_vline(xintercept = est_agbd_2_5_quant, color = "red", linetype = "dashed")

p_low_end_comparison <- plot_grid(p_l4_low_end, p_biwf_low_end, labels = c("A", "B"), nrow = 2)

ggsave("figures/low_end_comparison_finetuned.png", p_low_end_comparison, width = 10, height = 10, dpi = 300)

p_biwf_vs_l4_scatter <-
  sf_gabon %>%
  filter(l4_agbd < 75) %>%
  ggplot(aes(x = l4_agbd, y = biwf)) +
  geom_point(size = 0.01, alpha = .01) +
  ylim(c(0, 25)) +
  labs(title = "L4A vs. BIWF AGBD in Gabon, BIWF < 1", y = "BIWF", x = "L4 AGBD (Mg/ha)") +
  ## bigger text
  theme(axis.text = element_text(size = 12),
        axis.title = element_text(size = 14))

ggsave("figures/biwf_vs_l4_scatter_finetuned.png", p_biwf_vs_l4_scatter, width = 6, height = 6, dpi = 300)

sf_gabon %>%
  filter(biwf < 1,
         l4_agbd > 40) %>%
  nrow

## mismatch in ~ 6 per 100,000 shots
