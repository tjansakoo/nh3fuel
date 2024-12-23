
library('gdxrrw')
library('tidyverse')
library('openxlsx')
library(stringr)

igdx("/Library/Frameworks/GAMS.framework/Versions/47/Resources")
df_gdx <- rgdx.param("../data/240418/global_17_IAMC.gdx","IAMC_Template")
df_gdx$SCENARIO <- as.character(df_gdx$SCENARIO)

df <- df_gdx %>% filter(REMF %in% c("World"),SCENARIO %in% c("SSP2_BaU_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_amm_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_amm_LoAQC_NoCC_globalnh3_global2")) %>% 
  mutate(SCENARIO = case_when(str_detect("SSP2_BaU_NoCC_globalnh3_global2", 
                                    SCENARIO) ~ "Baseline",
                              str_detect("SSP2_600C_CACN_DAC_NoCC_globalnh3_global2", 
                                    SCENARIO)  ~"wo/NH3",
                              str_detect("SSP2_600C_CACN_DAC_amm_NoCC_globalnh3_global2", 
                                    SCENARIO)  ~"w/NH3",
                              str_detect("SSP2_600C_CACN_DAC_amm_LoAQC_NoCC_globalnh3_global2", 
                                    SCENARIO)  ~"With Ammonia Fuel LoAQC"
  )
  )

Emi_IAMC <- df %>% filter(str_detect(VEMF, "^Emi"))

Emi_IAMC_group <- Emi_IAMC %>%
  mutate(source = case_when(
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}__AFO_Agriculture_Liv$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Agriculture_Ric$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Cro$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Frs$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Gra_Pst$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Oth_Lan$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Set$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Wet$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Avi$") ~ "Transportation",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Oth_Sec$") ~ "Transportation",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Rai$") ~ "Transportation",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Roa$") ~ "Transportation",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Sup$") ~ "Energy Supply",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Ind$") ~ "Industry",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Emi_Ind_Pro$") ~ "Industry",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Res_and_Com_and_AFO$") ~ "Residential and Commercial",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Pro_Use$") ~ "Solvent",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Was$") ~ "Waste Management",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Shi$") ~ "Shipping",
    TRUE ~ "Other"
  )) %>% 
  mutate(Species = case_when(
    str_detect(VEMF, "CO2") ~ "CO2",
    str_detect(VEMF, "CH4") ~ "CH4",
    str_detect(VEMF, "N2O") ~ "N2O",
    str_detect(VEMF, "NH3") ~ "NH3",
    str_detect(VEMF, "NOx") ~ "NOx",
    str_detect(VEMF, "Sul") ~ "SOx",
    str_detect(VEMF, "VOC") ~ "VOC",
    str_detect(VEMF, "BC") ~ "BC",
    TRUE ~ "Other"
  )) %>% filter(source != "Other")

Emi_IAMC_sum <- Emi_IAMC_group %>%
  group_by(SCENARIO, REMF, YEMF, source, Species) %>%
  summarise(value = sum(IAMC_Template, na.rm = TRUE))
#write.csv2(Emi_IAMC_group, "../data/csv/Emi_IAMC_group.csv")

df3 <- Emi_IAMC_sum %>% filter(SCENARIO %in% c("w/NH3", "wo/NH3")) %>%
  filter(YEMF %in% c("2015","2030", "2050", "2100"))
write.csv(df3, "../data/csv/Emi_IAMC_Sector.csv")

# Define colors based on the provided image (approximate hex values)
source_colors <- c(
  "Agriculture" = "#6AB187",
  "Energy Supply" = "#EA6A47",
  "Waste Management" = "#7E909A",
  "Transportation" = "#1C4E80",
  "Residential and Commercial" = "#A5D8DD",
  "Solvent" = "#488A99",
  "Industry" = "#202020",
  "Shipping" = "#0091D5"
)

library(dplyr)
library(ggplot2)

