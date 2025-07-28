** This do-file graphs underweight, weight, and gainhat with bootstrapped CIs


* @DIANE: should I make this just for NFHS-5 to keep the code simpler? or would we show the change from NFHS-3 in an appendix


local rounds 5

foreach round in `rounds' {

if `round'==3 {
	use "data/bootstrapresults_full_nfhs3.dta", clear
}


else {
	use "data/bootstrapresults_full.dta", clear
}

reshape long preg pct_drop bins dropbins pct_zero count9plus bmi underweight weight nineweighthat coeffhat gainhat, ///
    i(iteration) j(groups6)
	
* reordered groups variable for graphs
gen groups_display = 1 if groups6==4 // Adivasi
replace groups_display = 2 if groups6==3 // Dalit
// OBC is already 2
replace groups_display = 3 if groups6==2
replace groups_display = 4 if groups6==1 // Forward
replace groups_display = 5 if groups6==5 // Muslim
replace groups_display = 6 if groups6==0 // All 5 groups



foreach var in underweight {
    
	
    preserve
		
	
    collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(groups_display)

    local prettyname = upper("`var'")
    if "`var'" == "underweight" local prettyname "Rate of pre-pregnancy underweight"
    if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
    if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"


	foreach i of numlist 1/6 {
    quietly sum mean if groups_display==`i'
    local outcome_`i' = r(mean)
}

#delimit ;
twoway (rcap ub lb groups_display, lcolor(black)) ///
       (scatter mean groups_display, msymbol(circle) mcolor(black)), ///
       xlabel(1 "Adivasi" 2 "Dalit" 3 "OBC" 4 "Forward" 5 "Muslim" 6 "All five", nogrid) ///
       ylabel(, grid) ///
       ytitle("`prettyname'") ///
       xtitle("") ///
       graphregion(color(white)) ///
       legend(off) ///
       text(`outcome_1' 1.28 "`=string(`outcome_1', "%4.2f")'", placement(west) size(small)) ///
       text(`outcome_2' 2.28 "`=string(`outcome_2', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_3' 3.28 "`=string(`outcome_3', "%4.2f")'", placement(west) size(small))
	   text(`outcome_4' 4.28 "`=string(`outcome_4', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_5' 5.28 "`=string(`outcome_5', "%4.2f")'", placement(west) size(small))
	   text(`outcome_6' 6.28 "`=string(`outcome_6', "%4.2f")'", placement(west) size(small)) ///
	   text(0.077 5.4 "Social Groups", placement(west))
	   graphregion(color(white) margin(r+12));
#delimit cr


    graph export "figures/bootstrapped_`var'_by_group_`round'.png", replace

    restore
}


}
