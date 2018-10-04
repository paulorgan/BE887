********************************************************************************
* Author: Paul R. Organ
* Purpose: BE 887 Econometric Exercise
* Last Update: Oct 4, 2018
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

* define landlock if BOTH countries are landocked
gen landlock = n_landlock==2

* define island if BOTH countries are islands
gen island = n_islands==2

* rename variables for use in regs
rename ln_distance dist
rename legalsystem_same legal
rename common_lang lang
rename religion_same religion

* define country pairs
gen pair = expcode + impcode

* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* running regression
* fixed effects for exporter and for importer
* standard errors clustered at the country-pair level
quietly reg ln_trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)
estimates table, se keep (`vars') stats(N r2)

********************************************************************************
** Table 1, Column 2 for 1986 (Probit)

* define indicator for country pairs with positive trade
gen pos_trade = !missing(ln_trade)

* check we get 11,146 with positive trade (footnote 21)
tab pos_trade if year==1986

* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* regression
quietly probit pos_trade `vars' i.expcode i.impcode ///
if year==1986 & expcode!=141780, vce(cluster pair)

local controls = "dist border island landlock legal lang colonial cu fta religion i.impcode i.expcode"

margins, dydx(`controls') atmeans

* coefficients for border, island, landlock, a few others are off
* look into this

********************************************************************************
** Table 1, Column 3 for 1980s panel
* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* running regression
* fixed effects for exporter, importer, and year
* standard errors clustered at the country-pair level
quietly reg ln_trade `vars' i.expcode i.impcode i.year, vce(cluster pair)
estimates table, se keep (`vars') stats(N r2)

* signs on island and landlock are flipped?

********************************************************************************
** Merge in Regulation data
* see do file 'clean_data' for small pre-cleaning steps done before this
merge m:1 expcode using reg_costs_exp
drop _merge
merge m:1 impcode using reg_costs_imp
drop _merge

* generate indicators for pairs
gen reg_costs = (exp_ind_cost + imp_ind_cost)==2
gen reg_costs_procdays = (exp_ind_procdays + imp_ind_procdays)==2

********************************************************************************
** Table 2, Column 1
* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

* regression
quietly probit pos_trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

margins, dydx(`vars') atmeans

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
