*This do file creates bootstrapped confidence intervals for estimates of maternal nutrition outcomes by social group and for the five social groups studied in the paper combined. It also creates bootstrapped confidences intervals for estimates of maternal nutrition outcomes by parity, birth spacing category, parity + birthspacing category, and wealth quartile. It takes about 5 hours to run. 

set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap


******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

* initialize results dataset and results we want from each iteration
set obs 20000

* create variables to store outcomes for all five social groups combined (0)
gen bmi0 = .
gen underweight0 = .
gen weight0 = .
gen nineweighthat0 = .
gen coeffhat0 = .
gen gainhat0 = .

* create variables by social group (1-5)
foreach g of numlist 1/5 {
	* reweighting diagnostics
	gen preg`g' = .
	gen pct_drop`g' = .
	gen bins`g' = .
	gen dropbins`g' = .
	gen pct_zero`g' = .
	gen count9plus`g' = .
	
	* outcomes by social group
	gen bmi`g' = .
	gen underweight`g' = .
	gen weight`g' = .
	gen nineweighthat`g' = .
	gen coeffhat`g' = .
	gen gainhat`g' = .
		
}

* create variables to store outcomes by predictor variables (parity, birth spacing category, parity + birthspacing category, and wealth quartile)
foreach p in 1 2 3 4 {
	
	gen underweight_parity`p' = .
}


foreach b in 1 2 3 9 {
	
	gen underweight_bs`b' = .
}


foreach pb in 1 2 3 4 5 6 7 8 9 10 {
	
	gen underweight_parity_bs`pb' = .
}


foreach w in 1 2 3 4 {
	
	gen underweight_wealth`w' = .
}


save "data/bootstrapresults_full.dta", replace

**************************** BOOTSTRAPPING LOOP ********************************

* starting point for each bootstrap iteration
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
tempfile prepared_dataset

*rural Chandigarh has only 13 observations, 2 of whom are pregnant, so we combine with urban Chandigarh
replace strata = 7 if strata==8
save `prepared_dataset'

* bootstrapping loop start
forvalues i = 1(1)`B'{ 

// * ensure working directory hasn't changed
// qui do "dofiles/cleaned do files for submission/000_paths.do"

di "ITERATION ", `i', " of ", `B'

qui {
	
use `prepared_dataset', clear


* get bootstrap sample
bsample, strata(strata) cluster(psu) 

*-------------- reweight --------------
* @DIANE: I could replace this section of the code by just calling 020

* generate bins for reweighting (within social group and parity)
egen bin = group(c_user agebin less_edu urban hasboy wealth parity_bs groups6)
gen counter=1

// binvars
// 1. contraceptive user
// 2. age bin (combining all below 19)
// 3. less education
// 4. urban
// 5. hasboy
// 6. parity + birth spacing (new)
// 7. wealth quartile

* collapse to counts at the bin level to flag bins with only pregnant women 
preserve
collapse ///
    (sum) bin_preg = preg ///
    (sum) bin_women = counter, ///
    by(bin)

* define dropbin (only pregnant women) and zerobin (only nonpregnant women) at the bin level
gen dropbin = bin_preg == bin_women & bin_women > 0
gen zerobin = bin_preg == 0 & bin_women > 0
drop if bin==.

tempfile bininfo
save `bininfo'
restore

* merge dropbin flags back to individual level data
merge m:1 bin using `bininfo', nogen

* create new weights
egen pregweight = sum(v005) if preg==1, by(bin)
egen nonpregweight = sum(v005) if preg==0, by(bin)
egen transferpreg = mean(pregweight), by(bin) 
egen transfernonpreg = mean(nonpregweight), by(bin) 
gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0


*-------------- get outcomes by social group --------------

foreach g of numlist 1/5 {
	
	******** get reweighting diagnostics ********
	
	* number of bins per social group
	distinct bin if groups6==`g'
	local bins`g' = r(ndistinct)
	
	* percent pregnant per social group
	sum preg if groups6==`g'
	local preg`g' = r(mean)
	
	
	* number of bins that need to be dropped for having only pregnant women
	distinct bin if dropbin==1
	local dropbins`g' = r(N)
	
	* percent pregnant dropped within social group
	sum dropbin if preg==1 & groups6==`g'
	local pct_drop`g' = r(mean)
	
	* percent of nonpregnant women in bins without pregnant women (reweighted to zero)
	sum zerobin if groups6==`g' & preg==0
	local pct_zero`g' = r(mean)
	
	* count of nine plus pregnant women per social group
	count if mopreg>=9 & mopreg!=. & groups6==`g'
	local count9plus`g' = r(N)
	
	
	******** get prepregnancy outcomes ********
	
	
	foreach var of varlist bmi underweight weight {
		qui sum `var' [aw=reweightingfxn] if preg==0 & groups6==`g' & dropbin!=1
		local `var'`g' = r(mean)
	}
	
	* calculate weight at 9+ mopreg
	qui sum weight [aw=v005] if mopreg>=9 & mopreg!=. & groups6==`g'
	local nineweighthat`g' = r(mean)
	
	* get beta from weight on mopreg regression
	qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if groups6==`g'& inrange(mopreg,3,9)
	local coeffhat`g' = _b[mopreg]

	

}

