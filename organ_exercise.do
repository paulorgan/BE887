********************************************************************************
* Author: Paul R. Organ
* Purpose: BE 887 Econometric Exercise
* Last Update: Oct 17, 2018
********************************************************************************
clear all
set more off
capture log close

cd "C:\Users\prorgan\Box\Classes\BE 887\Exercise"
log using organ_exercise.log, replace

* load data
use "data\data1980s_share.dta"

********************************************************************************
*** Data Cleaning
********************************************************************************

* data cleaning for HMR Rep parts 1, 2, and 3 and Alt Specs part 3

* define landlock if we don't have two landlocked countries
gen landlock = n_landlock!=2
* define island if we don't have two island countries
gen island = n_islands!=2

* rename variables for use in regs
rename ln_distance dist
rename legalsystem_same legal
rename common_lang lang
rename religion_same religion

** create id we can use for clustering
* convert to strings
gen impcode_str = impcode
gen expcode_str = expcode
tostring impcode_str, replace
tostring expcode_str, replace

* create id for pairs (need exp-imp and imp-exp to be same, so we do conditional)
gen newid = cond(impcode_str <= expcode_str, impcode_str, expcode_str) ///
	+ cond(impcode_str >= expcode_str, impcode_str, expcode_str) 

* create pair variable we will use for clustering
egen pair = group(newid)

* drop temporary variables
drop newid impcode_str expcode_str

* define indicator for country pairs with positive trade
gen pos_trade = !missing(ln_trade)

* save data
save "data\cleaned_part1.dta", replace

********************************************************************************
* data cleaning for HMR Rep parts 4, 5, and 6, and Alt Specs parts 1 and 2

** Merge in Regulation data
* see do file 'clean_data' for small pre-cleaning steps done before this
merge m:1 expcode using "data\reg_costs_exp.dta"
drop _merge
merge m:1 impcode using "data\reg_costs_imp.dta"
drop _merge

* generate indicators for pairs
gen reg_costs = (exp_ind_cost + imp_ind_cost)==2
replace reg_costs = . if missing(exp_ind_cost) | missing(imp_ind_cost)
gen reg_costs_procdays = (exp_ind_procdays + imp_ind_procdays)==2
replace reg_costs_procdays = . if missing(exp_ind_procdays) | missing(imp_ind_procdays)

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

save "data\cleaned_part2.dta", replace

********************************************************************************
*** HMR Replication
********************************************************************************

** Replication of Table 1, Columns 1, 2, and 3

clear all
use "data\cleaned_part1.dta"

* Column 1
* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* running regression
* fixed effects for exporter and for importer
* standard errors clustered at the country-pair level
quietly reg ln_trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

