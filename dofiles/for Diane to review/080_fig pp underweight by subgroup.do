* ok so this file needs to do 080 


use "data/results.dta", clear




local var underweight


local prettyname = upper("`var'")
if "`var'" == "underweight" local prettyname "Rate of pre-pregnancy underweight"
if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

keep if inlist(rows, "Forward", "OBC", "Dalit", "Adivasi", "Muslim", "All five social groups")

keep `var'_ll `var'_mean `var'_ul

gen group = _n


levelsof(group), local(levels)
foreach i in `levels' {
	
	sum `var'_mean if group==`i'
	local outcome_`i' =  r(mean)
	
	if inlist("`var'", "underweight", "overweight", "obesity") local textpos_`i' = 0.28+`i'
	
	else local textpos_`i' = 0.34+`i'
	
}



#delimit ;
twoway (rcap `var'_ul `var'_ll group, lcolor(black)) ///
       (scatter `var'_mean group, msymbol(circle) mcolor(black)),
       xlabel(1 "Adivasi" 2 "Dalit" 3 "OBC" 4 "Forward" 5 "Muslim" 6 "All five", nogrid) ///
       ylabel(, grid) ///
       ytitle("`prettyname'") ///
       xtitle("") ///
       graphregion(color(white)) ///
       legend(off) ///
	   text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", placement(west) size(small)) ///
       text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", placement(west) size(small))
	   text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_5' `textpos_5' "`=string(`outcome_5', "%4.2f")'", placement(west) size(small))
	   text(`outcome_6' `textpos_6' "`=string(`outcome_6', "%4.2f")'", placement(west) size(small)) ///
	   text(0.077 6.4 "Social Groups", placement(west)) ///
	   graphregion(color(white) margin(r+12));
#delimit cr


