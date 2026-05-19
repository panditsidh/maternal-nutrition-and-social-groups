/*


The final version will have the following 

- wealth, quintile
- parity bs, 10 categories
- open defecation, quartiles (?)
- fraction higher ranking: <0.75, <0.5, <0.25, <0.1
- 4 category protein 


Each one will have a different reweighting (core vars + current var)





*/






* This dofile gets us appendix table #???? which shows the number of women in each subgroup and percent of pregnant women dropped in reweighting.

 
do "$paths"
use "$dataset", clear

drop if group==6|group==.
do "dofiles/050_weights to estimate pp nutrition.do"


* dummy variables for looping and table format
gen all_predictors = 1
gen blank = .


matrix results = J(19, 12, .)
local row = 1

* loop over the predictor variables: 10 category parity & birth spacing and wealth quartiles
foreach over_predictor in blank parity_bs blank blank wealth blank all_predictors {
	
	* creates blank rows in the table
	if "`over_predictor'"=="blank" {
		foreach i of numlist 1/12 { 
			matrix results[`row', `i'] = .
		}
		local ++row
	}
	
	
	* we want N and % pregnant women dropped for each predictor level within each social group
	levelsof(`over_predictor'), local(predictor_levels)
	foreach i in `predictor_levels' {
		
		local col = 1
		foreach g of numlist 0/5 {
			
			
			if `g'==0 qui count if preg==1 & `over_predictor'==`i'
			else qui count if preg==1 & group==`g' & `over_predictor'==`i'
			
			matrix results[`row', `col'] = r(N)
			
			if `g'==0 qui sum dropbin if preg==1 & `over_predictor'==`i'
			else qui sum dropbin if preg==1 & group==`g' & `over_predictor'==`i'
			
			matrix results[`row', `col'+1] = round(r(mean)*100, .01)
			
			local col = `col'+2
		}
		
		local ++row		
	}
	
}

* now the matrix is populated, use svmat to bring it into the stata data environment and export using listtex
matrix colnames results = ///
	n_allgroups /// 
	pctdrop_allgroups ///
	n_group1 ///
	pctdrop_group1 ///
	n_group2 ///
	pctdrop_group2 ///
	n_group3 ///
	pctdrop_group3 ///
	n_group4 ///
	pctdrop_group4 ///
	n_group5 ///
	pctdrop_group5 ///
	
	
drop *

input str100 rows
"\textbf{Parity and time since last live birth categories}"
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
" "
"\textbf{Wealth Categories}"
"\hspace*{2em}1st quartile" 
"\hspace*{2em}2nd quartile" 
"\hspace*{2em}3rd quartile" 
"\hspace*{2em}4th quartile"
" " 
"\textbf{All predictor groups}"
end

svmat results, names(col)

*-------------------------------*
* Format N columns with commas
*-------------------------------*
foreach v of varlist n_* {
    gen str20 disp_`v' = cond(missing(`v'), "", string(`v', "%15.0fc"))
}

* Keep pctdrop formatted as before (or create disp_ versions too)
foreach v of varlist pctdrop_* {
    gen str10 disp_`v' = cond(missing(`v'), "", string(`v', "%4.2f"))
}


drop if missing(rows)


foreach v of varlist pctdrop_* {
    format `v' %4.2f
}

preserve 
keep rows disp*



#delimit ;
listtex rows ///
    disp_n_allgroups disp_pctdrop_allgroups ///
    disp_n_group1    disp_pctdrop_group1 ///
    disp_n_group2    disp_pctdrop_group2 ///
    disp_n_group3    disp_pctdrop_group3 ///
    disp_n_group4    disp_pctdrop_group4 ///
    disp_n_group5    disp_pctdrop_group5 ///
    using "tables/tableA4 percent dropped.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{12}{>{\centering\arraybackslash}p{1.2cm}}}" ///
         "\toprule" ///
         "& \multicolumn{2}{c}{\shortstack{All five \\\\ social groups}} & \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Forward} & \multicolumn{2}{c}{Muslim} \\\\" ///
         "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9} \cmidrule(lr){10-11} \cmidrule(lr){12-13}" ///
         "Predictor Group & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr


// #delimit ;
// listtex rows ///
//     n_allgroups pctdrop_allgroups ///
//     n_group1 pctdrop_group1 ///
//     n_group2 pctdrop_group2 ///
//     n_group3 pctdrop_group3 ///
//     n_group4 pctdrop_group4 ///
//     n_group5 pctdrop_group5 ///
//     using "tables/tableA3 percent dropped.tex", replace ///
//     rstyle(tabular) ///
//     head("\begin{tabular}{l*{12}{>{\centering\arraybackslash}p{1.2cm}}}" ///
//          "\toprule" ///
//          "& \multicolumn{2}{c}{\shortstack{All five \\\\ social groups}} & \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Forward} & \multicolumn{2}{c}{Muslim} \\\\" ///
//          "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9} \cmidrule(lr){10-11} \cmidrule(lr){12-13}" ///
//          "Predictor Group & n & \% dropped & n & \% dropped & n & \% dropped & n & \% dropped & n & \% dropped & n & \% dropped \\\\" ///
//          "\midrule") ///
//     foot("\bottomrule" ///
//          "\end{tabular}");
// #delimit cr
