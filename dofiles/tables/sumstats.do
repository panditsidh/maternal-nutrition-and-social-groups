qui do "dofiles/assemble data/00_assemble prepreg sample.do"

gen blank = .


svyset psu [pw=v005], strata(strata) singleunit(centered)


#delimit ;
local varlist blank c_user less_edu rural hasboy blank blank
age1519 age2024 age2529 age3049 blank blank
parity_bs1 parity_bs2 parity_bs3 parity_bs4 parity_bs5 parity_bs6 parity_bs7 parity_bs8 parity_bs9 parity_bs10 blank blank
wealth1 wealth2 wealth3 wealth4 blank blank;
#delimit cr


foreach i of numlist 0/1 {

local nvars : word count `varlist'
matrix results_`i' = J(`nvars', 18, .)

local row = 1

* Loop over variables
foreach var in `varlist' {
	replace `var' = `var'*100
    local col = 1
	
    foreach g of numlist 0/5 {
        
        * Check if non-missing data exists for this round
        
        if "`var'"!="blank" {
						
			if `g'==0 quietly svy: mean `var' if preg==`i'
			if `g'!=0 quietly svy: mean `var' if groups6==`g' & preg==`i'
		
            matrix temp = r(table)
            
            * Extract mean, LL, UL
            matrix results_`i'[`row', `col']     = temp[1,1]
            matrix results_`i'[`row', `col'+1]   = temp[5,1]
            matrix results_`i'[`row', `col'+2]   = temp[6,1]
        }
		
		if "`var'"=="blank" {
			matrix results_`i'[`row', `col']     = .
            matrix results_`i'[`row', `col'+1]   = .
            matrix results_`i'[`row', `col'+2]   = .
		}

        local col = `col' + 3
    }
    local ++row
}


}


matrix results_all = results_1, results_0


matrix colnames results_all = ///
    mean_india_p ll_india_p ul_india_p ///
    mean_adivasi_p ll_adivasi_p ul_adivasi_p ///
    mean_dalit_p ll_dalit_p ul_dalit_p ///
    mean_obc_p ll_obc_p ul_obc_p ///
    mean_muslim_p ll_muslim_p ul_muslim_p ///
    mean_forward_p ll_forward_p ul_forward_p ///
    mean_india_np ll_india_np ul_india_np ///
    mean_adivasi_np ll_adivasi_np ul_adivasi_np ///
    mean_dalit_np ll_dalit_np ul_dalit_np ///
    mean_obc_np ll_obc_np ul_obc_np ///
    mean_muslim_np ll_muslim_np ul_muslim_np ///
    mean_forward_np ll_forward_np ul_forward_np

					  
local nrows = rowsof(results_all)
local ncols = colsof(results_all)

forvalues i = 1/`nrows' {
    forvalues j = 1/`ncols' {
        matrix results_all[`i', `j'] = round(results_all[`i', `j'], 0.01)
    }
}


input str100 rows
"\multicolumn{13}{l}{\textbf{Binary Predictors of Pregnancy and Underweight}}"

"not using modern contraception" 
"none or incomplete primary education" 
"rural resident" 
"does not have boy child" 
""
"\multicolumn{13}{l}{\textbf{Age Categories}}"
"15 to 19" 
"20 to 24" 
"25 to 29"
"30 to 49" 
""
"\multicolumn{13}{l}{\textbf{Parity \& birth spacing}}"
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
""
"\multicolumn{13}{l}{\textbf{Wealth Categories}}"
"1st quartile" 
"2nd quartile" 
"3rd quartile" 
"4th quartile" 
""

end

svmat results_all, names(col)

foreach group in india adivasi dalit obc muslim forward {
    
    gen ci_`group'_p = string(mean_`group'_p, "%4.1f") + " (" + ///
                       string(ll_`group'_p, "%4.1f") + ", " + ///
                       string(ul_`group'_p, "%4.1f") + ")" ///
                       if !missing(mean_`group'_p)

    gen ci_`group'_np = string(mean_`group'_np, "%4.1f") + " (" + ///
                         string(ll_`group'_np, "%4.1f") + ", " + ///
                         string(ul_`group'_np, "%4.1f") + ")" ///
                         if !missing(mean_`group'_np)
}

keep row ci*
drop if missing(row)


#delimit ;
listtex row ///
    ci_india_p ci_adivasi_p ci_dalit_p ci_obc_p ci_muslim_p ci_forward_p ///
    ci_india_np ci_adivasi_np ci_dalit_np ci_obc_np ci_muslim_np ci_forward_np ///
    using "tables/sumstats.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{12}{c}}" ///
         "\toprule" ///
         "& \multicolumn{6}{c}{Pregnant} & \multicolumn{6}{c}{Nonpregnant} \\\\" ///
         "\cmidrule(lr){2-7} \cmidrule(lr){8-13}" ///
         "Group & India & Adivasi & Dalit & OBC & Muslim & Forward" ///
         " & India & Adivasi & Dalit & OBC & Muslim & Forward \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr

