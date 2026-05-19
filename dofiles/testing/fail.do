/*




This creates a results file


estimate_level     interaction_level	bmi_mean	bmi_ll		bmi_ul		underweight_mean	underweight_ll		underweight_ul

india				.						x			ll			ul			x					ll					ul
group				.						x			ll			ul			x					ll					ul
wealth				.						.			.			.			x					ll					ul
wealth				1						.			.			.			x					ll					ul
wealth				2						.			.			.			x					ll					ul


*/





*============================================================
* 2. Group-level CIs
*============================================================




foreach estimate_level in india group wealth parity bs protein_q4 psu_od_besideshh_q4 cutoff {
	
	if inlist("`estimate_level'", "india", "group") {
		local outcomes bmi underweight weight overweight obesity
		local interaction india
		
		if "`estimate_level'"=="india" local binvars agebin rural less_edu noboy
		else if "`estimate_level'"=="group" local binvars agebin rural less_edu noboy group
 
	}
	else {
		local outcomes underweight
		local interaction group
		local binvars agebin rural less_edu noboy group `estimate_level'
	}
	
	

	if "`estimate_level'"=="cutoff" local levels 1 0.75 0.5 0.25 0.1 
	else levelsof `estimate_level',  local(levels)
	
	levelsof `interaction', local(interaction_levels)
	
	
	foreach level in `levels' {
	
		
		foreach interaction_level in `interaction_levels' {
			
			
			foreach outcome in `outcomes' {
				
				use "$dataset", clear
				
				
				if inlist("`estimate_level'", "cutoff") {
					
					keep if pct_psu_higher <= `level'
     
					replace strata = 3  if strata == 4
					replace strata = 68 if strata == 67		
					sum `outcome' if preg==0 & `interaction'==`interaction_level' [aw=reweightingfxn]
				}
				
				else {
					qui do "dofiles/050_weights to estimate pp nutrition.do"
					sum `outcome' if `estimate_level'==`level' & preg==0 & `interaction'==`interaction_level' [aw=reweightingfxn]
				}
				
				
				
				
				local `outcome'_mean = r(mean)
				
				
				
				preserve
	
				if inlist("`estimate_level'", "india", "group") {
					use "data/results/bootstrap_grouplevel_all.dta", clear 
					_pctile `outcome' if estimate_level==`estimate_level' & level==`level', p(2.5 97.5)	
				}
				
				else if inlist("`estimate_level'", "cutoff") {
					use "data/results/bootstrap_cutofflevel_all.dta", clear
					_pctile `outcome' if cutoff==`level' & group==`interaction_level', p(2.5 97.5)
				} 
				
				else {
					use "data/results/bootstrap_decomplevel_all", clear
					_pctile `outcome' if decompvar==`estimate_level' & decompvarlevel==`level' & grouplevel==`interaction_level', p(2.5 97.5)
				}
				
				local `outcome'_ll = r(r1)
				local `outcome'_ul = r(r2)
				
				
				restore
				
			}
		
		}
		
		#delimit ;
		post ("`estimate_level'") (`level') (.) 
		(`bmi_mean') (`bmi_ll') (`bmi_ul')
		(`underweight_mean') (`underweight_ll') (`underweight_ul')
		(`weight_mean') (`weight_ll') (`weight_ul')
		(`overweight_mean') (`overweight_ll') (`overweight_ul')
		(`obesity_mean') (`obesity_ll') (`obesity_ul');
		#delimit cr
		
	}	
	
	
}
