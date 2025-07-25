** This do-file graphs underweight, weight, and gainhat with bootstrapped CIs

local rounds 5

foreach round in `rounds' {
	
local round 5

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

foreach var in underweight {
    
	
    preserve
	
	local var underweight
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
    if "`var'" == "underweight" local prettyname "Rate of pre-pregnancy underweight"
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

	foreach i of numlist 0/5 {
    quietly sum mean if groups==`i'
    local outcome_`i' = r(mean)
}

#delimit ;
twoway (rcap ub lb groups, lcolor(black)) ///
       (scatter mean groups, msymbol(circle) mcolor(black)), ///
       xlabel(0 "Adivasi" 1 "Dalit" 2 "OBC" 3 "Forward" 4 "Muslim" 5 "All five", nogrid) ///
       ylabel(, grid) ///
       ytitle("`prettyname'") ///
       xtitle("") ///
       graphregion(color(white)) ///
       legend(off) ///
       text(`outcome_0' 0.28 "`=string(`outcome_0', "%4.2f")'", placement(west) size(small)) ///
       text(`outcome_1' 1.28 "`=string(`outcome_1', "%4.2f")'", placement(west) size(small)) ///
       text(`outcome_2' 2.28 "`=string(`outcome_2', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_3' 3.28 "`=string(`outcome_3', "%4.2f")'", placement(west) size(small))
	   text(`outcome_4' 4.28 "`=string(`outcome_4', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_5' 5.28 "`=string(`outcome_5', "%4.2f")'", placement(west) size(small))
	   text(0.077 5.4 "Social Groups", placement(west))
	   graphregion(color(white) margin(r+12));
#delimit cr

    graph export "figures/bootstrapped_`var'_by_group_`round'.png", replace

    restore
}


}
