*============================================================
* create_decomplevel_results.do
*============================================================

do "$paths"

set more off
clear all

tempfile results

postfile handle ///
    str100 decompvar ///
    double decompvarlevel ///
    int grouplevel ///
    double underweight_mean underweight_ll underweight_ul ///
    using `results', replace


foreach decompvar in wealth parity bs protein_q4 psu_od_besideshh_q4 {
    
    *--------------------------------------------------------
    * Reweighting bins include group and decomposition variable
    *--------------------------------------------------------
    
    local binvars agebin rural less_edu noboy group `decompvar'
    
    use "$dataset", clear
    
    qui do "dofiles/050_weights to estimate pp nutrition.do"
    
    levelsof `decompvar', local(levels)
    levelsof group, local(groups)
    
    
    *========================================================
    * A. Group-level rows under this decomp-specific reweighting
    *    decompvarlevel = .
    *========================================================
    
    foreach g of local groups {
        
        local underweight_mean = .
        local underweight_ll   = .
        local underweight_ul   = .
        
        quietly sum underweight [aw=reweightingfxn] ///
            if preg==0 & group==`g'
        
        if r(N) > 0 {
            local underweight_mean = r(mean)
        }
        
        preserve
        
        use "data/results/bootstrap_decomplevel_all.dta", clear
        
        quietly count if decompvar=="`decompvar'" ///
            & missing(decompvarlevel) ///
            & grouplevel==`g' ///
            & !missing(underweight)
        
        if r(N) > 0 {
            quietly _pctile underweight if decompvar=="`decompvar'" ///
                & missing(decompvarlevel) ///
                & grouplevel==`g', p(2.5 97.5)
            
            local underweight_ll = r(r1)
            local underweight_ul = r(r2)
        }
        
        restore
        
        post handle ///
            ("`decompvar'") ///
            (.) ///
            (`g') ///
            (`underweight_mean') (`underweight_ll') (`underweight_ul')
    }
    
    
    *========================================================
    * B. Group x decomposition-category rows
    *========================================================
    
    foreach lev of local levels {
        
        foreach g of local groups {
            
            local underweight_mean = .
            local underweight_ll   = .
            local underweight_ul   = .
            
            quietly sum underweight [aw=reweightingfxn] ///
                if preg==0 & group==`g' & `decompvar'==`lev'
            
            if r(N) > 0 {
                local underweight_mean = r(mean)
            }
            
            preserve
            
            use "data/results/bootstrap_decomplevel_all.dta", clear
            
            quietly count if decompvar=="`decompvar'" ///
                & decompvarlevel==`lev' ///
                & grouplevel==`g' ///
                & !missing(underweight)
            
            if r(N) > 0 {
                quietly _pctile underweight if decompvar=="`decompvar'" ///
                    & decompvarlevel==`lev' ///
                    & grouplevel==`g', p(2.5 97.5)
                
                local underweight_ll = r(r1)
                local underweight_ul = r(r2)
            }
            
            restore
            
            post handle ///
                ("`decompvar'") ///
                (`lev') ///
                (`g') ///
                (`underweight_mean') (`underweight_ll') (`underweight_ul')
        }
    }
}

postclose handle

use `results', clear

order decompvar decompvarlevel grouplevel ///
    underweight_mean underweight_ll underweight_ul

sort decompvar grouplevel decompvarlevel

save "data/results/decomplevel_results_with_ci.dta", replace
