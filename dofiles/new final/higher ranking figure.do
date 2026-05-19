clear all


do "$paths"
// use "$dataset", clear

tempfile results

postfile handle ///
    double cutoff adivasi_ppunderweight dalit_ppunderweight obc_ppunderweight ///
    using `results', replace


forvalues c = 100(-2)0 {
    
    di "Now on cutoff `c'"
    
    qui { 
    
    use "$dataset", clear
    
    local cutoff = `c'/100
    
    keep if pct_psu_higher <= `cutoff'
    
    do "dofiles/050_weights to estimate pp nutrition.do"
    }
    
    foreach group in 1 2 3 {
        
        qui {
        sum underweight if preg == 0 & group == `group' [aw=reweightingfxn]
        local b`group' = r(mean)
        
        sum dropbin if group == `group'
        local pct_dropped = r(mean) * 100
        }

        if `pct_dropped' > 5 {
            di "Warning: for cutoff `cutoff' and group `group', `pct_dropped'% pregnant women are dropped."
        }
        
    }
    
    post handle (`cutoff') (`b1') (`b2') (`b3')
    
}


postclose handle


use `results', clear


*------------------------------------------------------------
* Save line-results dataset
*------------------------------------------------------------
foreach var in adivasi_ppunderweight dalit_ppunderweight obc_ppunderweight {
    capture confirm variable pct_`var'
    if _rc {
        gen pct_`var' = 100 * `var'
    }
}

tempfile line_results
save `line_results', replace


*------------------------------------------------------------
* Build CI dataset from new cutoff-level results file
*------------------------------------------------------------
use "data/results/cutofflevel_results_with_ci.dta", clear

keep if inlist(group, 1, 2, 3)

gen pp_mean = 100 * underweight_mean
gen pp_ll   = 100 * underweight_ll
gen pp_ul   = 100 * underweight_ul

keep group cutoff pp_mean pp_ll pp_ul

tempfile ci_results
save `ci_results', replace


*------------------------------------------------------------
* Merge CI variables into line-results dataset
*------------------------------------------------------------
use `line_results', clear

merge 1:m cutoff using `ci_results', nogen


* Split CI variables by group for easier graphing
gen adivasi_ci_mean = pp_mean if group == 1
gen adivasi_ci_ll   = pp_ll   if group == 1
gen adivasi_ci_ul   = pp_ul   if group == 1

gen dalit_ci_mean = pp_mean if group == 2
gen dalit_ci_ll   = pp_ll   if group == 2
gen dalit_ci_ul   = pp_ul   if group == 2

gen obc_ci_mean = pp_mean if group == 3
gen obc_ci_ll   = pp_ll   if group == 3
gen obc_ci_ul   = pp_ul   if group == 3


*------------------------------------------------------------
* Forward caste reference line
*------------------------------------------------------------
use "data/results/cutofflevel_results_with_ci.dta", clear

keep if cutoff == 1 & group == 4

if _N > 0 {
    gen forward_ppu = 100 * underweight_mean
    gen forward_ll  = 100 * underweight_ll
    gen forward_ul  = 100 * underweight_ul

    sum forward_ppu
    local forward_ppu = r(mean)

    sum forward_ll
    local forward_ll = r(mean)

    sum forward_ul
    local forward_ul = r(mean)
}
else {
    * fallback if group 4 is not in cutofflevel_results_with_ci.dta
    use "data/results.dta", clear

    keep if rows == "Forward"

    gen forward_ppu = 100 * underweight_mean
    gen forward_ll  = 100 * underweight_ll
    gen forward_ul  = 100 * underweight_ul

    sum forward_ppu
    local forward_ppu = r(mean)

    sum forward_ll
    local forward_ll = r(mean)

    sum forward_ul
    local forward_ul = r(mean)
}


*------------------------------------------------------------
* Return to merged line + CI dataset
*------------------------------------------------------------
use `line_results', clear
merge 1:m cutoff using `ci_results', nogen


* Split CI variables by group for easier graphing
gen adivasi_ci_mean = pp_mean if group == 1
gen adivasi_ci_ll   = pp_ll   if group == 1
gen adivasi_ci_ul   = pp_ul   if group == 1

gen dalit_ci_mean = pp_mean if group == 2
gen dalit_ci_ll   = pp_ll   if group == 2
gen dalit_ci_ul   = pp_ul   if group == 2

gen obc_ci_mean = pp_mean if group == 3
gen obc_ci_ll   = pp_ll   if group == 3
gen obc_ci_ul   = pp_ul   if group == 3


*------------------------------------------------------------
* Graph
*------------------------------------------------------------
twoway ///
    (line pct_adivasi_ppunderweight cutoff, sort lwidth(medthick) lcolor(navy)) ///
    (rcap adivasi_ci_ul adivasi_ci_ll cutoff if !missing(adivasi_ci_ll), ///
        lcolor(navy)) ///
    ///
    (line pct_dalit_ppunderweight cutoff, sort lwidth(medthick) lcolor(maroon)) ///
    (rcap dalit_ci_ul dalit_ci_ll cutoff if !missing(dalit_ci_ll), ///
        lcolor(maroon)) ///
    ///
    (line pct_obc_ppunderweight cutoff, sort lwidth(medthick) lcolor(green)) ///
    (rcap obc_ci_ul obc_ci_ll cutoff if !missing(obc_ci_ll), ///
        lcolor(green)) ///
    ///
    (function y = `forward_ppu', range(0 1) lpattern(dash) lcolor(gs10) lwidth(thin)) ///
    ///
    , ///
    xscale(reverse range(0 1)) ///
    xlabel(1(.1)0, angle(0)) ///
    ylabel(, angle(0)) ///
    xtitle("Maximum fraction of PSU" "higher ranking included") ///
    ytitle("Estimated prepregnancy" "underweight (%)") ///
    legend(order(1 "Adivasi" 3 "Dalit" 5 "OBC" 7 "Forward caste") ///
           rows(1) position(6)) ///
    title("Prepregnancy underweight by local higher caste-rank exposure") ///
    note("Lines re-estimate prepregnancy underweight after restricting the sample by fraction PSU higher ranking." ///
         "Confidence intervals are shown at selected cutoffs.")

// graph export "figures/ppu_by_pct_psu_higher_cutoff_with_ci.png", replace width(2400)