plot_species_emission <- function(species_name, df3, source_colors) {
  # Filter the data for the specified species
  new_order <- c("Shipping", "Agriculture", "Waste Management", "Transportation",
                 "Residential and Commercial", "Solvent", "Industry", "Energy Supply")
  new_order2 <- c("wo/NH3", "w/NH3")
  dfp <- df3 %>% 
    filter(Species == species_name)
  dfp$source <- as.factor(dfp$source )
  dfp$source <- factor(dfp$source, levels = new_order)
  dfp$SCENARIO <- as.factor(dfp$SCENARIO )
  dfp$SCENARIO <- factor(dfp$SCENARIO, levels = new_order2)

  # Identify unique sources and the corresponding colors
  unique_sources <- unique(dfp$source)
  colors_with_data <- source_colors[names(source_colors) %in% unique_sources]
  
  # Generate the plot
  species_name <- dfp %>% 
    ggplot(aes(x = YEMF, y = value, fill = source)) +
    geom_bar(stat = "identity", position = "stack") + # Bar chart
    scale_fill_manual(values = colors_with_data) +  # Use filtered colors
    theme_bw() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      text = element_text(size = 18),
      legend.position = 'none',
      strip.background = element_blank(),  # Remove strip background
      strip.placement = "outside",
      panel.border = element_blank(),  # Remove facet borders
      axis.line = element_line(color = "black"),
      legend.text=element_text(size=12),
    ) +
    labs(
      title = paste(species_name, "Emission by source"),
      x = "Year",
      y = "Emission (Gt/yr)"
    ) +
    facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
    theme(panel.border = element_blank())  # Remove facet borders
  
  print(species_name)
  
  ggsave(
    filename = "../figure/Emission/New/NH3_source.svg",
    plot = species_name, 
    width = 5, 
    height = 10, 
    dpi = 321)
  
  }

species_name <- "NH3"
species_list <- c("NH3", "NOx")
species_list <- c("CO2")

# Loop through each species and generate the plot
for (species in species_list) {
  plot_species_emission(species, df3, source_colors)
}



df_gdx$SCENARIO <- as.character(df_gdx$SCENARIO)
df_region <- df_gdx %>% filter(SCENARIO %in% c("SSP2_BaU_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_amm_NoCC_globalnh3_global2", 
                                                             "SSP2_600C_CACN_DAC_amm_LoAQC_NoCC_globalnh3_global2")) %>% 
  mutate(SCENARIO = case_when(str_detect("SSP2_BaU_NoCC_globalnh3_global2", 
                                         SCENARIO) ~ "Base",
                              str_detect("SSP2_600C_CACN_DAC_NoCC_globalnh3_global2", 
                                         SCENARIO)  ~"1p5c_wo/nh3",
                              str_detect("SSP2_600C_CACN_DAC_amm_NoCC_globalnh3_global2", 
                                         SCENARIO)  ~"1p5c_w/nh3",
                              str_detect("SSP2_600C_CACN_DAC_amm_LoAQC_NoCC_globalnh3_global2", 
                                         SCENARIO)  ~"1p5c_w/nh3_LoAQC"
  )
  )

Emi_IAMC_region <- df_region %>% filter(str_detect(VEMF, "^Emi"))

Emi_IAMC_group_region <- Emi_IAMC_region %>%
  mutate(source = case_when(
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}__AFO_Agriculture_Liv$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Agriculture_Ric$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Cro$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Frs$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Gra_Pst$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Oth_Lan$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Set$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_AFO_Lan_Wet$") ~ "Agriculture",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Agg___Rai_and_Dom_Shi$") ~ "Transportation",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Sup$") ~ "Energy",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Industry$") ~ "Industry",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Emi_Industry_Pro$") ~ "Industry",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Res_and_Com_and_AFO$") ~ "Residential and Commercial",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Pro_Use$") ~ "Solvent",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Was$") ~ "Waste Management",
    str_detect(VEMF, "Emi_[A-Za-z0-9]{2,3}_Ene_Dem_Tra_Shi_Int$") ~ "International Shipping",
    TRUE ~ "Other"
  )) %>% 
  mutate(Species = case_when(
    str_detect(VEMF, "CO2") ~ "CO2",
    str_detect(VEMF, "CH4") ~ "CH4",
    str_detect(VEMF, "N2O") ~ "N2O",
    str_detect(VEMF, "NH3") ~ "NH3",
    str_detect(VEMF, "NOx") ~ "NOx",
    str_detect(VEMF, "Sul") ~ "SOx",
    str_detect(VEMF, "VOC") ~ "VOC",
    str_detect(VEMF, "BC") ~ "BC",
    TRUE ~ "Other"
  )) %>% filter(source != "Other")

