library(sf)
library(ggplot2)
library(ggpubr)
library(patchwork)
library(geosphere)
library(tidyverse)

# DATA SOURCE: https://datafinder.stats.govt.nz/
# IMPORT SHAPE FILES FOR TA AND MESHBLOCK ---------------------------------------------------------
ta_shapes <- st_read("statsnz-territorial-authority-2025-SHP/territorial-authority-2025.shp") %>% 
  filter(!TA2025_V1_ %in% c("067", "999")) %>% 
  st_transform(4326)
mesh_shapes <- st_read("statsnz-2023-census-electoral-population-at-meshblock-level-2025-mes-SHP/2023-census-electoral-population-at-meshblock-level-2025-mes.shp") %>% 
  st_transform(4326)

# REVIEW THE SHAPE FILES
# num_TA <- nrow(ta_shapes)
# total_TA_coords <- sum(sapply(st_geometry(ta_shapes), function(geom) {
#   length(st_coordinates(geom)[,1])
# }))
# 
# total_meshblocks <- nrow(mesh_shapes)
# total_meshblock_coords <- sum(sapply(st_geometry(mesh_shapes), function(geom) {
#   length(st_coordinates(geom)[,1])
# }))

# IMPORT MESHBLOCK-TO-TA CONCORDANCE ---------------------------------------------------------
concordance <- read.csv("additional_data/397EADB811FB54E0649FC4DAE1B0C8A3941DA10C_2_C33CCCC70E1E5E83FEC1A05E081F21352C63B469.csv"
                        , skip = 6
                        , col.names = c("Mesh", "Relationship", "TA", "TA_Name", "dummy")
                        , colClasses = c("TA" = "character", "Mesh" = "character"))

# CLEAN AND PREPARE DATA ------------------------------------------------------------------------
# replace populations of -999 (suppressed for privacy, no usual residents) with 0
mesh_shapes$General_El[mesh_shapes$General_El == -999] <- 0
mesh_shapes$Maori_Elec[mesh_shapes$Maori_Elec == -999] <- 0
mesh_shapes$total_pop <- mesh_shapes$General_El + mesh_shapes$Maori_Elec

# Add the TA codes to the mesh shapes
# NOTE: discrepancy between number of meshblocks in the concordance and the mesh shapes (different years?)
mesh_data <- mesh_shapes %>%
  left_join(concordance %>% select(Mesh, TA, TA_Name), by = c("MB2025_V1_" = "Mesh"))

# Extract longitudinal (lon) and latitudinal (lat) coordinates from the geometry
ta_geometric_centroids <- st_centroid(ta_shapes)
ta_geometric_centroids <- ta_geometric_centroids %>%
  mutate(
    lon = st_coordinates(geometry)[, 1],
    lat = st_coordinates(geometry)[, 2]
)

mesh_geometric_centroids <- st_centroid(mesh_data)
mesh_geometric_centroids <- mesh_geometric_centroids %>%
  mutate(
    lon = st_coordinates(geometry)[, 1],
    lat = st_coordinates(geometry)[, 2]
  )


# Calculate population-weighted centroids for TAs using meshblock population data ---------------------------------------
ta_centroids <- mesh_geometric_centroids %>%
  st_drop_geometry() %>% 
  group_by(TA) %>%
  summarise(
    population = sum(total_pop),
    TA_Name = first(TA_Name),
    lon_meshblock_pop_weighted = weighted.mean(lon, total_pop),
    lat_meshblock_pop_weighted = weighted.mean(lat, total_pop),
    lon_meshblock_geometric = mean(lon),
    lat_meshblock_geometric = mean(lat)
  )

ta_centroids_pop_weighted <- ta_centroids %>%
  left_join(
    ta_geometric_centroids %>% select(lon, lat, TA2025_V1_),
    by = c("TA" = "TA2025_V1_")
  ) %>% 
  rename(
    lon_TA_geometric = lon,
    lat_TA_geometric = lat
  ) %>%
  mutate(
    lon_TA_geometricToweighted_delta = lon_TA_geometric - lon_meshblock_pop_weighted,
    lat_TA_geometricToweighted_delta = lat_TA_geometric - lat_meshblock_pop_weighted,
    lon_TA_geometricTogeometric_delta = lon_TA_geometric - lon_meshblock_geometric,
    lat_TA_geometricTogeometric_delta = lat_TA_geometric - lat_meshblock_geometric,
    TA_geometricToweighted_km = distHaversine(cbind(lon_TA_geometric, lat_TA_geometric), cbind(lon_meshblock_pop_weighted, lat_meshblock_pop_weighted)) / 1000,  # convert to km,
    TA_geometricTogeometric_km = distHaversine(cbind(lon_TA_geometric, lat_TA_geometric), cbind(lon_meshblock_geometric, lat_meshblock_geometric)) / 1000,  # convert to km
  )

# REVIEW THE DELTA BETWEEN TA_GEOMETRIC AND POPULATION-WEIGHTED CENTROIDS 
ta_centroids_pop_weighted %>%
  select(TA, TA_Name,  TA_geometricToweighted_km) %>%
  arrange(desc(TA_geometricToweighted_km)) %>%
  slice_head(n = 5)

# PLOT THE TOP 20 TAs BY GEOMETRIC DELTA
ta_centroids_pop_weighted %>%
  arrange(desc(TA_geometricToweighted_km)) %>%
  slice_head(n = 10) %>% 
  ggplot(aes(x = reorder(TA_Name, TA_geometricToweighted_km), y = TA_geometricToweighted_km)) +
  geom_col() +
  coord_flip() +
  labs(x = "", y = "Geometric Delta (km)", title = "Top 20 TAs by Geometric Delta")

# CALCULATE DELTA MATRIX (using crossing to create a flat table)

# -lon_meshblock_pop_weighted, -lat_meshblock_pop_weighted, 
distance_matrix <- ta_centroids_pop_weighted %>%
  select(-lon_meshblock_geometric, -lat_meshblock_geometric, -lon_TA_geometricToweighted_delta, -lat_TA_geometricToweighted_delta, -lon_TA_geometric, -lat_TA_geometric, -lon_TA_geometricTogeometric_delta, -lat_TA_geometricTogeometric_delta, -TA_geometricTogeometric_km, -TA_geometricToweighted_km, -geometry, -population, -TA_Name) %>% 
  rename(origin_TA = TA, origin_lon = lon_meshblock_pop_weighted, origin_lat = lat_meshblock_pop_weighted) %>%
  crossing(ta_centroids_pop_weighted %>%
  rename(dest_TA = TA)) %>% 
  mutate(
    dest_lat = lat_meshblock_pop_weighted,
    dest_lon = lon_meshblock_pop_weighted,
    distance_km = distHaversine(cbind(origin_lon, origin_lat), cbind(dest_lon, dest_lat)) / 1000  # convert to km
  )

write_csv(distance_matrix, "TA_distance_matrix_population_weighted.csv")