* write to file for use in tex
outreg2 using "tables/t1.tex", keep(`vars') ///
 stats(coef se) dec(3) replace
 
********************************************************************************
* Column 2
* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* regression (exclude Congo)
quietly probit pos_trade `vars' i.expcode i.impcode ///
if year==1986 & expcode!=141780, vce(cluster pair)

local controls = "dist border island landlock legal lang colonial cu fta religion i.impcode i.expcode"

margins, dydx(`controls') atmeans post

* write to file for use in tex
outreg2 using "tables/t1.tex", keep(`vars') ///
 stats(coef se) dec(3) append ///
 addnote(Note: All predictors at their mean value)
 
********************************************************************************
* Column 3
* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion"

* running regression
* fixed effects for exporter, importer, and year
* standard errors clustered at the country-pair level
quietly reg ln_trade `vars' i.expcode i.impcode i.year, vce(cluster pair)

* write to file for use in tex
outreg2 using "tables/t1.tex", keep(`vars') ///
 stats(coef se) dec(3) append

********************************************************************************
** Replication of Table II, Column 1

clear all
use "data\cleaned_part2.dta"

keep if year==1986

* local to list variables for inclusion in regression
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

* regression
quietly probit pos_trade `vars' i.expcode i.impcode, vce(cluster pair)

margins, dydx(`vars') atmeans post

* write to file for use in tex
outreg2 using "tables/t2c1.tex", keep(`vars') ///
 side noparen stats(coef se) dec(3) replace ///
 addnote(Note: All predictors at their mean value)
 
********************************************************************************
** Heckman Correction Model and Table II, Column 4
set matsize 11000

local fs_vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"
local ss_vars = "dist border island landlock legal lang colonial cu fta religion"

heckman ln_trade `ss_vars' i.expcode i.impcode, ///
select(pos_trade = `fs_vars' i.expcode i.impcode) twostep mills(mills_heckman)

* write to file for use in tex
outreg2 using "tables/t2c2.tex", keep(`fs_vars') ///
 stats(coef se) dec(3) replace
 
********************************************************************************
** Table 2, Column 4
* local to list variables for inclusion in probit
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

* regression
probit pos_trade `vars' i.expcode i.impcode, vce(cluster pair)

* predict probability of selection
predict rho

* generate zhat variable
gen zhat = invnormal(rho)

* generate mills ratio
gen mills=normalden(zhat)/normal(zhat)

* generate zbar variables
gen zbar = zhat + mills
gen zbar2 = zbar^2
gen zbar3 = zbar^3

* define variables for "polynomial" regression
local vars = "dist border island landlock legal lang colonial cu fta religion mills zbar zbar2 zbar3"

* running regression
* fixed effects for exporter, importer
quietly reg ln_trade `vars' i.expcode i.impcode

* write to file for use in tex
outreg2 using "tables/t2c4.tex", keep(`vars') ///
 side noparen stats(coef se) dec(3) replace

********************************************************************************
*** Alternative Specifications and Tests
********************************************************************************

** Santos-Silva and Tenreyro (2006) Approach
clear all
use "data\cleaned_part2.dta"

* replace missing ln_trade with 0, convert to levels
replace ln_trade = 0 if missing(ln_trade)
gen trade = exp(ln_trade)

* run same regression as in part 4
local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

poisson trade `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

* write to file for use in tex
outreg2 using "tables/alt1.tex", keep(`vars') ///
 side stats(coef se) noparen dec(3) replace

********************************************************************************
** Adding one to all trade flows
gen trade_plus_one = trade + 1
gen ln_trade_poorman = ln(trade_plus_one)

local vars = "dist border island landlock legal lang colonial cu fta religion reg_costs reg_costs_procdays"

reg ln_trade_poorman `vars' i.expcode i.impcode if year==1986, vce(cluster pair)

* write to file for use in tex
outreg2 using "tables/alt2.tex", keep(`vars') ///
 side stats(coef se) noparen dec(3) replace

********************************************************************************
** Fixed Effects
clear all
use "data\cleaned_part2.dta"

set matsize 11000

* importer, exporter, year FE
quietly reghdfe ln_trade fta, a(expcode impcode) vce(r)
outreg2 using "tables/alt3.tex", keep(fta) stats(coef se) dec(3) replace ///
 addtext(Importer and Exporter FE, Y, Im*Year and Ex*Year FE, N, Importer*Exporter FE, N)

* importer*year, exporter*year,
egen exp_year = group(expcode year)
egen imp_year = group(impcode year)

quietly reghdfe ln_trade fta, a(exp_year imp_year) vce(r)
outreg2 using "tables/alt3.tex", keep(fta) stats(coef se) dec(3) append ///
 addtext(Importer and Exporter FE, N, Im*Year and Ex*Year FE, Y, Importer*Exporter FE, N)

* importer*year, exporter*year, importer*exporter
quietly reghdfe ln_trade fta, a(exp_year imp_year pair) vce(r)
outreg2 using "tables/alt3.tex", keep(fta) stats(coef se) dec(3) append ///
 addtext(Importer and Exporter FE, N, Im*Year and Ex*Year FE, Y, Importer*Exporter FE, Y)

********************************************************************************
