clear all
set maxvar 7000
use "$nfhs5hr", clear

*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
egen strata = group(hv000 hv024 hv025)
replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)

gen ones = 1
gen open_defecates = inlist(hv205,30,31)
gen od = open_defecates


preserve

collapse (sum) od ones [aw=hv005], by(psu)

rename ones total_households
rename od total_odhh_psu

tempfile psu_hh_counts
save `psu_hh_counts'

restore




use "$nfhs5hr", clear

*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.
egen strata = group(hv000 hv024 hv025)
replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)

gen open_defecates = inlist(hv205,30,31)


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


keep v000 v001 v002 v024 v025  pct_psu_adivasi pct_psu_dalit pct_psu_obc pct_psu_forward pct_psu_muslim  pct_psu_open_defecates pct_psu_od_besideshh hr_group sh49 sh47


save "data/hh_level_vars.dta", replace


