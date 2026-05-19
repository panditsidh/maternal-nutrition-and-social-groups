do "$paths"
use "$dataset", clear

drop wealth
rename wealth_index wealth


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
    do "dofiles/00 resubmission/040 reweighting"

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
    do "dofiles/00 resubmission/040 reweighting"

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



*------------------------------------------------------------
* Format Kitagawa decomposition results for LaTeX table
* using listtex
*------------------------------------------------------------

* At this point, data should look like:
* quantity adivasigap dalitgap obcgap

* Create row order
gen order = .

replace order = 1  if quantity == "gaps"

replace order = 3  if quantity == "within group parity_bs"
replace order = 4  if quantity == "between group parity_bs"
replace order = 5  if quantity == "pct explained parity_bs"

replace order = 7  if quantity == "within group wealth"
replace order = 8  if quantity == "between group wealth"
replace order = 9  if quantity == "pct explained wealth"

replace order = 11 if quantity == "within group psu_od_besideshh_q4"
replace order = 12 if quantity == "between group psu_od_besideshh_q4"
replace order = 13 if quantity == "pct explained psu_od_besideshh_q4"


* Create row labels
gen str120 rowlabel = ""

replace rowlabel = "percentage point difference in prepregnancy underweight" ///
    if quantity == "gaps"

replace rowlabel = "pp difference within parity + birthspacing category" ///
    if quantity == "within group parity_bs"

replace rowlabel = "pp difference across parity + birthspacing category" ///
    if quantity == "between group parity_bs"

replace rowlabel = "\% explained by parity + birthspacing" ///
    if quantity == "pct explained parity_bs"

replace rowlabel = "pp difference within wealth category" ///
    if quantity == "within group wealth"

replace rowlabel = "pp difference across wealth category" ///
    if quantity == "between group wealth"

replace rowlabel = "\% explained by wealth" ///
    if quantity == "pct explained wealth"

replace rowlabel = "pp difference within PSU open defecation category" ///
    if quantity == "within group psu_od_besideshh_q4"

replace rowlabel = "pp difference across PSU open defecation category" ///
    if quantity == "between group psu_od_besideshh_q4"

replace rowlabel = "\% explained by PSU open defecation" ///
    if quantity == "pct explained psu_od_besideshh_q4"


* Format numeric columns as strings
gen str20 adivasi = string(adivasigap, "%9.1f")
gen str20 dalit   = string(dalitgap,   "%9.1f")
gen str20 obc     = string(obcgap,     "%9.1f")


* Add panel header rows
local oldN = _N
set obs `=`oldN' + 3'

replace order = 2  in `=`oldN' + 1'
replace order = 6  in `=`oldN' + 2'
replace order = 10 in `=`oldN' + 3'

replace rowlabel = "\textbf{Panel A: Decomposition by parity + birthspacing}" ///
    in `=`oldN' + 1'

replace rowlabel = "\textbf{Panel B: Decomposition by wealth}" ///
    in `=`oldN' + 2'

replace rowlabel = "\textbf{Panel C: Decomposition by fraction of other households in PSU that defecate in the open}" ///
    in `=`oldN' + 3'

gen panelheader = inlist(order, 2, 6, 10)

replace adivasi = "" if panelheader
replace dalit   = "" if panelheader
replace obc     = "" if panelheader


* Drop anything that did not get assigned to table
drop if missing(order)


* Add blank row before each panel header
expand 2 if panelheader, gen(blankrow)

replace order = order - .5 if blankrow

replace rowlabel = "" if blankrow
replace adivasi  = "" if blankrow
replace dalit    = "" if blankrow
replace obc      = "" if blankrow


* Sort final table
sort order


* Keep only display columns
keep rowlabel adivasi dalit obc


*------------------------------------------------------------
* Export with listtex
*------------------------------------------------------------

do "$paths"

#delimit ;

listtex rowlabel adivasi dalit obc
    using "tables/table2 kitagawa decomposition NEW.tex",
    replace
    rstyle(tabular)
    head(
        "\begin{tabular}{lccc}"
        "\toprule"
        " & Adivasi-Forward & Dalit-Forward & OBC-Forward \\"
        "\midrule"
    )
    foot(
        "\bottomrule"
        "\end{tabular}"
    )
;

#delimit cr
