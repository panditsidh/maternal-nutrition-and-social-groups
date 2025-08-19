set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap

******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

tempname H
tempfile results

#delimit ;
postfile `H' ///
    int    iteration ///
    str20  overvar ///
    double level ///
    double bmi underweight weight overweight obesity ///
    double gainhatm2 ///
    using `results', replace ;
#delimit cr


* bootstrapping loop start
forvalues iteration = 1(1)`B'{ 
	
		
di "ITERATION ", `iteration', " of ", `B'

qui {


/*

the problem is that if your working directory somehow changes (by moving around in your file explorer) while this is running (for 2+ hours) then the code will fail because it won't be able to find these paths

the results are written to a local postfile that isn't saved until all iterations are complete - meaning if the code fails, all of that is lost

so if anyone wants to run this, I recommend them to just let it go overnight, change the following line so that your path resets at the beginning of every iteration but that won't really solve the problem

*/

* ensure working directory hasn't changed
* REPLACE THIS LINE WITH YOUR 000 PATH
qui do "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/cleaned do files - reviewed/000_paths.do"

* get bootstrap sample
use "$dataset", clear
bsample, strata(strata) cluster(psu) 

* generate weights for calculating pre-pregnancy outcomes
qui do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"

* order corresponds to the list "vars" used above
foreach overvar in allfivegroups group parity bs parity_bs wealth {

	levelsof(`overvar'), local(levels)
	
	foreach i in `levels' {
				
		local bmi = .
		local underweight = .
		local weight = .
		local overweight = .
		local obesity = .
		local nineweighthat = .
		local coeffhat = .
		
		* for allfivegroups and each social group, we want all outcomes
		* for predictor groups, we only need underweight
		if inlist("`overvar'", "allfivegroups", "group") local outcomes bmi underweight weight overweight obesity gainhat
		else local outcomes underweight		
	
		* pre-pregnancy outcomes by subgroup (calculated using reweighting)
		foreach outcome in `outcomes' {
			
			if "`outcome'"=="gainhat" {			
				* nineweighthat: average weight of 9+ month pregnant women
				sum weight [aw=v005] if gestdur>=9 & gestdur!=. & `overvar'==`i'
				local nineweighthat = r(mean)
				
				* coeffhat: coefficient for method 2 weight gain calculation of subgroup 
				reghdfe weight gestdur i.v012 i.v133 i.v218 i.urban i.v190 ///
				[aw=v005] if inrange(gestdur,3,9) & `overvar'==`i', ///
				absorb(v024#v006) vce(cluster v021)

				local coeffhat = _b[gestdur]
			}
			
			else {
				sum `outcome' [aw=reweightingfxn] if preg==0 & dropbin!=1 & `overvar'==`i'
				local `outcome' = r(mean)
			}
		}
				
		local gainhatm2 = `nineweighthat' - `weight' + (0.5)*`coeffhat'
		
		post `H' (`iteration') ("`overvar'") (`i') (`bmi') (`underweight') (`weight') (`overweight') (`obesity') (`gainhatm2')
		
	}
		
	}
}

}

postclose `H'
use `results', clear
describe
list

gen str overlevel = "_" + overvar + string(level)
drop overvar level

reshape wide bmi underweight weight overweight obesity gainhatm2, i(iteration) j(overlevel) string

save "bootstrap_new_test.dta", replace


