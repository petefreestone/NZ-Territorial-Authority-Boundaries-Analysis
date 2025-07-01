library(ggplot2)
library(tidyverse)

# IMPORT DATA
centroids <- read.csv("TA_distance_matrix_population_weighted.csv"
                      , header = TRUE
                      , stringsAsFactors = FALSE
                      ,colClasses = c("origin_TA" = "character", "dest_TA" = "character"))
ta_shapes <- st_read("statsnz-territorial-authority-2025-SHP/territorial-authority-2025.shp") %>% 
  filter(!TA2025_V1_ %in% c("067", "999")) %>% 
  st_transform(4326)

# Highlight specific TA for comparison
centroids <- centroids %>%
  mutate(highlight = origin_TA == "062")


# PLOT COMPARISON OF CRUDE AND POPULATION-WEIGHTED CENTROIDS
ggplot(data = centroids) +
  geom_point(aes(x = abs(lon_TA_geometricTogeometric_delta), 
                 y = abs(lat_TA_geometricTogeometric_delta), 
                 color = ifelse(highlight, "062 Geometric", "Geometric")), 
             size = 2, alpha = 0.6) +
  geom_point(aes(x = abs(lon_TA_geometricToweighted_delta), 
                 y = abs(lat_TA_geometricToweighted_delta), 
                 color = ifelse(highlight, "062 Pop-Weighted", "Pop-Weighted")), 
             size = 2, alpha = 0.6) +
  geom_text(
    data = subset(centroids, highlight == TRUE),
    aes(x = abs(lon_TA_geometricToweighted_delta), 
        y = abs(lat_TA_geometricToweighted_delta), 
        label = dest_TA), 
    vjust = -1, color = "black", size = 3
  ) +
  geom_text(
    data = subset(centroids, highlight == TRUE),
    aes(x = abs(lon_TA_geometricToweighted_delta), 
        y = abs(lat_TA_geometricToweighted_delta), 
        label = paste0(dest_TA, "_pw")), 
    vjust = -1, color = "black", size = 3
  ) +
  geom_text(
    data = subset(centroids, highlight == TRUE),
    aes(x = abs(lon_TA_geometricTogeometric_delta), 
        y = abs(lat_TA_geometricTogeometric_delta), 
        label = paste0(dest_TA, "_g")), 
    vjust = -1, color = "black", size = 3
  ) +
  scale_color_manual(
    name = "Centroid Type",
    values = c("Geometric" = "blue", 
               "Pop-Weighted" = "red", 
               "062 Geometric" = "green", 
               "062 Pop-Weighted" = "green")
  ) +
  scale_y_log10() +
  scale_x_log10() +
  labs(title = "TA centroids: Comparison of Meshblock Population-Weighted and Unweighted to TA Geometric",
       x = "Longitude", y = "Latitude") +
  theme_minimal()

# PLOT ARROWS FROM TA-GEOMETRIC TO POPULATION-WEIGHTED CENTROIDS
ggplot(data = centroids) +
  # Arrow from crude to weighted
  geom_segment(aes(
    x = lon_TA_geometric,
    y = lat_TA_geometric,
    xend = lon_meshblock_pop_weighted,
    yend = lat_meshblock_pop_weighted
  ),
  arrow = arrow(length = unit(0.15, "cm")),
  color = "grey50") +
  
  # Crude centroid
  geom_point(aes(x = lon_TA_geometric, y = lat_TA_geometric), color = "blue", size = 1) +
  # Weighted centroid
  geom_point(aes(x = lon_meshblock_pop_weighted, y = lat_meshblock_pop_weighted), color = "red", size = 1) +
  # Unweighted centroid
  geom_point(aes(x = lon_meshblock_geometric, y = lat_meshblock_geometric), color = "purple", size = 1) +
  # Highlight label (optional)
  geom_text(
    data = filter(centroids, highlight),
    aes(x = lon_TA_geometric, y = lat_TA_geometric, label = dest_TA),
    vjust = -0.5, color = "black", size = 2
  ) +
  xlim(158, 187) +
  ylim(-47, -35) +
  labs(
    title = "Crude → Population-Weighted Centroids by TA",
    x = "Longitude Δ", y = "Latitude Δ"
  )

