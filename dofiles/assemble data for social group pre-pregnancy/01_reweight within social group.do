/* reweighting by 
- age
- education
- urban/rural
- hasboy
- child death

within each social group
*/


gen age = v012
gen counter=1


foreach i of numlist 1/5 {
	
	egen bin_`i' = group(age edu rural hasboy) if groups6==`i'
	
	preserve

	collapse (sum) counter (mean) age edu rural hasboy, by(bin_`i' preg)
	drop if bin_`i' == .
	reshape wide counter, i(bin_`i') j(preg)
	replace counter0 = 0 if counter0 == .
	replace counter1 = 0 if counter1 == .
	
	* number of bins with only pregnant women
// 	count if counter0==0 & counter1>0
	
	* number of pregnant women in dropbins
	tab counter1 if counter0==0 & counter1>0
	
	gen dropbin_`i' = counter0==0 & counter1>0
	
	tab dropbin
	
	keep bin_`i' dropbin_`i'
	
	tempfile dropbins_`i'
	save `dropbins_`i''

	restore
	
	merge m:1 bin_`i' using `dropbins_`i'', gen(dropbins_merge_`i')
	
	tab dropbin_`i'

 
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

