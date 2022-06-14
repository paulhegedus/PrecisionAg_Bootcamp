## Create prescription from Optimized Rates
##
## This script takes the simulation output data from the optimized OFPE framework 
## and creates a prescription shapefile that is compared against student generated
## prescriptions.
## 
## The resulting shapefile is saved to Strategies/OFPE/InputStrategy/.

library(tidyverse)
library(sf)
library(data.table)

## gather the simulation exported data and save the prescription as shapefile
NRopt_sim <- data.table::fread("Strategies/OFPE/Outputs/SimData/2021/sec35middle_NRopt_yldRF-proGAM_2021_ecol.csv")
NRopt_21 <- data.table::fread("Strategies/OFPE/Outputs/SimData/2021/sec35middle_NRopt_yldRF-proGAM_SimYr2021EconCond_ecol.csv")

## check what years were in the simulation
OFPE::MT_Organic_vs_Conv_wheat_N_prices[
  OFPE::MT_Organic_vs_Conv_wheat_N_prices$conv %in% unique(NRopt_sim$BaseP), 
  "Year"
] %>% 
  as.numeric() %>% 
  unique()
# 2000 - 2020

## compare economic parameters between mean of NRopt_sim and NRopt_21
data.frame(
  mean_BP_sim = mean(NRopt_sim$BaseP),
  BP_21 = mean(NRopt_21$BaseP),
  mean_EXP_sim = mean(NRopt_sim$EXP.cost),
  EXP_21 = mean(NRopt_21$EXP.cost)
)
# Mean Bp from sim was almost $5.25 less than Bp from 2021. 
# The mean cost of N from sim is about 10 cents higher than as 2021.

## isolate the prescription rates, the cell_id, and geometry columns
opt_rx <- NRopt_sim[, c("x", "y", "row", "col", "EXP.rate.ssopt")] %>% 
  aggregate(list(.$x, .$y, .$row, .$col), mean) %>% 
  .[, names(.)[!names(.) %in% names(.)[grep("Group", names(.))]]] %>% 
  sf::st_as_sf(coords = c("x", "y"), crs = 32612) 

## rename column for optimized rates
names(opt_rx)[grep("EXP.rate.ssopt", names(opt_rx))] <- "opt_N"

## export to ...
sf::st_write(opt_rx, "Strategies/OFPE/InputStrategy/OFPE_opt_rx.shp", append = FALSE)







