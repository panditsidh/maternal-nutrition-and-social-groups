do "$paths"
use "$dataset", clear

tempname decompresults
tempfile decompresultsfile

capture postclose `decompresults'

postfile `decompresults' ///
    str100 quantity ///
    double adivasigap dalitgap obcgap ///
    using `decompresultsfile', replace


*------------------------------------------------------------
* Outcome and decomposition variables
*------------------------------------------------------------
eststo clear

local outcome underweight
local decompvars parity_bs wealth psu_od_besideshh_q4


*------------------------------------------------------------
* First calculate total gaps
*------------------------------------------------------------
foreach g in 1 2 3 {

    use "$dataset", clear

    global binvars agebin rural less_edu noboy group 
    do "dofiles/new final/050 bootstrap"

    * forward caste prepreg outcome
    quietly sum `outcome' [aw=reweightingfxn] if group == 4 & preg == 0
    local fwd_`outcome' = r(mean) * 100

    * group g prepreg outcome
    quietly sum `outcome' [aw=reweightingfxn] if group == `g' & preg == 0
    local group_`g'_`outcome' = r(mean) * 100

    * gap to be explained, in percentage points
    local diff_`g' = `group_`g'_`outcome'' - `fwd_`outcome''

}

post `decompresults' ///
    ("gaps") ///
    (`diff_1') (`diff_2') (`diff_3')


*------------------------------------------------------------
* Kitagawa decompositions
*------------------------------------------------------------
foreach decompvar in `decompvars' {

    use "$dataset", clear

    global binvars agebin rural less_edu noboy group `decompvar' 
    do "dofiles/new final/050 bootstrap"

    levelsof `decompvar' if !missing(`decompvar'), local(decompvarlevels)

    foreach g in 1 2 3 {

        local within_group_`g' = 0
        local between_group_`g' = 0

        foreach p in `decompvarlevels' {

            tempvar level_indicator
            gen `level_indicator' = (`decompvar' == `p') if !missing(`decompvar')

            * proportion of forward caste pregnant women at predictor level p
            quietly sum `level_indicator' if group == 4 & preg == 1 [aw=v005]
            local fwd_wt_`p' = r(mean)

            * proportion of group g pregnant women at predictor level p
            quietly sum `level_indicator' if group == `g' & preg == 1 [aw=v005]
            local g_wt_`p' = r(mean)

            drop `level_indicator'

            * prepreg outcome of forward caste women at predictor level p
            quietly sum `outcome' if group == 4 & `decompvar' == `p' & preg == 0 [aw=reweightingfxn]
            local fwd_outcome_`p' = r(mean) * 100

            * prepreg outcome of group g women at predictor level p
            quietly sum `outcome' if group == `g' & `decompvar' == `p' & preg == 0 [aw=reweightingfxn]
            local g_outcome_`p' = r(mean) * 100

            * within-group / unexplained component
            local within_level_`p' = ///
                (`g_outcome_`p'' - `fwd_outcome_`p'') * ///
                (`g_wt_`p'' + `fwd_wt_`p'') / 2

            * between-group / compositional component
            local between_level_`p' = ///
                (`g_wt_`p'' - `fwd_wt_`p'') * ///
                (`g_outcome_`p'' + `fwd_outcome_`p'') / 2

            * add level components to group totals
            local within_group_`g' = ///
                `within_group_`g'' + `within_level_`p''

            local between_group_`g' = ///
                `between_group_`g'' + `between_level_`p''

        }

        * percent explained
        local pct_group_`g' = (`between_group_`g'' / `diff_`g'') * 100

    }

    post `decompresults' ///
        ("within group `decompvar'") ///
        (`within_group_1') (`within_group_2') (`within_group_3')

    post `decompresults' ///
        ("between group `decompvar'") ///
        (`between_group_1') (`between_group_2') (`between_group_3')

    post `decompresults' ///
        ("pct explained `decompvar'") ///
        (`pct_group_1') (`pct_group_2') (`pct_group_3')

}

postclose `decompresults'

use `decompresultsfile', clear
