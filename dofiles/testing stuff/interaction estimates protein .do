*------------------------------------------------------------
* Dynamic figure: outcome by protein category and social group
* Single graph with Adivasi, Dalit, OBC, Forward
*
* rows format:
*   "Adivasi 0-1 protein foods weekly"
*   "Dalit 0-1 protein foods weekly"
*   "OBC 2+ protein foods daily"
*   "Forward 1 protein food daily"
*
* Assumes results dataset has:
* rows, overvar, level,
* underweight_mean, underweight_ll, underweight_ul, etc.
*------------------------------------------------------------

use "data/results interaction with protein quartile.dta", clear
* change filename above if needed

local interaction_var protein_group
local prettyname "protein-rich food consumption"

local outcome underweight
local ytitle "Prepregnancy underweight (%)"

local figtitle "Prepregnancy underweight by `prettyname' and social group"

*------------------------------------------------------------
* Keep selected interaction rows
*------------------------------------------------------------

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
* Parse protein category from rows
* Remove social group prefix so category is common across groups
*------------------------------------------------------------

gen str100 cat_label = rows

replace cat_label = subinstr(cat_label, "Adivasi ", "", .)
replace cat_label = subinstr(cat_label, "Dalit ", "", .)
replace cat_label = subinstr(cat_label, "OBC ", "", .)
replace cat_label = subinstr(cat_label, "Forward ", "", .)

*------------------------------------------------------------
* Force intended protein category order
*------------------------------------------------------------

gen cat_order = .

replace cat_order = 1 if cat_label == "0-1 protein foods weekly"
replace cat_order = 2 if cat_label == "2+ protein foods weekly, none daily"
replace cat_order = 3 if cat_label == "1 protein food daily"
replace cat_order = 4 if cat_label == "2+ protein foods daily"

gen x = cat_order

* Sanity check
list rows group4 cat_label cat_order if missing(group4) | missing(cat_order)

*------------------------------------------------------------
* X-axis labels
*------------------------------------------------------------

local xlabels ///
    1 "0-1 protein foods weekly" ///
    2 "2+ weekly, none daily" ///
    3 "1 daily" ///
    4 "2+ daily"

*------------------------------------------------------------
* Convert outcome estimates to percentage points
* Only multiply if estimates are proportions.
*------------------------------------------------------------

foreach suffix in mean ll ul {
    replace `outcome'_`suffix' = `outcome'_`suffix' * 100
}

*------------------------------------------------------------
* Stagger groups within each protein category
*------------------------------------------------------------

distinct group4
local n_groups = r(ndistinct)

* Tight stagger
local radius = min(0.12, 0.035 + 0.02 * `n_groups')

capture drop grouppos offset xpos
egen grouppos = group(group4)

gen double offset = .

if `n_groups' == 1 {
    replace offset = 0
}
else {
    replace offset = -`radius' + ///
        (grouppos - 1) * (2 * `radius' / (`n_groups' - 1))
}

gen double xpos = x + offset

* Determine x-axis range
summ x
local xmin = r(min) - .25
local xmax = r(max) + .25

*------------------------------------------------------------
* Build graph layers dynamically
* Scatter only, no connected lines
* CI colors match point colors
* Point labels above markers
*------------------------------------------------------------

local colors navy forest_green dkorange maroon
local symbols Oh Sh Dh Th

levelsof group4, local(groups_graph)

local plots
local legend
local k = 0

foreach g of local groups_graph {
    
    local ++k
    
    local color  : word `k' of `colors'
    local symbol : word `k' of `symbols'
    
    local glab : label group4_lbl `g'
    
    local plots `plots' ///
        (rcap `outcome'_ul `outcome'_ll xpos if group4 == `g', ///
            lcolor(`color'%60)) ///
        (scatter `outcome'_mean xpos if group4 == `g', ///
            mcolor(`color') ///
            msymbol(`symbol') ///
            msize(medlarge) ///
            mlab(`outcome'_mean) ///
            mlabposition(12) ///
            mlabsize(vsmall) ///
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

twoway `plots', ///
    xlabel(`xlabels', angle(30) labsize(small)) ///
    xscale(range(`xmin' `xmax')) ///
    ytitle("`ytitle'") ///
    xtitle("") ///
    title("`figtitle'") ///
    legend(order(`legend') cols(4) pos(11) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) ///
    plotregion(color(white))

graph export "figures/`outcome'_by_`interaction_var'_groups_single.png", replace width(3000)
graph save "figures/`outcome'_by_`interaction_var'_groups_single.gph", replace
