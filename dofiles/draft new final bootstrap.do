
/*


We need
* group level estimates with base reweighting
* group x decomp category level estimates with base reweighting + decomp variable



* group x cutoff level estimates with base reweighting (cutoffs are sample restrictions)
* keep in mind that I need to run bsample BEFORE running the cutoff here


*/


do "$paths"

set more off
clear all

set seed 1231231
local B = 50
local chunk_size = 10


forvalues iteration = 1(1)`B' {
	
	di "ITERATION ", `iteration', " of ", `B'	
	
	qui {
	
	
	if mod(`iteration', `chunk_size')==0 | `iteration'==1 {
		
		* chunk ending
		if `iteration'!=1 {
		
			foreach postname in grouplevel decomplevel cutofflevel {
				
				postclose ``postname''
				
				* first chunk
				if `iteration'==`chunk_size' {
					use "`postname' estimates.dta", clear
					save "`postname' estimates.dta", replace
					
				}
				
				* later chunk
				else {
					use "`postname' estimates.dta", clear
					append using ``postname''
					save "`postname' estimates.dta", replace
				}
				
			}
		
		}
		
		tempname grouplevel decomplevel cutofflevel
		
		#delimit ;
		postfile `grouplevel' 
		int			iteration
		str100		estimate_level
		int			level
		double		bmi underweight weight overweight obesity using "grouplevel estimates.dta", replace;

		postfile `decomplevel'
		int			iteration
		str100		decompvar
		int 		decompvarlevel
		int 		grouplevel
		double		underweight using "decomplevel estimates.dta", replace;

		postfile `cutofflevel'
		int			iteration
		double		cutoff
		int 		group
		double		underweight using "cutofflevel estimates.dta", replace;
		#delimit cr

		
		
		
		
	}
	

	
	
	
	use "$dataset", clear
	
	********* For the cutoff levels, we need underweight for each group. This is done first so that we can use preserve restore.
	foreach cutoff in 1 0.75 0.5 0.25 0.1 {
		
		preserve
		
		keep if pct_psu_higher<=`cutoff'
		
		replace strata=3 if strata==4
		replace strata=68 if strata==67
		
		bsample, strata(strata) cluster(psu)
		
		local binvars agebin rural less_edu noboy group
		
		do "dofiles/050 bootstrap"
		
		
		foreach group in 1 2 3 {
			
			local underweight = .
			sum underweight [aw=reweightingfxn] if preg==0 & group==`group'
			
			local underweight = r(mean)
			
			post `cutofflevel' (`iteration') (`cutoff') (`group') (`underweight')
		}
		
		restore
		
	}
	
	
	
	
	
	
	bsample, strata(strata) cluster(psu)
	
	********* For India and group level estimates, we need all outcomes. Use a different postfile.
	foreach estimate_level in india group {
		
		********* First do the reweighting.
		
		* For India level estimates, we don't need to include social group in reweighting
		if "`estimate_level'"=="india" local binvars agebin rural less_edu noboy
		else if "`estimate_level'"=="group" local binvars agebin rural less_edu noboy group
		
		do "dofiles/050 bootstrap"
		
		
		********* Now post the estimates. 
		
		levelsof `estimate_level', local(levels)
		
		foreach level in `levels' {
			
			local bmi = .
			local underweight = .
			local weight = .
			local overweight = .
			local obesity = .
			
			foreach outcome in bmi underweight weight overweight obesity {
				
				sum `outcome' [aw=reweightingfxn] if preg==0 & `estimate_level'==`level'
				local `outcome' = r(mean)
		
			}
			
			post `grouplevel' (`iteration') ("`estimate_level'") (`level') (`bmi') (`underweight') (`weight') (`overweight') (`obesity')
			
		}
		
	}	
		
	********* For the decomposition vars, we only need underweight, but at the level of the interaction with group. 	
	foreach estimate_level in wealth parity bs protein_q4 psu_od_besideshh_q4 {
		
		local binvars agebin rural less_edu noboy group `estimate_level'
		do "dofiles/050 bootstrap"
		
		levelsof `estimate_level', local(levels)
		
		foreach level in . `levels' {
			
			* get group level and interaction estimates
			foreach group of numlist 1/5 {
				
				* Get the group level estimate to check if the reweighting is stable
				if `level'==. sum underweight [aw=reweightingfxn] if preg==0 & group==`group'
				
				* Get the interaction level estimate
				else sum underweight [aw=reweightingfxn] if preg==0 & group==`group' & `estimate_level'==`level'
				
				local underweight = r(mean)
				
				post `decomplevel' (`iteration') ("`estimate_level'") (`level') (`group') (`underweight')
				
			}
		}
	}
	
	}
	
}

