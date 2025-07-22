** This do-file graphs outcomes (with bootstrapped ci) by parity



foreach overvar in parity bs wealth {
	
	
	use "data/bootstrapresults_full.dta", clear
	
	keep underweight_`overvar'*
	gen iteration = _n
	
	reshape long underweight_`overvar', i(iteration) j(`overvar')
	
	keep `overvar' underweight_`overvar'
	rename underweight_`overvar' underweight
	
	local xtitle ""
	local xlabel ""
	if "`overvar'" == "parity" {
		local xtitle "Parity"
		local xlabel `"1 "Parity 1" 2 "Parity 2" 3 "Parity 3" 4 "Parity 4""'
	}
	if "`overvar'" == "wealth" {
		local xtitle "Wealth Quartile"
		local xlabel `"1 "Quartile 1" 2 "Quartile 2" 3 "Quartile 3" 4 "Quartile 4""'
	}
	if "`overvar'" == "bs" {
		local xtitle "Birth Spacing"
		local xlabel `"1 "<2 yrs" 2 "2–3 yrs" 3 ">3 yrs""'
		
		drop if bs==9
	}
	
	preserve
	
	

    collapse (mean) mean=underweight ///
             (p5) lb=underweight ///
             (p95) ub=underweight, by(`overvar')

   
    twoway (rcap ub lb `overvar', lcolor(black)) ///
           (scatter mean `overvar', msymbol(circle) mcolor(black)), ///
           xlabel(`xlabel') ///
           ytitle("Underweight Rate") ///
           xtitle("`xtitle'") ///
           title("Pre-Pregnancy Underweight Rate by `xtitle'") ///
		   yscale(range(0 0.3) fill) ///
		   ylabel(0(0.05)0.3) ///
           graphregion(color(white)) ///
           legend(off) name(`overvar', replace)

    graph export "figures/bootstrapped_underweight_by_`overvar'_5.png", replace
	graph save "figures/`overvar'.gph", replace
	
	
    restore
	
}

