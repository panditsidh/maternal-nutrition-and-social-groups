*------------------------------------------------------------
* Dynamic figure: outcome by interaction category and social group
* Panels compare Adivasi/Dalit/OBC to Forward
*
* Assumes results dataset has:
* rows, overvar, level, underweight_mean, underweight_ll, underweight_ul
*
* Change only interaction_var and outcome as needed.
*------------------------------------------------------------

use "data/results parity bs and social group interaction.dta", clear
* use "data/results wealth and social group interaction.dta", clear

// local interaction_var parity_group
local interaction_var bs_group
* local interaction_var wealth_group

local prettyname "birth spacing"

local outcome underweight
local ytitle "Prepregnancy underweight (%)"

* Optional title fragment
local figtitle "Prepregnancy underweight by `prettyname' and social group"

* Keep selected interaction rows
keep if overvar == "`interaction_var'"

* Drop Muslim if present
drop if strpos(rows, "Muslim")

* Keep only Adivasi, Dalit, OBC, Forward
keep if strpos(rows, "Adivasi") | strpos(rows, "Dalit") | ///
        strpos(rows, "OBC") | strpos(rows, "Forward")

*------------------------------------------------------------
* Parse social group from rows
*------------------------------------------------------------

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

*------------------------------------------------------------
* Parse category label from rows by removing social group text
*------------------------------------------------------------

gen str100 cat_label = rows

replace cat_label = subinstr(cat_label, " Adivasi", "", .)
replace cat_label = subinstr(cat_label, " Dalit", "", .)
replace cat_label = subinstr(cat_label, " OBC", "", .)
replace cat_label = subinstr(cat_label, " Forward", "", .)

* Encode category label in the order it appears in level
* Because levels are generated as category x group, sorting by level preserves category order.
sort level
egen cat_order = group(cat_label)

* Clean x variable
gen x = cat_order

* Store category labels dynamically for xlabel()
levelsof cat_order, local(cats)

local xlabels
foreach c of local cats {
    quietly levelsof cat_label if cat_order == `c', local(thislab)
    local xlabels `xlabels' `c' "`thislab'"
}

// di `"`xlabels'"'

local xlabels 1 "<2 years" 2 "2-3 years" 3 "3+ years" 

*------------------------------------------------------------
* Convert outcome estimates to percentage points
*------------------------------------------------------------