*-------------- get outcomes by predictors --------------

levelsof(parity), local(parity_levels)
levelsof(birth_space_cat), local(bs_levels)
levelsof(parity_bs), local(parity_bs_levels)
levelsof(wealth), local(wealth_levels)

* @DIANE, we can make this a list and calculate other outcomes, but it makes the bootstrap run slower. i just kept it as "var" to allow this functionality, but can replace with underweight if it keeps things simpler

local var underweight

* get outcomes by predictor categories
foreach p in `parity_levels' {
	
	qui sum `var' [aw=reweightingfxn] if preg==0  & dropbin!=1 & parity==`p'
	local underweight_parity`p' = r(mean)
}

foreach b in `bs_levels' {

	qui sum `var' [aw=reweightingfxn] if preg==0  & dropbin!=1 & birth_space_cat==`b'
	local underweight_bs`b' = r(mean)
}

foreach pb in `parity_bs_levels' {
	
	qui sum `var' [aw=reweightingfxn] if preg==0  & dropbin!=1 & parity_bs==`pb'
	local underweight_parity_bs`pb' = r(mean)
}

foreach w in `wealth_levels' {
	qui sum `var' [aw=reweightingfxn] if preg==0  & dropbin!=1 & wealth==`w'
	local underweight_wealth`w' = r(mean)	
}


* for all social groups: calculate outcomes of interest
foreach var of varlist bmi underweight weight {
	qui sum `var' [aw=reweightingfxn] if preg==0 & dropbin!=1
	local `var' = r(mean)
}

qui sum weight [aw=v005] if mopreg>=9 & mopreg!=.
local nineweighthat = r(mean)
	
	* get beta from weight on mopreg regression
qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if inrange(mopreg,3,9)
local coeffhat = _b[mopreg]


*-------------- add everything to the bootstrap results dataset  --------------

use "data/bootstrapresults_full.dta", clear
foreach g of numlist 1/5 {
			
	* Reweighting diagnostics
	replace preg`g'       = `preg`g''       if _n == `i'
	replace pct_drop`g'   = `pct_drop`g''   if _n == `i'
	replace bins`g'       = `bins`g''       if _n == `i'
	replace dropbins`g'   = `dropbins`g''   if _n == `i'
	replace pct_zero`g'   = `pct_zero`g''   if _n == `i'
	replace count9plus`g' = `count9plus`g'' if _n == `i'

	* Prepregnancy outcomes for non-pregnant women
	
	replace bmi`g' = `bmi`g'' if _n == `i'
	replace underweight`g' = `underweight`g'' if _n == `i'
	replace weight`g' = `weight`g'' if _n == `i'
	
	* late pregnancy weight
	replace nineweighthat`g' = `nineweighthat`g'' if _n == `i'
	
	* beta from weight on mopreg regression
	replace coeffhat`g' = `coeffhat`g'' if _n == `i'
	
	* weight gain from method 2
	replace gainhat`g' = nineweighthat`g'-weight`g'+(0.5)*coeffhat`g' if _n==`i'
}

*outcomes by predictor category


foreach p in `parity_levels' {
	replace underweight_parity`p' = `underweight_parity`p'' if _n == `i'
}

foreach b in `bs_levels' {
	replace underweight_bs`b' = `underweight_bs`b'' if _n == `i'
	
}

foreach pb in `parity_bs_levels' {
	replace underweight_parity_bs`pb' = `underweight_parity_bs`pb'' if _n == `i'

}

foreach w in `wealth_levels' {
	replace underweight_wealth`w' = `underweight_wealth`w'' if _n == `i'
}


* general outcomes
replace bmi = `bmi' if _n==`i'
replace underweight = `underweight' if _n==`i'
replace weight = `weight' if _n==`i'
replace nineweighthat = `nineweighthat' if _n==`i'
replace coeffhat = `coeffhat' if _n==`i'

replace nineweighthat = `nineweighthat' if _n == `i'
* beta from weight on mopreg regression
replace coeffhat = `coeffhat' if _n == `i'
* weight gain from method 2
replace gainhat = nineweighthat-weight+(0.5)*coeffhat if _n==`i'


save, replace

}

sum underweight_parity*
sum underweight_bs*
sum underweight*
sum bmi*
// sum weight*
sum gainhat*

sum pct_drop*
sum pct_zero*


	
} // bootstrapping loop end


* reordered groups variable for graphs
gen groups_display = 1 if groups6==4 // Adivasi
replace groups_display = 2 if groups6==3 // Dalit
// OBC is already 2
replace groups_display = 3 if groups6==2
replace groups_display = 4 if groups6==1 // Forward
replace groups_display = 5 if groups6==5 // Muslim
replace groups_display = 6 if groups6==0 // All 5 groups
