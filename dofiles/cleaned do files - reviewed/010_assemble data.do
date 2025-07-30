use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 using $nfhs5ir, clear

//generate variables for analyzing surveys with complex designs
egen strata = group(v000 v024 v025) 
*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
replace strata = 7 if strata==8
egen psu = group(v000 v001 v024 v025)

// keep currently married women because the NFHS only asks childbearing questions to married women
keep if v501==1 

********************************* SOCIAL GROUP *********************************

//This paper only analyzes data for women beloning to the following groups:
*Adivasi and Dalit (all religions)
*OBC (Hindu and Sikh)
*Forward Caste (Hindu)
*Muslim 
//It does not include women who are Christians or Jains who do not identify as Dalit or Adivasi, and it does not include women who are Sikhs who do not identify as Adivasi, Dalit, or OBC.
gen groups6 = .
replace groups6 = 3 if s116 == 1  // Dalit
replace groups6 = 4 if s116 == 2 // Adivasi
replace groups6 = 5 if v130 == 2 & groups6==.   // Muslim
replace groups6 = 6 if (v130 == 3| v130==4 | v130==6) & groups6==. // Christian, Sikh, Jain
replace groups6 = 2 if (v130 == 1 |v130==4) & s116 == 3 // OBC - hindu and sikh
replace groups6 = 1 if v130 == 1 & (s116 == 4 | s116==8 |s116==.) // Forward Caste

drop if groups6==6
drop if groups6==.

gen forward = groups6==1
gen obc = groups6==2
gen dalit = groups6==3
gen adivasi = groups6==4
gen muslim = group==5

label define grouplbl ///
    1 "Forward" ///
    2 "OBC" ///
    3 "Dalit" ///
    4 "Adivasi" ///
    5 "Muslim" 
label values groups6 grouplbl




**************************** GESTATIONAL DURATION ******************************

//generate months since last period in order to exclude women who are 1 or 2 months pregnant from the analysis.
gen moperiod = .
replace moperiod = 1 if v215>=101 & v215 <= 128 
replace moperiod = 2 if v215>=129 & v215 <= 156 
replace moperiod = 3 if v215>=157 & v215 <= 184 
replace moperiod = 4 if v215>=185 & v215 <= 198 
replace moperiod = 1 if v215>=201 & v215 <= 204 
replace moperiod = 2 if v215>=205 & v215 <= 208 
replace moperiod = 3 if v215>=209 & v215 <= 213 
replace moperiod = 1 if v215==301 
replace moperiod = 2 if v215==302 
replace moperiod = 3 if v215==303 
replace moperiod = 4 if v215==304 
replace moperiod = 5 if v215==305 
replace moperiod = 6 if v215==306 
replace moperiod = 7 if v215==307 
replace moperiod = 8 if v215==308 
replace moperiod = 9 if v215==309 
replace moperiod = 10 if v215==310 
replace moperiod = 11 if v215==311 

//months since last period is not reported for 1,274 women who also report pregnancy.  use self-reported "months pregnant" as a measure of gestational duration for those women.
//this allows us to assign a gestational duration for all but 5 women who report pregnancy.
count if moperiod==. & v213==1
gen gestdur = moperiod
replace gestdur = v214 if missing(moperiod) & v213==1
tab gestdur if v213==1, m

//create an appendix table to explain why we drop women who report 1, 2, or missing months of gestational duration.
tab gestdur if v213==1, m

//for the purpose of computing synthetic prepregnancy underweight, we will count women as pregnant if they have gestational duration as 3 or more months.  Those who report 1 or 2 months, or no duration, are a select sample who know about their pregnancies earlier than others.
drop if gestdur == 1 & v213==1
drop if gestdur == 2 & v213==1
drop if gestdur==. & v213==1

//Create a variable "preg" to distinguish between the two groups.
gen preg = v213 == 1
tab preg, m



**************************** CONTRACEPTIVE USE ********************************

//Create the variables that will be used to match pregnant and nonpregnant women for the estimation of prepregnancy underweight.
*contraceptive user (binary)
*age (4 categories)
*education (binary)
*rural resident (binary)
*parity and time since last birth (10 categories)
*wealth (4 categories)
// 

*contraceptive user
//This code identifies contraceptive use at the time of the survey for non-pregnant women and the contraceptive use before pregnancy for women who are currently pregnant.
//The Stata code below only accomodates numeric options as answers for the contraceptive use questions. In the NFHS-5 women's questionnaire, "other modern contraception" is listed as an option denoted by an "X," but no "Xs" were recorded in the contraceptive calendars.  So, the code can be used as is.
//We note that 1,554 pregnant women (7% of pregnant women) became pregnant while using a modern method.  337 (1.4%) of pregnant women became pregnant while sterilized.

