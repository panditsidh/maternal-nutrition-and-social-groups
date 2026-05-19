* Figure 1: Prepregnancy underweight by social group (plotted with confidence intervals)

do "$paths"


* the original is "data/results.dta"
// local results_file "data/results only age reweighting.dta"
local results_file "data/results figure1 simple reweighting.dta"



* the original is "figures/figure1 prepregnancy underweight by subgroup.png"
// local outfile "figures/figure1 only age reweighting.png"
local outfile "figures/figure1 reweighting without wealth and paritybs.png"


use "`results_file'", clear

* you can change this to any outcome, just add a prettyname for it. we report underweight in the paper.
local var underweight

local prettyname = upper("`var'")
if "`var'" == "underweight" local prettyname "Prevalence of prepregnancy underweight"
if "`var'" == "weight" local prettyname "Prepregnancy Weight (kg)"
if "`var'" == "gainhat" local prettyname "Pregnancy Weight Gain (kg)"

* only need pp outcome by social groups for this figure
keep if inlist(rows, "Forward", "OBC", "Dalit", "Adivasi", "Muslim", "All five social groups")

* focus on one variable
keep `var'_ll `var'_mean `var'_ul

gen group = _n

* get point estimates of pp outcome for each social group
levelsof(group), local(levels)
foreach i in `levels' {
	
	sum `var'_mean if group==`i'
	local outcome_`i' =  r(mean)
	
	* for formatting the point estimates on the figure later
	if inlist("`var'", "underweight", "overweight", "obesity") local textpos_`i' = 0.28+`i'
	
	else local textpos_`i' = 0.34+`i'
	
}


//
// #delimit ;
// twoway (rcap `var'_ul `var'_ll group, lcolor(black)) ///
//        (scatter `var'_mean group, msymbol(circle) mcolor(black)),
//        xlabel(1 "Adivasi" 2 "Dalit" 3 "OBC" 4 "Forward" 5 "Muslim" 6 "All five", nogrid labsize(medlarge)) ///
//        ylabel(0(.05)0.3, grid labsize(medlarge)) ///
//        ytitle("`prettyname'", size(medlarge)) ///
//        xtitle("") ///
// 	   title("Prepregnancy underweight by social groups", size(vlarge)) ///
// 	   yscale(range(0 .)) ///
//        graphregion(color(white)) ///
//        legend(off) ///
// 	   text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", placement(north) size(medlarge)) ///
//        text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", placement(north) size(medlarge)) 
// 	   text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", placement(north) size(medlarge))
// 	   text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", placement(north) size(medlarge)) 
// 	   text(`outcome_5' `textpos_5' "`=string(`outcome_5', "%4.2f")'", placement(north) size(medlarge))
// 	   text(`outcome_6' `textpos_6' "`=string(`outcome_6', "%4.2f")'", placement(north) size(medlarge)) ///
// 	   text(-0.04 6.5 "social groups", placement(west) size(medlarge)) ///
// 	   text(-0.04 4.35 "caste Hindu", placement(west) size(medlarge)) ///
// 	   graphregion(color(white) margin(r+12));
// #delimit cr
//
// graph export "figures/(poster) figure1 prepregnancy underweight by subgroup.png", replace


#delimit ;
twoway (rcap `var'_ul `var'_ll group, lcolor(black)) ///
       (scatter `var'_mean group, msymbol(circle) mcolor(black)),
       xlabel(1 "Adivasi" 2 "Dalit" 3 "OBC" 4 "Forward" 5 "Muslim" 6 "All five", nogrid) ///
       ylabel(0(.05)0.3, grid) ///
       ytitle("`prettyname'") ///
       xtitle("") ///
	   yscale(range(0 .)) ///
       graphregion(color(white)) ///
       legend(off) ///
	   text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", placement(west) size(small)) ///
       text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", placement(west) size(small))
	   text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", placement(west) size(small)) 
	   text(`outcome_5' `textpos_5' "`=string(`outcome_5', "%4.2f")'", placement(west) size(small))
	   text(`outcome_6' `textpos_6' "`=string(`outcome_6', "%4.2f")'") ///
	   text(-0.035 6.5 "social groups", placement(west)) ///
	   text(-0.035 4.35 "caste Hindu", placement(west)) ///
	   graphregion(color(white) margin(r+12));
#delimit cr





graph export "`outfile'", replace
