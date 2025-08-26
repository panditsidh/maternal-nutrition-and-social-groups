** This do-file graphs outcomes (with bootstrapped ci) by parity, wealth, and birth spacing

do "$paths"
local var underweight



foreach overvar in parity bs wealth {
	
	
	use "data/results.dta", clear
	
	
	local xtitle ""
	local xlabel ""
	if "`overvar'" == "parity" {
		local xtitle "parity"
		local xlabel `"1 "Parity 1" 2 "Parity 2" 3 "Parity 3" 4 "Parity 4""'
		local title "B. Prepregnancy underweight by `xtitle'"
		local note "n=474,664 (non-pregnant women)" 
		
		keep if strpos(rows, "Parity")==1
	}
	if "`overvar'" == "wealth" {
		local xtitle "wealth quartile"
		local xlabel `"1 "Quartile 1" 2 "Quartile 2" 3 "Quartile 3" 4 "Quartile 4""'
		local title "F. Prepregnancy underweight" "by `xtitle'"
		local note "n=474,664 (non-pregnant women)" 
		
		keep if strpos(rows, "Wealth")==1
	}
	
	
	if "`overvar'" == "bs" {
		local xtitle "birth spacing"
		local title "D. Prepregnancy underweight" "by `xtitle'"
		local xlabel `"1 "<2 yrs" 2 "2–3 yrs" 3 ">3 yrs""'
		local note "n=440,732 (non-pregnant women who have at least one live birth)" 
		
		keep if inlist(_n, 11,12,13)
	}
	
	
	keep `var'_ll `var'_mean `var'_ul
	gen group = _n
	
	preserve
	use "$dataset", clear
	levelsof(`overvar'), local(levels)
	restore
	
	foreach i in `levels' {
		sum underweight_mean if group==`i'
		local outcome_`i' = r(mean)
		
		
		if inlist("`overvar'", "wealth", "parity") local text_shift = 0.2
		else local text_shift = 0.18
		
		if "`overvar'"=="bs" & `i'==3 local textpos_`i' = `i'-0.1
		else local textpos_`i' = `text_shift'+`i'
	}	
	
	
	#delimit ;
	twoway (rcap `var'_ul `var'_ll group, lcolor(black)) ///
		   (scatter `var'_mean group, msymbol(circle) mcolor(black)),
		   xlabel(`xlabel', nogrid) ///
           ytitle("Rate of pre-pregnancy underweight") ///
           xtitle("`xtitle'") ///
           title("`title'") ///
		   yscale(range(0 0.3) fill) ///
		   ylabel(0(0.05)0.3) ///
		   legend(off) name(`overvar', replace) ///
		   note("`note'", size(medsmall)) 
		   graphregion(color(white) margin(r+12))
		   text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", placement(west) size(small)) ///
		   text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", placement(west) size(small)) 
		   text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", placement(west) size(small))
		   text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", placement(west) size(small)) ; ///;
	#delimit cr

    graph export "figures/pp_underweight_by_`overvar'.png", replace
	
	if "`overvar'"=="parity" local graph b
	if "`overvar'"=="bs" local graph d
	if "`overvar'"=="wealth" local graph f
	graph save "figures/`graph'.gph", replace
	
    
	
}




