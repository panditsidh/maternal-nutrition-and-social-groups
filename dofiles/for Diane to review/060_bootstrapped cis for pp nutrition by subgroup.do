do "$paths"

set more off 
clear all

set seed 8062011
local B = 1001 //how many times to bootstrap
local chunk_size = 50
******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

* bootstrapping loop start
forvalues iteration = 1(1)`B'{ 

di "ITERATION ", `iteration', " of ", `B'

qui {

do "$paths"
	
* every 50 iterations (chunk), save the data
if mod(`iteration', `chunk_size')==0 | `iteration'==1{
	
	* if the iteration is a multiple of 50, chunk complete & to bootstrap.dta
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
	
	* if the iteration is starting a new chunk, open a new postfile 
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

* get bootstrap sample for current iteration
use "$dataset", clear
bsample, strata(strata) cluster(psu) 

* generate weights for calculating pre-pregnancy outcomes based on bootstrap sample
qui do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"

* get prepregnancy estimates within various subgrouping variables 
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
	
		* get pre-pregnancy outcomes by subgroup (calculated using reweighting)
		foreach outcome in `outcomes' {
		
			* weight gain calculation requires (1) coefficient for monthly weight gain and (2) prepregnancy weight. this chunk gets saves (1) in a local
			if "`outcome'"=="gainhat" {			
				
				* nineweighthat: average weight of 9+ month pregnant women
				sum weight [aw=v005] if gestdur>=9 & gestdur!=. & `overvar'==`i' & preg==1
				local nineweighthat = r(mean)
				
				* coeffhat: coefficient for method 2 weight gain calculation
				preserve
				
				* per Coffey 2015 - topcode gestdur at 9 for regression
				replace gestdur = 9 if inrange(gestdur,10,11)
				reghdfe weight gestdur i.v012 i.v133 i.v218 i.urban i.v190 ///
				[aw=v005] if preg==1 & inrange(gestdur,3,9) & `overvar'==`i', ///
				absorb(v024#v006) vce(cluster v021)
				local coeffhat = _b[gestdur]
				restore
				
				
			}
			
			* other outcomes are simple means using reweighting
			else {
				
				sum `outcome' [aw=reweightingfxn] if preg==0 & dropbin!=1 & `overvar'==`i'
				local `outcome' = r(mean)
			}
		}
		
		* weight gain = 9+mopreg weight - prepregnancy weight + adjustment 
		local gainhatm2 = `nineweighthat' - `weight' + (0.5)*`coeffhat'
		
		
		* post all estimates from this iteration to the current chunk's postfile
		post `H' (`iteration') ("`overvar'") (`i') (`bmi') (`underweight') (`weight') (`overweight') (`obesity') (`gainhatm2')
		
	}
		
	}
	
}


}

use "data/bootstrap cis for pp outcomes.dta", clear
gen str overlevel = "_" + overvar + string(level)
drop overvar level

reshape wide bmi underweight weight overweight obesity gainhatm2, i(iteration) j(overlevel) string

save "data/bootstrap cis for pp outcomes.dta", replace




