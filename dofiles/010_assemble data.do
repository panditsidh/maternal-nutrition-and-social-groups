do "$paths"

use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 using "$nfhs5ir", clear

//generate variables for analyzing surveys with complex designs
egen strata = group(v000 v024 v025)
*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
replace strata = 7 if strata==8
egen psu = group(v000 v001 v024 v025)

**Keep only married women
keep if v501==1

count

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

// drop if group==6
drop if group==.

/*number of married women dropped because they are not in social group 1, 2, 3, 4, or 5*/
count if group == 6

di (1780+9877)/512408

label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward" ///
    5 "Muslim" 
label values group grouplbl

gen adivasi = group==1
gen dalit = group==2
gen obc = group==3
gen forward = group==4
gen muslim = group==5
gen allfivegroups = 1

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


count if moperiod==. & v213==1
//months since last period is not reported for ~1000 women who also report pregnancy.  use self-reported "months pregnant" as a measure of gestational duration for those women.
//this allows us to assign a gestational duration for all but 5 women who report pregnancy.

gen gestdur = moperiod if v213==1
replace gestdur = v214 if missing(moperiod) & v213==1

//divide the number for whom "gestdur" is filled with v214 by the number of pregnant women

//create an appendix table to explain why we drop women who report 1, 2, or missing months of gestational duration.
tab gestdur if v213==1, m

//Create a variable "preg" to distinguish between the two groups.
* we define it as those who self report being pregnant and have gestational duration of 3 months or more (defining gestdur as months since last period and self reported gestational duration if that is unavailable)
gen preg = v213
replace preg = . if gestdur<3 & v213==1
gen gestdur_3plus = gestdur>=3 if !missing(gestdur) & v213==1


**Note that there are still 230 people missing due to the problem described above.

**************************** CONTRACEPTIVE USE ********************************

//Create the variables that will be used to match pregnant and nonpregnant women for the estimation of prepregnancy underweight.
*not using modern contraception (binary)
*age (4 categories)
*less education (binary)
*rural resident (binary)
*parity and time since last birth (10 categories)
*wealth (4 categories)
// 

*not a contraceptive user
//This code identifies contraceptive use at the time of the survey for non-pregnant women and the contraceptive use in the month before conception/pregnancy for women who are currently pregnant.
//The Stata code below only accomodates numeric options as answers for the contraceptive use questions. In the NFHS-5 women's questionnaire, "other modern contraception" is listed as an option denoted by an "X," but no "Xs" were recorded in the contraceptive calendars.  So, the code can be used as is.
//We note that 1,554 pregnant women (2.44% of pregnant women) became pregnant while using a modern method.  only 4 of 23,246 currently pregnant women became pregnant despite herself sterilized and only 2 despite her husband sterilized

/*

this is the DHS recode key for modern method contraception

i put (is a modern method) next to the methods that v313 considers modern

B -Birth
T - Terminated pregnancy/non-live birth
P - Pregnancy
0 - Non-use of contraception
1 - Pill (is a modern method)
2 - IUD (is a modern method)
3 - Injectables (is a modern method)
4 - Diaphragm (is a modern method)
5 - Condom (is a modern method)
6 - Female sterilization (is a modern method)
7 - Male sterilization (is a modern method)
8 - Periodic abstinence/rhythm
9 - Withdrawal
W - Other traditional methods
N - Implants (is a modern method)
A - Abstinence
L - Lactational amenorrhea method (LAM) (is a modern method)
C - Female condom (is a modern method)
F - Foam and Jelly (is a modern method)
E1 - Emergency contraception (DHSVI) (is a modern method)
S1 - Standard days method (DHSVI) (is a modern method)
M1 - Other modern method (DHSVI) (is a modern method)
? - Unknown method/missing data

*/



gen modernmethod = .
replace modernmethod = (v313 == 3) if preg == 0

gen precon_pos = indexnot(trim(vcal_1), "P")
gen precon_code = substr(trim(vcal_1), precon_pos,1) if preg==1


replace modernmethod = inlist(precon_code,"1","2","3","4","5","6","7") if preg==1
replace modernmethod = inlist(precon_code, "L","C","F","N","S","M") if preg==1

gen female_ster = .
gen male_ster   = .
gen sterilized    = .

* Nonpregnant: use v312 (current method)
replace female_ster = (v312==6) if preg==0
replace male_ster   = (v312==7) if preg==0

* Pregnant: use calendar code month before conception
replace female_ster = (precon_code=="6") if preg==1
replace male_ster   = (precon_code=="7") if preg==1

replace sterilized = (female_ster==1 | male_ster==1)

gen c_user = (sterilized==1 | modernmethod==1)
bysort v213: tab c_user

gen not_c_user = c_user
recode not_c_user (0=1) (1=0)

label define not_c_userlbl ///
    1 "not using modern contraception" ///
    0 "using contraception" 
