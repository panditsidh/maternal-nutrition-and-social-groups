*============================================================
* create_grouplevel_results.do
*============================================================

do "$paths"

set more off
clear all

tempfile results

postfile handle ///
    str100 estimate_level ///
    int level ///
    double bmi_mean bmi_ll bmi_ul ///
    double underweight_mean underweight_ll underweight_ul ///
    double weight_mean weight_ll weight_ul ///
    double overweight_mean overweight_ll overweight_ul ///
    double obesity_mean obesity_ll obesity_ul ///
    using `results', replace


foreach estimate_level in india group {
    
    *--------------------------------------------------------
    * Define reweighting bins
    *--------------------------------------------------------
    
    if "`estimate_level'" == "india" {
        global binvars agebin rural less_edu noboy
    }
    else if "`estimate_level'" == "group" {
        global binvars agebin rural less_edu noboy group
    }
    
    
    *--------------------------------------------------------
    * Compute point estimates
    *--------------------------------------------------------
    
    use "$dataset", clear
    
    qui do "dofiles/00 resubmission/040 reweighting.do"
    
    levelsof `estimate_level', local(levels)
    
    foreach level of local levels {
        
        foreach outcome in bmi underweight weight overweight obesity {
            local `outcome'_mean = .
            local `outcome'_ll   = .
            local `outcome'_ul   = .
        }
        
        foreach outcome in bmi underweight weight overweight obesity {
            
            quietly sum `outcome' [aw=reweightingfxn] ///
                if preg==0 & `estimate_level'==`level'
            
            if r(N) > 0 {
                local `outcome'_mean = r(mean)
            }
        }
        
        
        *----------------------------------------------------
        * Bootstrap CIs
        *----------------------------------------------------
        
        preserve
        
        use "data/results/bootstrap_grouplevel_all.dta", clear
        
        foreach outcome in bmi underweight weight overweight obesity {
            
            quietly count if estimate_level=="`estimate_level'" ///
                & level==`level' ///
                & !missing(`outcome')
            
            if r(N) > 0 {
                quietly _pctile `outcome' if estimate_level=="`estimate_level'" ///
                    & level==`level', p(2.5 97.5)
                
                local `outcome'_ll = r(r1)
                local `outcome'_ul = r(r2)
            }
        }
        
        restore
        
        
        *----------------------------------------------------
        * Post row
        *----------------------------------------------------
        
        post handle ///
            ("`estimate_level'") ///
            (`level') ///
            (`bmi_mean') (`bmi_ll') (`bmi_ul') ///
            (`underweight_mean') (`underweight_ll') (`underweight_ul') ///
            (`weight_mean') (`weight_ll') (`weight_ul') ///
            (`overweight_mean') (`overweight_ll') (`overweight_ul') ///
            (`obesity_mean') (`obesity_ll') (`obesity_ul')
    }
}






postclose handle

use `results', clear

order estimate_level level ///
    bmi_mean bmi_ll bmi_ul ///
    underweight_mean underweight_ll underweight_ul ///
    weight_mean weight_ll weight_ul ///
    overweight_mean overweight_ll overweight_ul ///
    obesity_mean obesity_ll obesity_ul

save "data/results/grouplevel_results_with_ci.dta", replace

