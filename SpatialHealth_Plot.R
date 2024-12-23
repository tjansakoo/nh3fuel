
library('gdxrrw')
library('tidyverse')
library(here)
library(maps)
library(ggplot2)
library(tidyverse)
library(reshape2)
library(scales)
library(lubridate)
library(readr)
library(stringr)
library(ecospace)
library(ggrepel)
library(ggpubr)



igdx("/Library/Frameworks/GAMS.framework/Versions/47/Resources/")
setwd("/Users/tjansakoo/Library/CloudStorage/OneDrive-KyotoUniversity/KUAtmos_2024/Analysis/NH3base/R") 

#Input data from GAMS (.gdx) using rgdx.param("File_Name", "Dataset in gdx file")

scenariolist <- c('1p5c_wo_ammo', '1p5c_w_ammo', '1p5c_w_ammo_LoAQC')
Yearlist <- c('2030', '2050', '2100')

  for (sce in 1:length(scenariolist)){
    for (y in 1:length(Yearlist)){
      
        names <- paste('Health_grid_SSP2_BaU_NoCC_',Yearlist[y], sep = '')
        filepath <- file.path(here(paste("../Health/",scenariolist[sce],sep='')),paste(names,".gdx",sep=""))
        dat1     <- rgdx.param(filepath, "MtMbReg17") %>% mutate(scenario = paste0(scenariolist[sce])) %>% select(-scn0)
        assign(paste("MtMbReg17", Yearlist[y],sep=''), dat1)
        rm(dat1)
      
    }
    nam <- paste("MtMbReg17_", scenariolist[sce], sep = '')
    assign(nam, Filter(function(x) is(x, "data.frame"), mget(ls())))
    rm(list=ls(all=TRUE)[sapply(mget(ls(all=TRUE)), class) == "data.frame"])
  }
  
  dat1 <- rbind_listdf(MtMbReg17_1p5c_w_ammo) 
  dat2 <- rbind_listdf(MtMbReg17_1p5c_wo_ammo)
  #dat3 <- rbind_listdf(MtMbReg17_1p5c_w_ammo) 
  dat4 <- rbind_listdf(MtMbReg17_1p5c_w_ammo_LoAQC) 
  
  Mortality_all <- bind_rows(dat1, dat4)
  Mortality <- Mortality_all %>% filter(fun == "IER" , Ch == "inCh" , quant == "med" , 
                                            mtmb == "mt", sex == 'Both', age_range == "25+") 
  
  write.csv(Mortality, file = "../R/output/csv/Mortality_NH3Base_w_and_w_LoAQC_nh3.csv", row.names = FALSE)
  
  Mortality <- read.csv("../R/output/csv/Mortality_NH3Base_ver2.csv")
  
  Mortality_IER_sum <- Mortality %>% filter(fun == "IER" , Ch == "inCh" , quant == "med" , 
                                                mtmb == "mt", sex == 'Both', age_range != "25+", age_range != "95+") 
  
  #dat_test <- Mortality_IER_sum %>% group_by(set_plt, ep, Syr, REMF, sex, quant, fun, Ch, mtmb, scenario) %>%
  #  dplyr::summarize(MtMbReg17_sum = sum(MtMbReg17))
  
  #%changing 
  
  dat11 <- rbind_listdf(MtMbReg17_Baseline) %>% mutate(MtMbReg17_Baseline = MtMbReg17)
  dat22 <- rbind_listdf(MtMbReg17_1p5c_wo_ammo) %>% mutate(MtMbReg17_1p5c_wo_ammo = MtMbReg17)
  dat33 <- rbind_listdf(MtMbReg17_1p5c_w_ammo) %>% mutate(MtMbReg17_1p5c_w_ammo = MtMbReg17)
  dat44 <- rbind_listdf(MtMbReg17_1p5c_w_ammo_LoAQC) %>% mutate(MtMbReg17_1p5c_w_ammo_LoAQC = MtMbReg17)
  
  #df.merge <- merge(dat33, dat44, by=c('set_plt', 'ep', 'Syr', 'REMF', 'sex', 'quant', 'fun', 'Ch', 'age_range', 'mtmb'), all=FALSE)
  
  df.merge <- dat33 %>%
    #merge(dat44, by = c('set_plt', 'ep', 'Syr', 'REMF', 'sex', 'quant', 'fun', 'Ch', 'age_range', 'mtmb'), all = FALSE) %>%
    #merge(dat11, by = c('set_plt', 'ep', 'Syr', 'REMF', 'sex', 'quant', 'fun', 'Ch', 'age_range', 'mtmb'), all = FALSE) %>%
    merge(dat44, by = c('set_plt', 'ep', 'Syr', 'REMF', 'sex', 'quant', 'fun', 'Ch', 'age_range', 'mtmb'), all = FALSE)
  
  df.merge <- df.merge %>% select(-contains("MtMbReg17."), -contains("scenario."))
  
  df.all <- df.merge %>% #mutate(diff_1p5c_w_amm = MtMbReg17_1p5c_w_ammo - MtMbReg17_1p5c_wo_ammo) %>%
    mutate(diff_1p5c_w_amm_LoAQC = MtMbReg17_1p5c_w_ammo_LoAQC - MtMbReg17_1p5c_w_ammo) %>%
    #mutate(re_1p5c_w_amm = ((diff_1p5c_w_amm/MtMbReg17_1p5c_wo_ammo)*100)) 
    mutate(re_1p5c_w_amm_LoAQC = (diff_1p5c_w_amm_LoAQC/MtMbReg17_1p5c_w_ammo)*100)
                          
  df.all_fil_check <- df.all %>% filter(fun != "GEMM" , Ch == "inCh" , quant == "med" , 
                                  mtmb == "mt", sex == 'Both', age_range == "25+", ep == "total") %>%
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
      TRUE ~ NA_character_
    )) 
  
  write.csv(df.all_fil_check, file = "../R/output/csv/check2.csv", row.names = FALSE)
                          
  df.all_fil <- df.all %>% filter(fun != "GEMM" , Ch == "inCh" , quant == "med" , 
                                    mtmb == "mt", sex == 'Both', age_range == "25+") %>% select(-contains("MtMbReg17"))
  
  df.re_melt <- melt(df.all_fil, id = c('set_plt', 'ep', 'Syr', 'REMF', 'sex', 'quant', 'fun', 'Ch', 'age_range', 'mtmb')) %>%
                mutate(Scenario = case_when(
                                            variable == "diff_1p5c_w_amm_LoAQC" ~ "1p5c_w/nh3_LoAQC",
                                            variable == "re_1p5c_w_amm_LoAQC" ~ "1p5c_w/nh3_LoAQC"
                                            #variable == "re_1p5c_w_amm_LoAQC" ~ "1p5c_w/nh3_LoAQC"
                                            ))
  
  df.diff <- df.re_melt %>% filter(str_detect(variable, "^diff"))
  df.re <- df.re_melt %>% filter(str_detect(variable, "^re"))
  
  
  write.csv(df.re, file = "../R/output/csv/Mortality_NH3Base_rechange_wonh3_ver2.csv", row.names = FALSE)
  write.csv(df.diff, file = "../R/output/csv/Mortality_NH3Base_diff_wonh3_ver2.csv", row.names = FALSE)
  
  #Plot
  
  df.diff <- read.csv(file = "../R/output/csv/Mortality_NH3Base_diff_wonh3.csv")
  dp1 <- df.diff %>% filter(REMF == "World", ep == "total") %>% 
    mutate(Species = case_when(set_plt == "PM2.5" ~ "PM2.5",
                               set_plt == "O3" ~ "Ozone"))
  dp1$Syr <- as.character(dp1$Syr)
  
  dp1_re <- df.re %>% filter(REMF == "World", ep == "total") %>% 
    mutate(Species = case_when(set_plt == "PM2.5" ~ "PM2.5",
                               set_plt == "O3" ~ "Ozone"))
  library(ggplot2)
  source_colors <- c(
    "PM2.5" = "#ff7c81",
    "Ozone" = "#2e5497"
  )
  
  #new_order <- c("1p5c_w/nh3", "1p5c_w/nh3_LoAQC")
  #dp1$Scenario <- as.factor(dp1$Scenario)
  #dp1$Scenario <- factor(dp1$Scenario, levels = new_order)
  
  Global <- dp1 %>% 
    mutate(mor = value/1e6) %>%
    ggplot(aes(x = Syr, y = mor, fill = Species)) +
    geom_bar(stat = "identity", position = "stack") + # Bar chart
    scale_fill_manual(values = source_colors) +  # Use filtered colors
    theme_bw() +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      legend.title = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1),
      text = element_text(size = 20),
      legend.position = 'bottom',
      strip.background = element_blank(),  # Remove strip background
      strip.placement = "outside",
      panel.border = element_blank(),  # Remove facet borders
      axis.line = element_line(color = "black"),
      legend.text=element_text(size=20),
    ) +
    labs(
      title = paste("World"),
      x = "",
      y = "Mortality change (million people)"
    ) +
    #facet_wrap(~ Scenario, ncol = 3, strip.position = "top", scales = "free_x") +  # Separate facets with free x-axis scales
    theme(panel.border = element_blank())  # Remove facet borders
  Global
    
  ggsave("../R/output/figure/World_mortality_pm25_o3.tiff", plot = Global, width = 5, height = 10) 
  
  #Regional
  dp2 <- df.diff %>%
    filter(Syr != "2015",
           Scenario == "1p5c_w/nh3_LoAQC") %>%
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
      TRUE ~ NA_character_
    )) %>%
    group_by(Syr, set_plt, Scenario, Region, ep) %>%
    summarise(
      mor = sum(value / 1e4),
    ) %>% 
    mutate(Species = case_when(set_plt == "PM2.5" ~ "PM2.5",
                               set_plt == "O3" ~ "Ozone")) %>% drop_na()

  
  dp2$Syr <- as.character(dp2$Syr)
  dp2$Scenario <- as.factor(dp2$Scenario)
  dp2$Scenario <- factor(dp2$Scenario, levels = new_order)
  
  # Define the regions and y-axis labels
  regions <- c("China", "India", "Asia", "Europe", "America", "Africa")
  y_labels <- c("Mortality change (10,000 deaths/year)", "", "", "", "Mortality change (10,000 deaths/year)", "")
  
  # Loop over the regions and create the plots
  for (i in 1:length(regions)) {
    region <- regions[i]
    y_label <- y_labels[i]
    
    plot <- dp2 %>% filter(ep == "total", Region == region) %>% 
      ggplot(aes(x = Syr, y = mor, fill = Species)) +
      geom_bar(stat = "identity", position = "stack") + # Bar chart
      scale_fill_manual(values = source_colors) +  # Use filtered colors
      theme_bw() +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1),
        text = element_text(size = 14),
        legend.position = 'bottom',
        strip.background = element_blank(),  # Remove strip background
        strip.placement = "outside",
        panel.border = element_blank(),  # Remove facet borders
        axis.line = element_line(color = "black"),
        legend.text = element_text(size = 18),
      ) +
      labs(
        title = paste(region),
        x = "",
        y = y_label
      ) +
      #facet_wrap(~Scenario, ncol = 3, strip.position = "top", scales = "free_x", labeller = label_wrap_gen(multi_line = TRUE)) +
      theme(panel.border = element_blank())  # Remove facet borders
    
    # Assign the plot to a variable named after the region
    assign(region, plot)
  }
  
 library(patchwork)
  
  p4 <- China+India+Asia+America+Africa+Europe + plot_layout(guides="collect") & theme(legend.position = 'bottom') +
    theme(legend.key.size = unit(0.5, 'cm')) +
    theme(text=element_text(size=20)) 
  p4

  ggsave("../R/output/figure/Region_mortality_pm25_o3_ver2.svg", plot = p4, width = 25, height = 15) 
  
  
  p5 <- Global + p4 + plot_layout(widths = c(25, 80)) & theme(legend.position = 'bottom') +
    theme(legend.key.size = unit(1, 'cm')) +
    theme(text=element_text(size=18))
  p5
  ggsave("../R/output/figure/Region_mortality_pm25_o3_t_LoAQC.svg", plot = p5, width = 20, height = 10) 
  
 
  
  
  