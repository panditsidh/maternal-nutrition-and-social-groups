if "`c(username)'" == "sidhpandit" {
	global nfhs3ir "/Users/sidhpandit/Desktop/nfhs/nfhs3ir/IAIR52FL.dta"
	global nfhs4ir "/Users/sidhpandit/Desktop/nfhs/nfhs4ir/IAIR74FL.DTA"	
	global nfhs5ir "/Users/sidhpandit/Desktop/nfhs/nfhs5ir/IAIR7EFL.DTA"
	
	global nfhs3br "/Users/sidhpandit/Desktop/nfhs/nfhs3br/IABR52FL.dta"
	global nfhs4br "/Users/sidhpandit/Desktop/nfhs/nfhs4br/IABR74FL.DTA"
	global nfhs5br "/Users/sidhpandit/Desktop/nfhs/nfhs5br/IABR7EFL.DTA"
	
	global ir_combined "/Users/sidhpandit/Desktop/ra/ir345_prepregweights.dta"
	
	global reweight "/Users/sidhpandit/Documents/GitHub/trends-in-health-in-pregnancy-overleaf-/do files/data prep/assemble data for social group pre-pregnancy/01_reweight within social group.do"
	
}

if "`c(username)'" == "dc42724" {
	global nfhs3ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\ir\IAIR52FL.dta"
	global nfhs4ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\ir\IAIR71FL.DTA"
	global nfhs5ir "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IAIR7DDT\IAIR7DFL.DTA"
	
	global nfhs3br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS06\br\IABR52FL.dta"
	global nfhs4br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS15\br\IABR71FL.DTA"
	global nfhs5br "C:\Users\dc42724\Dropbox\Data\NFHS\NFHS19\IABR7EDT\IABR7EFL.DTA"

	global reweight "C:\Users\dc42724\Documents\GitHub\trends-in-health-in-pregnancy-overleaf-\do files\data prep\assemble data for social group pre-pregnancy\01_reweight within social group.do"
	
	
}


clear all
use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s using $nfhs5ir

gen round5=(v000=="IA7")
gen round4=(v000=="IA6")
gen round3=(v000=="IA5")

gen round=5 if round5==1
replace round=4 if round4==1
replace round=3 if round3==1

keep if v501==1 // currently married women

* months since last period
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

* compare to self reported duration of current pregnancy
gen diff = moperiod-v214 if v213==1
* gen preg, an indicator for 3+ mo gestational duration
gen preg = v214>=3 if !missing(v214)
replace preg = moperiod>=3 if missing(v214)

* QUESTION:
* v214<3 are those women who detect their pregnancies early
* otherwise, 1/2 moperiod may still be nonpregnant - don't drop those
gen mopreg = v214
replace mopreg = moperiod if missing(v214) & moperiod>=3

* drop 1,2, month pregnant women (self-reportedly pregnant, v213==1)
drop if inlist(mopreg,1,2) 

* drop nonpreg women who are sterilized or using modern contraception
gen vcal_1_trim = trim(vcal_1)
gen done = 0
gen isnumber = .
gen answer = .
forvalues i = 1(1)15 {
	gen month`i' = substr(vcal_1_trim,`i',1)
	replace isnumber = real(month`i')
	replace answer = isnumber if isnumber !=.&done==0
	replace done = 1 if done == 0 & isnumber !=.
}
gen modernmethod = .
replace modernmethod = 0 if answer==0 | answer ==8 | answer==9
replace modernmethod = 1 if answer>0 & answer <8 

gen sterilized = answer==6 | answer ==7

*** QUESTION: drop all sterilized/modern method? or just non-pregnant
// drop if v213==0 & (sterilized==1 | modernmethod==1)
gen drop = (sterilized==1 | modernmethod==1)
drop if drop==1
bysort v213: tab drop

* social group - leave out 6 (C/S/J non SC/ST/OBC)
gen groups6 = .
replace groups6 = 3 if s116 == 1 & inlist(round, 4, 5) // Dalit
replace groups6 = 4 if s116 == 2 & inlist(round, 4, 5) // Adivasi
replace groups6 = 5 if v130 == 2 & groups6==. & inlist(round, 4, 5)  // Muslim
replace groups6 = 6 if (v130 == 3| v130==4 | v130==6) & groups6==. & inlist(round, 4, 5) // Christian, Sikh, Jain
replace groups6 = 2 if (v130 == 1 |v130==4) & s116 == 3 & inlist(round, 4, 5) // OBC - hindu and sikh
replace groups6 = 1 if v130 == 1 & (s116 == 4 | s116==8 |s116==.) & inlist(round, 4, 5) // Forward Caste

drop if groups6==6

gen forward = groups6==1
gen obc = groups6==2
gen dalit = groups6==3
gen adivasi = groups6==4
gen muslim = group==5
// gen sikh_jain_christian = groups6==6
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

* previous child died
preserve
	clear all
	use $nfhs5br
	sort caseid
	gen timeagodied = v008-b3
	gen diedpastfiveyr= timeagodied<60 & b5==0
	by caseid: egen diedpast5yr = max(diedpastfiveyr)
	collapse diedpast5yr, by(caseid)
	tab diedpast5yr, m
	
	tempfile nfhs_dead
	save `nfhs_dead'
restore

merge 1:1 caseid using `nfhs_dead'
drop if _merge == 2
gen childdied = diedpast5yr==1

* gen outcome variables

gen bmi = v445 if v445!=9998 & v445!= 9999
replace bmi = bmi/100

gen underweight = bmi<18.5

gen parity = v219 if v219<=3 
replace parity = 4 if v219>=4 
replace parity = parity-1 if v213==1


* gen svy vars
egen strata = group(v000 v024 v025) 
egen psu = group(v000 v001 v024 v025)

* label vars
label define roundlbl 3 "NFHS-3 (2005-2006)" 4 "NFHS-4 (2015-2016)" 5 "NFHS-5 (2019-2021)"
label values round roundlbl

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
	3 "3" ///
	4 "4+" ///
	
label values parity paritylbl







* gen reweighting!

do "${reweight}"
