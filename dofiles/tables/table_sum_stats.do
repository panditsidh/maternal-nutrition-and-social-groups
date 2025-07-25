qui do "dofiles/assemble data/00_assemble prepreg sample.do"

gen blank = .

svyset psu [pw=v005], strata(strata) singleunit(centered)

#delimit ;
local varlist blank c_user less_edu rural hasboy blank 
age1519 age2024 age2529 age3049 blank 
parity_bs1 parity_bs2 parity_bs3 parity_bs4 parity_bs5 parity_bs6 parity_bs7 parity_bs8 parity_bs9 parity_bs10 blank 
wealth1 wealth2 wealth3 wealth4;
#delimit cr



// foreach var in `varlist' {
//     if "`var'" != "blank" {
//         replace `var' = `var' * 100
//     }
// }

foreach i of numlist 0/1 {

local nvars : word count `varlist'
matrix results_`i' = J(`nvars'+1, 6, .)

local row = 1

* Loop over variables
foreach var in `varlist' {
    local col = 1
	
	display("`var'")
    foreach g of numlist 0/5 {
        
		
        * Check if non-missing data exists for this round
        
        if "`var'"!="blank" {
						
			if `g'==0 quietly svy: mean `var' if preg==`i'
			if `g'!=0 quietly svy: mean `var' if groups6==`g' & preg==`i'
		
            matrix temp = r(table)
            
            * Extract mean, LL, UL
            matrix results_`i'[`row', `col']     = temp[1,1]
        }
		
		if "`var'"=="blank" {
			matrix results_`i'[`row', `col']     =  .
		}

        local col = `col' + 1
    }
    local ++row
}

	*last row
	local col = 1
	foreach g of numlist 0/5 {
		
		if `g' == 0 count if preg==`i'
		if `g' != 0 count if preg==`i' & groups6==`g'
		matrix results_`i'[`row', `col'] = r(N)
		local col = `col' + 1
		
	}

}


matrix results_all = results_1, results_0

matrix colnames results_all = ///
    mean_india_p  ///
    mean_adivasi_p  ///
    mean_dalit_p  ///
    mean_obc_p  ///
    mean_muslim_p  ///
    mean_forward_p  ///
    mean_india_np  ///
    mean_adivasi_np  ///
    mean_dalit_np  ///
    mean_obc_np  ///
    mean_muslim_np  ///
    mean_forward_np 	


local nrows = rowsof(results_all)
local ncols = colsof(results_all)

// forvalues i = 1/`nrows' {
//     forvalues j = 1/`ncols' {
//         matrix results_all[`i', `j'] = round(results_all[`i', `j'], 0.01)
//     }
// }



input str100 rows
"\textbf{Binary Predictors of Pregnancy and Underweight}"
"\hspace*{2em}not using modern contraception" 
"\hspace*{2em}no education or incomplete primary" 
"\hspace*{2em}rural resident" 
"\hspace*{2em}does not have boy child" 
"\textbf{Age Categories}"
"\hspace*{2em}15 to 19" 
"\hspace*{2em}20 to 24" 
"\hspace*{2em}25 to 29"
"\hspace*{2em}30 to 49" 
"\textbf{Categories for parity and spacing from last birth}"
"\hspace*{2em}No births"  
"\hspace*{2em}1 birth, \textless{}2y spacing"
"\hspace*{2em}1 birth, 2–3y spacing"
"\hspace*{2em}1 birth, \textgreater{}3y spacing"
"\hspace*{2em}2 births, \textless{}2y spacing"
"\hspace*{2em}2 births, 2–3y spacing"
"\hspace*{2em}2 births, \textgreater{}3y spacing"
"\hspace*{2em}3+ births, \textless{}2y spacing"
"\hspace*{2em}3+ births, 2–3y spacing"
"\hspace*{2em}3+ births, \textgreater{}3y spacing"
"\textbf{Wealth Categories}"
"\hspace*{2em}1st quartile" 
"\hspace*{2em}2nd quartile" 
"\hspace*{2em}3rd quartile" 
"\hspace*{2em}4th quartile" 
"\textbf{Sample size}"
end


svmat results_all, names(col)



foreach group in india adivasi dalit obc muslim forward {
	
    
    gen ci_`group'_p = substr(string(mean_`group'_p, "%4.2f"), 2, .) if row!="\textbf{Sample size}"

	
    gen ci_`group'_np = substr(string(mean_`group'_np, "%4.2f"), 2, .) if row!="\textbf{Sample size}"
						 
	replace ci_`group'_p = string(mean_`group'_p, "%15.0fc") if row == "\textbf{Sample size}"
	replace ci_`group'_np = string(mean_`group'_np, "%15.0fc") if row == "\textbf{Sample size}"

}

keep row ci*
gen blank = ""
gen blank2 = ""

gen is_header = regexm(row, "\\textbf")
gen order = _n

gen insert_blank = is_header[_n+1]  // this flags the row *before* each header
replace insert_blank = 0 if missing(insert_blank)

expand 2 if insert_blank
expand 2 if missing(row) & row[_n+1]=="\textbf{Sample size}"

bysort order (insert_blank): replace row = "" if _n == 2 & insert_blank

foreach var of varlist ci_* {
    replace `var' = "" if row == ""
}


drop if missing(insert_blank)
drop is_header order insert_blank

#delimit ;
listtex row ///
     ci_adivasi_p ci_dalit_p ci_obc_p ci_forward_p ci_muslim_p ci_india_p ///
     ci_adivasi_np ci_dalit_np ci_obc_np ci_forward_np ci_muslim_np ci_india_np ///
    using "tables/sumstats.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{0.9cm}}@{\hspace{3em}}*{6}{>{\centering\arraybackslash}p{0.9cm}}}" ///
         "\toprule" ///
         "& \multicolumn{6}{c}{Pregnant women (3+ months)} & \multicolumn{6}{c}{Nonpregnant women} \\\\" ///
         "Social Group & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny All five & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny All five \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr




//
// #delimit ;
// listtex row ///
//      ci_adivasi_p ci_dalit_p ci_obc_p ci_forward_p ci_muslim_p ci_india_p ///
//      ci_adivasi_np ci_dalit_np ci_obc_np ci_forward_np ci_muslim_np ci_india_np ///
//     using "tables/sumstats.tex", replace ///
//     rstyle(tabular) ///
//     head("\begin{tabular}{l*{12}{c}}" ///
//      "\toprule" ///
//      "& \multicolumn{6}{c}{Pregnant women (3+ months)} & \multicolumn{6}{c}{Nonpregnant women} \\\\" ///
//      "\cmidrule(lr){2-7} \cmidrule(lr){8-13}" ///
//      "Social Group & Adivasi & Dalit & OBC & Forward & Muslim & \shortstack{All five\\\\social groups} & Adivasi & Dalit & OBC & Muslim & Forward & \shortstack{All five\\\\social groups} \\\\" ///
//      "\midrule") ///
//     foot("\bottomrule" ///
//          "\end{tabular}");
// #delimit cr




