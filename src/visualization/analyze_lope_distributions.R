library(sf)
library(tidyverse)
library(FactoMineR)
library(factoextra)

lope <- st_read("/home/ian/projects/gabon/data/gedi_avg_agb_lvis/gedi_avg_lvis_agb_lope_25m.gpkg")

lope <-
  lope %>%
  mutate(error = est_agbd - avg_lvis_agb_pred)

st_write(lope, "/home/ian/projects/gabon/data/gedi_avg_agb_lvis/all/gedi_avg_lvis_agb_lope_25m_error.gpkg")

# Perform PCA
lope_pca_data <- lope %>% select(est_agbd, avg_lvis_agb_pred, error) %>% st_drop_geometry()
lope_pca <- PCA(lope_pca_data, graph = FALSE)

# Visualize PCA results
fviz_pca_ind(lope_pca, geom.ind = "point", col.ind = "cos2", 
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE)
