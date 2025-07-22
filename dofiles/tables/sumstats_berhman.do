qui do "dofiles/assemble data/00_assemble prepreg sample.do"

gen blank = .

svyset psu [pw=v005], strata(strata) singleunit(centered)

#delimit ;
local varlist blank c_user less_edu rural hasboy blank 
age1519 age2024 age2529 age3049 blank 
parity_bs1 parity_bs2 parity_bs3 parity_bs4 parity_bs5 parity_bs6 parity_bs7 parity_bs8 parity_bs9 parity_bs10 blank 
wealth1 wealth2 wealth3 wealth4;
#delimit cr



foreach var in `varlist' {
    if "`var'" != "blank" {
        replace `var' = `var' * 100
    }
}

foreach i of numlist 0/1 {

local nvars : word count `varlist'
matrix results_`i' = J(`nvars', 12, .)

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
            matrix results_`i'[`row', `col'+1]   = temp[2,1]
        }
		
		if "`var'"=="blank" {
			matrix results_`i'[`row', `col']     = .
            matrix results_`i'[`row', `col'+1]   = .
		}

        local col = `col' + 2
    }
    local ++row
}


}


matrix results_all = results_1, results_0


matrix colnames results_all = ///
    mean_india_p sd_india_p ///
    mean_adivasi_p sd_adivasi_p ///
    mean_dalit_p sd_dalit_p ///
    mean_obc_p sd_obc_p ///
    mean_muslim_p sd_muslim_p ///
    mean_forward_p sd_forward_p ///
    mean_india_np sd_india_np ///
    mean_adivasi_np sd_adivasi_np ///
    mean_dalit_np sd_dalit_np ///
    mean_obc_np sd_obc_np ///
    mean_muslim_np sd_muslim_np ///
    mean_forward_np sd_forward_np	



local nrows = rowsof(results_all)
local ncols = colsof(results_all)

forvalues i = 1/`nrows' {
    forvalues j = 1/`ncols' {
        matrix results_all[`i', `j'] = round(results_all[`i', `j'], 0.01)
    }
}


// input str100 rows
// "\multicolumn{13}{l}{\textbf{Binary Predictors of Pregnancy and Underweight}}"
// "not using modern contraception" 
// "none or incomplete primary education" 
// "rural resident" 
// "does not have boy child" 
// "\multicolumn{13}{l}{\textbf{Age Categories}}"
// "15 to 19" 
// "20 to 24" 
// "25 to 29"
// "30 to 49" 
// "\multicolumn{13}{l}{\textbf{Parity \& birth spacing}}"
// "No births"  
// "1 birth, \textless{}2y spacing"
// "1 birth, 2–3y spacing"
// "1 birth, \textgreater{}3y spacing"
// "2 births, \textless{}2y spacing"
// "2 births, 2–3y spacing"
// "2 births, \textgreater{}3y spacing"
// "3+ births, \textless{}2y spacing"
// "3+ births, 2–3y spacing"
// "3+ births, \textgreater{}3y spacing"
// "\multicolumn{13}{l}{\textbf{Wealth Categories}}"
// "1st quartile" 
// "2nd quartile" 
// "3rd quartile" 
// "4th quartile" 
// ""
//
// end


input str100 rows
"\textbf{Binary Predictors of Pregnancy and Underweight}"
"not using modern contraception" 
"none or incomplete primary education" 
"rural resident" 
"does not have boy child" 
"\textbf{Age Categories}"
"15 to 19" 
"20 to 24" 
"25 to 29"
"30 to 49" 
"\textbf{Parity \& birth spacing}"
"No births"  
"1 birth, \textless{}2y spacing"
"1 birth, 2–3y spacing"
"1 birth, \textgreater{}3y spacing"
"2 births, \textless{}2y spacing"
"2 births, 2–3y spacing"
"2 births, \textgreater{}3y spacing"
"3+ births, \textless{}2y spacing"
"3+ births, 2–3y spacing"
"3+ births, \textgreater{}3y spacing"
"\textbf{Wealth Categories}"
"1st quartile" 
"2nd quartile" 
"3rd quartile" 
"4th quartile" 

end

svmat results_all, names(col)



keep row mean* sd*
drop if missing(row)

//
// #delimit ;
// listtex row ///
//      ci_adivasi_p ci_dalit_p ci_obc_p ci_muslim_p ci_forward_p ci_india_p///
//      ci_adivasi_np ci_dalit_np ci_obc_np ci_muslim_np ci_forward_np ci_india_np ///
//     using "tables/sumstats.tex", replace ///
//     rstyle(tabular) ///
//     head("\begin{tabular}{l*{12}{c}}" ///
//          "\toprule" ///
//          "& \multicolumn{6}{c}{Pregnant women (3+ months)} & \multicolumn{6}{c}{Nonpregnant women} \\\\" ///
//          "\cmidrule(lr){2-7} \cmidrule(lr){8-13}" ///
//          "Social Group & Adivasi & Dalit & OBC & Muslim & Forward & All five social groups" ///
//          " & Adivasi & Dalit & OBC & Muslim & Forward & All five social groups \\\\" ///
//          "\midrule") ///
//     foot("\bottomrule" ///
//          "\end{tabular}");
// #delimit cr


     
#delimit ;
listtex row mean_adivasi_p sd_adivasi_p mean_dalit_p sd_dalit_p mean_obc_p sd_obc_p mean_muslim_p sd_muslim_p mean_forward_p sd_forward_p mean_india_p sd_india_p mean_adivasi_np sd_adivasi_np mean_dalit_np sd_dalit_np mean_obc_np sd_obc_np mean_muslim_np sd_muslim_np mean_forward_np sd_forward_np mean_india_np sd_india_np ///
    using "tables/sumstats_sd.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{24}{c}}" ///
     "\toprule" ///
     "& \multicolumn{12}{c}{Pregnant women (3+ months)} & \multicolumn{12}{c}{Nonpregnant women} \\\\" ///
     "\cmidrule(lr){2-13} \cmidrule(lr){14-25}" ///
     "Social Group & \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Muslim} & \multicolumn{2}{c}{Forward} & \multicolumn{2}{c}{All} " ///
     "& \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Muslim} & \multicolumn{2}{c}{Forward} & \multicolumn{2}{c}{All} \\\\" ///
     "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
		 