** This do-file graphs underweight, weight, and gainhat with bootstrapped CIs

local rounds 5

foreach round in `rounds' {

if `round'==3 {
	use "data/bootstrapresults_full_nfhs3.dta", clear
}


else {
	use "data/bootstrapresults_full.dta", clear
}



gen iteration = _n


rename bmi bmi0
rename underweight underweight0
rename weight weight0
rename nineweighthat nineweighthat0
rename coeffhat coeffhat0
rename gainhat gainhat0


reshape long preg pct_drop bins dropbins pct_zero count9plus bmi underweight weight nineweighthat coeffhat gainhat, ///
    i(iteration) j(groups6)

foreach var in underweight weight gainhat bmi {
    
    preserve

    collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(groups6)

    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Underweight Rate"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

    twoway (rcap ub lb groups6, lcolor(black)) ///
           (scatter mean groups6, msymbol(circle) mcolor(black)), ///
           xlabel(0 "all groups" 1 "Forward" 2 "OBC" 3 "Dalit" 4 "Adivasi" 5 "Muslim") ///
           ytitle("`prettyname'") ///
           xtitle("Social Group") ///
           title("Pre-Pregnancy `prettyname' by Social Group - `round'") ///
           graphregion(color(white)) ///
           legend(off)

    graph export "figures/bootstrapped_`var'_by_group_`round'.png", replace

    restore
}


}
