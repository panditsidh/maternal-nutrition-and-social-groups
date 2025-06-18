* this dofile does reweighting by age (single year) edu rural hasboy c_user within parity and social group
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
capture drop age 
capture drop counter 
capture drop bin_*
capture drop dropbin* 
capture drop dropbins*
capture drop reweightingfxn
capture drop pregweight* nonpregweight* transfer*
capture drop tag

gen age = 2 * floor(v012 / 2)
gen counter=1
gen dropbin = 0


reg preg age edu rural hasboy c_user v404 [aw=v005]
display e(r2)

egen tag = tag(age edu rural hasboy c_user v404)
count if tag==1

foreach i of numlist 1/5 {
	
	foreach p of numlist 0/3 {
		
		
		display as text "social group " as result `i' as text " at parity " as result `p'
		
		qui egen bin_`i'_`p' = group(age edu rural hasboy c_user) if groups6==`i' & parity==`p'
		
		
		preserve

		collapse (sum) counter (mean) age edu rural hasboy, by(bin_`i'_`p' preg)
		qui drop if bin_`i'_`p' == .
		qui reshape wide counter, i(bin_`i'_`p') j(preg)
		qui replace counter0 = 0 if counter0 == .
		qui replace counter1 = 0 if counter1 == .
		
		
		qui count if counter0==0 & counter1>0
		local droppedbins = r(N)
		
		if r(N)==0 {
			local drop_women = 0
		}
		
		else {
			qui total counter1 if counter0==0 & counter1>0
			local drop_women = r(table)[1,1]
			
		}
		
		
		
		qui total counter1
		local total_pregnant = r(table)[1,1]
		
		
		local percent_drop = (`drop_women'/`total_pregnant') * 100 
		
		display as text "percent of pregnant women to be dropped " as result `percent_drop'
		
		gen dropbin_`i'_`p' = counter0==0 & counter1>0
		keep bin_`i'_`p' dropbin_`i'_`p'

		
		tempfile dropbins_`i'_`p'
		qui save `dropbins_`i'_`p''

		
		restore
		
		qui merge m:1 bin_`i'_`p' using `dropbins_`i'_`p'', gen(dropbins_merge_`i'_`p')
		qui replace dropbin = 1 if dropbin_`i'_`p'==1
		
		
	}

}


gen reweightingfxn = .
forvalues i = 1/5 {
	
	forvalues p = 0/3 {
		
		egen pregweight_`i'_`p' = sum(v005) if preg==1 & dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen nonpregweight_`i'_`p' = sum(v005) if preg==0 & dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen transferpreg_`i'_`p' = mean(pregweight_`i'_`p') if dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen transfernonpreg_`i'_`p' = mean(nonpregweight_`i'_`p') if dropbin_`i'_`p'==0, by(bin_`i'_`p')	
		replace reweightingfxn = v005*transferpreg_`i'_`p'/transfernonpreg_`i'_`p' if dropbin_`i'_`p'==0
		
		
	}
	
	
}


// * testing code
// preserve
// egen bin = group(age edu rural hasboy c_user v404) if groups6==1 & parity==3
//
// collapse (sum) counter (mean) age edu rural hasboy c_user v404, by(bin preg)
// drop if bin == .
// reshape wide counter, i(bin) j(preg)
//
// qui replace counter0 = 0 if counter0 == .
// qui replace counter1 = 0 if counter1 == .
//
// list bin counter1 age edu rural hasboy c_user v404 if counter0==0 & counter1>0
//
//		
// restore