label values not_c_user not_c_userlbl


**************************** BIRTH HISTORY ********************************

* does not have living boy child
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


label define agebinlbl 1 "15–19" 2 "20–24" 3 "25–29" 4 "30–49"
label values agebin agebinlbl

gen age1519 = agebin==1
gen age2024 = agebin==2
gen age2529 = agebin==3
gen age3049 = agebin==4




*age
gen agebin2 = .
replace agebin2 = 1 if inrange(v012, 15, 19)     // Teens
replace agebin2 = 2 if inrange(v012, 20, 24)     // Highest fertility
replace agebin2 = 3 if inrange(v012, 25, 29)     // Lower fertility
replace agebin2 = 4 if inrange(v012, 30, 34)     // Lowest fertility
replace agebin2 = 5 if inrange(v012, 35, 49)     // Lowest fertility

gen agebin3 = .
replace agebin3 = 1 if inrange(v012, 15, 19)     // Teens
replace agebin3 = 2 if inrange(v012, 20, 22)     // Highest fertility
replace agebin3 = 3 if inrange(v012, 23, 25)     // Lower fertility
replace agebin3 = 4 if inrange(v012, 26, 29)     // Lowest fertility
replace agebin3 = 5 if inrange(v012, 30, 34)     // Lowest fertility
replace agebin3 = 6 if inrange(v012, 35, 49)

gen agebin4 = .
replace agebin4 = 1 if inrange(v012, 15, 17)     // Teens
replace agebin4 = 2 if inrange(v012, 18, 20)     // Highest fertility
replace agebin4 = 3 if inrange(v012, 21, 23)     // Lower fertility
replace agebin4 = 4 if inrange(v012, 24, 26)     // Lowest fertility
replace agebin4 = 5 if inrange(v012, 27, 30)     // Lowest fertility
replace agebin4 = 6 if inrange(v012, 31, 34)
replace agebin4 = 7 if inrange(v012, 35, 49)

*parity and time since last birth (10 categories)
//bord_01 tells us how many live births the woman has had
//we will code "parity" as 1, 2, 3, 4 (1 - no live births 2 - one live birth 3 - two live births 4 - three or more live births)
gen parity = bord_01 + 1 if !missing(bord_01)
replace parity = 1 if missing(bord_01)
replace parity = 4 if parity>=4 

gen parity1 = parity==1
gen parity2 = parity==2
gen parity3 = parity==3
gen parity4 = parity==4

//birth spacing is time between last delivery and interview for non-pregnant women and time between last delivery and estimated conception of current pregnancy for pregnant women
//it is only defined for women that have had at least one live birth
//v008 is the date of the interview and b3 is the date of birth of the child
gen birth_space = (v008 - b3_01) + 9 if preg==0 & !missing(b3_01)
replace birth_space = (v008 - b3_01) + (9-gestdur) if preg==1 & !missing(b3_01)

gen bs = .
replace bs = 1 if birth_space < 24
replace bs = 2 if inrange(birth_space, 24, 36)
replace bs = 3 if birth_space > 36

gen bs_below2 = bs==1
gen bs_2to3 = bs==2
gen bs_above3 = bs==3
gen bs_noprior = parity<2

label define paritylbl ///
    1 "1 (no live births)" ///
    2 "2 (1 live birth)" ///
	3 "3 (2 live births)" ///
	4 "4+ (3+ live births)" 	
label values parity paritylbl

label define bslbl /// 
	1 "under 2 years" ///
	2 "2-3 years" ///
	3 "over 3 years" 

label values bs bslbl

//now generate a variable that combines parity and birth spacing
gen parity_bs = .
replace parity_bs = 1 if parity==1

local i = 2
foreach p of numlist 2/4 {
	
	foreach b of numlist 1/3 {
		
		replace parity_bs = `i' if parity==`p' & bs==`b'		
		local i = `i' + 1
	}
}



forvalues i = 1/10 {
    gen parity_bs`i' = parity_bs == `i'
}

label define parity_bs_lbl ///
    1 "No births/1 birth, NA spacing" ///
    2 "1 birth, below 2y spacing" ///
    3 "1 birth, 2–3y spacing" ///
    4 "1 birth, 3+y spacing" ///
    5 "2 births, below 2y spacing" ///
    6 "2 births, 2–3y spacing" ///
    7 "2 births, 3+y spacing" ///
    8 "3+ births, below 2y spacing" ///
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
    0 "primary education or higher" ///
    1 "less than primary education" 
label values less_edu lessedulbl


* rural resident
//it is not missing for any of the pregnant or nonpregnant women.
gen rural = v025==2

gen urban = rural==0
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
gen overweight = bmi>25 
gen obesity = bmi>30

//We may use measured weight as an outcome in supplementary analyses.
gen weight = v437
replace weight =. if v437>9990
replace weight =weight/10


drop if c_user==1 & preg==0
save "$dataset", replace
