do "$paths"

set more off
clear all

set seed 8062011
local B = 1001
local chunk_size = 20

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
                    save "data/bootstrap cis for pp outcomes.dta", replace
                }
                else {
                    use "data/bootstrap cis for pp outcomes.dta", clear
                    append using `results'
                    save "data/bootstrap cis for pp outcomes.dta", replace
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
        use "$dataset", clear
        bsample, strata(strata) cluster(psu)

        * ---- Generate reweighting ----
        qui do "dofiles/050_weights to estimate pp nutrition.do"

        * ---- Prepregnancy estimates ----
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

use "data/bootstrap cis for pp outcomes.dta", clear
gen str overlevel = "_" + overvar + string(level)
drop overvar level

reshape wide bmi underweight weight overweight obesity, ///
    i(iteration) j(overlevel) string

save "data/bootstrap cis for pp outcomes.dta", replace
