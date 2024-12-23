library(gdxrrw)
library(ncdf4)
library(dplyr)
library(tidyr)
library(tidyverse)
library(ggpattern)
library(ggplot2)
library(ggsci)
library(ecospace)
library(maps)
library(ggplot2)
library(tidyverse)
library(reshape2)
library(scales)
library(lubridate)
library(dplyr)
library(readr)
library(stringr)
library(countrycode)


igdx("/Library/Frameworks/GAMS.framework/Versions/47/Resources/")

RYC <- rgdx.param("../Crop/analysis.gdx","RYC") %>%
  mutate_all(as.character)%>%
  rename(Scenario="i1",Scenario2="i2",Year="i3",Region="i4",Crop="i5",ISO3="i6",RY="value") %>%
  select("Scenario","Year","Crop","Region","RY") %>%
  mutate(Region = case_when(
    Region == "USA" ~ "America",
    Region == "XLM" ~ "America",
    Region == "CAN" ~ "America",
    Region == "BRA" ~ "America",
    Region == "XE25" ~ "Europe",
    Region == "XER" ~ "Europe",
    Region == "XME" ~ "Middle East",
    Region == "XNF" ~ "Africa",
    Region == "XAF" ~ "Africa",
    Region == "JPN" ~ "Asia",
    Region == "XSA" ~ "Asia",
    Region == "TUR" ~ "Asia",
    Region == "XSE" ~ "Asia",
    Region == "CHN" ~ "China",
    Region == "IND" ~ "India",
    TRUE ~ "Others"
  )) 

write_csv2(RYC, "../data/OzoneAssessment_Crop_yield.csv")


df_RYL_crop_No_amm <- RYC %>% group_by(Scenario, Year, Region) %>%
  filter(Year != "2015",
         Scenario == "SSP2_600C_CACN_DAC_NoCC") %>%
  summarize(RY_no_amm = mean(as.numeric(RY))) %>%
  mutate(RYL_no_amm =100 - RY_no_amm) %>% 
  ungroup() %>%  # Ungroup first
  select(-Scenario) 

df_RYL_crop_amm <- RYC %>% group_by(Scenario, Year, Region) %>%
  filter(Year != "2015",
         Scenario == "SSP2_600C_CACN_DAC_amm_NoCC") %>%
  summarize(RY_amm = mean(as.numeric(RY))) %>%
  mutate(RYL_amm =100 - RY_amm) %>% 
  ungroup() %>%  # Ungroup first
  select(-Scenario) 

df_RYL_crop_amm_LoAQC <- RYC %>% group_by(Scenario, Year, Region) %>%
  filter(Year != "2015",
         Scenario == "SSP2_600C_CACN_DAC_amm_LoAQC_NoCC") %>%
  summarize(RY_amm_LoAQC = mean(as.numeric(RY))) %>%
  mutate(RYL_amm_LoAQC =100 - RY_amm_LoAQC) %>% 
  ungroup() %>%  # Ungroup first
  select(-Scenario) 


# No amm - amm
df_RYL_crop_diff_re <- left_join(df_RYL_crop_No_amm, df_RYL_crop_amm) %>%
  mutate(RLY_diff = RYL_amm - RYL_no_amm) 

df_RYL_crop_diff_wrd <- left_join(df_RYL_crop_No_amm, df_RYL_crop_amm) %>% 
  group_by(Year) %>%
  summarize(RY_amm = mean(RY_amm),
            RYL_amm = mean(RYL_amm),
            RY_no_amm = mean(RY_no_amm),
            RYL_no_amm = mean(RYL_no_amm)
            ) %>%
  mutate(RLY_diff = RYL_amm - RYL_no_amm,
         Region = "World")

df_RYL_crop_diff <- full_join(df_RYL_crop_diff_wrd, df_RYL_crop_diff_re)

