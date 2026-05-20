/********************************************************************
Purpose:
    Protein-only underweight estimates and 95% CIs by social group.

Input:
    data/results/decomplevel_results_with_ci.dta

Output:
    figures/protein_q4_underweight.gph
********************************************************************/

clear all
set more off

do "$paths"

use "data/results/decomplevel_results_with_ci.dta", clear

capture mkdir "figures"

*------------------------------------------------------------
* Keep protein only
*------------------------------------------------------------

keep if decompvar == "protein_q4"
keep if inlist(grouplevel, 1, 2, 3, 4)

drop if missing(decompvarlevel)
drop if missing(grouplevel)
drop if missing(underweight_mean)

* Percent scale
foreach v in underweight_mean underweight_ll underweight_ul {
    replace `v' = 100 * `v'
}

*------------------------------------------------------------
* Labels
*------------------------------------------------------------

capture label drop grouplbl
label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward", replace

label values grouplevel grouplbl

capture label drop protein_q4lbl
label define protein_q4lbl ///
    1 "0-1 protein foods weekly" ///
    2 "2+ protein foods weekly, none daily" ///
    3 "1 protein food daily" ///
    4 "2+ protein foods daily", replace

*------------------------------------------------------------
* X-axis and staggered group positions
*------------------------------------------------------------

gen double x = decompvarlevel

egen grouppos = group(grouplevel)

quietly summarize grouppos, meanonly
local n_groups = r(max)

local radius = 1.7 * min(0.12, 0.035 + 0.02 * `n_groups')

gen double offset = .

if `n_groups' == 1 {
    replace offset = 0
}
else {
    replace offset = -`radius' + ///
        (grouppos - 1) * (2 * `radius' / (`n_groups' - 1))
}

gen double xpos = x + offset

quietly summarize x, meanonly
local xmin = r(min) - .30
local xmax = r(max) + .30

quietly summarize underweight_ll, meanonly
local ymin = r(min)

quietly summarize underweight_ul, meanonly
local ymax = r(max) + 5

if `ymin' > 0 {
    local ymin = 0
}

*------------------------------------------------------------
* X-axis labels
*------------------------------------------------------------

levelsof x, local(xlevels) clean

local xlabels

foreach lev of local xlevels {
    local thislab : label protein_q4lbl `lev'

    if `"`thislab'"' == "" {
        local thislab "`lev'"
    }

    local xlabels `xlabels' `lev' `"`thislab'"'
}

*------------------------------------------------------------
* Build plot layers
*------------------------------------------------------------

local colors navy forest_green dkorange maroon
local symbols Oh Sh Dh Th

levelsof grouplevel, local(groups_graph) clean

local plots
local legend
local k = 0

foreach g of local groups_graph {

    local ++k

    local color  : word `k' of `colors'
    local symbol : word `k' of `symbols'

    local glab : label grouplbl `g'

    local plots `plots' ///
        (rcap underweight_ul underweight_ll xpos if grouplevel == `g', ///
            lcolor(`color'%60)) ///
        (scatter underweight_mean xpos if grouplevel == `g', ///
            mcolor(`color') ///
            msymbol(`symbol') ///
            msize(small) ///
            mlab(underweight_mean) ///
            mlabposition(12) ///
            mlabsize(tiny) ///
            mlabformat(%4.1f) ///
            mlabcolor(`color'))

    local scatter_layer = 2 * `k'
    local legend `legend' `scatter_layer' `"`glab'"'
}

*------------------------------------------------------------
* Graph
*------------------------------------------------------------

twoway `plots', ///
    xlabel(`xlabels', angle(30) labsize(vsmall) nogrid) ///
    xscale(range(`xmin' `xmax')) ///
    ylabel(`ymin'(5)`ymax', angle(horizontal) labsize(tiny) grid) ///
    yscale(range(`ymin' `ymax')) ///
    ytitle("Prepregnancy underweight (%)", size(vsmall)) ///
    xtitle("") ///
    title("B. Prepregnancy underweight by protein consumption", size(small)) ///
    legend(order(`legend') cols(4) pos(11) ring(0) region(lstyle(none)) size(tiny)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(protein_q4_underweight, replace)

graph save "figures/protein_q4_underweight.gph", replace

graph export "figures/protein_q4_underweight.pdf", ///
    replace as(pdf) name(protein_q4_underweight)

graph export "figures/protein_q4_underweight.png", ///
    replace as(png) name(protein_q4_underweight) width(2400)
