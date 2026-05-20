*============================================================
* create_cutofflevel_results.do
*============================================================

do "$paths"

set more off
clear all

tempfile results

postfile handle ///
    double cutoff ///
    int group ///
    double underweight_mean underweight_ll underweight_ul ///
    using `results', replace


foreach cutoff in 1 0.75 0.5 0.25 0.1 {
    
    *--------------------------------------------------------
    * Point estimates
    *--------------------------------------------------------
    
    use "$dataset", clear
    
    keep if pct_psu_higher <= `cutoff'
    
    replace strata = 3  if strata == 4
    replace strata = 68 if strata == 67
    
    global binvars agebin rural less_edu noboy group
    
    qui do "dofiles/050_weights to estimate pp nutrition.do"
    
    foreach g in 1 2 3 {
        
        local underweight_mean = .
        local underweight_ll   = .
        local underweight_ul   = .
        
        quietly sum underweight [aw=reweightingfxn] ///
            if preg==0 & group==`g'
        
        if r(N) > 0 {
            local underweight_mean = r(mean)
        }
        
        
        *----------------------------------------------------
        * Bootstrap CIs
        *----------------------------------------------------
        
        preserve
        
        use "data/results/bootstrap_cutofflevel_all.dta", clear
        
        quietly count if cutoff==`cutoff' ///
            & group==`g' ///
            & !missing(underweight)
        
        if r(N) > 0 {
            quietly _pctile underweight if cutoff==`cutoff' ///
                & group==`g', p(2.5 97.5)
            
            local underweight_ll = r(r1)
            local underweight_ul = r(r2)
        }
        
        restore
        
        
        *----------------------------------------------------
        * Post row
        *----------------------------------------------------
        
        post handle ///
            (`cutoff') ///
            (`g') ///
            (`underweight_mean') (`underweight_ll') (`underweight_ul')
    }
}

postclose handle

use `results', clear

order cutoff group underweight_mean underweight_ll underweight_ul
sort group cutoff

save "data/results/cutofflevel_results_with_ci.dta", replace
