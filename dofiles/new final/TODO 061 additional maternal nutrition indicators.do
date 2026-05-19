* Table A7: Means and 95% CIs for additional maternal nutrition indicators by social group

do "$paths"
use "data/results/grouplevel_results_with_ci.dta", clear


*------------------------------------------------------------
* Keep social groups plus India row
* India row is used as "All five social groups" for coding purposes
*------------------------------------------------------------

keep if estimate_level == "india" | estimate_level == "group"

* Keep five social groups only; drop group 6
drop if estimate_level == "group" & level == 6


*------------------------------------------------------------
* Create display order and row labels
*------------------------------------------------------------

gen order = .
replace order = 1 if estimate_level == "group" & level == 1
replace order = 2 if estimate_level == "group" & level == 2
replace order = 3 if estimate_level == "group" & level == 3
replace order = 4 if estimate_level == "group" & level == 4
replace order = 5 if estimate_level == "group" & level == 5
replace order = 6 if estimate_level == "india"

gen str40 rows = ""
replace rows = "Adivasi" if estimate_level == "group" & level == 1
replace rows = "Dalit"   if estimate_level == "group" & level == 2
replace rows = "OBC"     if estimate_level == "group" & level == 3
replace rows = "Forward" if estimate_level == "group" & level == 4
replace rows = "Muslim"  if estimate_level == "group" & level == 5
replace rows = "All five social groups" if estimate_level == "india"

keep if !missing(order)
sort order


*------------------------------------------------------------
* Create CI variables for display
*------------------------------------------------------------

foreach var in bmi weight overweight obesity {

    * Convert weight from kg to lbs
    if "`var'" == "weight" {
        replace `var'_mean = `var'_mean * 2.20462
        replace `var'_ll   = `var'_ll   * 2.20462
        replace `var'_ul   = `var'_ul   * 2.20462
    }

    * BMI and weight: one decimal place
    if inlist("`var'", "bmi", "weight") {
        gen `var'_ci = string(`var'_mean, "%9.1f") + " [" + ///
                       string(`var'_ll,   "%9.1f") + ", " + ///
                       string(`var'_ul,   "%9.1f") + "]"
    }

    * Overweight and obesity: two decimal places
    if inlist("`var'", "overweight", "obesity") {
        gen `var'_ci = string(`var'_mean, "%9.2f") + " [" + ///
                       string(`var'_ll,   "%9.2f") + ", " + ///
                       string(`var'_ul,   "%9.2f") + "]"
    }

}


*------------------------------------------------------------
* Keep final display variables
*------------------------------------------------------------

keep rows bmi_ci weight_ci overweight_ci obesity_ci


*------------------------------------------------------------
* Export LaTeX table
*------------------------------------------------------------

#delimit ;

listtex rows bmi_ci weight_ci overweight_ci obesity_ci ///
    using "tables/tableA6 additional maternal nutrition indicators NEW.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{4}{>{\centering\arraybackslash}p{3.5cm}}}" ///
         "\toprule" ///
         "Social Group & BMI & Weight (lbs) & Overweight$^{a}$ & Obesity$^{b}$ \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");

#delimit cr