gen vcal_1_trim = trim(vcal_1)
gen done = 0
gen isnumber = .
gen answer = .
forvalues i = 1(1)15 {
	gen month`i' = substr(vcal_1_trim,`i',1)
	replace isnumber = real(month`i')
	replace answer = isnumber if isnumber !=. & done==0
	replace done = 1 if done == 0 & isnumber !=.
}
gen modernmethod = .
replace modernmethod = 0 if answer==0
replace modernmethod = 1 if answer>0 & answer <=8 

gen sterilized = answer==1 | answer ==2
gen c_user = (sterilized==1 | modernmethod==1)
bysort v213: tab c_user

label define c_userlbl ///
    0 "not using contraception" ///
    1 "using contraception" 
label values c_user c_userlbl



**************************** BIRTH HISTORY ********************************

* has living boy
//v202 is "sons at home"
//v204 is "sons elsewhere"
//it is not missing for any pregnant or nonpregnant women
gen hasboy = v202 >0 & v202!=.
replace hasboy = 1 if v204 >0 & v204!=.
gen noboy = hasboy
recode noboy (1=0) (0=1)
tab hasboy noboy, m

label define noboylbl ///
    1 "does not have boy child" ///
    0 "has at least one boy child" 
label values noboy noboylbl

*age
gen agebin = .
replace agebin = 1 if inrange(v012, 15, 19)     // Teens
replace agebin = 2 if inrange(v012, 20, 24)     // Highest fertility
replace agebin = 3 if inrange(v012, 25, 29)     // Lower fertility
replace agebin = 4 if inrange(v012, 30, 49)     // Lowest fertility

label define agebinlbl 1 "15–19" 2 "20–24" 3 "25–29" 4 "30–34" 5 "35–49"
label values agebin agebinlbl

gen age1519 = agebin==1
gen age2024 = agebin==2
gen age2529 = agebin==3
gen age3049 = agebin==4

*parity and time since last birth (10 categories)
//bord_01 tells us how many live births the woman has had
//we will code "parity" as 1, 2, 3, 4 (1 - no live births 2 - one live birth 3 - two live births 4 - three or more live births)
gen parity = bord_01 + 1 if !missing(bord_01)
replace parity = 1 if missing(bord_01)
replace parity = 4 if parity>=4 

gen parity0 = parity==0
gen parity1 = parity==1
gen parity2 = parity==2
gen parity3 = parity==3
gen parity4 = parity==4


//birth spacing is time between last delivery and interview for non-pregnant women and time between last delivery and estimated conception of current pregnancy for pregnant women
//it is only defined for women that have had at least one live birth
//v008 is the date of the interview and b3 is the date of birth of the child
gen birth_space = (v008 - b3_01) + 9 if preg==0 & !missing(b3_01)
replace birth_space = (v008 - b3_01) + (9-gestdur) if preg==1 & !missing(b3_01)

gen birth_space_cat = .
replace birth_space_cat = 1 if birth_space < 24
replace birth_space_cat = 2 if inrange(birth_space, 24, 36)
replace birth_space_cat = 3 if birth_space > 36
replace birth_space_cat = 9 if parity<2 // so that it can still be a reweighting bin

gen bs_below2 = birth_space_cat==1
gen bs_2to3 = birth_space_cat==2
gen bs_above3 = birth_space_cat==3
gen bs_noprior = birth_space_cat==9

label define paritylbl ///
    1 "1 (no live births)" ///
    2 "2 (1 live birth)" ///
	3 "3 (2 live births)" ///
	4 "4+ (3+ live births)" 	
label values parity paritylbl

label define birth_space_catlbl /// 
	1 "under 2 years" ///
	2 "2-3 years" ///
	3 "over 3 years" ///
 	9 "no previous birth" 
label values birth_space_cat birth_space_catlbl

//now generate a variable that combines parity and birth spacing
gen parity_bs = .
replace parity_bs = 1 if parity==1

local i = 2
foreach p of numlist 2/4 {
	
	foreach b of numlist 1/3 {
		
		replace parity_bs = `i' if parity==`p' & birth_space_cat==`b'		
		local i = `i' + 1
	}
}


forvalues i = 1/10 {
    gen parity_bs`i' = parity_bs == `i'
}

label define parity_bs_lbl ///
    1 "No births/1 birth, NA spacing" ///
    2 "1 birth, <2y spacing" ///
    3 "1 birth, 2–3y spacing" ///
    4 "1 birth, 3+y spacing" ///
    5 "2 births, <2y spacing" ///
    6 "2 births, 2–3y spacing" ///
    7 "2 births, 3+y spacing" ///
    8 "3+ births, <2y spacing" ///
    9 "3+ births, 2–3y spacing" ///
   10 "3+ births, 3+y spacing"
label values parity_bs parity_bs_lbl



**************************** SOCIOECONOMIC ************************************

*education
//this is a binary indicator for whether the woman's highest completed grade is "no education" or in the "primary" grades.
//it is not missing for any of the pregnant or nonpregnant women.
gen less_edu = inlist(v106,0,1)
tab less_edu, m

label define lessedulbl ///
    0 "none or incomplete primary education" ///
    1 "primary education or higher" 
label values less_edu lessedulbl


* rural resident
//it is not missing for any of the pregnant or nonpregnant women.
gen rural = v025==2
tab rural, m

label define rurallbl ///
    0 "not a rural resident" ///
    1 "rural resident" 
label values rural rurallbl



*wealth (4)
//it is not missing for any of the pregnant or nonpregnant women.
xtile wealth=v191, n(4)
gen wealth1 = wealth==1
gen wealth2 = wealth==2
gen wealth3 = wealth==3
gen wealth4 = wealth==4

tab preg wealth, m

label define wealthlbl ///
    1 "1st quartile" ///
    2 "2nd quartile" ///
    3 "3rd quartile" ///
    4 "4th quartile" 
label values wealth wealthlbl

**************************** OUTCOME ************************************

//Our outcome variable is "underweight," defined as having a BMI less than 18.5.
gen bmi = v445 if v445!=9998 & v445!= 9999
replace bmi = bmi/100

gen underweight = bmi<18.5

//We may use measured weight as an outcome in supplementary analyses.
gen weight = v437
replace weight =. if v437>9990
replace weight =weight/10

save "data\prepared_dataset.dta", replace