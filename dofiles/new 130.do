



local overvars wealth parity_bs psu_od_besideshh_q4 protein_q4 pct_psu_higher_bins allgroups


capture postclose handle

tempfile results

postfile handle /// 
str100 overvar /// 
str100 level /// 
double n_allgroups /// 
double pctdrop_allgroups ///
double n_adivasi ///
double pctdrop_adivasi ///
double n_dalit ///
double pctdrop_dalit ///
double n_obc ///
double pctdrop_obc ///
double n_forward ///
double pctdrop_forward ///
double n_muslim ///
double pctdrop_muslim ///
using `results', replace



foreach overvar in `overvars' {
	
	
	*----------------------------------------------------
    * Do the reweighting
    *----------------------------------------------------
	
	qui  {
		
		use "$dataset", clear
		gen allgroups = 1

		local overvar parity_bs
		local binvars agebin rural less_edu noboy group `overvar'

		drop if missing(preg)

		egen bin = group(`binvars')
		gen counter=1

		preserve
		collapse ///
			(sum) bin_preg = preg ///
			(sum) bin_women = counter, ///
			by(bin)

		gen dropbin = bin_preg == bin_women & bin_women > 0
		gen zerobin = bin_preg == 0 & bin_women > 0
		drop if bin==.

		tempfile bininfo
		save `bininfo'
		restore

		merge m:1 bin using `bininfo', nogen

		egen pregweight = sum(v005) if preg==1, by(bin)
		egen nonpregweight = sum(v005) if preg==0, by(bin)
		egen transferpreg = mean(pregweight), by(bin)
		egen transfernonpreg = mean(nonpregweight), by(bin)
		gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0

	}
	
	
	levelsof `overvar', local(levels)
	
	foreach level in `levels' {
		
		
		*----------------------------------------------------
        * Dynamic row label
        *----------------------------------------------------
        
		if "`overvar'" == "allgroups" {
			local overlabel "Overall"
			local overlevel ""
		}
		
		else {
			* Variable label
			local overlabel : variable label `overvar'

			* If variable has no label, fall back to variable name
			if `"`overlabel'"' == "" {
				local overlabel "`overvar'"
			}

			* Value label name attached to overvar
			local vallab : value label `overvar'

			* Level label
			if "`vallab'" != "" {
				local overlevel : label `vallab' `level'
			}
			else {
				local overlevel "`level'"
			}

			* Clean up empty level labels just in case
			if `"`overlevel'"' == "" {
				local overlevel "`level'"
			}
		}
		
		
		*----------------------------------------------------
        * Get the estimates
        *----------------------------------------------------
		
		foreach g of numlist 0/5 {
			
			if `g'==0 qui count if preg==1 & `overvar'==`level'
			else qui count if preg==1 & group==`g' & `overvar'==`level'
			
			local n_group`g' = r(N)
			
			
			if `g'==0 qui sum dropbin if preg==1 & `overvar'==`level'
			else qui sum dropbin if preg==1 & group==`g' & `overvar'==`level'
			
			local pctdrop_group`g' = round(r(mean)*100, .01)
			
			
		}
		
		
		*----------------------------------------------------
        * Post them to results file
        *----------------------------------------------------
		
		
		if "`overvar'"=="pct_psu_higher_bins" {
			
			local n_group4 = .
			local n_group5 = .
			local pctdrop_group4 = .
			local pctdrop_group5 = . 
		}
		
		post handle ///
		(`"`overlabel'"') (`"`overlevel'"') ///
		(`n_group0') (`pctdrop_group0') ///
		(`n_group1') (`pctdrop_group1') ///
		(`n_group2') (`pctdrop_group2') ///
		(`n_group3') (`pctdrop_group3') ///
		(`n_group4') (`pctdrop_group4') ///
		(`n_group5') (`pctdrop_group5')
		
		
		
	}
	
}

postclose handle


use `results', clear
