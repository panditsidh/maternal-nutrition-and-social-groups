
/*

we want 

main result in one column

another column: husbands underweight whose

*/




/*

we want underweight among men who's wives are pregnant or gave birth in the last year

*/





/*

via questionnaire: men's height and weight is taken only if they are
- one of three men in the household
- not above age of 55
- household is selected for state module (???)


via hhmr 
- hb13: result of height weight measurement for men
- sh10a: men age 15+
- shmweight: household weight - male subsample

we want to know
- prepregnant underweight
- underweight men who's wife is pregnant/ birth in last year
- % husband not in household


- % of eligible male sample not surveyed (refused)



if shmweight is not 0, the household's men are not eligible



rule for not surveyed
- shmweight is not 0 and hv118==1 (husband is eligible)
- 


*/

* prepare the household member recode for merge - we need this for men's bmi
use "$nfhs5hmr", clear

keep if hv104==1 // men

* clean men's bmi variable
gen husband_bmi = hb40 if !inlist(hb40, 9998, 9999)
replace husband_bmi = husband_bmi/100
replace husband_bmi = . if inlist(hb40, 9996, 9997, 9998, .)
gen husband_underweight = husband_bmi<18.5

rename hv000 v000
rename hv001 v001 // cluster number
rename hv002 v002 // household number
rename hvidx v034 // respondent's line number should match line number of husband
tempfile nfhs5hmr 
save `nfhs5hmr'



* prepare the household recode for merge - we need this for bmi measurement eligibility for husbands not at home

use hv000 hv001 hv002 shmweight using "$nfhs5hr"

rename hv000 v000
rename hv001 v001 // cluster number
rename hv002 v002 // household number
rename shmweight hh_shmweight

tempfile nfhs5hr
save `nfhs5hr'


use "$dataset", clear

* married women
keep if v501==1

gen birthinlastyear = v209>=1

* merge women to their households to determine men's bmi measurement eligibility
merge m:1 v000 v001 v002 using `nfhs5hr'
keep if _merge==3
drop _merge

* merge women to their husband in household member recode for bmi measurements 
merge m:1 v000 v001 v002 v034 using `nfhs5hmr'

* 436,791 married women match to their husband in the hhmr
* drop men in hhmr who don't match to a women in ir
drop if _merge==2

* of the 60,254 women who's husband was not found in hhmr, almost all report "husband not in household"

* via questionnaire: men should be measured if "household selected for state module" & age 15-54


gen husband_not_home = v034==0
gen state_module = shmweight!=0 if !missing(shmweight)
gen husband_eligible_age = inrange(hb1, 15, 54)
gen husband_ineligible = shmweight==0 | husband_eligible_age==0
gen bmi_measured = hb13==0
gen bmi_notmeasured = hb13!=0

replace state_module = hh_shmweight!=0 if missing(state_module)

* we need to know whether if a woman's husband WAS present, he would be measured (based on household in state module, and his age)

* problem is, for 83% of "not at home" husbands, we don't know their age

* COME BACK TO THIS 

svyset psu [pw=v005], strata(strata) singleunit(centered)
matrix R = J(6, 5, .)
matrix colnames R = mean ll ul refusals migrants
matrix rownames R = Adivasi Dalit OBC Forward Muslim All_groups

foreach i of numlist 1/6 {
    preserve
		
		* focus on men who's wife is currently pregnant
		keep if preg==1
		
		* focus on men in social group i (& all groups i==6)
		if `i'!=6 keep if group==`i'
		
		* get the percent of men missing from eligible households 
		keep if state_module
		svy: mean husband_not_home
		matrix H = r(table)
        local migrant = H[1,1]
	
		 * now focus on husbands that we were able to match that are eligible for bmi measurement
        keep if husband_ineligible==0 & _merge==3
		
		* get the percent not measured
		svy: mean bmi_notmeasured 
		matrix U = r(table)
        local refusals = U[1,1]
		
		* now restrict to men who were actually measured (were present and didn't refuse) and get percent underweight
        keep if bmi_measured
		
        svy: mean husband_underweight 
        matrix M = r(table)
        local mean = M[1,1]
        local ll   = M[5,1]
        local ul   = M[6,1]
    restore
	
	
	

    matrix R[`i', 1] = `mean'
    matrix R[`i', 2] = `ll'
    matrix R[`i', 3] = `ul'
	matrix R[`i', 4] = `refusals'
	matrix R[`i', 5] = `migrant'
}

matlist R

clear
* convert matrix into a dataset using svmat
input str100 rows
"Adivasi"
"Dalit"
"OBC"
"Forward"
"Muslim"
"All five social groups"
end


svmat R, names(col)

drop if missing(rows)

keep rows-migrants


gen husband_underweight = string(mean, "%9.2f") + " [" + ///
                   string(ll, "%9.2f") + ", " + ///
                   string(ul, "%9.2f") + "]"

gen refusals_ci = string(refusals, "%9.2f")

gen migrants_ci = string(migrants, "%9.2f")
				   
				   
keep rows husband_underweight refusals_ci migrants_ci


tempfile husband_results
save `husband_results'


use "data/results.dta", clear

keep if _n<=6

gen underweight_ci = string(underweight_mean, "%9.2f") + " [" + ///
                   string(underweight_ll, "%9.2f") + ", " + ///
                   string(underweight_ul, "%9.2f") + "]"


keep rows underweight_ci

gen __ord = _n

				   
merge 1:1 rows using `husband_results', nogen


sort __ord
drop __ord

#delimit ;
listtex rows underweight_ci husband_underweight refusals_ci migrants_ci ///
    using "tables/husband_underweight_table.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l>{\centering\arraybackslash}p{3cm}>{\centering\arraybackslash}p{3.6cm}*{2}{>{\centering\arraybackslash}p{3cm}}}" ///
     "\toprule" ///
     "Social Group & \shortstack{Underweight \\ (prepregnant women)$^1$} & \shortstack{Underweight \\ (husbands \\ of pregnant women)$^2$} & \shortstack{Eligible but \\ not measured (\%)$^3$} & Not at home (\%)$^4$ \\\\" ///
     "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr


* this code is in case you have keep if preg==1 | birthinlastyear instead of just keep if preg==1

// #delimit ;
// listtex rows underweight_ci husband_underweight refusals_ci migrants_ci ///
//     using "tables/husband_underweight_table2.tex", replace ///
//     rstyle(tabular) ///
//     head("\begin{tabular}{l>{\centering\arraybackslash}p{3cm}>{\centering\arraybackslash}p{3.6cm}*{2}{>{\centering\arraybackslash}p{3cm}}}" ///
//      "\toprule" ///
//      "Social Group & \shortstack{Underweight \\ (prepregnant women)$^1$} & \shortstack{Underweight \\ (husbands of women \\ pregnant or \\ $\le$1 year postpartum)$^2$} & \shortstack{Eligible but \\ not measured (\%)$^3$} & Not at home (\%)$^4$ \\\\" ///
//      "\midrule") ///
//     foot("\bottomrule" ///
//          "\end{tabular}");
// #delimit cr




