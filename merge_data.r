###############################################################################
# Author: Paul R. Organ
# Purpose: BE 887, Econometric Exercise
# Last Update: Oct 4, 2018
###############################################################################
# Preliminaries
options(stringsAsFactors = F)

# packages
require(tidyverse) # data cleaning and manipulation
require(magrittr)  # syntax
require(foreign)   # read .dta files

select = dplyr::select
setwd('C:/Users/prorgan/Box/Classes/BE 887/Exercise')

###############################################################################
# read in data
df <- read.dta('data1980s_share.dta') %>%
  rename(dist = ln_distance,
         legal = legalsystem_same,
         lang = common_lang,
         religion = religion_same)%>%
  mutate(landlock = n_landlock==2 * 1,
         island = n_islands==2 * 1)

reg <- read.dta('data_regulation_share.dta')

###############################################################################
# merge
comb <- left_join(df, reg, by=c('expcode' = 'code'))

###############################################################################
# write to dta file (write.dta)

###############################################################################