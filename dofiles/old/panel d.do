** This do-file graphs outcomes (with bootstrapped ci) by parity


use "data/bootstrapresults_full.dta", clear

keep underweight_bs*
gen iteration = _n

reshape long underweight_bs, ///
    i(iteration) j(bs)

keep bs underweight_bs
rename underweight_bs underweight



foreach var in underweight  {
    
    preserve

    
	collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(bs)
	
	drop if bs==9
	
    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Underweight Rate"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

    twoway (rcap ub lb bs, lcolor(black)) ///
           (scatter mean bs, msymbol(circle) mcolor(black)), ///
           xlabel(1 "<2 yrs" 2 "2-3 yrs" 3 ">3 yrs") ///
           ytitle("`prettyname'") ///
           xtitle("Birth Spacing") ///
           title("Pre-Pregnancy `prettyname' by birth spacing") ///
           graphregion(color(white)) ///
           legend(off) name(d, replace) 

    graph export "figures/bootstrapped_`var'_by_bs_`round'.png", replace
	
	

    restore
}



