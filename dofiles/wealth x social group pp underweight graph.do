*------------------------------------------------------------
* Figure: Prepregnancy underweight by wealth quartile and social group
* Panels compare each disadvantaged group to Forward caste
* Requires results dataset with wealth_group rows
*------------------------------------------------------------

use "data/results wealth and social group interaction.dta", clear

* Keep only wealth_group rows
keep if overvar == "wealth_group"

* Keep only Adivasi, Dalit, OBC, Forward
drop if strpos(rows, "Muslim")

* Create wealth quartile from row labels
gen wealth_q = .
replace wealth_q = 1 if strpos(rows, "1st quartile")
replace wealth_q = 2 if strpos(rows, "2nd quartile")
replace wealth_q = 3 if strpos(rows, "3rd quartile")
replace wealth_q = 4 if strpos(rows, "4th quartile")

label define wealthq_lbl ///
    1 "Q1" ///
    2 "Q2" ///
    3 "Q3" ///
    4 "Q4", replace
label values wealth_q wealthq_lbl

* Create social group
gen group4 = .
replace group4 = 1 if strpos(rows, "Adivasi")
replace group4 = 2 if strpos(rows, "Dalit")
replace group4 = 3 if strpos(rows, "OBC")
replace group4 = 4 if strpos(rows, "Forward")

label define group4_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward", replace
label values group4 group4_lbl

* Convert underweight estimates to percentages
foreach v in underweight_mean underweight_ll underweight_ul {
    replace `v' = `v' * 100
}

* Slight x-offsets so confidence intervals do not overlap perfectly
gen x = wealth_q
gen x_adivasi = x - .09 if group4 == 1
gen x_dalit   = x - .09 if group4 == 2
gen x_obc     = x - .09 if group4 == 3
gen x_forward = x + .09 if group4 == 4


*------------------------------------------------------------
* Panel A: Adivasi vs Forward
*------------------------------------------------------------

#delimit ;
twoway
    connected underweight_mean x_adivasi if group4 == 1,
        lcolor(navy%35) mcolor(navy) msymbol(circle) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_adivasi if group4 == 1,
        lcolor(navy%60)
    ||
    connected underweight_mean x_forward if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_forward if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
    xscale(range(.75 4.25))
    ytitle("Prepregnancy underweight (%)")
    xtitle("Wealth quartile")
    title("A. Adivasi vs Forward")
    legend(
        order(1 "Adivasi" 3 "Forward")
        cols(2) pos(6) region(lstyle(none))
    )
    name(panel_a, replace)
;
#delimit cr


*------------------------------------------------------------
* Panel B: Dalit vs Forward
*------------------------------------------------------------

#delimit ;
twoway
    connected underweight_mean x_dalit if group4 == 2,
        lcolor(forest_green%35) mcolor(forest_green) msymbol(square) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_dalit if group4 == 2,
        lcolor(forest_green%60)
    ||
    connected underweight_mean x_forward if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_forward if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
    xscale(range(.75 4.25))
    ytitle("Prepregnancy underweight (%)")
    xtitle("Wealth quartile")
    title("B. Dalit vs Forward")
    legend(
        order(1 "Dalit" 3 "Forward")
        cols(2) pos(6) region(lstyle(none))
    )
    name(panel_b, replace)
;
#delimit cr


*------------------------------------------------------------
* Panel C: OBC vs Forward
*------------------------------------------------------------

#delimit ;
twoway
    connected underweight_mean x_obc if group4 == 3,
        lcolor(orange%35) mcolor(orange) msymbol(diamond) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_obc if group4 == 3,
        lcolor(orange%60)
    ||
    connected underweight_mean x_forward if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap underweight_ul underweight_ll x_forward if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
    xscale(range(.75 4.25))
    ytitle("Prepregnancy underweight (%)")
    xtitle("Wealth quartile")
    title("C. OBC vs Forward")
    legend(
        order(1 "OBC" 3 "Forward")
        cols(2) pos(6) region(lstyle(none))
    )
    name(panel_c, replace)
;
#delimit cr


*------------------------------------------------------------
* Combine panels
*------------------------------------------------------------

graph combine panel_a panel_b panel_c, ///
    col(3) ///
    ycommon ///
    imargin(tiny) ///
    title("Prepregnancy underweight by wealth quartile and social group")

graph export "figures/prepreg_underweight_by_wealth_group_panels.png", replace width(3000)
// graph save "figures/prepreg_underweight_by_wealth_group_panels.gph", replace
