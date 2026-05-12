


use "/Users/sidhpandit/Desktop/data/nfhs/nfhs5hr/IAHR7EFL.DTA", clear


//generate variables for analyzing surveys with complex designs
egen strata = group(hv000 hv024 hv025)
*Rural Chandigarh has a very small number of observations, so we combine with urban Chandigarh.

replace strata = 7 if strata==8
egen psu = group(hv000 hv001 hv024 hv025)



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




preserve

collapse (mean) adivasi dalit obc forward muslim [aw=hv005], by(psu)

foreach var in adivasi dalit obc forward muslim {
	
	rename `var' pct_psu_`var'
	
}






tempfile psu_share_group
save `psu_share_group'


restore



merge m:1 psu using `psu_share_group', nogen

gen pct_psu_higher = pct_psu_obc + pct_psu_forward + pct_psu_muslim if inlist(group,1,2)
replace pct_psu_higher = pct_psu_forward if obc==1



rename hv000 v000
rename hv001 v001
rename hv002 v002
rename hv024 v024
rename hv025 v025


keep v000 v001 v002 v024 v025 pct_psu_higher pct_psu_forward

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




tab wealth3 fwd_psu_bin4 [aw=v005], row
tab wealth3 fwd_psu_bin4 [aw=v005], col

bys group: tab wealth3 fwd_psu_bin4 [aw=v005], row
