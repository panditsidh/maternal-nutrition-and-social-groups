

do "$paths"

use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 m15* using "$nfhs5ir", clear

********************************* SOCIAL GROUP *********************************
//This paper only analyzes data for women beloning to the following groups:
*Adivasi and Dalit (all religions)∂
*OBC (Hindu and Sikh)
*Forward Caste (Hindu)
*Muslim 
//It does not include women who are Christians or Jains who do not identify as Dalit or Adivasi, and it does not include women who are Sikhs who do not identify as Adivasi, Dalit, or OBC.

gen group = .
replace group = 1 if s116 == 2 									// Adivasi
replace group = 2 if s116 == 1 									// Dalit
replace group = 6 if (v130 == 3| v130==4 | v130==6) & group==. // Christian, Sikh, Jain
replace group = 5 if v130 == 2 & group==. 						// Muslims that aren't Adivasi or Dalit
replace group = 3 if (v130 == 1 |v130==4) & s116 == 3 			// OBC that are Hindu or Sikh
replace group = 4 if v130 == 1 & (s116 == 4 | s116==8 |s116==.) // Forward caste Hindus

drop if group==6
drop if group==.

label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward" ///
    5 "Muslim" 
label values group grouplbl

* we want 7 age specific fertility rates (5 year age groups), total fertility rate, and confidence intervals for total fertility rate by social group
matrix results = J(6, 10, .)

* use tfr 2 command and hard code the stored results into a matrix with our formatting requirement
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




* use svmat to bring the matrix into the stata data environment and export using listtex
matrix results = results'
matrix colnames results = c1 c2 c3 c4 c5 c6


drop *
* use svmat to bring the matrix into the stata data environment and edit strings from there
input str100 rows
"15-19"
"20-24"
"25-29"
"30-34"
"35-39"
"40-44"
"45-49"
"TFR"
"TFR ll"
"TFR ul"
"95\% CI for TFR"
end



svmat results, names(col)

foreach i of numlist 1/6 {
	
	gen group`i' = string(c`i', "%9.2f")
	
	
	
	gen str20 tfr_ci`i' = ""
	
	
	sum c`i' if _n==9
	local tfr_ll = r(mean)
	
	sum c`i' if _n==10
	local tfr_ul = r(mean)
	
	
	replace tfr_ci`i' = "[" + string(`tfr_ll',"%9.2f") + ", " + string(`tfr_ul',"%9.2f") + "]" if _n==11
	
	replace group`i' = tfr_ci`i' if !missing(tfr_ci`i')
	
	
	
	drop c`i' tfr_ci`i'
	
}

drop if _n==9 | _n==10


#delimit ;
listtex row group* using "tables/tableA7 fertility rate by social group.tex", replace rstyle(tabular) ///
  head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{1.9cm}}}" ///
       "\toprule" ///
       "ASFR & Adivasi & Dalit & OBC & Forward & Muslim & All five social groups \\\\" ///
       "\midrule") ///
  foot("\bottomrule" "\end{tabular}");
#delimit cr
