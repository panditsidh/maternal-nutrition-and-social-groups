use "$dataset", clear


/*


ASFRs in 5 year age groups?

in the 5 years before a women was surveyed, 
   - she contributes 2 person-years lived and 1 child born to age group 15-20 
   - and 3 person-years lived and 1 child born to age group 20-25 
      

then you can get a table that is, by age group:
   - total person years lived
   - number of births	  

at that point, get ASFR by number of births/ total person years lived
then, 5 times the sum of ASFRs gives you TFR 
   
standard errors for TFR?

*/




matrix results = J(6, 10, .)


local row = 1
foreach i of numlist 1/6 {
	

	preserve
	
	if `i'!=6 keep if group==`i'
	
	tfr2 [pweight=v005], len(3) ageg(5) bvar(b3_*) dates(v008) wbirth(v011)
	
	matrix tfr_results = r(table)
	matrix results[`i', 1] = tfr_results[1,1] // asfr 15-19
	matrix results[`i', 2] = tfr_results[1,2] // asfr 20-24
	matrix results[`i', 3] = tfr_results[1,3] // asfr 25-29
	matrix results[`i', 4] = tfr_results[1,4] // asfr 30-34
	matrix results[`i', 5] = tfr_results[1,5] // asfr 35-39
	matrix results[`i', 6] = tfr_results[1,6] // asfr 40-44
	matrix results[`i', 7] = tfr_results[1,7] // asfr 45-49
	matrix results[`i', 8] = tfr_results[1,8] // tfr
	matrix results[`i', 9] = tfr_results[5,8] // tfrll
	matrix results[`i', 10] = tfr_results[6,8] // tfrul
	
	restore
	
	local row = `row'+1
}





matrix results = results'



matrix colnames results = c1 c2 c3 c4 c5 c6


drop *
* use svmat to bring the matrix into the stata data environment and edit strings from there
input str100 rows
"ASFR 15-19"
"ASFR 20-24"
"ASFR 25-29"
"ASFR 30-34"
"ASFR 35-39"
"ASFR 40-44"
"ASFR 45-49"
"TFR"
"TFR ll"
"TFR ul"
"TFR confidence interval"
end



svmat results, names(col)

foreach i of numlist 1/6 {
	
	gen group`i' = string(c`i', "%9.2f")
	
	
	
	gen str20 tfr_ci`i' = ""
	
	
	
	
	sum c`i' if _n==9
	local tfr_ll = r(mean)
	
	sum c`i' if _n==10
	local tfr_ul = r(mean)
	
	
	replace tfr_ci`i' = "(" + string(`tfr_ll',"%9.2f") + ", " + string(`tfr_ul',"%9.2f") + ")" if _n==11
	
	replace group`i' = tfr_ci`i' if !missing(tfr_ci`i')
	
	
	
	drop c`i' tfr_ci`i'
	
}

drop if _n==9 | _n==10

#delimit ;
listtex row group* using "tables/table_tfr_by_socialgroup.tex", replace rstyle(tabular) ///
  head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{1.4cm}}}" ///
       "\toprule" ///
       " & Adivasi & Dalit & OBC & Forward & Muslim & All five social groups \\\\" ///
       "\midrule") ///
  foot("\bottomrule" "\end{tabular}");
#delimit cr
