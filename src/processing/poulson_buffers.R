library(tidyverse)
library(sf)
library(janitor)

poulson_plots <-
    read_csv('data/poulson/poulson_plots.csv') %>% clean_names()

sf_poulson_plots <-
    st_as_sf(poulson_plots, coords=(c("longitude_dd", "latitude_dd")),
             crs=4326)

sf_gedi_gabon <-
    read_sf("/home/ian/Documents/projects/gabon_analysis/data/model_output/full_gabon_1-29/full_gabon_1-29.gpkg",
            crs=4326)

## Transform to 5223
sf_poulson_plots <-
    st_transform(sf_poulson_plots, 5223)

gedi_gabon <-
    st_transform(sf_gedi_gabon, 5223)

## Spatial join with 1 km radius around poulson plots
plots_with_shots <- st_join(sf_poulson_plots,
                            gedi_gabon,
                            join=st_is_within_distance,
                            dist=100,
                            left=TRUE)
        
agg_shots_with_plots <- 
    plots_with_shots %>%
    group_by(plot) %>%
    summarise(n_shots = n(),
              mean_biwf = mean(biwf),
              mean_l4_agbd = mean(l4_agbd),
              poulson_agbd = mean(plot_agb_mg_ha))

## 
agg_1km <- 
poulson_1km %>%
    group_by(plot) %>%
    summarise(n_shots = n(),
              mean_biwf = mean(biwf),
              mean_l4_agbd = mean(l4_agbd),
              poulson_agbd = mean(plot_agb_mg_ha))


