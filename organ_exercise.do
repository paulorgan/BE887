********************************************************************************
* Author: Paul R. Organ
* Purpose: BE 887 Econometric Exercise
* Last Update: Oct 6, 2018
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
replace reg_costs = . if missing(exp_ind_cost) | missing(imp_ind_cost)
gen reg_costs_procdays = (exp_ind_procdays + imp_ind_procdays)==2
replace reg_costs_procdays = . if missing(exp_ind_procdays) | missing(imp_ind_procdays)

save "merged_data.dta"

********************************************************************************
** Table 2, Column 1
* drop if (1) reg cost data is missing or 
* (2) exporter in 8 country list or (3) importer is Japan
* Japan = 413920
* Hong Kong = 453440
* France = 532500
* Germany = 532800
* Italy = 533800
* Netherlands = 535280
* UK = 538260
* Sweden = 557520
drop if exp_ind_cost == .
drop if imp_ind_cost == .
drop if expcode == 413920 | expcode == 453440 | expcode == 532500 | ///
expcode == 532800 | expcode == 533800 | expcode == 535280 | ///
expcode == 538260 | expcode == 557520
drop if impcode == 413920

* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

* regression
quietly probit pos_trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

margins, dydx(`vars') atmeans

********************************************************************************
** Heckman Selection Correction
set matsize 10000

local fs_vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

local ss_vars = "dist border island landlock legal lang colonial cu fta religion"

heckman ln_trade `ss_vars' i.expcode i.impcode if year==1986, ///
select(pos_trade = `fs_vars' i.expcode i.impcode) vce(cluster pair)

* this gets close, obs count still off?

********************************************************************************
** Table 2, Column 4
* predict probability of selection (z_ij)
predict psel if year==1986, xb

gen mills = exp(-.5*psel^2)/(sqrt(2*_pi)*normprob(psel))

gen z = invnormal(psel)
gen z2 = z^2
gen z3 = z^3

local vars = "dist border island landlock legal lang colonial cu fta religion mills z z2 z3"

* running regression
* fixed effects for exporter, importer, and year
* standard errors clustered at the country-pair level
quietly reg ln_trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)
estimates table, se keep(`vars') stats(N r2)

* not working

********************************************************************************
*** Alternative Specifications and Tests using data from HMR (2008)
********************************************************************************
** Santos-Silva and Tenreyro (2006) Approach
* reload merged data
clear all
use "merged_data.dta"

* replace missing ln_trade with 0, convert to levels
replace ln_trade = 0 if missing(ln_trade)
gen trade = exp(ln_trade)

* run same regression as in part 4
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

poisson trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

********************************************************************************
** Adding one to all trade flows
gen trade_plus_one = trade + 1
gen ln_trade_poorman = ln(trade_plus_one)

local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

reg ln_trade_poorman `vars' i.expcode i.impcode if year==1986, vce(cluster pair)
* distance coefficient grows in magnitude

********************************************************************************
** Fixed Effects
clear all
use "merged_data.dta"

* importer, exporter, year FE
quietly reg ln_trade fta i.expcode i.impcode
estimates table, se keep(fta)

* importer*year, exporter*year,
egen exp_year = group(expcode year)
egen imp_year = group(impcode year)

quietly reg ln_trade fta i.exp_year i.imp_year
estimates table, se keep(fta)
* estimate drops slightly

* importer*year, exporter*year, importer*exporter
set matsize 11000
quietly reg ln_trade fta i.exp_year i.imp_year i.pair
estimates table, se keep(fta)
* too many interactions

********************************************************************************
