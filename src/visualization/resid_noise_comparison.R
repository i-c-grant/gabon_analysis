sf_finetuned_subset <-
  sf_finetuned_subset %>%
  rename(biwf_resid_noise_removed = biwf)

sf_no_resid_noise_subset <-
  sf_no_resid_noise_subset %>%
  rename(biwf_signal_noise_only = biwf)

sf_joined <-
  sf_no_resid_noise_subset %>%
  left_join(tibble(sf_finetuned_subset), join_by(shot_number))

sf_joined %>%
  ggplot(aes(x = biwf_signal_noise_only, y = biwf_resid_noise_removed)) +
  geom_point() +
  labs(x = "BIWF (only signal noise removal)", y = "BIWF (residual noise removal)") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red")