ggsave("TA_centroids_all_types.png", plot = last_plot(), width = 8, height = 6, units = "in", dpi = 300)

# CONSIDER CALCULATING THE DELTA AS A PERCENTAGE OF SHAPE WIDTH/HEIGHT

# PREPARE DATA FOR PLOTTING
geometric_delta_projection <- centroids %>%
  select(origin_TA, dest_TA, distance_km, TA_geometricToweighted_km, TA_geometricTogeometric_km) %>%
  filter(origin_TA == "062") %>% 
  left_join(ta_shapes, by = c("dest_TA" = "TA2025_V1_")) %>% 
  mutate(
    top_errors = abs(TA_geometricToweighted_km - distance_km),
  ) %>% 
  st_as_sf()    # required to reassert that this is an sf object

# PLOT TA_GEOMETRIC TO MESHBLOCK_POP_WEIGHTED DELTA ON MAP OF NZ
ggplot() +
  geom_sf(data = geometric_delta_projection, aes(fill = TA_geometricToweighted_km), color = "black") +
  scale_fill_viridis_c(option = "plasma", name = "TA geom. to MB pop. weighted (km)")
  
  ggsave("TA_centroids_delta_NZ_MAP.png", plot = last_plot(), width = 8, height = 6, units = "in", dpi = 300)

# Why are some TAs geometries enlarged (e.g. Auckland)??

# MODEL THE RELATIONSHIP BETWEEN MESHBLOCK_GEOMETRIC AND MESHBLOCK_POP_WEIGHTED CENTROIDS ------------------------------------
model <- loess(
  formula = TA_geometricToweighted_km ~ TA_geometricTogeometric_km,
  data = geometric_delta_projection
)
model

# Create x grid
x_grid <- data.frame(
  TA_geometricTogeometric_km = seq(
    min(geometric_delta_projection$TA_geometricToweighted_km, na.rm = TRUE),
    max(geometric_delta_projection$TA_geometricToweighted_km, na.rm = TRUE),
    length.out = 200
  )
)

# Predict with standard errors
loess_preds <- predict(model, newdata = x_grid, se = TRUE)

# Add predictions and 95% CI using z = 1.96
x_grid$fit <- loess_preds$fit
x_grid$lower <- loess_preds$fit - 1.96 * loess_preds$se.fit
x_grid$upper <- loess_preds$fit + 1.96 * loess_preds$se.fit


# CALCULATE PSEUDO R² ---------------------------------------------------
y <- model$x #geometric_delta_projection$TA_geometricToweighted_km
yhat <- model$fitted

rss <- sum((y - yhat)^2)
tss <- sum((y - mean(y))^2)
r_squared <- 1 - rss/tss
cat("Pseudo R-squared:", round(r_squared, 3), "\n")

ggplot(geometric_delta_projection, aes(x = TA_geometricTogeometric_km, y = TA_geometricToweighted_km)) +
  geom_point() +
  geom_text(
    data = subset(geometric_delta_projection, top_errors > 0),
    aes(label = dest_TA), vjust = -0.5, color = "black"
  ) +
  geom_text(label = paste("Pseudo R²:", round(r_squared, 3)), 
            x = Inf, y = Inf, hjust = 1.1, vjust = 1.5, size = 3) +
  geom_ribbon(
    data = x_grid,
    aes(x = TA_geometricTogeometric_km, ymin = lower, ymax = upper),
    fill = "blue", alpha = 0.2, inherit.aes = FALSE
  ) +
  geom_line(
    data = x_grid,
    aes(x = TA_geometricTogeometric_km, y = fit),
    color = "blue", size = 1, inherit.aes = FALSE
  ) +
  labs(
    title = "LOESS Fit: TA Geometric vs Pop Weighted Centroid Distance",
    x = "TA Geometric to Meshblock Geometric (km)",
    y = "TA Geometric to Meshblock Pop. Weighted (km)"
  ) +
  theme_minimal()

plot(model)


