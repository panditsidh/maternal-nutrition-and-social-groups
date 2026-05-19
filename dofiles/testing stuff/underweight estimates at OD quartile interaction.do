*------------------------------------------------------------
* Dynamic figure: outcome by PSU open defecation quartile and social group
* Single graph with Adivasi, Dalit, OBC, Forward
*
* rows format:
*   "Adivasi 1"
*   "Adivasi 2"
*   "Dalit 1"
*   ...
* where the number is the PSU open defecation quartile.
*------------------------------------------------------------

use "data/results interaction with psu od.dta", clear

local interaction_var od_group
local prettyname "PSU open defecation quartile"

local outcome underweight
local ytitle "Prepregnancy underweight (%)"

local figtitle "Prepregnancy underweight by `prettyname' and social group"

* Keep selected interaction rows
keep if overvar == "`interaction_var'"

* Drop Muslim if present
drop if strpos(rows, "Muslim")

* Keep only Adivasi, Dalit, OBC, Forward
keep if strpos(rows, "Adivasi") | strpos(rows, "Dalit") | ///
        strpos(rows, "OBC") | strpos(rows, "Forward")

*------------------------------------------------------------
* Parse social group and OD quartile from rows
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

* Pull the final number from rows as the OD quartile
gen od_quartile = real(regexs(1)) if regexm(rows, " ([0-9]+)$")

label define odq_lbl ///
    1 "Q1: lowest OD" ///
    2 "Q2" ///
    3 "Q3" ///
    4 "Q4: highest OD", replace

label values od_quartile odq_lbl

* X-axis is OD quartile
gen x = od_quartile

* Sanity check
list rows group4 od_quartile if missing(group4) | missing(od_quartile)

*------------------------------------------------------------
* X-axis labels
*------------------------------------------------------------

local xlabels ///
    1 "Q1: lowest OD" ///
    2 "Q2" ///
    3 "Q3" ///
    4 "Q4: highest OD"

*------------------------------------------------------------
* Convert outcome estimates to percentage points
*------------------------------------------------------------

foreach suffix in mean ll ul {
    replace `outcome'_`suffix' = `outcome'_`suffix' * 100
}

*------------------------------------------------------------
* Stagger groups within each OD quartile
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
* With point labels above markers
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
