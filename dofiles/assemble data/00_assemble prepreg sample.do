clear all
use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* using $nfhs5ir

// keep currently married women
keep if v501==1 

//generate months since last period
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

* compare to self reported duration of current pregnancy to the months since last period
* it is different for about half the pregnant sample (45%) - the most common mismatch is when months since last period if 1 month greater than months of pregnancy
gen diff = moperiod-v214 if v213==1
tab diff

* When v214 (months pregnant) is less than 2, it is a select group of women who detect and report their pregnancies early
tab v214, m
tab v214 if v213==1
gen mopreg = v214

*If the mother does not report the duration of the pregnancy but does report the months since last period, then use months since last period.
*If months since last period is missing but months of pregnancy is not, then use month of pregnancy.
replace mopreg = moperiod if missing(v214) & v214>=2 & v213==1
replace moperiod = v214 if missing(moperiod) & v214>=2 & v213==1
replace moperiod=. if v213!=1

// mopreg is gestional duration based on reported months of pregnancy -- only 6% of pregnant women report being 9 or more months pregnant by this measure
// moperiod is gestational duration based on time since last period -- 11.3% of pregnant women report being 9 or more months pregnant by this measure.

*count women as pregnant if they are 3+ months pregnant to avoid selection
gen preg= moperiod>=3 if !missing(moperiod) 
replace preg=0 if preg==.

* drop women who report that they are 1, 2 month pregnant 
drop if moperiod==1 | moperiod==2

*This code should give the contraceptive use at the time of the survey for non-pregnant women and the contraceptive use before pregnancy for women who are currently pregnant.
*It was written for NFHS-3, in which all of the codes for contraceptive use were numeric.
*In NFHS-5, "other modern contraception" is marked with an "X," but when I copy/pasted the data, no "Xs" were found.  So, it can be used as is.
*We will drop nonpreg women who are sterilized or using modern contraception.
*Could go back and make it a reweighting variable.

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

***  non-pregnant women who are sterlized or using a modern method.
*** Could use these data to look at the sterilization failure rate.  (343 women report being pregnant and sterilized by our variables.)
***1,581 report being pregnant after using a modern method.
gen c_user = (sterilized==1 | modernmethod==1)
bysort v213: tab c_user

* social group - leave out 6 (Christians, Sikhs, or Jains who are not SC/ST/OBC)
gen groups6 = .
replace groups6 = 3 if s116 == 1  // Dalit
replace groups6 = 4 if s116 == 2 // Adivasi
replace groups6 = 5 if v130 == 2 & groups6==.   // Muslim
replace groups6 = 6 if (v130 == 3| v130==4 | v130==6) & groups6==. // Christian, Sikh, Jain
replace groups6 = 2 if (v130 == 1 |v130==4) & s116 == 3 // OBC - hindu and sikh
replace groups6 = 1 if v130 == 1 & (s116 == 4 | s116==8 |s116==.) // Forward Caste

drop if groups6==6

gen forward = groups6==1
gen obc = groups6==2
gen dalit = groups6==3
gen adivasi = groups6==4
gen muslim = group==5
gen other_group = missing(groups6)

* education vars
gen edu = 0 if inlist(v106,0,1) // none or primary
replace edu = 1 if v106==2 // secondary
replace edu = 2 if v106==3 // higher

gen less_edu = inlist(v106,0,1)
gen secondary = v106==2
gen higher = v106==3

* urban/rural
gen urban = v025==1
gen rural = v025==2

* has living boy
gen hasboy = v202 >0 & v202!=.
replace hasboy = 1 if v204 >0 & v204!=.

/*
if we want to, we can put a variable that says whether a non-pregnant woman is currently BF a child under two
for pregnant women, this variable would be coded according to whether she was BF a child under two in the month before she became pregnant
there would be code for this in the original paper
*/

*two year age bins
*if we want to get more precise, we can match age of non-pregnant women now to age of pregnant women when they became pregnant
gen age = 2 * floor(v012 / 2)

* age bins that are more coarse at lower pregnancy likelihood
gen agebin = .
replace agebin = 1 if inrange(age, 14, 17)     // low frequency
replace agebin = 2 if inrange(age, 18, 19)     // keep narrow here
replace agebin = 3 if inrange(age, 20, 21)
replace agebin = 4 if inrange(age, 22, 23)
replace agebin = 5 if inrange(age, 24, 25)
replace agebin = 6 if inrange(age, 26, 29)
replace agebin = 7 if inrange(age, 30, 34)
replace agebin = 8 if inrange(age, 35, 49)     // collapse tail
label define agebinlbl 1 "14–17" 2 "18–19" 3 "20–21" 4 "22–23" 5 "24–25" 6 "26–29" 7 "30–34" 8 "35–49"
label values agebin agebinlbl


* gen outcome variables
gen bmi = v445 if v445!=9998 & v445!= 9999
replace bmi = bmi/100

gen underweight = bmi<18.5

gen weight = v437
replace weight =. if v437>9990
replace weight =weight/10

/*we originally coded parity with living children + current pregnancy
*then decided to do it with live births
gen parity = v219 
replace parity = v219-1 if v213==1
// replace parity = 4 if parity>=4
replace parity = 3 if parity>=3
*/

gen parity = bord_01
replace parity = 0 if parity == .
replace parity = 3 if parity>=3

gen parity0 = parity==0
gen parity1 = parity==1
gen parity2 = parity==2
gen parity3 = parity==3

* gen svy vars
egen strata = group(v000 v024 v025) 
egen psu = group(v000 v001 v024 v025)

* label vars
label define edulbl ///
    0 "None or primary education" ///
    1 "Secondary education" ///
    2 "Higher education" ///
    
label values edu edulbl

label define grouplbl ///
    1 "Forward Caste" ///
    2 "OBC" ///
    3 "Dalit" ///
    4 "Adivasi" ///
    5 "Muslim" 

label values groups6 grouplbl

label var forward "Forward"
label var obc "OBC"
label var dalit "Dalit"
label var adivasi "Adivasi"
label var muslim "Muslim"
// label var sikh_jain_christian "Sikh, Jain or Christian"
label var other_group "Other social group"


label define paritylbl ///
    0 "0" ///
    1 "1" ///
    2 "2" ///
	3 "3+" ///
	
label values parity paritylbl

* gen reweighting!

// do "${reweight}"


do "dofiles/assemble data/additional reweighting variables.do"

