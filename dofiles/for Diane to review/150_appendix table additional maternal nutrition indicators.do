/*


rows are social group

cols are: BMI, weight, overweight, obesity, weight gain m1, weight gain m2

*/


do "$paths"
use "data/results.dta", clear

* focus on social groups, not other subgroup divisions
keep if inlist(rows, "All five social groups", "Adivasi", "Dalit", "OBC", "Forward", "Muslim")


foreach var in bmi weight overweight obesity gainhatm1 gainhatm2 {
	
	
	
	* create CI variable for display purposes
	if inlist("`var'", "bmi", "weight", "gainhatm1", "gainhatm2") {
		
		gen `var'_ci = string(`var'_mean, "%9.1f") + " [" + ///
                   string(`var'_ll, "%9.1f") + ", " + ///
                   string(`var'_ul, "%9.1f") + "]"
		
	}
	
	if inlist("`var'", "overweight", "obesity") {
		
		gen `var'_ci = string(`var'_mean, "%9.2f") + " [" + ///
                   string(`var'_ll, "%9.2f") + ", " + ///
                   string(`var'_ul, "%9.2f") + "]"
	}
				   
	
}


keep rows bmi_ci weight_ci overweight_ci obesity_ci gainhatm1_ci gainhatm2_ci



// #delimit ;
// listtex rows  bmi_ci weight_ci overweight_ci obesity_ci gainhatm1_ci gainhatm2_ci ///
//     using "tables/addl_maternal_nutrition_table.tex", replace ///
//     rstyle(tabular) ///
//     head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{3.5cm}}}" ///
//          "\toprule" ///
//          "Social Group & \$^{a}\$BMI & \$^{b}\$Weight (kg) & \$^{c}\$Overweight & \$^{d}\$Obesity & \$^{e}\$Weight gain M1 & \$^{f}\$Weight gain M2 \\\\" ///
//          "\midrule") ///
//     foot("\bottomrule" ///
//          "\end{tabular}");
// #delimit cr



#delimit ;
listtex rows  bmi_ci weight_ci overweight_ci obesity_ci gainhatm1_ci gainhatm2_ci ///
    using "tables/addl_maternal_nutrition_table.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{3.5cm}}}" ///
         "\toprule" ///
         "\Social Group & BMI & Weight (kg) & Overweight^a & Obesity^b & Weight gain \newline method 1 (kg)^c & Weight gain \newline method 2 (kg)^d \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr


