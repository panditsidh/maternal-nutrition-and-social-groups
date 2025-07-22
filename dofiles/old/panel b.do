** This do-file graphs outcomes (with bootstrapped ci) by parity


use "data/bootstrapresults_full.dta", clear

keep underweight_parity*
gen iteration = _n

reshape long underweight_parity, ///
    i(iteration) j(parity)

keep parity underweight_parity
rename underweight_parity underweight

foreach var in underweight  {
    
    preserve

    collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(parity)

    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Underweight Rate"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

    twoway (rcap ub lb parity, lcolor(black)) ///
           (scatter mean parity, msymbol(circle) mcolor(black)), ///
           xlabel(1 "Parity 1" 2 "Parity 2" 3 "Parity 3" 4 "Parity 4") ///
           ytitle("`prettyname'") ///
           xtitle("Parity") ///
           title("Pre-Pregnancy `prettyname' by Parity") ///
           graphregion(color(white)) ///
           legend(off) name(b, replace)

    graph export "figures/bootstrapped_`var'_by_parity_`round'.png", replace
	
	

    restore
}