Emi_IAMC_sum_region <- Emi_IAMC_group_region %>%
  group_by(SCENARIO, REMF, YEMF, source, Species) %>%
  summarise(value = sum(IAMC_Template, na.rm = TRUE))
write.csv2(Emi_IAMC_sum_region, "../data/csv/Emi_IAMC_17Region.csv")

df3 <- Emi_IAMC_sum %>% filter(SCENARIO %in% c("1p5c_w/nh3", "1p5c_w/nh3_LoAQC")) %>%
  filter(YEMF %in% c("2015","2030", "2050", "2100"))

dp678 <- Emi_IAMC_sum_region %>%
  mutate(Region = case_when(
    REMF == "USA" ~ "America",
    REMF == "XLM" ~ "America",
    REMF == "CAN" ~ "America",
    REMF == "BRA" ~ "America",
    REMF == "XE25" ~ "Europe",
    REMF == "XER" ~ "Europe",
    REMF == "XME" ~ "Middle East",
    REMF == "XNF" ~ "Africa",
    REMF == "XAF" ~ "Africa",
    REMF == "JPN" ~ "Asia",
    REMF == "XSA" ~ "Asia",
    REMF == "TUR" ~ "Asia",
    REMF == "XSE" ~ "Asia",
    REMF == "CHN" ~ "China",
    REMF == "IND" ~ "India",
    REMF == "World" ~ "World",
    TRUE ~ "Other"
  )) %>%
  group_by(SCENARIO, YEMF, Species, source, Region) %>%
  summarise(Emi = sum(value))

write.csv(dp678, "../data/csv/Emi_IAMC_Region.csv", row.names = FALSE)


##############################################################################

new_order <- c("Shipping", "Agriculture", "Energy Supply", "Waste Management", "Transportation",
               "Residential and Commercial", "Solvent", "Industry")

new_order2 <- c("wo/NH3", "w/NH3")
#CO2

dfp <- df3 %>% 
  filter(Species == "CO2")
dfp$source <- as.factor(dfp$source )
dfp$source <- factor(dfp$source, levels = new_order)
dfp$SCENARIO <- as.factor(dfp$SCENARIO)
dfp$SCENARIO <- factor(dfp$SCENARIO, levels = new_order2)

# Identify unique sources and the corresponding colors
unique_sources <- unique(dfp$source)
colors_with_data <- source_colors[names(source_colors) %in% unique_sources]

