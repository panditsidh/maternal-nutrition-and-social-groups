do "$paths"

set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap
local chunk_size = 50
******************* PREPARING BOOTSTRAP RESULTS DATASET ************************





* bootstrapping loop start
forvalues iteration = 1(1)`B'{ 

di "ITERATION ", `iteration', " of ", `B'

qui {

do "$paths"
	
* every 50 iterations, save the data
if mod(`iteration', `chunk_size')==0 | `iteration'==1{
	
	
	if `iteration'!=1 {
		
		
		postclose `H'
		
		* first "chunk": create the results file
		if `iteration'==`chunk_size' {
			use `results', clear
			save "data/bootstrap cis for pp outcomes.dta", replace
			
		}
		
		* all later chunks: append to the results file
		else {
			use "data/bootstrap cis for pp outcomes.dta", clear
			append using `results'
			save "data/bootstrap cis for pp outcomes.dta", replace
		}
		
		
	}
	
	* start new postfile
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
}	

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


gen str overlevel = "_" + overvar + string(level)
drop overvar level

reshape wide bmi underweight weight overweight obesity gainhatm2, i(iteration) j(overlevel) string

save "data/bootstrap cis for pp outcomes.dta", replace




