* --- WEALTH GRAPH ONLY ---

use "data/results.dta", clear

local xtitle "wealth quartile"
local xlabel `"1 "Poorest" 2 "Quartile 2" 3 "Quartile 3" 4 "Richest""'
local title "Prepregnancy underweight by `xtitle'"
// local note "n=`sample_size_bf' (married nonpregnant women who aren't using modern contraception)" 

keep if strpos(rows, "Wealth")==1

local var underweight

keep `var'_ll `var'_mean `var'_ul
gen group = _n

* get levels for labeling
preserve
use "$dataset", clear
levelsof(wealth), local(levels)
restore

foreach i in `levels' {
    sum underweight_mean if group==`i'
    local outcome_`i' = r(mean)
    
    local text_shift = 0.2
    local textpos_`i' = `text_shift' + `i'
}

#delimit ;
twoway ///
    (rcap `var'_ul `var'_ll group, lcolor(black) lwidth(medthick)) ///
    (scatter `var'_mean group, msymbol(circle) mcolor(black) msize(large)),
    xlabel(`xlabel', nogrid labsize(medlarge)) ///
    ylabel(0(.05)0.3, grid labsize(large) angle(horizontal)) ///
    ytitle("Rate of pre-pregnancy underweight", size(medlarge)) ///
    xtitle("`xtitle'", size(medlarge)) ///
    title("`title'", size(large)) ///
    yscale(range(0 0.3) fill) ///
    graphregion(color(white) margin(r+16 l+8 t+8 b+8)) ///
    plotregion(margin(medium)) ///
    legend(off) ///
    note("`note'", size(medium)) ///
    text(`outcome_1' `textpos_1' "`=string(`outcome_1', "%4.2f")'", placement(north) size(medium)) ///
    text(`outcome_2' `textpos_2' "`=string(`outcome_2', "%4.2f")'", placement(north) size(medium)) ///
    text(`outcome_3' `textpos_3' "`=string(`outcome_3', "%4.2f")'", placement(north) size(medium)) ///
    text(`outcome_4' `textpos_4' "`=string(`outcome_4', "%4.2f")'", placement(north) size(medium));
#delimit cr

