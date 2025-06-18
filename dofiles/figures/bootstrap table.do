* Load and reshape
use "data/bootstrapresults_full.dta", clear
gen iteration = _n

reshape long preg pct_drop bins dropbins pct_zero count9plus bmi underweight weight nineweighthat coeffhat gainhat, ///
    i(iteration) j(groups6)

* Variables to summarize
local vars underweight bmi weight gainhat
local nvars : word count `vars'

* Initialize stat matrices
matrix means = J(5, `nvars', .)
matrix lbs   = J(5, `nvars', .)
matrix ubs   = J(5, `nvars', .)

* Fill the matrices
local c = 1
foreach var of local vars {
    preserve

    collapse (mean) mean=`var' ///
             (p5) lb=`var' ///
             (p95) ub=`var', by(groups6)

    * If underweight, multiply all by 100
    if "`var'" == "underweight" {
        replace mean = mean * 100
        replace lb   = lb   * 100
        replace ub   = ub   * 100
    }

    forvalues r = 1/5 {
        matrix means[`r', `c'] = mean[`r']
        matrix lbs[`r', `c']   = lb[`r']
        matrix ubs[`r', `c']   = ub[`r']
    }

    restore
    local ++c
}

* Stack into one matrix: [mean1 mean2 ... | lb1 lb2 ... | ub1 ub2 ...]
matrix allstats = means, lbs, ubs

* Convert to variables (using default col names: allstats1, allstats2, etc.)
svmat allstats

* Rename the variables to something readable
local i = 1
foreach var of local vars {
    rename allstats`i' mean_`var'
    local ++i
}
foreach var of local vars {
    rename allstats`i' lb_`var'
    local ++i
}
foreach var of local vars {
    rename allstats`i' ub_`var'
    local ++i
}

* Add group labels
gen group = _n
label define groups6 1 "Forward" 2 "OBC" 3 "Dalit" 4 "Adivasi" 5 "Muslim"
label values group groups6

* Generate final string variables
foreach var of local vars {
    gen result_`var' = string(round(mean_`var', 0.01), "%4.2f") + " (" + ///
                       string(round(lb_`var', 0.01), "%4.2f") + ", " + ///
                       string(round(ub_`var', 0.01), "%4.2f") + ")"
}

* Final view
keep group result_*
drop if _n>5



listtex group result_underweight result_bmi result_weight result_gainhat ///
    using "tables/bootstrap_results.tex", ///
    replace rstyle(tabular) ///
    head("\begin{tabular}{lcccc}" ///
         "\toprule" ///
         "Social Group & Underweight (\%) & BMI & Weight (kg) & Weight Gain (kg) \\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}")
