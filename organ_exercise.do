********************************************************************************
* Author: Paul R. Organ
* Purpose: BE 887 Econometric Exercise
* Last Update: Sept 20, 2018
********************************************************************************
clear all
set more off
capture log close

cd "C:\Users\prorgan\Box\Classes\BE 887\Exercise"
log using organ_exercise.log, replace

* load data
use "data1980s_share.dta"

********************************************************************************
*** Replication of Helpman, Melitz, and Rubenstein (2008)
********************************************************************************
** Table 1, Column 1 for 1986

* defining landlocked if BOTH countries are landocked
gen landlock = n_landlock==2

* defining island if BOTH countries are islands
gen island = n_islands==2

* rename variables for use in regs
rename ln_distance dist
rename legalsystem_same legal
rename common_lang lang
rename religion_same religion

* define country pairs
gen pair = expcode + impcode

local vars = "dist border island landlock legal lang colonial cu fta religion"

* running regression (cluster ses at country pair)
xtset year
quietly xtreg ln_trade `vars' ///
i.expcode i.impcode if year==1986, fe vce(robust)
estimates table, se keep (`vars')
* coefficients are right, but need to figue out clustering SEs
* table says they cluster at the country-pair level

********************************************************************************
** Table 1, Column 2 for 1986 (Probit)

* indicator for country pair with positive trade

* regression

* marginal effects

********************************************************************************
** Table 1, Column 3 for 1980s panel

********************************************************************************
** Merge in Regulation data

********************************************************************************
** Table 2, Column 1

********************************************************************************
** Heckman Selection Correction

********************************************************************************
** Table 2, Column 4


********************************************************************************
*** Alternative Specifications and Tests using data from HMR (2008)
********************************************************************************
** Santos-Silva and Tenreyro (2006) Approach

********************************************************************************
** Adding one to all trade flows

********************************************************************************
** Fixed Effects

********************************************************************************
