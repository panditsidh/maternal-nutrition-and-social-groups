if "`c(username)'" == "sidhpandit" {
	
	global out_tex "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_"
	
	global rw "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/01_reweight 2yr age + breastfeeding.do"
	
	global bootstrapresults_full "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/bootstrapresults_full.dta"
	
	
	global assemble "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/00_assemble prepreg sample.do"
	
}

if "`c(username)'" == "dc42724" {
	global out_tex "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\tables\rw_"
	
	global rw "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\01_reweight 2yr age + breastfeeding.do"
	
	global out_tex "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\bootstrapresults_full.dta"
	
	global assemble "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\00_assemble prepreg sample.do"
	
}

* we can get point estimates before 

set more off 
clear all

set seed 8062011
local B = 1000
* That's how many times to run it; I recommend 1,000


*** clear results dataset
set obs 20000
foreach var in bmihat underweighthat weighthat droppedbins droppedtargetwomen target {
gen `var' = .
}
save $bootstrapresults_full, replace


do "${assemble}"
tempfile prepared_dataset
save `prepared_dataset'

* bootstrapping loop
forvalues i = 1(1)`B'{ 

di `i', " of ", `B'

use `prepared_dataset', clear
replace strata = 7 if strata==8 // rural chandigadh

* CREATE REWEIGHTING BINS
egen bin=group(lessedu v013 urban youngest_status noliving childdied hasboy)
gen counter=1

* GET BOOTSTRAP SAMPLE
bsample, strata(strata) cluster(psu) 

* % pregnant in bootstrapped sample
qui sum preg
local target = r(mean)

do "${rw}"

* get prepregnancy outcomes
qui sum v445 [aweight=reweightingfxn] if target == 0, mean
local bmihat = r(mean)

qui sum underweight [aweight=reweightingfxn] if target == 0, mean
local underweighthat = r(mean)

qui sum v437 [aweight=reweightingfxn] if target == 0, mean
local weighthat = r(mean)

use $bootstrapresults_full, clear
foreach var in bmihat underweighthat weighthat droppedbins percent_drop target {
replace `var' = ``var'' if _n==`i'

}
save, replace


}



* Tell us what happened
sum bmihat, detail
sum underweighthat, detail
sum weighthat, detail

centile bmihat underweighthat weighthat, centile(2.5 97.5)





do "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/dummy.do"

display `i'
