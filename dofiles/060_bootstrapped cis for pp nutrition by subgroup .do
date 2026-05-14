do "$paths"

set more off
clear all

set seed 8062011
local B = 100
local chunk_size = 20


local cutoff = 0.75
* the original is "data/bootstrap cis for pp outcomes.dta"
local outfile "data/bootstrap cis `cutoff' cutoff.dta"

******************* PREPARING BOOTSTRAP RESULTS DATASET ************************

forvalues iteration = 1(1)`B' {

    di "ITERATION ", `iteration', " of ", `B'

    qui {

        do "$paths"

        * ---- Chunk handling ----
        if mod(`iteration', `chunk_size')==0 | `iteration'==1 {

            if `iteration'!=1 {
                postclose `H'

                if `iteration'==`chunk_size' {
                    use `results', clear
//                     save "data/bootstrap cis for pp outcomes.dta", replace
					
					save "`outfile'", replace
                }
                else {
//                     use "data/bootstrap cis for pp outcomes.dta", clear
					
					use "`outfile'", clear
                    append using `results'
					
//                     save "data/bootstrap cis for pp outcomes.dta", replace
					
					save "`outfile'", replace
                }
            }

            tempname H
            tempfile results

            #delimit ;
            postfile `H' ///
                int    iteration ///
                str20  overvar ///
                double level ///
                double bmi underweight weight overweight obesity ///
                using `results', replace ;
            #delimit cr
        }

        * ---- Bootstrap sample ----
//         use "$dataset", clear
		do "dofiles/new variables.do"
		keep if pct_psu_higher<=cutoff

				
        bsample, strata(strata) cluster(psu)

        * ---- Generate reweighting ----
        qui do "dofiles/050_weights to estimate pp nutrition.do"
		
		egen parity_group = group(parity group), label
		egen bs_group = group(bs group), label




        * ---- Prepregnancy estimates ----
// 		foreach overvar in allfivegroups group parity_group bs_group {

        foreach overvar in allfivegroups group parity bs parity_bs wealth {
			

            levelsof `overvar', local(levels)

            foreach i in `levels' {

                local bmi = .
                local underweight = .
                local weight = .
                local overweight = .
                local obesity = .

                if inlist("`overvar'", "allfivegroups", "group") ///
                    local outcomes bmi underweight weight overweight obesity
                else local outcomes underweight

                foreach outcome in `outcomes' {
                    sum `outcome' [aw=reweightingfxn] ///
                        if preg==0 & dropbin!=1 & `overvar'==`i'
                    local `outcome' = r(mean)
                }

                post `H' ///
                    (`iteration') ("`overvar'") (`i') ///
                    (`bmi') (`underweight') (`weight') (`overweight') (`obesity')
            }
        }
    }
}

// use "data/bootstrap cis for pp outcomes.dta", clear


use "`outfile'", clear
gen str overlevel = "_" + overvar + string(level)
drop overvar level

reshape wide bmi underweight weight overweight obesity, ///
    i(iteration) j(overlevel) string

// save "data/bootstrap cis for pp outcomes.dta", replace

save "`outfile'", replace
