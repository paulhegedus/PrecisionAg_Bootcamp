## Source File for Broyles sec35middle
##
## This script is for fitting the models used to predict yield and protein in sec35middle.
## The models are saved as an .Rdata file. This script also generated performs the 
## analysis to identify optimized N fertilizer rates.
## 
## Analysis results and output data are saved to Strategies/OFPE/Outputs/.

pc <- proc.time()

library(OFPE)
source("~/Library/CloudStorage/OneDrive-MontanaStateUniversity/BoxMigratedData/Hegedus/Technician/google_key.R")
source("~/Library/CloudStorage/OneDrive-MontanaStateUniversity/BoxMigratedData/Hegedus/Technician/difm_db_con.R")

dir.create("Strategies/OFPE")
dir.create("Strategies/OFPE/Maps")
dir.create("Strategies/OFPE/InputStrategy")

# import data and set up dat class
OFPE::removeTempTables(dbCon$db)
datClass <- DatClass$new(dbCon = dbCon,
                         farmername = "broyles",
                         fieldname = "sec35middle",
                         respvar = c("Yield", "Protein"),
                         expvar = "As-Applied Nitrogen",
                         sys_type = "Conventional",
                         yldyears = list(sec35middle = c("2020", "2018", "2016")), #
                         proyears = list(sec35middle = c("2020", "2018", "2016")), #
                         mod_grid = "Grid",
                         dat_used = "Decision Point",
                         center = TRUE,
                         split_pct = 80,
                         SI = FALSE,
                         clean_rate = 300) # 300 lbs/ac to kg/ha
invisible(datClass$setupDat())
gc()

# fit/train the models
modClass <- ModClass$new(fxn = list(yld = "RF",
                                    pro = "GAM"), 
                         fxn_path = NULL,
                         SAVE = TRUE,
                         out_path = "Strategies/OFPE/")
modClass$setupOP()
modClass$setupMod(datClass,
                  list(
                    yld = c("aspect_cos_cent", "aspect_sin_cent",
                            "slope_cent", "elev_cent", "tpi_cent",
                            "prec_cy_g", "prec_py_g", "gdd_cy_g", "gdd_py_g",
                            "ndvi_cy_l", "ndvi_py_l", "ndvi_2py_l",
                            "ndwi_cy_l", "ndwi_py_l", "ndwi_2py_l",
                            "bulkdensity_cent", "claycontent_cent", "sandcontent_cent",
                            "phw_cent", "watercontent_cent", "carboncontent_cent"),
                    pro = c("aspect_cos_cent", "aspect_sin_cent",
                            "slope_cent", "elev_cent", "tpi_cent",
                            "prec_cy_g", "prec_py_g", "gdd_cy_g", "gdd_py_g",
                            "ndvi_cy_l", "ndvi_py_l", "ndvi_2py_l",
                            "ndwi_cy_l", "ndwi_py_l", "ndwi_2py_l",
                            "bulkdensity_cent", "claycontent_cent", "sandcontent_cent",
                            "phw_cent", "watercontent_cent", "carboncontent_cent")
                  ))
invisible(modClass$fitModels())
invisible(modClass$savePlots())
gc()

# export the models as .Rdata in general folder
saveRDS(modClass, "R/sec35middle_modClass.rds")
# export the 2021 simulation data
data.table::fwrite(datClass$sim_dat$`2021`, "R/simdat_2021.csv")

# run the simulation without 2021 economic data
# generates an optimized rx map based on 2021 data up to dp but without 2021 data
simClass <- SimClass$new(dbCon = dbCon,
                         sPr = 100,
                         opt = "Ecological",
                         sim_year = 2021,
                         fs =  120, # 120 lbs/ac
                         EXPvec =  0:150, # 0 and 150 lbs/ac
                         SAVE = TRUE,
                         out_path = "Strategies/OFPE/")
econDat <- EconDat$new(ssAC = 0,
                       Prc = "Default",
                       PD = "2021")
invisible(simClass$setupSim(datClass, modClass, econDat))
simClass$executeSim()
OFPE::removeTempTables(dbCon$db) # removes temporary tables. good practice
gc()

# save all outputs
sec35middle_simOP <- list(
  dat_path = "Strategies/OFPE/Outputs/SimData/",
  unique_fieldname = "sec35middle",
  unique_fxn = "yldRF-proGAM",
  sim_years = 2021,
  opt = "ecol",
  fieldsize = 158, # 158 ac
  fs = 120, # 120 lbs/ac
  EXPvec = 0:150, # 0 and 150 lbs/ac
  expvar = "aa_n",
  farmername = "broyles",
  respvar = c("yld", "pro"),
  db = dbCon$db,
  utm_fieldname = "sec35middle",
  out_path = "Strategies/OFPE/"
)
sec35middle_simOP <- SimOP$new(input_list = sec35middle_simOP, create = TRUE, SI = FALSE)
invisible(suppressWarnings(suppressMessages(sec35middle_simOP$savePlots(TRUE))))
dbCon$disconnect()
gc()

(proc.time() - pc) / 60





