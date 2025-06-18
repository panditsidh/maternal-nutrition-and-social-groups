/* reweighting by 
- age
- education
- urban/rural
- hasboy
- contraceptive user

within each social group
*/


* just testing this code with the social group reweighting (01)

if "`c(username)'" == "sidhpandit" {
	global assemble "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/00_assemble prepreg sample.do"
	
}

if "`c(username)'" == "dc42724" {
	
	global assemble "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\00_assemble prepreg sample.do"
	
}

capture drop counter bin* dropbin*
capture drop pct_drop
capture drop reweightingfxn* pregweight* nonpregweight* transfer*
gen counter=1


gen pct_drop = .
gen droppedbins = .
gen droppedpregwomen = .

foreach i of numlist 1/5 {
	
	
	* create bins within each social group
	egen bin_`i' = group(age edu rural hasboy c_user) if groups6==`i'
	
	preserve
	
	* track bins that have only pregnant women
	collapse (sum) counter (mean) age edu rural hasboy, by(bin_`i' preg)
	drop if bin_`i' == .
	reshape wide counter, i(bin_`i') j(preg)
	replace counter0 = 0 if counter0 == .
	replace counter1 = 0 if counter1 == .
	
	* # bins with only pregnant women
	qui count if counter0==0 & counter1>0
	local droppedbins`i' = r(N)
	
	gen dropbin_`i' = counter0==0 & counter1>0
	
	keep bin_`i' dropbin_`i'
	
	tempfile dropbins_`i'
	save `dropbins_`i''

	restore
	
	merge m:1 bin_`i' using `dropbins_`i'', gen(dropbins_merge_`i')
	
	tab dropbin_`i'
	
	
	* percent of pregnant women dropped
	sum dropbin_`i' [aw=v005] if preg==1	
	replace pct_drop = r(mean) if groups6==`i'
	local pct_drop`i' = r(mean)
	replace droppedbins = `droppedbins`i'' if groups6==`i'
	
	
	if `pct_drop`i''==0 replace droppedpregwomen=0 if groups6==`i'
	else {
		total preg if dropbin_`i'==1
		local droppedpregwomen`i' = r(table)[1,1]
		replace droppedpregwomen = r(table)[1,1] if groups6==`i'
	}
	
}






egen dropbin = anymatch(bin_1-bin_5), values(1)

gen reweightingfxn = .
forvalues i = 1/5 {
	egen pregweight_`i' = sum(v005) if preg==1 & dropbin_`i'==0, by(bin_`i')
	egen nonpregweight_`i' = sum(v005) if preg==0 & dropbin_`i'==0, by(bin_`i')
	egen transferpreg_`i' = mean(pregweight_`i') if dropbin_`i'==0, by(bin_`i')
	egen transfernonpreg_`i' = mean(nonpregweight_`i') if dropbin_`i'==0, by(bin_`i')	
	replace reweightingfxn = v005*transferpreg_`i'/transfernonpreg_`i' if dropbin_`i'==0
}

