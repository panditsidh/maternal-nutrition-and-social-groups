set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap

/*
	
every bootstrap iteration: 

what bins have no pregnant women in them

- reweight again
- get % pregnant women within each reweighting group
- get # dropped bins per reweighting group 
- get % of pregnant women dropped within reweighting group

- get outcomes (bmi, underweight, weight)

- get 9/10 month pregnant women weights

- get mopreg beta from regression of weight on mopreg, age, edu, # living children, wealth index, state/month interaction (sample, mopreg 3-9)

*/

* clear results dataset and initialize results variables we want from each iteration
set obs 20000

gen bmi = .
gen underweight = .
gen weight = .
gen nineweighthat = .
gen coeffhat = .
gen gainhat = .

foreach g of numlist 1/5 {
	* reweighting diagnostics
	gen preg`g' = .
	gen pct_drop`g' = .
	gen bins`g' = .
	gen dropbins`g' = .
	gen pct_zero`g' = .
	gen count9plus`g' = .
	
	* outcomes
	gen bmi`g' = .
	gen underweight`g' = .
	gen weight`g' = .
	gen nineweighthat`g' = .
	gen coeffhat`g' = .
	gen gainhat`g' = .
	
	

}

save "data/bootstrapresults_full.dta", replace


* starting point for each bootstrap iteration
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
tempfile prepared_dataset
replace strata = 7 if strata==8
save `prepared_dataset'

* bootstrapping loop start
forvalues i = 1(1)`B'{ 
	
qui do "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/paths.do"

di "ITERATION ", `i', " of ", `B'

qui {
	
use `prepared_dataset', clear
	
// 	* testing code
// 	qui do "dofiles/assemble data/00_assemble prepreg sample.do"
// // 	qui do "dofiles/assemble data/prepare nfhs3 data.do"
// 	replace strata = 7 if strata==8
// 	local i = 1
// 	* testing code

* get bootstrap sample
bsample, strata(strata) cluster(psu) 

* generate bins for reweighting (within social group and parity)
egen bin = group(c_user agebin less_edu urban hasboy parity_bs wealth groups6)
gen counter=1


preserve
collapse ///
    (sum) bin_preg = preg ///
    (sum) bin_women = counter, ///
    by(bin)

* Step 3: define dropbin and zerobin at the bin level
gen dropbin = bin_preg == bin_women & bin_women > 0
gen zerobin = bin_preg == 0 & bin_women > 0
drop if bin==.

tempfile bininfo
save `bininfo'
restore

* Step 4: merge back to full data
merge m:1 bin using `bininfo', nogen

* create new weights
egen pregweight = sum(v005) if preg==1, by(bin)
egen nonpregweight = sum(v005) if preg==0, by(bin)
egen transferpreg = mean(pregweight), by(bin) // should assign to everyone
egen transfernonpreg = mean(nonpregweight), by(bin) // should assign to everyone
* the first four are bin level characteristics


gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0




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


* get general outcomes
foreach var of varlist bmi underweight weight {
	qui sum `var' [aw=reweightingfxn] if preg==0 & dropbin!=1
	local `var' = r(mean)
}

qui sum weight [aw=v005] if mopreg>=9 & mopreg!=.
local nineweighthat = r(mean)
	
	* get beta from weight on mopreg regression
qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if inrange(mopreg,3,9)
local coeffhat = _b[mopreg]


******** add everything to the bootstrap results file ********

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



sum bmi*
sum underweight*
sum weight*
sum gainhat*

sum pct_drop*
sum pct_zero*
	
} // bootstrapping loop end

