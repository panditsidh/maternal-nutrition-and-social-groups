set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap

******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

set obs 20000

* for every bootstrap iteration, these are the things we want to record
#delimit ;
local vars 
preg  			// percent pregnant in subgroup
pct_drop		// percent pregnant women dropped in reweighting in subgroup
bins			// number of reweighting bins in subgroup
dropbins		// number of reweighting bins with only pregnant women in subgroup
pct_zero		// number of reweighting bins with only non-pregnant women in subgroup
count9plus		// number of 9+ mo pregnant women in subgroup (for weight gain calculation)
bmi 			// average pre-pregnancy bmi of subgroup (calculated using reweighting)
underweight		// average pre-pregnancy underweight of subgroup (calculated using reweighting)
weight 			// average pre-pregnancy weight of subgroup (calculated using reweighting)
overweight		// average pre-pregnancy overweight of subgroup (calculated using reweighting)
obesity			// average pre-pregnancy obesity of subgroup (calculated using reweighting)
nineweighthat	// average weight of 9+ month pregnant 
coeffhat 		// coefficient for method 2 weight gain calculation of subgroup
gainhatm2;		// method 2 weight gain of subgroup
#delimit cr


* initialize variables to later store these variables for all subgroups
foreach overvar in allfivegroups group parity bs parity_bs wealth {
	
	
	preserve
	
	use "$dataset", clear
	levelsof(`overvar'), local(levels)
	
	restore
	
	foreach i in `levels' {
			
		foreach var in `vars' {
				
			gen `var'_`overvar'`i' = .
		}
	}
}


save "data/bootstrapresults_test.dta", replace

**************************** BOOTSTRAPPING LOOP ********************************

* bootstrapping loop start
forvalues iteration = 1(1)`B'{ 
	
	
di "ITERATION ", `iteration', " of ", `B'


* ensure working directory hasn't changed
qui do "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/cleaned do files - reviewed/000_paths.do"

* get bootstrap sample
use "$dataset", clear
bsample, strata(strata) cluster(psu) 

* generate weights for calculating pre-pregnancy outcomes
qui do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"




*-------------- get reweghting diagnostics and outcomes by subgroups --------------

* order corresponds to the list "vars" used above
foreach overvar in allfivegroups group parity bs parity_bs wealth {
	
	levelsof(`overvar'), local(levels)
	
	foreach i in `levels' {
		
		qui {
		
		* preg: percent pregnant in subgroup
		sum preg if `overvar'==`i'
		local preg_`overvar'`i' = r(mean)
		
		* pct_drop: percent pregnant women dropped in reweighting in subgroup
		sum dropbin if preg==1 & `overvar'==`i'
		local pct_drop_`overvar'`i' = r(mean)
		
		* bins: number of reweighting bins in subgroup
		distinct bin if `overvar'==`i'
		local bins_`overvar'`i' = r(ndistinct)
		
		* dropbins: number of reweighting bins with only pregnant women in subgroup
		distinct bin if dropbin==1 & `overvar'==`i'
		local dropbins_`overvar'`i' = r(ndistinct)
		
		* pct_zero: number of reweighting bins with only non-pregnant women in subgroup
		sum zerobin if preg==0 & `overvar'==`i'
		local pct_zero_`overvar'`i' = r(mean)
		
		* count9plus: number of 9+ mo pregnant women in subgroup (for weight gain calculation)
		count if gestdur>=9 & gestdur!=. & `overvar'==`i'
		local count9plus_`overvar'`i' = r(N)
		
		* bmi, underweight, weight, overweight, obesity - pre-pregnancy outcomes by subgroup (calculated using reweighting)
		foreach outcome of varlist bmi underweight weight overweight obesity {
			sum `outcome' [aw=reweightingfxn] if preg==0 & dropbin!=1 & `overvar'==`i'
			local `outcome'_`overvar'`i' = r(mean)
		}
		
		* nineweighthat: average weight of 9+ month pregnant women
		sum weight [aw=v005] if gestdur>=9 & gestdur!=. & `overvar'==`i'
		local nineweighthat_`overvar'`i' = r(mean)
		
		* coeffhat: coefficient for method 2 weight gain calculation of subgroup 
		reg weight gestdur i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if inrange(gestdur,3,9) & `overvar'==`i'
		local coeffhat_`overvar'`i' = _b[gestdur]
		
		}
		
	}
}

*-------------- add everything to the bootstrap results dataset  --------------

use "data/bootstrapresults_test.dta", clear


foreach overvar in allfivegroups group parity bs parity_bs wealth {
	
	preserve
	
	use "$dataset", clear
	levelsof(`overvar'), local(levels)
	
	restore
	
	foreach i in `levels' {
		
		foreach var in `vars' {
			
			if !inlist("`var'", "gainhatm1", "gainhatm2") qui replace `var'_`overvar'`i' = ``var'_`overvar'`i'' if _n == `iteration'
			
			* method 2 weight gain calculation
			else if "`var'"=="gainhatm2" qui replace gainhatm2_`overvar'`i' = nineweighthat_`overvar'`i' - weight_`overvar'`i' + (0.5)*coeffhat_`overvar'`i' if _n==`iteration'
		}
		
	}
	
}

save, replace
	
}
