# 🗺️ NZ Territorial Authority Boundaries Analysis  
**R Spatial Analysis Project | 2025**

---

## 🎯 Purpose  
This project explores internal migration modelling in New Zealand, focusing on how to best measure **distances between Territorial Authorities (TAs)** — essential for understanding and predicting internal migration flows.

Using spatial and population data from **Stats NZ**, the analysis compares three types of centroid-based distance calculations between New Zealand’s 66 TAs:

- **TA Geometric Centroid** (simple polygon center)
- **Unweighted Mean of Meshblock Centroids**
- **Population-Weighted Mean of Meshblock Centroids**

---

## 🧪 Methods  
Using R and the `sf`, `tidyverse`, and `geosphere` packages, this project:

1. **Loads and cleans shapefiles** for TAs and meshblocks  
2. **Calculates centroids** for each TA using:
   - geometric polygon center  
   - mean of meshblock centers  
   - population-weighted meshblock centers  
3. **Measures distance shifts** between centroid types  
4. **Generates a full TA-to-TA distance matrix** using population-weighted centroids  
5. **Visualizes deviations** on a national map and scatter plots  
6. **Fits a LOESS model** to assess the relationship between geometric and population-weighted centroid distances

---

## 📊 Key Outputs  

### 📌 Centroid Comparison  
Distances between centroid types (in km), showing how approximations deviate:

![TA_centroids_all_types](https://github.com/user-attachments/assets/0033e0a0-cd24-4650-8517-0fd4ed56251c)

- Red: Population-weighted  
- Purple: Unweighted  
- Blue: TA geometric centroid  

---

### 🌏 Geographical Impact of Approximation  
Visual map of the difference between geometric and population-weighted centroids across NZ:

![TA_centroids_delta_NZ_MAP](https://github.com/user-attachments/assets/e71323fc-7792-4161-9f8f-68f3fbc25a45)

Some districts show larger deviations due to population clustering within the TA.

---

### 📈 Predictive Fit (LOESS)  
A smoothed regression model evaluates how geometric approximations relate to actual weighted distances.

- **Pseudo R² ≈ 0.93**, indicating strong predictive alignment.

---

## 🧠 Insight  
If population data is unavailable at meshblock level, using the **mean meshblock centroid** (unweighted) is a suitable substitute with relatively low error in most districts.

---

## 📂 Technologies Used  
- **R** (`sf`, `ggplot2`, `dplyr`, `patchwork`, `geosphere`)  
- Spatial vector data (TA and meshblock shapefiles from Stats NZ)  
- CSV-based population concordance data  
- Haversine distance calculations  

---

## ✅ Skills Demonstrated  
- Spatial data wrangling and transformation  
- Geographic centroid computation and comparison  
- Population-weighted spatial analysis  
- Data visualization for spatial analytics  
- Predictive modeling with LOESS  
- Reproducible research with open-source tools  

---

*Author: Pete Freestone (pfre017)  
License: MIT*
