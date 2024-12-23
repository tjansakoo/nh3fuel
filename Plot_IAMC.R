
library('gdxrrw')
library('tidyverse')
library('openxlsx')
library(stringr)

igdx("/Library/Frameworks/GAMS.framework/Versions/47/Resources")
df_gdx <- rgdx.param("../data/240624/global_17_IAMC.gdx","IAMC_Template")
df_gdx$SCENARIO <- as.character(df_gdx$SCENARIO)

df <- df_gdx %>% filter(REMF %in% c("World"),SCENARIO %in% c("SSP2_BaU_NoCC_globalnh3_global2", 
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

Fin_IAMC <- df %>% filter(VEMF %in% c("Fin_Ene_Hyd", "Fin_Ene_Liq_Bio", "Fin_Ene_Liq_Oil","Fin_Ene_Heat",
                                      "Fin_Ene_Oth", "Fin_Ene_Solids", "Fin_Ene_Gas", "Fin_Ene_Ele"))
Fin_IAMC$VEMF <- as.character(Fin_IAMC$VEMF)
df2 <- Fin_IAMC %>% filter(SCENARIO %in% c("1p5c_wo/nh3", "1p5c_w/nh3")) %>%
  filter(YEMF %in% c("2010", "2020","2030","2040", "2050","2060","2070","2080","2090", "2100")) %>% mutate(Energy_type = case_when(
    str_detect("Fin_Ene_Hyd", VEMF) ~ "Hydrogen",
    str_detect("Fin_Ene_Liq_Bio", VEMF) ~ "Biofuels",
    str_detect("Fin_Ene_Liq_Oil", VEMF) ~ "Petrol",
    str_detect("Fin_Ene_Heat", VEMF) ~ "Heat",
    str_detect("Fin_Ene_Ele", VEMF) ~ "Electricity",
    str_detect("Fin_Ene_Solids", VEMF) ~ "Solids",
    str_detect("Fin_Ene_Gas", VEMF) ~ "Gas",
  ))
# Define colors based on the provided image (approximate hex values)

library(dplyr)
library(ggplot2)


#Pure ammonia
df11 <- df2 %>% filter(Energy_type == "Hydrogen" & SCENARIO == "1p5c_w/nh3") %>% mutate(Energy_type = case_when(
  str_detect("Fin_Ene_Hyd", VEMF) ~ "Ammonia"))
df22 <- df2 %>% filter(Energy_type != "Hydrogen" | SCENARIO != "1p5c_w/nh3")

df33 <- rbind(df11, df22)
df33$Energy_type <- factor(df33$Energy_type, levels = c("Electricity", "Gas", "Heat", "Hydrogen", "Ammonia", "Petrol", "Biofuels", "Solids"))

#Hydrogen - Ammonia
df11 <- df2 %>% 
  filter(Energy_type == "Hydrogen" & SCENARIO == "1p5c_w/nh3") %>% 
  mutate(ammonia = IAMC_Template) %>% 
  select(-SCENARIO, -IAMC_Template)

# Creating df111
df111 <- df2 %>% 
  filter(Energy_type == "Hydrogen" & SCENARIO == "1p5c_wo/nh3") %>% 
  mutate(hydrogen = IAMC_Template) %>% 
  select(-SCENARIO, -IAMC_Template)

# Full join
df_ammonia <- full_join(df111, df11) %>% mutate(IAMC_Template = ammonia-hydrogen) %>% 
  select(-ammonia, -hydrogen) %>%
  mutate(SCENARIO = "1p5c_w/nh3",
         Energy_type = "Ammonia")

df_hydrogen <- full_join(df111, df11) %>% mutate(IAMC_Template = hydrogen) %>% 
  select(-ammonia, -hydrogen) %>%
  mutate(SCENARIO = "1p5c_w/nh3",
         Energy_type = "Hydrogen")

df_com <- rbind(df_ammonia, df_hydrogen)

df22 <- df2 %>% filter(Energy_type != "Hydrogen" | SCENARIO != "1p5c_w/nh3")
df33 <- rbind(df_com, df22) %>%
  mutate(SCENARIO = case_when(
    str_detect("1p5c_w/nh3", SCENARIO) ~ "With Ammonia Fuel",
    str_detect("1p5c_wo/nh3", SCENARIO) ~ "Without Ammonia Fuel"))
df33$Energy_type <- factor(df33$Energy_type, levels = c("Electricity", "Heat", "Hydrogen", "Ammonia", "Petrol","Biofuels", "Solids", "Gas")) 
df33$SCENARIO <- factor(df33$SCENARIO, levels = c("Without Ammonia Fuel", "With Ammonia Fuel")) 

source_colors <- c(
  "Hydrogen" = "#D32D41",    # Vibrant Crimson Red for Hydrogen
  "Biofuels" = "#6AB187",    # Bright Moss Green for Biofuels
  "Petrol" = "#000000",      # Strong Black for Petrol
  "Electricity" = "#ADD8E6", # Light Blue for subtle Electricity
  "Heat" = "#B65FCF",        # Vibrant Orange for Heat
  "Solids" = "#C0C0C0",      # Silver Gray for Solids
  "Gas" = "#1E90FF",         # Dodger Blue for Gas
  "Ammonia" = "#FFA500"      # Bold Purple for Ammonia
)



# Generate the updated plot
p <- df33 %>% 
  ggplot(aes(x = YEMF, y = IAMC_Template, fill = Energy_type)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +  # Stacked bar chart
  scale_fill_manual(values = source_colors) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),  # Remove major grid lines
    panel.grid.minor = element_blank(),  # Remove minor grid lines
    legend.title = element_blank(),      # No legend title
    axis.text.x = element_text(angle = 90, hjust = 0, size = 22),  # Rotated x-axis labels
    axis.text.y = element_text(size = 22),  # Larger y-axis labels
    axis.title.y = element_text(size = 22), # Larger y-axis title
    text = element_text(size = 22),         # General text size
    legend.position = 'bottom',             # Position legend at bottom
    legend.text = element_text(size = 22),  # Legend text size
    strip.background = element_blank(),     # Remove strip background
    strip.placement = "outside",            # Place strip labels outside
    strip.text.x = element_text(margin = margin(t = 5, b = 5)),  # Add margin to strip text
    panel.border = element_blank(),         # Remove panel borders
    axis.line = element_line(color = "black"),  # Add axis lines
    plot.title = element_text(hjust = 0, size = 22, face = "bold"),  # Centered and bold title
    legend.spacing.x = unit(0.5, 'cm'),     # Adjust legend item spacing
    panel.spacing.y = unit(1, "lines")      # Increase spacing between facets
  ) +
  labs(
    title = "Final Energy Consumption by Sources",  # Chart title
    x = "",                                       # No x-axis label
    y = "EJ/year"                                   # y-axis label
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +
  theme(strip.placement = "inside") # Facet with free x-axis scales

print(p)


library("svglite")
ggsave(paste0("../figure/Energy/Final_Ene_Cons_source_with_ammonia_hydrogen_AIMWS.svg"), p, width = 12, height = 14, dpi = 321)

#Primary Ene

Pri_IAMC <- df %>% filter(VEMF %in% c("Prm_Ene_Bio_w_CCS", 
                                      "Prm_Ene_Bio_wo_CCS",
                                      "Prm_Ene_Coa_w_CCS", 
                                      "Prm_Ene_Coa_wo_CCS",
                                      "Prm_Ene_Oil_w_CCS", 
                                      "Prm_Ene_Oil_wo_CCS",
                                      "Prm_Ene_Gas_w_CCS", 
                                      "Prm_Ene_Gas_wo_CCS",
                                      "Prm_Ene_Nuc", 
                                      "Prm_Ene_Geo",
                                      "Prm_Ene_Hyd", 
                                      "Prm_Ene_Solar",
                                      "Prm_Ene_Win"
                                      ))
                                      
Pri_IAMC$VEMF <- as.character(Pri_IAMC$VEMF)
df4 <- Pri_IAMC %>% filter(SCENARIO %in% c("wo/NH3", "w/NH3")) %>%
  filter(YEMF %in% c("2010", "2020","2030","2040", "2050","2060","2070","2080","2090", "2100")) %>% mutate(Energy_type = case_when(
    str_detect("Prm_Ene_Bio_w_CCS", VEMF) ~ "Biomass w/CCS",
    str_detect("Prm_Ene_Bio_wo_CCS", VEMF) ~ "Biomass wo/CCS",
    str_detect("Prm_Ene_Coa_w_CCS", VEMF) ~ "Coal w/CCS",
    str_detect("Prm_Ene_Coa_wo_CCS", VEMF) ~ "Coal wo/CCS",
    str_detect("Prm_Ene_Oil_w_CCS", VEMF) ~ "Oil w/CCS",
    str_detect("Prm_Ene_Oil_wo_CCS", VEMF) ~ "Oil wo/CCS",
    str_detect("Prm_Ene_Gas_w_CCS", VEMF) ~ "Gas w/CCS",
    str_detect("Prm_Ene_Gas_wo_CCS", VEMF) ~ "Gas wo/CCS",
    str_detect("Prm_Ene_Nuc", VEMF) ~ "Nuclear",
    str_detect("Prm_Ene_Geo", VEMF) ~ "Geothermal",
    str_detect("Prm_Ene_Hyd", VEMF) ~ "Hydropower",
    str_detect("Prm_Ene_Solar", VEMF) ~ "Solar",
    str_detect("Prm_Ene_Win", VEMF) ~ "Wind"
  ))

# Create a color mapping for the energy types
energy_type_colors <- c(
  "Biomass w/CCS" = "#4E733C",    # Deep Forest Green for Biomass w/CCS
  "Biomass wo/CCS" = "#7C9D5F",   # Muted Olive Green for Biomass wo/CCS
  "Coal w/CCS" = "#4D4D4D",       # Dark Slate Gray for Coal w/CCS
  "Coal wo/CCS" = "#696969",       # Dim Gray for Coal wo/CCS
  "Oil w/CCS" = "#8B5E3C",     # Burnt Umber for Fossil w/CCS
  "Oil wo/CCS" = "#A0522D",     # Sienna for Fossil wo/CCS
  "Gas w/CCS" = "#1F78B4",         # Muted Blue for Gas w/CCS
  "Gas wo/CCS" = "#A6CEE3",        # Soft Sky Blue for Gas wo/CCS
  "Nuclear" = "#FFD700",           # Goldenrod for Nuclear
  "Geothermal" = "#D2691E",        # Earthy Saddle Brown for Geothermal
  "Hydropower" = "#6BAED6",             # Light Steel Blue for Hydro
  "Solar" = "#FDBF6F",             # Pale Golden Yellow for Solar
  "Wind" = "#B2DF8A"               # Light Green for Wind
)

df44 <- df4 %>%
  mutate(SCENARIO = case_when(
    str_detect("w/NH3", SCENARIO) ~ "With Ammonia Fuel",
    str_detect("wo/NH3", SCENARIO) ~ "Without Ammonia Fuel"))
df44$SCENARIO <- factor(df44$SCENARIO, levels = c("Without Ammonia Fuel", "With Ammonia Fuel")) 
df44$Energy_type <- factor(df44$Energy_type, levels = c("Wind", "Solar", "Hydropower", "Geothermal", 
                                                        "Nuclear", "Biomass w/CCS","Biomass wo/CCS", 
                                                        "Gas w/CCS", "Gas wo/CCS", "Oil w/CCS", 
                                                        "Oil wo/CCS", "Coal w/CCS", "Coal wo/CCS")) 

# Generate the updated plot
p <- df44 %>% 
  ggplot(aes(x = YEMF, y = IAMC_Template, fill = Energy_type)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +  # Stacked bar chart
  scale_fill_manual(values = energy_type_colors) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),  # Remove major grid lines
    panel.grid.minor = element_blank(),  # Remove minor grid lines
    legend.title = element_blank(),      # No legend title
    axis.text.x = element_text(angle = 90, hjust = 0, size = 22),  # Rotated x-axis labels
    axis.text.y = element_text(size = 22),  # Larger y-axis labels
    axis.title.y = element_text(size = 22), # Larger y-axis title
    text = element_text(size = 22),         # General text size
    legend.position = 'bottom',             # Position legend at bottom
    legend.text = element_text(size = 18),  # Legend text size
    strip.background = element_blank(),     # Remove strip background
    strip.placement = "outside",            # Place strip labels outside
    strip.text.x = element_text(margin = margin(t = 5, b = 5)),  # Add margin to strip text
    panel.border = element_blank(),         # Remove panel borders
    axis.line = element_line(color = "black"),  # Add axis lines
    plot.title = element_text(hjust = 0, size = 22, face = "bold"),  # Centered and bold title
    legend.spacing.x = unit(0.5, 'cm'),     # Adjust legend item spacing
    panel.spacing.y = unit(1, "lines")      # Increase spacing between facets
  ) +
  labs(
    title = "Primary Energy Consumption by Sources",  # Chart title
    x = "",                                       # No x-axis label
    y = "EJ/year"                                   # y-axis label
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +
  theme(strip.placement = "inside") # Facet with free x-axis scales

print(p)


library("svglite")
ggsave(paste0("../figure/Energy/Primary_Ene_Cons_source_com_wwo_amm.svg"), p, width = 12, height = 14, dpi = 321)



#Final Energy Sector

Fin_IAMC_sec <- df %>% filter(VEMF %in% c("Fin_Ene_AFO", "Fin_Ene_Res", "Fin_Ene_Com",
                                      "Fin_Ene_Tra", "Fin_Ene_Ind", "Fin_Ene_Oth_Sec
"))
Fin_IAMC_sec$VEMF <- as.character(Fin_IAMC_sec$VEMF)
df4 <- Fin_IAMC_sec %>% filter(SCENARIO %in% c("1p5c_wo/nh3", "1p5c_w/nh3")) %>%
  filter(YEMF %in% c("2010", "2020","2030","2040", "2050","2060","2070","2080","2090", "2100")) %>% mutate(Energy_type = case_when(
    str_detect("Fin_Ene_AFO", VEMF) ~ "AFOFI",
    str_detect("Fin_Ene_Res", VEMF) ~ "Residential",
    str_detect("Fin_Ene_Com", VEMF) ~ "Commercial",
    str_detect("Fin_Ene_Tra", VEMF) ~ "Transportation",
    str_detect("Fin_Ene_Ind", VEMF) ~ "Industry",
    str_detect("Fin_Ene_Oth_Sec", VEMF) ~ "Other",
  ))
# Define colors based on the provided image (approximate hex values)

source_colors <- c(
  "Transportation" = "#d32d41",
  "AFOFI" = "#6ab187",
  "Residential" = "#23282d",
  "Commercial" = "#4cb5f5",
  "Other" = "#ced2cc",
  "Industry" = "#A5D8DD"
)

library(dplyr)
library(ggplot2)

# Generate the updated plot
library(ggplot2)

# Generate the updated plot
p <- df4 %>% 
  ggplot(aes(x = YEMF, y = IAMC_Template, fill = Energy_type)) +
  geom_bar(stat = "identity", position = "stack") + # Bar chart
  scale_fill_manual(values = source_colors) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 1),
    text = element_text(size = 18),
    legend.position = 'bottom',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black")  # Add axis lines# Place strip labels outside the plot
  ) +
  labs(
    title = "Final energy consumption by sector",
    x = "",
    y = "EJ/yr"
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
  theme(panel.border = element_blank())  # Remove facet borders
# Print the plot
print(p)

ggsave(paste0("../figure/Energy//Final_Ene_Cons_sector.png"), p, width = 12, height = 10, dpi = 321)


Fin_IAMC_Hyd_sec <- df %>% filter(VEMF %in% c("Fin_Ene_Ind_Hyd", "Fin_Ene_Tra_Hyd"))
Fin_IAMC_Hyd_sec$VEMF <- as.character(Fin_IAMC_Hyd_sec$VEMF)
df5 <- Fin_IAMC_Hyd_sec %>% filter(SCENARIO %in% c("w/NH3", "wo/NH3")) %>%
  filter(YEMF %in% c("2010", "2020","2030","2040", "2050","2060","2070","2080","2090", "2100")) %>% mutate(Energy_type = case_when(
    str_detect("Fin_Ene_AFO", VEMF) ~ "AFOFI",
    str_detect("Fin_Ene_Res", VEMF) ~ "Residential",
    str_detect("Fin_Ene_Com", VEMF) ~ "Commercial",
    str_detect("Fin_Ene_Tra_Hyd", VEMF) ~ "Transportation",
    str_detect("Fin_Ene_Ind_Hyd", VEMF) ~ "Industry",
    str_detect("Fin_Ene_Oth_Sec", VEMF) ~ "Other",
  ))
# Define colors based on the provided image (approximate hex values)
df5$New_Scenario <- paste(df5$SCENARIO, df5$YEMF, sep = "_")
df6 <- df5 %>% filter(YEMF %in% c("2030", "2050", "2100"))
write.csv(df6, "../data/Final_Ene_Cons_sector.csv", sep = ",")
df7 <- read.csv("../data/Final_Ene_Cons_sector.csv")
df7$YEMF <- as.character(df7$YEMF)
df7$SCENARIO_LABEL <- factor(ifelse(df7$SCENARIO == "w/NH3", "w/NH3", "wo/NH3"),
                             levels = c("wo/NH3", "w/NH3"))  # Set the desired order

p33 <- ggplot(df7, aes(x = YEMF, y = IAMC_Template)) +
  geom_bar(aes(fill = "Total Energy Use (Hydrogen+Ammonia)"), stat = "identity", color = "black") +
  geom_bar(aes(y = NH3_use, fill = "Ammonia Contribution"), stat = "identity", color = "black") +
  labs(title = "Comparison of Energy Use in Scenarios with and without Ammonia Fuel",
       x = "", y = "Final Energy Consumption (EJ)") +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    text = element_text(size = 30),
    legend.position = 'top',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "inside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    strip.text.x = element_text(size = 22, face = "bold"),  # Larger text for Energy_type labels
    plot.title = element_text(size = 28, face = "bold", hjust = 0),  # Adjust title size and center it
    axis.title.y = element_text(size = 22)  # Adjust y-axis title size
    ) +
  scale_fill_manual(name = "Legend", values = c("Total Energy Use (Hydrogen+Ammonia)" = "#6ab187", "Ammonia Contribution" = "#d32d41")) +
  facet_grid(. ~ Energy_type + SCENARIO_LABEL, scales = "free_x", space = "free")  # Facet by Energy_type, split by SCENARIO

p33
ggsave(paste0("../figure/Energy/Final_Ene_Cons_sector_Hyd_Amm.svg"), p33, width = 20, height = 8, dpi = 321)


# Display the updated dataframe
print(df)


source_colors3 <- c(
  "Transportation" = "#d32d41",
  "Industry" = "#6ab187"
)

library(dplyr)
library(ggplot2)

# Generate the updated plot
p3 <- df5 %>% 
  ggplot(aes(x = YEMF, y = IAMC_Template, fill = Energy_type)) +
  geom_bar(stat = "identity", position = "stack") + # Bar chart
  scale_fill_manual(values = source_colors3) +  # Use filtered colors
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 1),
    text = element_text(size = 22),
    legend.position = 'bottom',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "outside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black")  # Add axis lines# Place strip labels outside the plot
  ) +
  labs(
    title = "",
    x = "",
    y = "EJ/year"
  ) +
  facet_wrap(~ SCENARIO, ncol = 2, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
  theme(panel.border = element_blank())  # Remove facet borders
# Print the plot
print(p3)

ggsave(paste0("../figure/Energy/Final_Ene_Cons_sector_Hyd.svg"), p3, width = 18, height = 10, dpi = 321)


library(patchwork)
p1 <- CO2pp1 + p 

ggsave("figure/Figure1.svg", plot = p1, width = 12, height = 6) 



