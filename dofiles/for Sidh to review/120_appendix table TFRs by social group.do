 

// use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 using $nfhs5ir, clear


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


matrix colnames results = asfr1519 asfr2024 asfr2529 asfr3034 asfr3539 asfr4044 asfr4549 tfr tfrll tfrul

* use svmat to bring the matrix into the stata data environment and edit strings from there
input str100 rows
"Adivasi"
"Dalit"
"OBC"
"Forward"
"Muslim"
"All five social groups"
end



svmat results, names(col)




foreach v in asfr1519 asfr2024 asfr2529 asfr3034 asfr3539 asfr4044 asfr4549 tfr tfrll tfrul {
	
	gen str_`v' = string(`v', "%9.2g")
	replace str_`v' = "0" + str_`v' if substr(str_`v',1,1)=="."
}


keep rows str_*


drop if missing(rows)





#delimit ;
listtex row str* using "tables/tfr.tex", replace rstyle(tabular) ///
    head("\begin{tabular}{l>{\centering\arraybackslash}p{1.4cm}}" ///
         "\toprule" ///
         "Social group & ASFR 15-19 & ASFR 20-24 & ASFR 30-34 & ASFR 40-44 & ASFR 45-49 \\\\" ///
         "\midrule") ///
    foot("\bottomrule" "\end{tabular}");
#delimit cr





