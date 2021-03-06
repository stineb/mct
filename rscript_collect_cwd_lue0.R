#!/usr/bin/env Rscript

## This can easily be run on the local computer after downloading data into ~/mct/data/df_cwd_lue0_2/

library(dplyr)
library(purrr)
library(tidyr)
library(magrittr)
library(multidplyr)
library(rlang)
library(lubridate)

source("R/collect_cwd_lue0_byilon.R")

## get all available cores
#ncores <- parallel::detectCores()
ncores <- 1

##------------------------------------------------------------------------
## 2. collect data from small files into a single dataframe
##------------------------------------------------------------------------
nlon <- 7200

if (ncores > 1){
  
  cl <- multidplyr::new_cluster(ncores) %>%
    multidplyr::cluster_assign(collect_cwd_lue0_byilon = collect_cwd_lue0_byilon)
  
  ## distribute to cores, making sure all data from a specific site is sent to the same core
  df <- tibble(ilon = seq(nlon)) %>%
    multidplyr::partition(cl) %>%
    dplyr::mutate(data = purrr::map( ilon,
                                    ~collect_cwd_lue0_byilon(.))) %>% 
    collect()
  
} else {
  
  ## testing
  df <- purrr::map(as.list(seq(nlon)), ~collect_cwd_lue0_byilon(.)) %>% 
    bind_rows()
  
}

## write to file
dirn <- "~/mct/data/"
filn <- paste0("df_cwd_lue0_2.RData")
path <- paste0(dirn, filn)
print(paste("Writing file:", path))
save(df, file = path)

## determine missing
vec_lon_avl <- round(unique(df$lon), digits = 3)
vec_lon_hires <- round(seq(-179.975, 179.975, by = 0.05), digits = 3)
vec_lon_missing <- vec_lon_hires[!(vec_lon_hires %in% vec_lon_avl)]
vec_ilon_missing <- (vec_lon_missing + 179.975)/0.05 + 1
save(vec_ilon_missing, file = "data/vec_ilon_missing.RData")

## run rscript_calc_cwd_lue0.R again for missing longitude bands

