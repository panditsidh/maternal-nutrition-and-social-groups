do "$paths"

set more off
clear all

set seed 1231231
local B = 100
local chunk_size = 10 

cap mkdir "data/bootstrap_chunks"

forvalues chunk_start = 1(`chunk_size')`B' {
    
    local chunk_end = min(`chunk_start' + `chunk_size' - 1, `B')
    
    di as text "=================================="
    di as text "Running chunk `chunk_start' to `chunk_end'"
    di as text "=================================="
    
    tempname grouplevel decomplevel cutofflevel
    
    local group_file  "data/bootstrap_chunks/grouplevel_`chunk_start'_`chunk_end'.dta"
    local decomp_file "data/bootstrap_chunks/decomplevel_`chunk_start'_`chunk_end'.dta"
    local cutoff_file "data/bootstrap_chunks/cutofflevel_`chunk_start'_`chunk_end'.dta"
    
    #delimit ;
    postfile `grouplevel' 
        int         iteration
        str100      estimate_level
        int         level
        double      bmi underweight weight overweight obesity
        using "`group_file'", replace;

    postfile `decomplevel'
        int         iteration
        str100      decompvar
        int         decompvarlevel
        int         grouplevel
        double      underweight
        using "`decomp_file'", replace;

    postfile `cutofflevel'
        int         iteration
        double      cutoff
        int         group
        double      underweight
        using "`cutoff_file'", replace;
    #delimit cr
    
    
    forvalues iteration = `chunk_start'/`chunk_end' {
        
        di "ITERATION `iteration' of `B'"
        
        qui {
            
            use "$dataset", clear
            
            *------------------------------------------------------------
            * Cutoff-level estimates
            *------------------------------------------------------------
            foreach cutoff in 1 0.75 0.5 0.25 0.1 {
                
                preserve
                
                keep if pct_psu_higher <= `cutoff'
                
                replace strata = 3  if strata == 4
                replace strata = 68 if strata == 67
                
                bsample, strata(strata) cluster(psu)
                
                global binvars agebin rural less_edu noboy group
                
                do "dofiles/new final/040 reweighting"
                
                foreach group in 1 2 3 {
                    
                    local underweight = .
                    
                    sum underweight [aw=reweightingfxn] if preg==0 & group==`group'
                    if r(N) > 0 {
                        local underweight = r(mean)
                    }
                    
                    post `cutofflevel' (`iteration') (`cutoff') (`group') (`underweight')
                }
                
                restore
            }
            
            
            *------------------------------------------------------------
            * Full-sample bootstrap for main/decomp estimates
            *------------------------------------------------------------
            bsample, strata(strata) cluster(psu)
            
            
            *------------------------------------------------------------
            * India and group-level estimates
            *------------------------------------------------------------
            foreach estimate_level in india group {
                
				local estimate_level "group"
				
                if "`estimate_level'"=="india" {
                    global binvars agebin rural less_edu noboy
                }
                else if "`estimate_level'"=="group" {
                    global binvars agebin rural less_edu noboy group
                }
				
                do "dofiles/new final/040 reweighting"
                
                levelsof `estimate_level', local(levels)
                
                foreach level in `levels' {
                    
                    local bmi = .
                    local underweight = .
                    local weight = .
                    local overweight = .
                    local obesity = .
                    
                    foreach outcome in bmi underweight weight overweight obesity {
                        
                        sum `outcome' [aw=reweightingfxn] if preg==0 & `estimate_level'==`level'
                        if r(N) > 0 {
                            local `outcome' = r(mean)
                        }
                    }
                    
                    post `grouplevel' (`iteration') ("`estimate_level'") (`level') ///
                        (`bmi') (`underweight') (`weight') (`overweight') (`obesity')
                }
            }
            
            
            *------------------------------------------------------------
            * Decomposition-level estimates
            *------------------------------------------------------------
            foreach estimate_level in wealth parity bs protein_q4 psu_od_besideshh_q4 {
                
                global binvars agebin rural less_edu noboy group `estimate_level'
                
                do "dofiles/new final/040 reweighting"
                
                levelsof `estimate_level', local(levels)
                
                foreach level in . `levels' {
                    
                    foreach group of numlist 1/5 {
                        
                        local underweight = .
                        
                        if "`level'" == "." {
                            sum underweight [aw=reweightingfxn] if preg==0 & group==`group'
                        }
                        else {
                            sum underweight [aw=reweightingfxn] if preg==0 & group==`group' & `estimate_level'==`level'
                        }
                        
                        if r(N) > 0 {
                            local underweight = r(mean)
                        }
                        
                        post `decomplevel' (`iteration') ("`estimate_level'") ///
                            (`level') (`group') (`underweight')
                    }
                }
            }
        }
    }
    
    postclose `grouplevel'
    postclose `decomplevel'
    postclose `cutofflevel'
    
    di as result "Saved chunk `chunk_start' to `chunk_end'"
}





*============================================================
* 1. Append bootstrap chunks into final bootstrap files
*============================================================

do "$paths"

cap mkdir "data/results"

foreach level in grouplevel decomplevel cutofflevel {
    
    clear
    local first = 1
    
    forvalues chunk_start = 1(`chunk_size')`B' {
        
        local chunk_end = min(`chunk_start' + `chunk_size' - 1, `B')
        local f "data/bootstrap_chunks/`level'_`chunk_start'_`chunk_end'.dta"
        
        capture confirm file "`f'"
        if _rc {
            di as error "Missing file: `f'"
            continue
        }
        
        if `first' {
            use "`f'", clear
            local first = 0
        }
        else {
            append using "`f'"
        }
    }
    
    save "data/results/bootstrap_`level'_all.dta", replace
}



