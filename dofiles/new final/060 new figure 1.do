


*------------------------------------------------------------
* Figure 1: Prepregnancy underweight by social group
* Plotted with confidence intervals
* Adapted for new results file structure:
* estimate_level level bmi_mean bmi_ll bmi_ul underweight_mean ...
*------------------------------------------------------------

clear all
set more off

do "$paths"






*------------------------------------------------------------
* File paths
*------------------------------------------------------------


local outfile "figures/figure1 prepregnancy underweight by social group NEW.png"


*------------------------------------------------------------
* Load results
*------------------------------------------------------------

use "data/results/grouplevel_results_with_ci.dta", clear

*------------------------------------------------------------
* Choose outcome
*------------------------------------------------------------

local var underweight

local prettyname = upper("`var'")

if "`var'" == "underweight" local prettyname "Prevalence of prepregnancy underweight"
if "`var'" == "weight"      local prettyname "Prepregnancy weight (kg)"
if "`var'" == "gainhat"     local prettyname "Pregnancy weight gain (kg)"
if "`var'" == "bmi"         local prettyname "Prepregnancy BMI"
if "`var'" == "overweight"  local prettyname "Prevalence of prepregnancy overweight"
if "`var'" == "obesity"     local prettyname "Prevalence of prepregnancy obesity"


*------------------------------------------------------------
* Keep social groups plus all-India estimate
*------------------------------------------------------------

keep if estimate_level == "group" | estimate_level == "india"

* Keep only five social groups plus India.
* Drop group 6 unless you actually want it in the figure.
drop if estimate_level == "group" & level == 6


*------------------------------------------------------------
* Create plotting order and labels
*------------------------------------------------------------

gen group = .

replace group = 1 if estimate_level == "group" & level == 1
replace group = 2 if estimate_level == "group" & level == 2
replace group = 3 if estimate_level == "group" & level == 3
replace group = 4 if estimate_level == "group" & level == 4
replace group = 5 if estimate_level == "group" & level == 5
replace group = 6 if estimate_level == "india"

label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward" ///
    5 "Muslim" ///
    6 "All India", replace

label values group grouplbl

keep if !missing(group)

sort group


*------------------------------------------------------------
* Keep selected outcome variables
*------------------------------------------------------------

keep group `var'_mean `var'_ll `var'_ul


*------------------------------------------------------------
* Store point estimates for text labels
*------------------------------------------------------------

levelsof group, local(levels)

foreach i in `levels' {

    quietly sum `var'_mean if group == `i'
    local outcome_`i' = r(mean)

    * x-position for text labels
    if inlist("`var'", "underweight", "overweight", "obesity") {
        local textpos_`i' = 0.28 + `i'
    }
    else {
        local textpos_`i' = 0.34 + `i'
    }

}


*------------------------------------------------------------
* Figure
*------------------------------------------------------------

#delimit ;

twoway 
    (rcap `var'_ul `var'_ll group, 
        lcolor(black)
    )
    (scatter `var'_mean group, 
        msymbol(circle) 
        mcolor(black)
    ),
    xlabel(
        1 "Adivasi" 
        2 "Dalit" 
        3 "OBC" 
        4 "Forward" 
        5 "Muslim" 
        6 "All India",
        nogrid
    )
    ylabel(0(.05)0.3, grid)
    ytitle("`prettyname'")
    xtitle("")
    yscale(range(0 .))
    graphregion(color(white) margin(r+12))
    plotregion(color(white))
    legend(off)
    text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", 
        placement(west) size(small)
    )
    text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", 
        placement(west) size(small)
    )
    text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", 
        placement(west) size(small)
    )
    text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", 
        placement(west) size(small)
    )
    text(`outcome_5' `textpos_5' "`=string(`outcome_5', "%4.2f")'", 
        placement(west) size(small)
    )
    text(`outcome_6' `textpos_6' "`=string(`outcome_6', "%4.2f")'", 
        placement(west) size(small)
    )
    text(-0.035 6.5 "all India", 
        placement(west)
    )
    text(-0.035 4.35 "caste Hindu", 
        placement(west)
    );

#delimit cr


*------------------------------------------------------------
* Export
*------------------------------------------------------------

graph export "`outfile'", replace
