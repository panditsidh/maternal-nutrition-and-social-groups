/********************************************************************
Purpose:
    Plot underweight estimates and 95% CIs by decomposition-variable
    level and social group.

Input:
    data/results/decomplevel_results_with_ci.dta

Required columns:
    decompvar
    decompvarlevel
    grouplevel
    underweight_mean
    underweight_ll
    underweight_ul
********************************************************************/

clear all
set more off

do "$paths"

*------------------------------------------------------------
* Load data
*------------------------------------------------------------
use "data/results/decomplevel_results_with_ci.dta", clear

*------------------------------------------------------------
* Keep groups to graph
*------------------------------------------------------------
keep if inlist(grouplevel, 1, 2, 3, 4)

*------------------------------------------------------------
* Scale underweight estimates from proportion to percent
*------------------------------------------------------------
foreach v in underweight_mean underweight_ll underweight_ul {
    replace `v' = 100 * `v'
}

*------------------------------------------------------------
* Output folder
*------------------------------------------------------------
capture mkdir "figures"

*------------------------------------------------------------
* Social group labels
*------------------------------------------------------------
capture label drop grouplbl
label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward" ///
    5 "Muslim", replace

label values grouplevel grouplbl

*------------------------------------------------------------
* X-axis value labels
* Name labels as `overvar'lbl so we can call them dynamically
*------------------------------------------------------------
capture label drop paritylbl
label define paritylbl ///
    1 "1 (no live births)" ///
    2 "2 (1 live birth)" ///
    3 "3 (2 live births)" ///
    4 "4+ (3+ live births)", replace

capture label drop bslbl
label define bslbl ///
    1 "Under 2 years" ///
    2 "2-3 years" ///
    3 "Over 3 years", replace

capture label drop v190lbl
label define v190lbl ///
    1 "Poorest" ///
    2 "Poorer" ///
    3 "Middle" ///
    4 "Richer" ///
	5 "Richest", replace

capture label drop psu_od_besideshh_q4lbl
label define psu_od_besideshh_q4lbl ///
    1 "Lowest quartile" ///
    2 "2nd quartile" ///
    3 "3rd quartile" ///
    4 "Highest quartile", replace

capture label drop protein_q4lbl
label define protein_q4lbl ///
    1 "Lowest protein quartile" ///
    2 "2nd protein quartile" ///
    3 "3rd protein quartile" ///
    4 "Highest protein quartile", replace
	

label define psu_od_besideshh_q4lbl ///
    1 "Q1: 0%" ///
    2 "Q2: 4% - 10%" ///
    3 "Q3: 10% - 33.3%" ///
    4 "Q4: > 33.3%", replace


	
*------------------------------------------------------------
* Figure titles
*------------------------------------------------------------
local figtitle_bs                  "D. Time since last live birth"
local figtitle_parity              "C. Parity"
local figtitle_protein_q4          "Protein consumption"
local figtitle_psu_od_besideshh_q4 "B. Fraction of neighboring households" "that defecate in the open (quartiles)"
local figtitle_v190              "A. Wealth quintile"

*------------------------------------------------------------
* Decomposition variables to graph
* Add/remove/order variables here
*------------------------------------------------------------
local overvars bs parity protein_q4 psu_od_besideshh_q4 v190



*------------------------------------------------------------
* Graph aesthetics
*------------------------------------------------------------
local outcome underweight
local ytitle "Underweight (%)"

local colors navy forest_green dkorange maroon
local symbols Oh Sh Dh Th

local graphlist

*------------------------------------------------------------
* Loop over decomposition variables
*------------------------------------------------------------
foreach dv of local overvars {

    preserve

        *------------------------------------------------------------
        * Keep current decomposition variable
        *------------------------------------------------------------
        keep if decompvar == "`dv'"
        drop if missing(decompvarlevel)
        drop if missing(grouplevel)
        drop if missing(`outcome'_mean)

        *------------------------------------------------------------
        * X-axis variable
        *------------------------------------------------------------
        gen double x = decompvarlevel

        *------------------------------------------------------------
        * Dynamic stagger within each x-axis category
        *------------------------------------------------------------
        capture drop grouppos offset xpos

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

        *------------------------------------------------------------
        * Y-axis range: add 5 percentage points of headroom
        *------------------------------------------------------------
        quietly summarize `outcome'_ll, meanonly
        local ymin = r(min)

        quietly summarize `outcome'_ul, meanonly
        local ymax = r(max) + 5

        * Optional: keep lower bound clean if estimates are all positive
        if `ymin' > 0 {
            local ymin = 0
        }

        *------------------------------------------------------------
        * Dynamic x-axis labels
        * Assumes value label is named `dv'lbl
        * e.g. bs -> bslbl, parity -> paritylbl
        *------------------------------------------------------------
        local labname "`dv'lbl"

        levelsof x, local(xlevels) clean

        local xlabels

        foreach lev of local xlevels {
            local thislab : label `labname' `lev'

            if `"`thislab'"' == "" {
                local thislab "`lev'"
            }

            local xlabels `xlabels' `lev' `"`thislab'"'
        }

        *------------------------------------------------------------
        * Build twoway layers dynamically by social group
        *------------------------------------------------------------
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
                (rcap `outcome'_ul `outcome'_ll xpos if grouplevel == `g', ///
                    lcolor(`color'%60)) ///
                (scatter `outcome'_mean xpos if grouplevel == `g', ///
                    mcolor(`color') ///
                    msymbol(`symbol') ///
                    msize(small) ///
                    mlab(`outcome'_mean) ///
                    mlabposition(12) ///
                    mlabsize(tiny) ///
                    mlabformat(%4.1f) ///
                    mlabcolor(`color'))

            * Legend only for scatter layers.
            * Each group contributes:
            *   rcap    = 2*k - 1
            *   scatter = 2*k
            local scatter_layer = 2 * `k'

            local legend `legend' `scatter_layer' `"`glab'"'
        }

        *------------------------------------------------------------
        * Single graph
        *------------------------------------------------------------
        local gname "underweight_`dv'"
		
		local xscaleopt "xscale(range(`xmin' `xmax'))"

		if "`dv'" == "psu_od_besideshh_q4" {
			local xscaleopt "xscale(reverse range(`xmin' `xmax'))"
		}

        twoway `plots', ///
            xlabel(`xlabels', angle(45) labsize(vsmall) nogrid) ///
            `xscaleopt' ///
            ylabel(`ymin'(5)`ymax', angle(horizontal) labsize(tiny) grid) ///
            yscale(range(`ymin' `ymax')) ///
            ytitle("`ytitle'", size(vsmall)) ///
            xtitle("") ///
            title("`figtitle_`dv''", size(small)) ///
            legend(order(`legend') cols(4) pos(11) ring(0) region(lstyle(none)) size(tiny)) ///
            graphregion(color(white)) ///
            plotregion(color(white)) ///
            name(`gname', replace)

        graph export "figures/`gname'.png", replace width(2400)

        local graphlist `graphlist' `gname'

    restore
}



graph combine ///
	underweight_v190 ///
	underweight_psu_od_besideshh_q4 ///
    underweight_parity ///
    underweight_bs, ///
    cols(2) ///
    xsize(10) ///
    ysize(8) ///
    graphregion(color(white)) ///
    name(combined_underweight_4panel, replace)

graph export "figures/combined_underweight_4panel.pdf", ///
    replace as(pdf) 
