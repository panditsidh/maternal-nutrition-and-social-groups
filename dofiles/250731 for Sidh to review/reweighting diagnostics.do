* this table gets us reweighting diagnostics

/*



rows are predictor groups

- all 
- levels of paritybs
- levels of wealth

columns are social groups
- all 
- 1-5


each column has actually 2 columns
- sample size of pregnant
- % pregnant dropped



so cols 6*2 


*/

gen all_predictors = 1


matrix results = J(15, 12, .)
local row = 1


foreach over_predictor in all_predictors parity_bs wealth {
	
	levelsof(`over_predictor'), local(predictor_levels)
	
	foreach i in `predictor_levels' {
		
		local col = 1
		foreach g of numlist 0/5 {
			
			
			if `g'==0 qui count if preg==1 & `over_predictor'==`i'
			else qui count if preg==1 & groups6==`g' & `over_predictor'==`i'
			
			matrix results[`row', `col'] = r(N)
			
			if `g'==0 qui sum dropbin if preg==1 & `over_predictor'==`i'
			else qui sum dropbin if preg==1 & groups6==`g' & `over_predictor'==`i'
			
			matrix results[`row', `col'+1] = r(mean)
			
			local col = `col'+2
		}
		
		local ++row		
	}
	
	
	
	
	
}


matrix colnames results_all = ///
	n_allgroups /// 
	pctdrop_allgroups ///
	n_group1 ///
	pctdrop_group1 ///
	n_group2 ///
	pctdrop_group2 ///
	n_group3 ///
	pctdrop_group3 ///
	n_group4 ///
	pctdrop_group4 ///
	n_group5 ///
	pctdrop_group5 ///
	