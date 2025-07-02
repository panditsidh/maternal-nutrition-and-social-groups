* Load and reshape bootstrap results

local rounds 3 5

foreach round in `rounds' {
	
if `round'==3 {
	use "data/bootstrapresults_full_nfhs3.dta", clear
}

if `round'==5 {
	use "data/bootstrapresults_full.dta", clear
}


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

    * If underweight, scale to percentage
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

* Stack into one matrix
matrix allstats = means, lbs, ubs
svmat allstats

* Rename variables
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

* Generate formatted string variables
foreach var of local vars {
    gen result_`var' = string(round(mean_`var', 0.01), "%4.2f") + " (" + ///
                       string(round(lb_`var', 0.01), "%4.2f") + ", " + ///
                       string(round(ub_`var', 0.01), "%4.2f") + ")"
}

* Save bootstrap summary temporarily
keep group result_*
drop if _n > 5
tempfile summary
save `summary'

* Load original sample to compute sample size of 3+ mo pregnant women

if `round'==3 {
	qui do "dofiles/assemble data/prepare nfhs3 data.do"
}

if `round'==5 {
	qui do "dofiles/assemble data/00_assemble prepreg sample.do"
}


gen preg3plus = mopreg >= 3 & preg==1
collapse (sum) preg3plus, by(groups6)
rename groups6 group
rename preg3plus sample_preg3plus

* Merge with bootstrap summary
merge 1:1 group using `summary'
drop _merge

* Export final table
listtex group result_underweight result_bmi result_weight result_gainhat sample_preg3plus ///
    using "tables/bootstrap_results_`round'.tex", ///
    replace rstyle(tabular) ///
    head("\begin{tabular}{lccccr}" ///
         "\toprule" ///
         "Social Group & Underweight (\%) & BMI & Weight (kg) & Weight Gain (kg) & N (≥3 mo pregnant) \\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}")

}
