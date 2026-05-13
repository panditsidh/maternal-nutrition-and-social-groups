


use "/Users/sidhpandit/Desktop/data/nfhs/nfhs5hr/IAHR7EFL.DTA", clear


//generate variables for analyzing surveys with complex designs
egen strata = group(hv000 hv024 hv025)
*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.

replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)


gen open_defecates = inlist(hv205,30,31)

gen od = open_defecates

gen group = .
replace group = 1 if sh49==2 // Adivasi
replace group = 2 if sh49==1 // Dalit
replace group = 5 if sh47==2 & group==. // Muslims that aren't SC or ST
replace group = 3 if inlist(sh47,1,4) // OBC that are Hindu or Sikh
replace group = 4 if sh47==1 & inlist(sh49,4,8,.) // forward caste Hindu



gen adivasi = group==1 & !missing(group)
gen dalit = group==2 & !missing(group)
gen obc = group==3 & !missing(group)
gen forward = group==4 & !missing(group)
gen muslim = group==5 & !missing(group)


gen ones = 1 


preserve


* you need to remove the weights for the leave household out case i think
collapse (mean) adivasi dalit obc forward muslim open_defecates (sum) od ones [aw=hv005], by(psu)

foreach var in adivasi dalit obc forward muslim open_defecates {
	
	rename `var' pct_psu_`var'
	
}

rename ones total_households
rename od total_odhh_psu



tempfile psu_share_group
save `psu_share_group'


restore



merge m:1 psu using `psu_share_group', nogen

gen besideshh_od_psu = total_odhh_psu - open_defecates

gen pct_psu_od_besideshh = besideshh_od_psu/(total_households-1)

gen pct_psu_different = pct_psu_dalit + pct_psu_obc + pct_psu_forward + pct_psu_muslim if dalit==1
replace pct_psu_different = pct_psu_adivasi + pct_psu_obc + pct_psu_forward + pct_psu_muslim if adivasi==1
replace pct_psu_different = pct_psu_adivasi + pct_psu_dalit + pct_psu_forward + pct_psu_muslim if obc==1
replace pct_psu_different = pct_psu_adivasi + pct_psu_dalit + pct_psu_obc + pct_psu_muslim if forward==1
replace pct_psu_different = pct_psu_adivasi + pct_psu_dalit + pct_psu_obc + pct_psu_forward if muslim==1

gen pct_psu_higher = pct_psu_obc + pct_psu_forward + pct_psu_muslim if inlist(group,1,2)
replace pct_psu_higher = pct_psu_forward if obc==1



rename hv000 v000
rename hv001 v001
rename hv002 v002
rename hv024 v024
rename hv025 v025


keep v000 v001 v002 v024 v025 pct_psu_higher pct_psu_forward pct_psu_different pct_psu_open_defecates pct_psu_od_besideshh
 
* common PSU-level variable for decomposition
gen pct_forward_psu = pct_psu_forward


tempfile hh_psu_share_group
save `hh_psu_share_group'



use "$dataset", clear

merge m:1 v000 v001 v002 v024 v025 using `hh_psu_share_group'

keep if _merge==3
drop _merge



gen pct_outrank_bin = 1 if pct_psu_higher==0
replace pct_outrank_bin = 2 if pct_psu_higher>0 & pct_psu_higher<=0.1
replace pct_outrank_bin = 3 if pct_psu_higher>0.1 & pct_psu_higher<=0.333333
replace pct_outrank_bin = 4 if pct_psu_higher>0.333333 & pct_psu_higher<=0.666666
replace pct_outrank_bin = 5 if pct_psu_higher>0.666666


label define pct_outrank_lbl ///
    1 "Nobody outranks" ///
    2 "Low pct outranks" ///
    3 "Medium pct outranks" ///
    4 "Large pct outranks"  ///
	5 "Substantial pct outranks" 
label values pct_outrank_bin pct_outrank_lbl






gen fwd_psu_bin = .
replace fwd_psu_bin = 0 if pct_forward_psu == 0
replace fwd_psu_bin = 1 if pct_forward_psu > 0    & pct_forward_psu <= .10
replace fwd_psu_bin = 2 if pct_forward_psu > .10  & pct_forward_psu <= .33
replace fwd_psu_bin = 3 if pct_forward_psu > .33  & pct_forward_psu <= .66
replace fwd_psu_bin = 4 if pct_forward_psu > .66  & pct_forward_psu < .

label define fwd_psu_bin_lbl ///
    0 "No forward-caste residents" ///
    1 "Low forward-caste presence" ///
    2 "Moderate forward-caste presence" ///
    3 "High forward-caste presence" ///
    4 "Majority forward-caste presence", replace

label values fwd_psu_bin fwd_psu_bin_lbl




capture drop wealth3
xtile wealth3 = v191, n(3)

label define wealth3lbl ///
    1 "Low wealth" ///
    2 "Middle wealth" ///
    3 "High wealth"

