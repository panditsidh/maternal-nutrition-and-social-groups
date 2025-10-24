
/*

we want 

main result in one column

another column: husbands underweight whose

*/



use "data/results.dta", clear

keep if _n<=6

gen underweight_ci = string(underweight_mean, "%9.2f") + " [" + ///
                   string(underweight_ll, "%9.2f") + ", " + ///
                   string(underweight_ul, "%9.2f") + "]"

keep rows underweight_ci



/*

we want underweight among men who's wives are pregnant or gave birth in the last year

*/

use "$dataset", clear




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


gen state_module = shmweight!=0
gen husband_eligible_age = inrange(hb1, 15, 54)
gen husband_ineligible = shmweight==0 | husband_eligible_age==0
gen bmi_measured = hb13==0

gen bmi_notmeasured = hb13!=0

* we need to know whether if a woman's husband WAS present, he would be measured (based on household in state module, and his age)

* problem is, for 83% of "not at home" husbands, we don't know their age

* COME BACK TO THIS

* 




svyset psu [pw=v005], strata(strata) singleunit(centered)
matrix R = J(5, 4, .)
matrix colnames R = mean ll ul refusals
matrix rownames R = Adivasi Dalit OBC Forward Muslim

foreach i of numlist 1/5 {
    preserve
	
		* focus on men in social group i who's wife is currently pregnant
		keep if group==`i' & preg==1
	
		* focus husbands that we were able to match that are eligible for bmi measurement
        keep if husband_ineligible==0 & _merge==3
		
		* get the percent not measured
		svy: mean bmi_notmeasured 
		matrix U = r(table)
        local refusals = U[1,1]
		
		* now restrict to men who were actually measured (were present and didn't refuse)
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
}

matlist R





svyset psu [pw=v005], strata(strata) singleunit(centered)


preserve 

keep if state_module & husband_eligible_age & _merge==3

svy: mean husband_underweight if group==1 & preg==1



mat M = r(table)

local mean = M[1,1]
local ll   = M[5,1]
local ul   = M[6,1]

display "Mean: `mean'"
display "95% CI: (`ll', `ul')"





// do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"
//
// eststo clear
// eststo woman: reg v201 v201
//
// foreach i of numlist 1/5 {
//	
// 	sum underweight [aw=reweightingfxn] if group==`i' & preg==0
//	
// 	local group`i' = r(mean)*100
//	
// 	eststo woman: estadd scalar group`i' = `group`i''
// }
//
// eststo husband: reg v201 v201
//
// foreach i of numlist 1/5 {
//	
// 	sum husband_underweight [aw=reweightingfxn] if group==`i' & !missing(husband_underweight) & preg==0
//	
// 	local group`i' = r(mean)*100
//	
// 	eststo husband: estadd scalar group`i' = `group`i''
//	
// 	count if !missing(husband_underweight) & preg==0 & group==`i'
//	
// 	local sample1`i' = r(N)
// }
//
//
// eststo men_1yo: reg v201 v201
//
// foreach i of numlist 1/5 {
//	
// 	sum husband_underweight [aw=v005] if group==`i' & !missing(husband_underweight) & v209==1
//	
// 	local group`i' = r(mean)*100
//	
// 	eststo men_1yo: estadd scalar group`i' = `group`i''
//	
// 	count if !missing(husband_underweight) & v209==1 & group==`i'
//	
// 	local sample2`i' = r(N)
//	
// }
//
//
// #delimit ;
// esttab woman husband using "tables/apdx_husbands.tex", replace 
//     stats(group1 group2 group3 group4 group5, 
//           label("Adivasi n=`sample11'" "Dalit n=`sample12'" "OBC n=`sample13'" "Forward n=`sample14'" "Muslim n=`sample15'")) 
//     drop(v201 _cons)
//     mtitles("\shortstack{Underweight among \\ prepregnant women}"
//             "\shortstack{Underweight among \\ prepregnant women's \\ husbands}")
//     nonumbers nonote;
// #delimit cr
//
// #delimit ;
// esttab men_1yo using "tables/apdx_men1yo.tex", replace
//     stats(group1 group2 group3 group4 group5, 
//           label("Adivasi n=`sample21'" "Dalit n=`sample22'" "OBC n=`sample23'" "Forward n=`sample24'" "Muslim n=`sample25'")) 
//     drop(v201 _cons)
//     mtitles("\shortstack{Underweight among men \\ whose wife gave birth \\ in the last year}")
//     nonumbers nonote;
// #delimit cr






