library(dplyr)
library(rbeni)
library(tidyr)
library(purrr)
library(ncdf4)
library(lubridate)
library(ggplot2)
library(readr)
library(rsofun)
library(ingestr)
library(stringr)

source("R/get_data_mct_global.R")
source("R/extract_points_filelist.R")
source("R/convert_et.R")
source("R/align_events.R")

##------------------------------------------------------------------------
## Adjust site set by hand ("sj02" or "fluxnet")
##------------------------------------------------------------------------
siteset <- "sj02"

##------------------------------------------------------------------------
## get site meta info
##------------------------------------------------------------------------
if (siteset == "sj02"){

  ## Get meta info of sites (lon, lat)
  siteinfo <- read_csv("~/data/rootingdepth/root_profiles_schenkjackson02/data/root_profiles_D50D95.csv") %>%
    dplyr::filter(Wetland == "N" & Anthropogenic == "N" & Schenk_Jackson_2002 == "YES") %>% 
    dplyr::rename(sitename = ID, lat = Latitude, lon = Longitude) %>% 
    dplyr::mutate(elv = ifelse(elv==-999, NA, elv)) %>% 
    dplyr::filter(lon!=-999 & lat!=-999) %>% 
    dplyr::mutate(year_start = 1982, year_end = 2011) %>% 
    dplyr::select(sitename, lon, lat, elv, year_start, year_end)

} else {

  siteinfo <- read_csv("~/data/FLUXNET-2015_Tier1/siteinfo_fluxnet2015_sofun+whc.csv") %>% 
    rename(sitename = mysitename) %>% 
    filter(!(classid %in% c("CRO", "WET"))) %>% 
    #filter(year_start<=2007) %>%    # xxx USE ONLY FOR LANDEVAL xxx
    mutate(date_start = lubridate::ymd(paste0(year_start, "-01-01"))) %>% 
    mutate(date_end = lubridate::ymd(paste0(year_end, "-12-31")))

}

df_grid <- siteinfo %>% 
  dplyr::select(sitename, lon, lat, elv) %>% 
  dplyr::rename(idx = sitename)

##------------------------------------------------------------------------
## Get data from global fields (WATCH-WFDEI and LandFlux)
##------------------------------------------------------------------------
## df_grid must contain columns lon, lat, elv, and idx

# ## PT-JPL
# filn <- paste0("data/df_pt_jpl_", siteset, ".Rdata")
# filn_csv <- str_replace(filn, "Rdata", "csv")
# if (!file.exists(filn)){
#   if (!file.exists(filn_csv)){
#     df_pt_jpl <- get_data_mct_global(
#       df_grid,
#       dir_et   = "~/data/landflux/et_prod/",        fil_et_pattern   = "ET_PT-SRB-PU_daily_",
#       dir_prec = "~/data/watch_wfdei/Rainf_daily/", fil_prec_pattern = "Rainf_daily_WFDEI_CRU",
#       dir_snow = "~/data/watch_wfdei/Snowf_daily/", fil_snow_pattern = "Snowf_daily_WFDEI_CRU",
#       dir_temp = "~/data/watch_wfdei/Tair_daily/",  fil_temp_pattern = "Tair_daily_WFDEI",
#       get_watch = TRUE, get_landeval = TRUE, get_alexi = FALSE,
#       year_start_watch = 1984, year_end_watch = 2007
#     )
#     save(df_pt_jpl, file = filn)
#     df_pt_jpl %>%
#       tidyr::unnest(df) %>%
#       write_csv(path = filn_csv)
#   } else {
#     df_pt_jpl <- read_csv(file = filn_csv) %>%
#       group_by(idx, lon, lat) %>%
#       tidyr::nest() %>%
#       dplyr::mutate(data = purrr::map(data, ~as_tibble(.))) %>%
#       dplyr::rename(df = data)
#   }
# } else {
#   load(filn)
#   df_pt_jpl %>%
#     tidyr::unnest(df) %>%
#     write_csv(path = paste0("data/df_pt_jpl_", siteset, ".csv"))
# }


# ## PM
# filn <- paste0("data/df_pm_mod_", siteset, ".Rdata")
# filn_csv <- str_replace(filn, "Rdata", "csv")
# if (!file.exists(filn)){
#   if (!file.exists(filn_csv)){
#     df_pm_mod <- get_data_mct_global(
#       df_grid,
#       dir_et   = "~/data/landflux/et_prod/",        fil_et_pattern   = "ET_PM-SRB-PU_daily_",
#       dir_prec = "~/data/watch_wfdei/Rainf_daily/", fil_prec_pattern = "Rainf_daily_WFDEI_CRU",
#       dir_snow = "~/data/watch_wfdei/Snowf_daily/", fil_snow_pattern = "Snowf_daily_WFDEI_CRU",
#       dir_temp = "~/data/watch_wfdei/Tair_daily/",  fil_temp_pattern = "Tair_daily_WFDEI",
#       get_watch = TRUE, get_landeval = TRUE, get_alexi = FALSE,
#       year_start_watch = 1984, year_end_watch = 2007
#     )
#     save(df_pm_mod, file = filn)
#     df_pm_mod %>%
#       tidyr::unnest(df) %>%
#       write_csv(path = filn_csv)
#   } else {
#     df_pm_mod <- read_csv(file = filn_csv) %>%
#       group_by(idx, lon, lat) %>%
#       tidyr::nest() %>%
#       dplyr::mutate(data = purrr::map(data, ~as_tibble(.))) %>%
#       dplyr::rename(df = data)
#   }
# } else {
#   load(filn)
#   df_pm_mod %>%
#     tidyr::unnest(df) %>%
#     write_csv(path = paste0("data/df_pm_mod_", siteset, ".csv"))
# }


