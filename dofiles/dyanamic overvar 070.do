/* 
This dofile generates a Stata dataset with one row per category of selected overvars.

Columns:
    rows
    overvar
    level
    mean / ll / ul for each outcome
*/

*------------------------------------------------------------
* Output files
*------------------------------------------------------------


clear all
local outfile "data/results interaction with protein quartile.dta"

* the original is "data/bootstrap cis for pp outcomes.dta"
local bootstrap_results "data/bootstrap cis with protein quartile.dta"


*------------------------------------------------------------
* Prepare dataset
*------------------------------------------------------------

qui do "$paths"
do "dofiles/new variables.do"

egen protein_group = group(group protein_q4), label

qui do "dofiles/050_weights to estimate pp nutrition.do"

drop if group==6 | group==.


*------------------------------------------------------------
* Settings
*------------------------------------------------------------

local outcomes bmi weight underweight overweight obesity

* Put any overvars here
local overvars group allfivegroups protein_group
* local overvars group allfivegroups parity bs parity_bs wealth wealth_group


*------------------------------------------------------------
* Set up postfile
*------------------------------------------------------------

tempfile results_long

postfile handle ///
    str100 rows ///
    str32 overvar ///
    double level ///
    double bmi_mean double bmi_ll double bmi_ul ///
    double weight_mean double weight_ll double weight_ul ///
    double underweight_mean double underweight_ll double underweight_ul ///
    double overweight_mean double overweight_ll double overweight_ul ///
    double obesity_mean double obesity_ll double obesity_ul ///
    using `results_long', replace


*------------------------------------------------------------
* Loop over overvars and levels
*------------------------------------------------------------

foreach overvar of local overvars {
    
    * get value label attached to overvar, if any
    local vallab : value label `overvar'
    
    levelsof `overvar' if !missing(`overvar'), local(levels)
    
    foreach i of local levels {
        
        *----------------------------------------------------
        * Dynamic row label
        *----------------------------------------------------
        
        if "`overvar'" == "allfivegroups" {
            local rowlabel "All five social groups"
        }
        else if "`vallab'" != "" {
            local rowlabel : label `vallab' `i'
        }
        else {
            local rowlabel "`overvar' `i'"
        }
        
        * clean up empty labels just in case
        if `"`rowlabel'"' == "" {
            local rowlabel "`overvar' `i'"
        }
        
        
        *----------------------------------------------------
        * Initialize row-specific locals
        *----------------------------------------------------
        
        foreach outcome of local outcomes {
            local `outcome'_mean .
            local `outcome'_ll .
            local `outcome'_ul .
        }
        
        
        *----------------------------------------------------
        * Calculate means and bootstrap CIs
        *----------------------------------------------------
        
        foreach outcome of local outcomes {
            
            quietly sum `outcome' if `overvar' == `i' & preg == 0 [aw=reweightingfxn]
            local `outcome'_mean = r(mean)
            
            
            preserve
            
            use "`bootstrap_results'", clear
            
            * Bootstrap variable should be named like:
            * outcome_overvarlevel
            * example: underweight_group1, bmi_wealth_group8, etc.
            
            capture confirm variable `outcome'_`overvar'`i'
            
            if !_rc {
                quietly _pctile `outcome'_`overvar'`i', p(2.5 97.5)
                local `outcome'_ll = r(r1)
                local `outcome'_ul = r(r2)
            }
            else {
                di as error "Bootstrap variable not found: `outcome'_`overvar'`i'"
                local `outcome'_ll = .
                local `outcome'_ul = .
            }
            
            restore
        }
        
        
        *----------------------------------------------------
        * Post row
        *----------------------------------------------------
        
        post handle ///
            (`"`rowlabel'"') ///
            (`"`overvar'"') ///
            (`i') ///
            (`bmi_mean') (`bmi_ll') (`bmi_ul') ///
            (`weight_mean') (`weight_ll') (`weight_ul') ///
            (`underweight_mean') (`underweight_ll') (`underweight_ul') ///
            (`overweight_mean') (`overweight_ll') (`overweight_ul') ///
            (`obesity_mean') (`obesity_ll') (`obesity_ul')
    }
}

postclose handle


*------------------------------------------------------------
* Save result dataset
*------------------------------------------------------------

use `results_long', clear

save "`outfile'", replace
