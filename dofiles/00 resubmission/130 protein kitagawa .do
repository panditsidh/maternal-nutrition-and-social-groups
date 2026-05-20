/********************************************************************
Purpose:
    Protein-only Kitagawa decomposition of prepregnancy underweight gaps

Output:
    tables/table2 kitagawa decomposition protein.tex
********************************************************************/

clear all
set more off

do "$paths"

tempname decompresults
tempfile decompresultsfile

capture postclose `decompresults'

postfile `decompresults' ///
    str100 quantity ///
    double adivasigap dalitgap obcgap ///
    using `decompresultsfile', replace


*------------------------------------------------------------
* Outcome and decomposition variable
*------------------------------------------------------------

local outcome underweight
local decompvar protein_q4


*------------------------------------------------------------
* First calculate total gaps
*------------------------------------------------------------

use "$dataset", clear

global binvars agebin rural less_edu noboy group
do "dofiles/00 resubmission/040 reweighting"

* Forward caste prepreg outcome
quietly sum `outcome' [aw=reweightingfxn] if group == 4 & preg == 0
local fwd_`outcome' = r(mean) * 100

* Adivasi, Dalit, OBC prepreg outcomes and gaps
foreach g in 1 2 3 {

    quietly sum `outcome' [aw=reweightingfxn] if group == `g' & preg == 0
    local group_`g'_`outcome' = r(mean) * 100

    local diff_`g' = `group_`g'_`outcome'' - `fwd_`outcome''

}

post `decompresults' ///
    ("gaps") ///
    (`diff_1') (`diff_2') (`diff_3')


*------------------------------------------------------------
* Kitagawa decomposition by protein_q4
*------------------------------------------------------------

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

        * Proportion of forward caste pregnant women at protein level p
        quietly sum `level_indicator' if group == 4 & preg == 1 [aw=v005]
        local fwd_wt_`p' = r(mean)

        * Proportion of group g pregnant women at protein level p
        quietly sum `level_indicator' if group == `g' & preg == 1 [aw=v005]
        local g_wt_`p' = r(mean)

        drop `level_indicator'

        * Prepreg underweight of forward caste women at protein level p
        quietly sum `outcome' if group == 4 & `decompvar' == `p' & preg == 0 [aw=reweightingfxn]
        local fwd_outcome_`p' = r(mean) * 100

        * Prepreg underweight of group g women at protein level p
        quietly sum `outcome' if group == `g' & `decompvar' == `p' & preg == 0 [aw=reweightingfxn]
        local g_outcome_`p' = r(mean) * 100

        * Within-group / unexplained component
        local within_level_`p' = ///
            (`g_outcome_`p'' - `fwd_outcome_`p'') * ///
            (`g_wt_`p'' + `fwd_wt_`p'') / 2

        * Between-group / compositional component
        local between_level_`p' = ///
            (`g_wt_`p'' - `fwd_wt_`p'') * ///
            (`g_outcome_`p'' + `fwd_outcome_`p'') / 2

        local within_group_`g' = ///
            `within_group_`g'' + `within_level_`p''

        local between_group_`g' = ///
            `between_group_`g'' + `between_level_`p''

    }

    local pct_group_`g' = (`between_group_`g'' / `diff_`g'') * 100

}

post `decompresults' ///
    ("within group protein_q4") ///
    (`within_group_1') (`within_group_2') (`within_group_3')

post `decompresults' ///
    ("between group protein_q4") ///
    (`between_group_1') (`between_group_2') (`between_group_3')

post `decompresults' ///
    ("pct explained protein_q4") ///
    (`pct_group_1') (`pct_group_2') (`pct_group_3')


postclose `decompresults'

use `decompresultsfile', clear


*------------------------------------------------------------
* Format results for LaTeX table
*------------------------------------------------------------

gen order = .

replace order = 1 if quantity == "gaps"
replace order = 3 if quantity == "within group protein_q4"
replace order = 4 if quantity == "between group protein_q4"
replace order = 5 if quantity == "pct explained protein_q4"

gen str120 rowlabel = ""

replace rowlabel = "percentage point difference in prepregnancy underweight" ///
    if quantity == "gaps"

replace rowlabel = "pp difference within protein consumption category" ///
    if quantity == "within group protein_q4"

replace rowlabel = "pp difference across protein consumption category" ///
    if quantity == "between group protein_q4"

replace rowlabel = "\% explained by protein consumption" ///
    if quantity == "pct explained protein_q4"


* Format numeric columns as strings
gen str20 adivasi = string(adivasigap, "%9.1f")
gen str20 dalit   = string(dalitgap,   "%9.1f")
gen str20 obc     = string(obcgap,     "%9.1f")


* Add panel header row
local oldN = _N
set obs `=`oldN' + 1'

replace order = 2 in `=`oldN' + 1'
replace rowlabel = "\textbf{Decomposition by protein consumption}" ///
    in `=`oldN' + 1'

gen panelheader = order == 2

replace adivasi = "" if panelheader
replace dalit   = "" if panelheader
replace obc     = "" if panelheader


* Add blank row before panel header
expand 2 if panelheader, gen(blankrow)

replace order = order - .5 if blankrow

replace rowlabel = "" if blankrow
replace adivasi  = "" if blankrow
replace dalit    = "" if blankrow
replace obc      = "" if blankrow


sort order

keep rowlabel adivasi dalit obc


*------------------------------------------------------------
* Export with listtex
*------------------------------------------------------------

#delimit ;

listtex rowlabel adivasi dalit obc
    using "tables/table2 kitagawa decomposition protein.tex",
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