# ## SEBS
# filn <- paste0("data/df_sebs_", siteset, ".Rdata")
# filn_csv <- str_replace(filn, "Rdata", "csv")
# if (!file.exists(filn)){
#   if (!file.exists(filn_csv)){
#     df_sebs <- get_data_mct_global(
#       df_grid,
#       dir_et   = "~/data/landflux/et_prod/",        fil_et_pattern   = "ET_SEBS-SRB-PU_daily_",
#       dir_prec = "~/data/watch_wfdei/Rainf_daily/", fil_prec_pattern = "Rainf_daily_WFDEI_CRU",
#       dir_snow = "~/data/watch_wfdei/Snowf_daily/", fil_snow_pattern = "Snowf_daily_WFDEI_CRU",
#       dir_temp = "~/data/watch_wfdei/Tair_daily/",  fil_temp_pattern = "Tair_daily_WFDEI",
#       get_watch = TRUE, get_landeval = TRUE, get_alexi = FALSE,
#       year_start_watch = 1984, year_end_watch = 2007
#     )
#     save(df_sebs, file = filn)
#     df_sebs %>%
#       tidyr::unnest(df) %>%
#       write_csv(path = filn_csv)
#   } else {
#     df_sebs <- read_csv(file = filn_csv) %>% 
#       group_by(idx, lon, lat) %>%
#       tidyr::nest() %>% 
#       dplyr::mutate(data = purrr::map(data, ~as_tibble(.)))%>% 
#       dplyr::rename(df = data)
#   }
# } else {
#   load(filn)
#   df_sebs %>%
#     tidyr::unnest(df) %>%
#     write_csv(path = paste0("data/df_sebs_", siteset, ".csv"))
# }

# ##------------------------------------------------------------------------
# ## WATCH-WFDEI and ALEXI
# ##------------------------------------------------------------------------
# filn <- paste0("data/df_alexi_", siteset, ".Rdata")
# filn_csv <- str_replace(filn, "Rdata", "csv")
# if (!file.exists(filn)){
#   if (!file.exists(filn_csv)){
#     df_alexi <- get_data_mct_global(
#       df_grid,
#       dir_et   = "~/data/alexi_tir/netcdf/",        fil_et_pattern   = "EDAY_CERES_",
#       dir_prec = "~/data/watch_wfdei/Rainf_daily/", fil_prec_pattern = "Rainf_daily_WFDEI_CRU",
#       dir_snow = "~/data/watch_wfdei/Snowf_daily/", fil_snow_pattern = "Snowf_daily_WFDEI_CRU",
#       dir_temp = "~/data/watch_wfdei/Tair_daily/",  fil_temp_pattern = "Tair_daily_WFDEI",
#       get_watch = TRUE, get_landeval = FALSE, get_alexi = TRUE,
#       year_start_watch = 2003, year_end_watch = 2018
#     )
#     save(df_alexi, file = filn)
#     df_alexi %>%
#       tidyr::unnest(df) %>%
#       write_csv(path = filn_csv)
#   } else {
#     df_alexi <- read_csv(file = filn_csv) %>%
#       group_by(idx, lon, lat) %>%
#       tidyr::nest() %>%
#       dplyr::mutate(data = purrr::map(data, ~as_tibble(.))) %>%
#       dplyr::rename(df = data)
#   }
# } else {
#   load(filn)
#   df_alexi %>%
#     tidyr::unnest(df) %>%
#     write_csv(path = paste0("data/df_alexi_", siteset, ".csv"))
# }

##------------------------------------------------------------------------
## SiF-downscaled from Duveiller
##------------------------------------------------------------------------
filn <- paste0("data/df_sif_", siteset, ".Rdata")
filn_csv <- str_replace(filn, "Rdata", "csv")
if (!file.exists(filn)){
  if (!file.exists(filn_csv)){
    df_sif <- get_data_mct_global(
      df_grid,
      dir_et   = "~/data/sif_tir/netcdf/", fil_et_pattern = "EDAY_CERES_",
      dir_prec = "~/data/watch_wfdei/Rainf_daily/", fil_prec_pattern = "Rainf_daily_WFDEI_CRU",
      dir_snow = "~/data/watch_wfdei/Snowf_daily/", fil_snow_pattern = "Snowf_daily_WFDEI_CRU",
      dir_temp = "~/data/watch_wfdei/Tair_daily/",  fil_temp_pattern = "Tair_daily_WFDEI",
      dir_sif  = "~/data/gome_2_sif_downscaled/data_orig/", fil_sif_pattern = "GOME_JJ_dcSIF_005deg_8day_",
      get_watch = FALSE, get_landeval = FALSE, get_alexi = FALSE, get_sif = TRUE
    )
    save(df_sif, file = filn)
    df_sif %>%
      tidyr::unnest(df) %>%
      write_csv(path = filn_csv)
  } else {
    df_sif <- read_csv(file = filn_csv) %>%
      group_by(idx, lon, lat) %>%
      tidyr::nest() %>%
      dplyr::mutate(data = purrr::map(data, ~as_tibble(.))) %>%
      dplyr::rename(df = data)
  }
} else {
  load(filn)
  df_sif %>%
    tidyr::unnest(df) %>%
    write_csv(path = paste0("data/df_sif_", siteset, ".csv"))
}


# ## compare
# ggplot() +
#   geom_line(data = df_pt_jpl$df[[29]], aes(x = date, y = et_mm)) +
#   geom_line(data = df_alexi$df[[70]],  aes(x = date, y = et_mm), col = 'red')
