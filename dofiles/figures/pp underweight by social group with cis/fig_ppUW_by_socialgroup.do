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
	
	gen groups = 0 if groups6==4 // Adivasi
	replace groups = 1 if groups6==3 // Dalit
	// OBC is already 2
	replace groups = 2 if groups6==2
	replace groups = 3 if groups6==1 // Forward
	replace groups = 4 if groups6==5 // Muslim
	replace groups = 5 if groups6==0 // All 5 groups

    collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(groups)

    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Underweight Rate"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

//     twoway (rcap ub lb groups, lcolor(black)) ///
//            (scatter mean groups, msymbol(circle) mcolor(black)), ///
//            xlabel(0 "Adivasi" 1 "Dalit" 2 "OBC" 3 "Forward" 4 "Muslim" 5 "All groups") ///
//            ytitle("`prettyname'") ///
//            xtitle("Social Group") ///
//            title("Pre-Pregnancy `prettyname' by Social Group - `round'") ///
//            graphregion(color(white)) ///
//            legend(off)

    twoway (rcap ub lb groups, lcolor(black)) ///
           (scatter mean groups, msymbol(circle) mcolor(black)), ///
           xlabel(0 "Adivasi" 1 "Dalit" 2 "OBC" 3 "Forward" 4 "Muslim" 5 "All groups") ///
           ytitle("`prettyname'") ///
           graphregion(color(white)) ///
		   xtitle("") ///
           legend(off)

    graph export "figures/bootstrapped_`var'_by_group_`round'.png", replace

    restore
}


}