# Generate the plot
CO2 <- dfp %>% 
  ggplot(aes(x = YEMF, y = value/1000, fill = source)) +
  geom_bar(stat = "identity", position = "stack") + # Bar chart
  scale_fill_manual(values = colors_with_data) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    text = element_text(size = 22),
    legend.position = 'none',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    legend.text=element_text(size=22),
    strip.text = element_text(size = 22)
  ) +
  labs(
    title = expression("CO"[2] ~ " Emission"),
    x = "",
    y = "Emission (Gt/year)"
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
  theme(panel.border = element_blank())  # Remove facet borders

print(CO2)


#NOx

dfp <- df3 %>% 
  filter(Species == "NOx")
dfp$source <- as.factor(dfp$source )
dfp$source <- factor(dfp$source, levels = new_order)
dfp$SCENARIO <- as.factor(dfp$SCENARIO)
dfp$SCENARIO <- factor(dfp$SCENARIO, levels = new_order2)


# Identify unique sources and the corresponding colors
unique_sources <- unique(dfp$source)
colors_with_data <- source_colors[names(source_colors) %in% unique_sources]

# Generate the plot
NOX <- dfp %>% 
  ggplot(aes(x = YEMF, y = value, fill = source)) +
  geom_bar(stat = "identity", position = "stack") + # Bar chart
  scale_fill_manual(values = colors_with_data) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    text = element_text(size = 22),
    legend.position = 'bottom',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    legend.text=element_text(size=22),
    legend.justification = 'center',       # Legend centered
    legend.title = element_blank(),
    strip.text = element_text(size = 22)) + 
  labs(
    title = paste("NOx Emission"),
    x = "",
    y = "Emission (Mt/year)"
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
  theme(panel.border = element_blank())  # Remove facet borders

print(NOX)


#NH3

dfp <- df3 %>% 
  filter(Species == "NH3")
dfp$source <- as.factor(dfp$source )
dfp$source <- factor(dfp$source, levels = new_order)
dfp$SCENARIO <- as.factor(dfp$SCENARIO)
dfp$SCENARIO <- factor(dfp$SCENARIO, levels = new_order2)

# Identify unique sources and the corresponding colors
unique_sources <- unique(dfp$source)
colors_with_data <- source_colors[names(source_colors) %in% unique_sources]

# Generate the plot
NH3 <- dfp %>% 
  ggplot(aes(x = YEMF, y = value, fill = source)) +
  geom_bar(stat = "identity", position = "stack") + # Bar chart
  scale_fill_manual(values = colors_with_data) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    text = element_text(size = 22),
    legend.position = 'none',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    legend.text=element_text(size=22),
    strip.text = element_text(size = 22)    # Adjust strip text size here
  ) +
  labs(
    title = expression("NH"[3] ~ " Emission"),
    x = "",
    y = "Emission (Mt/year)"
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
  theme(panel.border = element_blank())  # Remove facet borders

print(NH3)

library(patchwork)
emission <- CO2+NOX+NH3

emission

p2 <- p+p3/emission
p2

ggsave(paste0("../figure/Emission/Emission.svg"), emission, width = 16, height = 10, dpi = 321)


CO2df_plot <- CO2df %>%
  filter(YEMF %in% seq(2010, 2100, by = 10))
CO2df_plot_bf <- CO2_baseline %>%
  filter(YEMF %in% seq(2010, 2100, by = 10))

CO2pp1 <- ggplot(CO2df_plot, aes(x = factor(YEMF), y = value, fill = SCENARIO)) +
  # Adding shaded area for the CO2df_plot_bf data in the background
  geom_area(data = CO2df_plot_bf, aes(x = factor(YEMF), y = value, group = 1), 
            fill = "black", alpha = 0.1) +  
  
  # Main bar plot
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +  
  scale_fill_manual(values = c("wo/NH3" = "#6AB187", "w/NH3" = "#d32d41")) +
  
  labs(x = "", y = expression(CO[2]~Emission~(Gt/yr))) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(),
    text = element_text(size = 22),
    legend.position = 'none',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    legend.text = element_text(size = 22),
    strip.text = element_text(size = 22)  # Adjust strip text size here
  )

CO2pp1
ggsave("figure/CO2_new_29Oct.svg", plot = CO2pp1, width = 24, height = 12) 

# Assuming that you have already calculated the differences between scenarios in CO2df_plot
CO2df_plot$difference <- with(CO2df_plot, ave(value, YEMF, FUN = function(x) x[1] - x[2]))

CO2pp1 <- ggplot(CO2df_plot, aes(x = factor(YEMF), y = value, fill = SCENARIO)) +
  # Adding shaded area for the CO2df_plot_bf data in the background
  geom_area(data = CO2df_plot_bf, aes(x = factor(YEMF), y = value, group = 1), 
            fill = "black", alpha = 0.1) +  
  
  # Main bar plot
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +  
  scale_fill_manual(values = c("wo/NH3" = "#6AB187", "w/NH3" = "#d32d41")) +
  
  # Adding labels for the difference between scenarios
  geom_text(aes(x = factor(YEMF), y = max(value) + 5, label = round(difference, 2)), 
            data = CO2df_plot, 
            position = position_dodge(width = 0.8), size = 5, color = "black", vjust = -0.5) +

  labs(x = "", y = expression(CO[2]~Emission~(Gt/yr))) +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(),
    text = element_text(size = 22),
    legend.position = 'none',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    legend.text = element_text(size = 22),
    strip.text = element_text(size = 22)  # Adjust strip text size here
  )

CO2pp1

