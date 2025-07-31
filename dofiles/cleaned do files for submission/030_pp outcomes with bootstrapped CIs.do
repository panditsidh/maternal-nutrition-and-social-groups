* this do file takes about 5 hours to run, uses bootstrapping to estimate pre-pregnancy outcomes by social group, predictors, and for all India with confidence intervals

set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap


******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

* initialize results dataset and results we want from each iteration
set obs 20000

* create variables to store outcomes for all social groups (0)
gen bmi_allfivegroups1 = .
gen underweight_allfivegroups1 = .
gen weight_allfivegroups1 = .
gen nineweighthat_allfivegroups1 = .
gen coeffhat_allfivegroups1 = .
gen gainhat_allfivegroups1 = .

* create variables by social group (1-5)
foreach g of numlist 1/5 {
	* reweighting diagnostics
	gen preg_group`g' = .
	gen pct_drop_group`g' = .
	gen bins_group`g' = .
	gen dropbins_group`g' = .
	gen pct_zero_group`g' = .
	gen count9plus_group`g' = .
	
	* outcomes by social group
	gen bmi_group`g' = .
	gen underweight_group`g' = .
	gen weight_group`g' = .
	gen nineweighthat_group`g' = .
	gen coeffhat_group`g' = .
	gen gainhat_group`g' = .
	
}

* create variables to store outcomes by predictor variables

foreach overvar in parity bs parity_bs wealth {
	
	if "`overvar'"=="parity" local levels 1 2 3 4
	if "`overvar'"=="bs" local levels 1 2 3
	if "`overvar'"=="parity_bs" local levels 1 2 3 4 5 6 7 8 9 10
	if "`overvar'"=="wealth" local levels 1 2 3 4 
	
	foreach outcome in underweight bmi weight nineweighthat coeffhat gainhat {
		
		foreach i in `levels' {
			
			gen `outcome'_`overvar'`i' = .
		}
	}
}







save "data/bootstrapresults_full.dta", replace

**************************** BOOTSTRAPPING LOOP ********************************

* starting point for each bootstrap iteration
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
tempfile prepared_dataset
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
egen bin = group(c_user agebin less_edu urban hasboy wealth parity_bs group)
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
	distinct bin if group==`g'
	local bins`g' = r(ndistinct)
	
	* percent pregnant per social group
	sum preg if group==`g'
	local preg`g' = r(mean)
	
	
	* number of bins that need to be dropped for having only pregnant women
	distinct bin if dropbin==1
	local dropbins`g' = r(N)
	
	* percent pregnant dropped within social group
	sum dropbin if preg==1 & group==`g'
	local pct_drop`g' = r(mean)
	
	* percent of nonpregnant women in bins without pregnant women (reweighted to zero)
	sum zerobin if group==`g' & preg==0
	local pct_zero`g' = r(mean)
	
	* count of nine plus pregnant women per social group
	count if mopreg>=9 & mopreg!=. & group==`g'
	local count9plus`g' = r(N)
	
	
	******** get prepregnancy outcomes ********
	
	
	foreach var of varlist bmi underweight weight {
		qui sum `var' [aw=reweightingfxn] if preg==0 & group==`g' & dropbin!=1
		local `var'`g' = r(mean)
	}
	
	* calculate weight at 9+ mopreg
	qui sum weight [aw=v005] if mopreg>=9 & mopreg!=. & group==`g'
	local nineweighthat`g' = r(mean)
	
	* get beta from weight on mopreg regression
	qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if group==`g'& inrange(mopreg,3,9)
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
	replace preg_group`g'       = `preg`g''       if _n == `i'
	replace pct_drop_group`g'   = `pct_drop`g''   if _n == `i'
	replace bins_group`g'       = `bins`g''       if _n == `i'
	replace dropbins_group`g'   = `dropbins`g''   if _n == `i'
	replace pct_zero_group`g'   = `pct_zero`g''   if _n == `i'
	replace count9plus_group`g' = `count9plus`g'' if _n == `i'

	* Prepregnancy outcomes for non-pregnant women
	
	replace bmi_group`g' = `bmi`g'' if _n == `i'
	replace underweight_group`g' = `underweight`g'' if _n == `i'
	replace weight_group`g' = `weight`g'' if _n == `i'
	
	* late pregnancy weight
	replace nineweighthat_group`g' = `nineweighthat`g'' if _n == `i'
	
	* beta from weight on mopreg regression
	replace coeffhat_group`g' = `coeffhat`g'' if _n == `i'
	
	* weight gain from method 2
	replace gainhat_group`g' = nineweighthat_group`g'-weight_group`g'+(0.5)*coeffhat_group`g' if _n==`i'
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
replace bmi_allfivegroups1 = `bmi' if _n==`i'
replace underweight_allfivegroups1 = `underweight' if _n==`i'
replace weight_allfivegroups1 = `weight' if _n==`i'
replace nineweighthat_allfivegroups1 = `nineweighthat' if _n==`i'
replace coeffhat_allfivegroups1 = `coeffhat' if _n==`i'

replace nineweighthat_allfivegroups1 = `nineweighthat' if _n == `i'
* beta from weight on mopreg regression
replace coeffhat_allfivegroups1 = `coeffhat' if _n == `i'
* weight gain from method 2
replace gainhat_allfivegroups1 = nineweighthat_allfivegroups1-weight_allfivegroups1+(0.5)*coeffhat_allfivegroups1 if _n==`i'


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


