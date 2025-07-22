** This do-file graphs outcomes (with bootstrapped ci) by parity


use "data/bootstrapresults_full.dta", clear

keep underweight_wealth*
gen iteration = _n

reshape long underweight_wealth, ///
    i(iteration) j(wealth)

keep wealth underweight_wealth
rename underweight_wealth underweight



foreach var in underweight  {
    
    preserve

    
	collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(wealth)
	
	
    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Underweight Rate"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

    twoway (rcap ub lb wealth, lcolor(black)) ///
           (scatter mean wealth, msymbol(circle) mcolor(black)), ///
           xlabel(1 "Quartile 1" 2 "Quartile 2" 3 "Quartile 3" 4 "Quartile 4") ///
           ytitle("`prettyname'") ///
           xtitle("Wealth quartile") ///
           title("Pre-Pregnancy `prettyname' by wealth quartile") ///
           graphregion(color(white)) ///
           legend(off) name(f, replace) 

    graph export "figures/bootstrapped_`var'_by_wealth_`round'.png", replace
	
	

    restore
}