p_df_RYL <- ggplot(df_RYL_crop_diff, aes(x = RYL_amm, y = Region)) +
  geom_bar(aes(fill = "Ammonia Contribution"), stat = "identity") +
  geom_bar(aes(x = RYL_no_amm, fill = "Relative Yield Loss (before using Ammonia)"), stat = "identity", alpha = 0.7) + # Added alpha transparency to differentiate bars
  labs(title = "",
       x = "Relative Yield Loss (%)", y = "") +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    text = element_text(size = 20),
    legend.position = 'top',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "inside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    strip.text.x = element_text(size = 22, face = "bold"),  # Larger text for Energy_type labels
    plot.title = element_text(size = 28, face = "bold", hjust = 0),  # Adjust title size and left-align it
    plot.subtitle = element_text(size = 22, face = "italic"),  # Subtitle for context
    axis.title.y = element_text(size = 20),  # Adjust y-axis title size
    axis.text.y = element_text(size = 20),  # Larger y-axis label text
    legend.text = element_text(size = 22)  # Adjust legend text size
  ) +
  scale_fill_manual(name = "Legend", values = c("Relative Yield Loss (before using Ammonia)" = "#2e5498", 
                                                "Ammonia Contribution" = "#6ab187")) +
  scale_x_continuous(limits = c(0, 25), labels = scales::percent_format(scale = 1)) +  # Set x-axis from 0 to 100%
  facet_wrap(~ Year, ncol = 1, strip.position = "top", scales = "free_x") 

p_df_RYL
ggsave("../R/output/figure/Relative_crop_yield_loss_21Oct.svg", plot = p_df_RYL, width = 20, height = 12) 

p123 <- p5/p_df_RYL
p123

ggsave("../R/output/figure/Health_and_Relative_crop_yield_loss_21Oct.svg", plot = p123, width = 15, height = 20) 

#amm - LoAQC

df_RYL_crop_diff_re <- left_join(df_RYL_crop_amm, df_RYL_crop_amm_LoAQC) %>%
  mutate(RLY_diff = RYL_amm - RYL_amm_LoAQC) 

df_RYL_crop_diff_wrd <- left_join(df_RYL_crop_amm, df_RYL_crop_amm_LoAQC) %>% 
  group_by(Year) %>%
  summarize(RY_amm = mean(RY_amm),
            RYL_amm = mean(RYL_amm),
            RY_amm_LoAQC = mean(RY_amm_LoAQC),
            RYL_amm_LoAQC = mean(RYL_amm_LoAQC)
  ) %>%
  mutate(RLY_diff = RYL_amm - RYL_amm_LoAQC,
         Region = "World")

df_RYL_crop_diff <- full_join(df_RYL_crop_diff_wrd, df_RYL_crop_diff_re)

p_df_RYL <- ggplot(df_RYL_crop_diff, aes(x = RYL_amm_LoAQC, y = Region)) +
  geom_bar(aes(fill = "Low Air Quality"), stat = "identity") +
  geom_bar(aes(x = RYL_amm, fill = "Air Pollution Control Act"), stat = "identity") + # Added alpha transparency to differentiate bars
  labs(title = "",
       x = "Relative Yield Loss (%)", y = "") +
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_blank(),
    text = element_text(size = 20),
    legend.position = 'top',
    strip.background = element_blank(),  # Remove strip background
    strip.placement = "inside",
    panel.border = element_blank(),  # Remove facet borders
    axis.line = element_line(color = "black"),
    strip.text.x = element_text(size = 22, face = "bold"),  # Larger text for Energy_type labels
    plot.title = element_text(size = 28, face = "bold", hjust = 0),  # Adjust title size and left-align it
    plot.subtitle = element_text(size = 22, face = "italic"),  # Subtitle for context
    axis.title.y = element_text(size = 20),  # Adjust y-axis title size
    axis.text.y = element_text(size = 20),  # Larger y-axis label text
    legend.text = element_text(size = 22)  # Adjust legend text size
  ) +
  scale_fill_manual(name = "Legend", values = c("Air Pollution Control Act" = "#2e5498", 
                                                "Low Air Quality" = "red")) +
  scale_x_continuous(limits = c(0, 25), labels = scales::percent_format(scale = 1)) +  # Set x-axis from 0 to 100%
  facet_wrap(~ Year, ncol = 1, strip.position = "top", scales = "free_x") 

p_df_RYL
ggsave("../R/output/figure/Relative_crop_yield_loss_LowAQC.svg", plot = p_df_RYL, width = 20, height = 12) 

p123 <- p5/p_df_RYL
p123

ggsave("../R/output/figure/Health_and_Relative_crop_yield_loss_21Oct.svg", plot = p123, width = 15, height = 20) 





