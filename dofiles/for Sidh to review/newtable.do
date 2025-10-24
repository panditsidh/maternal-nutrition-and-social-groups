
/*


okkk we have to use hmr
 
 
in master
- v034: line number of husband
 

then in hhmr
- keep if male
- keep if 
 
 
 
 label variable hb1      "Man's age in years"
label variable hb2      "Man's weight in kilograms (1 decimal)"
label variable hb3      "Man's height in centimeters (1 decimal)"

 
*/





use "$nfhs5hmr", clear

keep if hv104==1


drop if missing(hb40)
gen husband_bmi = hb40 if !inlist(hb40, 9998, 9999)
replace husband_bmi = husband_bmi/100
replace husband_bmi = . if inlist(hb40, 9996, 9997, 9998, .)
gen husband_underweight = husband_bmi<18.5

* 98,216 nonmissing husband underweight

rename hv000 v000
rename hv001 v001 // cluster number
rename hv002 v002 // household number
rename hvidx v034 // respondent's line number should match line number of husband
tempfile nfhs5hmr 


save `nfhs5hmr'

use "$dataset", clear

drop if missing(v034) 
* lose like 200k women without husband in household


merge m:1 v000 v001 v002 v034 using `nfhs5hmr'

* only like 54k match to a man in the hhmr

keep if _merge==3

do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"

eststo clear
eststo woman: reg v201 v201

foreach i of numlist 1/5 {
	
	sum underweight [aw=reweightingfxn] if group==`i' & preg==0
	
	local group`i' = r(mean)*100
	
	eststo woman: estadd scalar group`i' = `group`i''
}

eststo husband: reg v201 v201

foreach i of numlist 1/5 {
	
	sum husband_underweight [aw=reweightingfxn] if group==`i' & !missing(husband_underweight) & preg==0
	
	local group`i' = r(mean)*100
	
	eststo husband: estadd scalar group`i' = `group`i''
	
	count if !missing(husband_underweight) & preg==0 & group==`i'
	
	local sample1`i' = r(N)
}


eststo men_1yo: reg v201 v201

foreach i of numlist 1/5 {
	
	sum husband_underweight [aw=v005] if group==`i' & !missing(husband_underweight) & v209==1
	
	local group`i' = r(mean)*100
	
	eststo men_1yo: estadd scalar group`i' = `group`i''
	
	count if !missing(husband_underweight) & v209==1 & group==`i'
	
	local sample2`i' = r(N)
	
}
#delimit ;
esttab woman husband, 
    stats(group1 group2 group3 group4 group5, 
          label("Adivasi n=`sample11'" "Dalit n=`sample12'" "OBC n=`sample13'" "Forward n=`sample14'" "Muslim n=`sample15'")) 
    drop(v201 _cons)
    mtitles("\shortstack{Underweight among \\ prepregnant women}"
            "\shortstack{Underweight among \\ prepregnant women's \\ husbands}")
    nonumbers nonote;
#delimit cr

#delimit ;
esttab men_1yo using "tables/apdx_men1yo.tex", replace
    stats(group1 group2 group3 group4 group5, 
          label("Adivasi n=`sample21'" "Dalit n=`sample22'" "OBC n=`sample23'" "Forward n=`sample24'" "Muslim n=`sample25'")) 
    drop(v201 _cons)
    mtitles("\shortstack{Underweight among men \\ whose wife gave birth \\ in the last year}")
    nonumbers nonote;
#delimit cr




**# Bookmark #1