foreach suffix in mean ll ul {
    replace `outcome'_`suffix' = `outcome'_`suffix' * 100
}

*------------------------------------------------------------
* Slight x-offsets so CIs do not sit exactly on top of each other
*------------------------------------------------------------

gen x_disadv = x - .08 if inlist(group4, 1, 2, 3)
gen x_fwd    = x + .08 if group4 == 4

* Determine x-axis range
summ x
local xmin = r(min) - .35
local xmax = r(max) + .35

*------------------------------------------------------------
* Panel A: Adivasi vs Forward
*------------------------------------------------------------



#delimit ;
twoway
    connected `outcome'_mean x_disadv if group4 == 1,
        lcolor(navy%35) mcolor(navy) msymbol(circle) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_disadv if group4 == 1,
        lcolor(navy%60)
    ||
    connected `outcome'_mean x_fwd if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_fwd if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(`xlabels', angle(30) labsize(small))
    xscale(range(`xmin' `xmax'))
    ytitle("`ytitle'")
    xtitle("")
    title("A. Adivasi vs Forward")
    legend(
        order(1 "Adivasi" 3 "Forward")
        cols(2) pos(11) ring(0) region(lstyle(none))
    )
	
    name(panel_a, replace)
;
#delimit cr


*------------------------------------------------------------
* Panel B: Dalit vs Forward
*------------------------------------------------------------

#delimit ;
twoway
    connected `outcome'_mean x_disadv if group4 == 2,
        lcolor(forest_green%35) mcolor(forest_green) msymbol(square) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_disadv if group4 == 2,
        lcolor(forest_green%60)
    ||
    connected `outcome'_mean x_fwd if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_fwd if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(`xlabels', angle(30) labsize(small))
    xscale(range(`xmin' `xmax'))
    ytitle("`ytitle'")
    xtitle("")
    title("B. Dalit vs Forward")
    legend(
        order(1 "Dalit" 3 "Forward")
        cols(2) pos(11) ring(0) region(lstyle(none))
    )
    name(panel_b, replace)
;
#delimit cr


*------------------------------------------------------------
* Panel C: OBC vs Forward
*------------------------------------------------------------

#delimit ;
twoway
    connected `outcome'_mean x_disadv if group4 == 3,
        lcolor(orange%35) mcolor(orange) msymbol(diamond) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_disadv if group4 == 3,
        lcolor(orange%60)
    ||
    connected `outcome'_mean x_fwd if group4 == 4,
        lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
    ||
    rcap `outcome'_ul `outcome'_ll x_fwd if group4 == 4,
        lcolor(maroon%60)
    ,
    xlabel(`xlabels', angle(30) labsize(small))
    xscale(range(`xmin' `xmax'))
    ytitle("`ytitle'")
    xtitle("")
    title("C. OBC vs Forward")
    legend(
        order(1 "OBC" 3 "Forward")
        cols(2) pos(11) ring(0) region(lstyle(none))
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
    title("`figtitle'")

graph export "figures/`outcome'_by_`interaction_var'_panels.png", replace width(3000)
graph save "figures/`outcome'_by_`interaction_var'_panels.gph", replace

// *------------------------------------------------------------
// * Figure: Prepregnancy underweight by wealth quartile and social group
// * Panels compare each disadvantaged group to Forward caste
// * Requires results dataset with wealth_group rows
// *------------------------------------------------------------
//
// use "data/results wealth and social group interaction.dta", clear
//
// * Keep only wealth_group rows
// keep if overvar == "wealth_group"
//
// * Keep only Adivasi, Dalit, OBC, Forward
// drop if strpos(rows, "Muslim")
//
// * Create wealth quartile from row labels
// gen wealth_q = .
// replace wealth_q = 1 if strpos(rows, "1st quartile")
// replace wealth_q = 2 if strpos(rows, "2nd quartile")
// replace wealth_q = 3 if strpos(rows, "3rd quartile")
// replace wealth_q = 4 if strpos(rows, "4th quartile")
//
// label define wealthq_lbl ///
//     1 "Q1" ///
//     2 "Q2" ///
//     3 "Q3" ///
//     4 "Q4", replace
// label values wealth_q wealthq_lbl
//
// * Create social group
// gen group4 = .
// replace group4 = 1 if strpos(rows, "Adivasi")
// replace group4 = 2 if strpos(rows, "Dalit")
// replace group4 = 3 if strpos(rows, "OBC")
// replace group4 = 4 if strpos(rows, "Forward")
//
// label define group4_lbl ///
//     1 "Adivasi" ///
//     2 "Dalit" ///
//     3 "OBC" ///
//     4 "Forward", replace
// label values group4 group4_lbl
//
// * Convert underweight estimates to percentages
// foreach v in underweight_mean underweight_ll underweight_ul {
//     replace `v' = `v' * 100
// }
//
// * Slight x-offsets so confidence intervals do not overlap perfectly
// gen x = wealth_q
// gen x_adivasi = x - .09 if group4 == 1
// gen x_dalit   = x - .09 if group4 == 2
// gen x_obc     = x - .09 if group4 == 3
// gen x_forward = x + .09 if group4 == 4
//
//
// *------------------------------------------------------------
// * Panel A: Adivasi vs Forward
// *------------------------------------------------------------
//
// #delimit ;
// twoway
//     connected underweight_mean x_adivasi if group4 == 1,
//         lcolor(navy%35) mcolor(navy) msymbol(circle) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_adivasi if group4 == 1,
//         lcolor(navy%60)
//     ||
//     connected underweight_mean x_forward if group4 == 4,
//         lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_forward if group4 == 4,
//         lcolor(maroon%60)
//     ,
//     xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
//     xscale(range(.75 4.25))
//     ytitle("Prepregnancy underweight (%)")
//     xtitle("Wealth quartile")
//     title("A. Adivasi vs Forward")
//     legend(
//         order(1 "Adivasi" 3 "Forward")
//         cols(2) pos(6) region(lstyle(none))
//     )
//     name(panel_a, replace)
// ;
// #delimit cr
//
//
// *------------------------------------------------------------
// * Panel B: Dalit vs Forward
// *------------------------------------------------------------
//
// #delimit ;
// twoway
//     connected underweight_mean x_dalit if group4 == 2,
//         lcolor(forest_green%35) mcolor(forest_green) msymbol(square) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_dalit if group4 == 2,
//         lcolor(forest_green%60)
//     ||
//     connected underweight_mean x_forward if group4 == 4,
//         lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_forward if group4 == 4,
//         lcolor(maroon%60)
//     ,
//     xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
//     xscale(range(.75 4.25))
//     ytitle("Prepregnancy underweight (%)")
//     xtitle("Wealth quartile")
//     title("B. Dalit vs Forward")
//     legend(
//         order(1 "Dalit" 3 "Forward")
//         cols(2) pos(6) region(lstyle(none))
//     )
//     name(panel_b, replace)
// ;
// #delimit cr
//
//
// *------------------------------------------------------------
// * Panel C: OBC vs Forward
// *------------------------------------------------------------
//
// #delimit ;
// twoway
//     connected underweight_mean x_obc if group4 == 3,
//         lcolor(orange%35) mcolor(orange) msymbol(diamond) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_obc if group4 == 3,
//         lcolor(orange%60)
//     ||
//     connected underweight_mean x_forward if group4 == 4,
//         lcolor(maroon%35) mcolor(maroon) msymbol(triangle) msize(medlarge)
//     ||
//     rcap underweight_ul underweight_ll x_forward if group4 == 4,
//         lcolor(maroon%60)
//     ,
//     xlabel(1 "Q1" 2 "Q2" 3 "Q3" 4 "Q4")
//     xscale(range(.75 4.25))
//     ytitle("Prepregnancy underweight (%)")
//     xtitle("Wealth quartile")
//     title("C. OBC vs Forward")
//     legend(
//         order(1 "OBC" 3 "Forward")
//         cols(2) pos(6) region(lstyle(none))
//     )
//     name(panel_c, replace)
// ;
// #delimit cr
//
//
// *------------------------------------------------------------
// * Combine panels
// *------------------------------------------------------------
//
// graph combine panel_a panel_b panel_c, ///
//     col(3) ///
//     ycommon ///
//     imargin(tiny) ///
//     title("Prepregnancy underweight by wealth quartile and social group")
//
// graph export "figures/prepreg_underweight_by_wealth_group_panels.png", replace width(3000)
// // graph save "figures/prepreg_underweight_by_wealth_group_panels.gph", replace