label values wealth3 wealth3lbl


gen fwd_psu_bin4 = .

replace fwd_psu_bin4 = 1 if fwd_psu_bin == 0
replace fwd_psu_bin4 = 2 if fwd_psu_bin == 1
replace fwd_psu_bin4 = 3 if fwd_psu_bin == 2
replace fwd_psu_bin4 = 4 if inlist(fwd_psu_bin,3,4)

label define fwd4lbl ///
    1 "No forward-caste residents" ///
    2 "Low forward-caste presence" ///
    3 "Moderate forward-caste presence" ///
    4 "High forward-caste presence"

label values fwd_psu_bin4 fwd4lbl


egen wealth_fwd4 = group(wealth3 fwd_psu_bin4), label





gen pct_diff_bin5 = .

replace pct_diff_bin5 = 0 if pct_psu_different == 0
replace pct_diff_bin5 = 1 if pct_psu_different > 0    & pct_psu_different <= .10
replace pct_diff_bin5 = 2 if pct_psu_different > .10  & pct_psu_different <= .33
replace pct_diff_bin5 = 3 if pct_psu_different > .33  & pct_psu_different <= .66
replace pct_diff_bin5 = 4 if pct_psu_different > .66  & pct_psu_different < .

label define pct_diff_bin5_lbl ///
    0 "No different-caste residents" ///
    1 "Low different-caste presence" ///
    2 "Moderate different-caste presence" ///
    3 "High different-caste presence" ///
    4 "Very high different-caste presence", replace

label values pct_diff_bin5 pct_diff_bin5_lbl

tab pct_diff_bin5, missing
bys group: tab pct_diff_bin5 [aw=v005], missing
bys group: tab pct_diff_bin5 if preg==1 [aw=v005], missing
bys group: tab pct_diff_bin5 if preg==0 [aw=v005], missing







*------------------------------------------------------------
* PSU open defecation bins
* pct_psu_open_defecates ranges from 0 to 1
*------------------------------------------------------------

gen psu_od_bin5 = .

replace psu_od_bin5 = 0 if pct_psu_open_defecates == 0
replace psu_od_bin5 = 1 if pct_psu_open_defecates > 0    & pct_psu_open_defecates <= .10
replace psu_od_bin5 = 2 if pct_psu_open_defecates > .10  & pct_psu_open_defecates <= .33
replace psu_od_bin5 = 3 if pct_psu_open_defecates > .33  & pct_psu_open_defecates <= .66
replace psu_od_bin5 = 4 if pct_psu_open_defecates > .66  & pct_psu_open_defecates < .

label define psu_od_bin5_lbl ///
    0 "No PSU open defecation" ///
    1 "Low PSU open defecation" ///
    2 "Moderate PSU open defecation" ///
    3 "High PSU open defecation" ///
    4 "Very high PSU open defecation", replace

label values psu_od_bin5 psu_od_bin5_lbl

label variable psu_od_bin5 "PSU open defecation category"

* Check distribution/support
tab psu_od_bin5, missing
bys group: tab psu_od_bin5 [aw=v005], missing
bys group: tab psu_od_bin5 if preg==1 [aw=v005], missing
bys group: tab psu_od_bin5 if preg==0 [aw=v005], missing



*------------------------------------------------------------
* PSU open defecation quartiles
*------------------------------------------------------------

xtile psu_od_q4 = pct_psu_open_defecates [aw=v005], nq(4)

label define psu_od_q4_lbl ///
    1 "Lowest PSU open defecation quartile" ///
    2 "Second PSU open defecation quartile" ///
    3 "Third PSU open defecation quartile" ///
    4 "Highest PSU open defecation quartile", replace

label values psu_od_q4 psu_od_q4_lbl
label variable psu_od_q4 "PSU open defecation quartile"

tab psu_od_q4, missing
bys group: tab psu_od_q4 [aw=v005], missing
bys group: tab psu_od_q4 if preg==1 [aw=v005], missing
bys group: tab psu_od_q4 if preg==0 [aw=v005], missing





xtile psu_od_besideshh_q4 = pct_psu_od_besideshh [aw=v005], nq(4)

label define psu_od_besdieshh_q4_lbl ///
    1 "Lowest PSU open defecation (besides hh) quartile" ///
    2 "Second PSU open defecation (besides hh) quartile" ///
    3 "Third PSU open defecation (besides hh) quartile" ///
    4 "Highest PSU open defecation (besides hh) quartile", replace

label values psu_od_q4 psu_od_besideshh_q4_lbl
label variable psu_od_besideshh_q4 "PSU open defecation (besides hh) quartile"

tab psu_od_q4, missing
bys group: tab psu_od_q4 [aw=v005], missing
bys group: tab psu_od_q4 if preg==1 [aw=v005], missing
bys group: tab psu_od_q4 if preg==0 [aw=v005], missing




****



