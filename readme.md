Study of migration patterns within New Zealand is best carried out at the [Territorial Authority (TA)]() level (e.g. Auckland, Far North District, Kaipara District).
When modelling migration, distance between origin and destination TAs is important. This project compared 3 approaches for determining distance using:
* TA geometric centroid - blue
* Mean geometric meshblock centroids (per TA) - purple
* Population-weighted mean geometric meshblock centroids (per TA) - red

![TA_centroids_all_types](https://github.com/user-attachments/assets/0033e0a0-cd24-4650-8517-0fd4ed56251c)

![TA_centroids_delta_NZ_MAP](https://github.com/user-attachments/assets/e71323fc-7792-4161-9f8f-68f3fbc25a45)

# Conclusion
SUMMARIZE DIFFERENCE BETWEEN TA_geometric and the other two approaches
If population data not available at the meshblock level, mean geometric meshblock centroids are a suitable substitute offering XXXX coverage/similariarity (
Source data is from [Stats NZ]( https://datafinder.stats.govt.nz/data/)
* Territorial Authority boundaries: 66 polygons; 1,697,453 coordinates
* Meshblocks boundaries: 57535 polygons; 15,847,609 coordinates
* Concordance: Meshblock to TA

Uses `sf` ([simple features](https://github.com/r-spatial/sf)) package for manipulating spatial vector data (TA and meshblock boundaries)
