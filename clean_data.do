********************************************************************************
* Author: Paul R. Organ
* Purpose: BE 887 Econometric Exercise - data cleaning
* Last Update: Oct 4, 2018
********************************************************************************
clear all
set more off
capture log close

cd "C:\Users\prorgan\Box\Classes\BE 887\Exercise"

* load data
use "data_regulation_share.dta"

********************************************************************************
* keep only relevant variables
drop name proc days cost_gni_cap gni_cap

* keep only if have values
drop if missing(code)

* rename variables
rename code expcode
rename ind_cost exp_ind_cost
rename ind_procdays exp_ind_procdays

* save for use in export merge
save "reg_costs_exp.dta", replace

* rename variables
rename expcode impcode
rename exp_ind_cost imp_ind_cost
rename exp_ind_procdays imp_ind_procdays

* save for use in import merge
save "reg_costs_imp.dta", replace

********************************************************************************