*------------------------------------------------------------
* Protein-rich food consumption intensity/diversity
*
* Original coding:
* 0 = Never
* 1 = Daily
* 2 = Weekly
* 3 = Occasionally
*
* Foods:
* s731a = milk/curd
* s731b = pulses/beans
* s731e = eggs
* s731f = fish
* s731g = chicken/meat
*------------------------------------------------------------

* Indicators for daily and weekly-or-more consumption
foreach v in s731a s731b s731e s731f s731g {
    
    gen daily_`v' = .
    replace daily_`v' = 1 if `v' == 1
    replace daily_`v' = 0 if inlist(`v', 0, 2, 3)
    
    gen weeklyplus_`v' = .
    replace weeklyplus_`v' = 1 if inlist(`v', 1, 2)
    replace weeklyplus_`v' = 0 if inlist(`v', 0, 3)
	
	gen weekly_`v' = .
    replace weekly_`v' = 1 if inlist(`v', 2)
    replace weekly_`v' = 0 if inlist(`v', 0, 1, 3)
	
	gen occ_`v' = .
    replace occ_`v' = 1 if inlist(`v', 3)
    replace occ_`v' = 0 if inlist(`v', 0, 1, 2)
}

* Count number of protein-rich foods consumed daily
egen protein_daily_count = rowtotal(daily_s731a daily_s731b daily_s731e daily_s731f daily_s731g)
egen protein_daily_nonmiss = rownonmiss(daily_s731a daily_s731b daily_s731e daily_s731f daily_s731g)


* Count number consumed at least weekly
egen protein_weeklyplus_count = rowtotal(weeklyplus_s731a weeklyplus_s731b weeklyplus_s731e weeklyplus_s731f weeklyplus_s731g)
egen protein_weeklyplus_nonmiss = rownonmiss(weeklyplus_s731a weeklyplus_s731b weeklyplus_s731e weeklyplus_s731f weeklyplus_s731g)

egen protein_weekly_count = rowtotal(weekly_s731a weekly_s731b weekly_s731e weekly_s731f weekly_s731g)

replace protein_daily_count = . if protein_daily_nonmiss == 0
replace protein_weeklyplus_count = . if protein_weeklyplus_nonmiss == 0

egen protein_occ_count = rowtotal(occ_s731a occ_s731b occ_s731e occ_s731f occ_s731g)

label variable protein_daily_count "Number of protein-rich foods consumed daily"
label variable protein_weekly_count "Number of protein-rich foods consumed weekly"
label variable protein_occ_count "Number of protein-rich foods consumed weekly"
label variable protein_weeklyplus_count "Number of protein-rich foods consumed at least weekly"


*------------------------------------------------------------
* Four-category protein intensity/diversity variable
*------------------------------------------------------------

gen protein_q4 = .

replace protein_q4 = 1 if protein_weeklyplus_count <= 1
replace protein_q4 = 2 if protein_weeklyplus_count >= 2 & protein_daily_count == 0
replace protein_q4 = 3 if protein_daily_count == 1 
replace protein_q4 = 4 if protein_daily_count >= 2 & protein_daily_count < .

label define protein_q4_lab ///
    1 "0-1 protein foods weekly" ///
    2 "2+ protein foods weekly, none daily" ///
    3 "1 protein food daily" ///
    4 "2+ protein foods daily", replace
	
label values protein_q4 protein_q4_lab
label variable protein_q4 "Protein-rich food consumption intensity/diversity"

	
	
gen protein_q4v2 = .

replace protein_q4v2 = 1 if protein_daily_count == 0
replace protein_q4v2 = 2 if protein_daily_count == 1 
replace protein_q4v2 = 3 if protein_daily_count == 2
replace protein_q4v2 = 4 if protein_daily_count > 2





label define protein_q4_labv2 ///
    1 "No daily protein" ///
    2 "1 daily protein" ///
    3 "2 daily protein" ///
    4 "3+ protein foods daily", replace

label values protein_q4v2 protein_q4_labv2
label variable protein_q4v2 "Protein-rich food consumption intensity/diversity v2"




/*

try this, break up on quartiles of this variable

daily 30 
weekly 5
occaisionally 2

*/


gen protein_score = (protein_daily_count * 30 + protein_weekly_count * 5 + protein_occ_count*1)/30


xtile protein_score_quartile = protein_score, n(4)


label define protein_score_quartilelbl ///
    1 "quartile 1 protein score" ///
    2 "quartile 2 protein score" ///
    3 "quartile 3 protein score" ///
    4 "quartile 4 protein score", replace

label values protein_score_quartile protein_score_quartilelbl
label variable protein_score_quartile "Protein score quartile"



tab protein_q4, missing
bys group: tab protein_q4 [aw=v005], missing
bys group: tab protein_q4 if preg==1 [aw=v005], missing
bys group: tab protein_q4 if preg==0 [aw=v005], missing
