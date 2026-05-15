use "$nfhs5hr", clear

*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
egen strata = group(hv000 hv024 hv025)
replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)


gen open_defecates = inlist(hv205,30,31)
gen od = open_defecates


preserve

collapse (sum) od ones [aw=hv005], by(psu)

rename ones total_households
rename od total_odhh_psu

tempfile psu_hh_counts
save `psu_hh_counts'

global psu_hh_counts_path "`psu_hh_counts'"


restore

merge m:1 psu using `psu_hh_counts', nogen



use "$nfhs5hr", clear

*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
egen strata = group(hv000 hv024 hv025)
replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)


* define group based on the household head
gen group = .
replace group = 1 if sh49==2 // Adivasi
replace group = 2 if sh49==1 // Dalit
replace group = 5 if sh47==2 & group==. // Muslims that aren't SC or ST
replace group = 3 if sh49==3 & inlist(sh47,1,4) // OBC that are Hindu or Sikh
replace group = 4 if sh47==1 & inlist(sh49,4,8,.) & group==. // forward caste Hindu

label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward" ///
    5 "Muslim" 
label values group grouplbl

gen adivasi = group==1 & !missing(group)
gen dalit = group==2 & !missing(group)
gen obc = group==3 & !missing(group)
gen forward = group==4 & !missing(group)
gen muslim = group==5 & !missing(group)

* save this for later to compare with "group" from the individual file
gen hr_group = group


* get the weighted shares of each group at the psu level
preserve

collapse (mean) adivasi dalit obc forward muslim open_defecates [aw=hv005], by(psu)

foreach var in adivasi dalit obc forward muslim open_defecates {
	
	rename `var' pct_psu_`var'
	
}


tempfile psu_share_group
save `psu_share_group'

global psu_share_group_path "`psu_share_group'"


restore


* merge, to the household level
* (1) the psu level weighted shares of social group
* and (2) psu level counts of households and open defecating households

merge m:1 psu using `psu_share_group', nogen
merge m:1 psu using `psu_hh_counts', nogen


* generate the var: share of psu that defecates in the open, leaving out the household
gen besideshh_od_psu = total_odhh_psu - open_defecates
gen pct_psu_od_besideshh = besideshh_od_psu/(total_households-1)


* prepare for merge to the individual level dataset
rename hv000 v000
rename hv001 v001
rename hv002 v002
rename hv024 v024
rename hv025 v025


keep v000 v001 v002 v024 v025  pct_psu_adivasi pct_psu_dalit pct_psu_obc pct_psu_forward pct_psu_muslim  pct_psu_different pct_psu_open_defecates pct_psu_od_besideshh hr_group sh49 sh47


tempfile hh_psu_share_group
save `hh_psu_share_group'



use "$dataset", clear

merge m:1 v000 v001 v002 v024 v025 using `hh_psu_share_group'


keep if _merge==3
drop _merge

* generate the var: percent of households in the psu where hh head is higher caste than the woman
* this variable is only defined for sc, st, obc women
gen pct_psu_higher = pct_psu_obc + pct_psu_forward + pct_psu_muslim if inlist(group,1,2)
replace pct_psu_higher = pct_psu_forward if obc==1

gen pct_outrank_bin = 1 if pct_psu_higher==0
replace pct_outrank_bin = 2 if pct_psu_higher>0 & pct_psu_higher<=0.1
replace pct_outrank_bin = 3 if pct_psu_higher>0.1 & pct_psu_higher<=0.333333
replace pct_outrank_bin = 4 if pct_psu_higher>0.333333 & pct_psu_higher<=0.666666
replace pct_outrank_bin = 5 if pct_psu_higher>0.666666 & !missing(pct_psu_higher)

label define pct_outrank_lbl ///
    1 "Nobody outranks" ///
    2 "Low pct outranks" ///
    3 "Medium pct outranks" ///
    4 "Large pct outranks"  ///
	5 "Substantial pct outranks" 
label values pct_outrank_bin pct_outrank_lbl


gen fwd_psu_bin = .
replace fwd_psu_bin = 0 if pct_psu_forward == 0
replace fwd_psu_bin = 1 if pct_psu_forward > 0    & pct_forward_psu <= .10
replace fwd_psu_bin = 2 if pct_psu_forward > .10  & pct_forward_psu <= .33
replace fwd_psu_bin = 3 if pct_psu_forward > .33  & pct_forward_psu <= .66
replace fwd_psu_bin = 4 if pct_psu_forward > .66  & pct_forward_psu < .

label define fwd_psu_bin_lbl ///
    0 "No forward-caste residents" ///
    1 "Low forward-caste presence" ///
    2 "Moderate forward-caste presence" ///
    3 "High forward-caste presence" ///
    4 "Majority forward-caste presence", replace

label values fwd_psu_bin fwd_psu_bin_lbl




* make quartiles of the variable: share of psu that defecates in the open, leaving out the household
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


save "$dataset", replace
