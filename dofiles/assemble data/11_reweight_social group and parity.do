/* reweighting by 
- age
- education
- urban/rural
- hasboy
- contraceptive user

within each social group/parity
*/


if "`c(username)'" == "sidhpandit" {
	
	global out_tex"/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_all.tex"

}


capture drop age counter 
capture drop bin_*
capture drop dropbin* 
capture drop dropbins*
capture drop reweightingfxn
capture drop pregweight* nonpregweight* transfer*

gen age = v012
gen counter=1
gen dropbin = 0

foreach i of numlist 1/5 {
	
	
	foreach p of numlist 0/4 {
		
		
		display as text "social group " as result `i' as text " at parity " as result `p'
		
		qui egen bin_`i'_`p' = group(age edu rural hasboy c_user) if groups6==`i' & parity==`p'
		
		
		preserve

		collapse (sum) counter (mean) age edu rural hasboy, by(bin_`i'_`p' preg)
		qui drop if bin_`i'_`p' == .
		qui reshape wide counter, i(bin_`i'_`p') j(preg)
		qui replace counter0 = 0 if counter0 == .
		qui replace counter1 = 0 if counter1 == .
		
		
		qui count if counter0==0 & counter1>0
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
	
	forvalues p = 0/4 {
		
		egen pregweight_`i'_`p' = sum(v005) if preg==1 & dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen nonpregweight_`i'_`p' = sum(v005) if preg==0 & dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen transferpreg_`i'_`p' = mean(pregweight_`i'_`p') if dropbin_`i'_`p'==0, by(bin_`i'_`p')
		egen transfernonpreg_`i'_`p' = mean(nonpregweight_`i'_`p') if dropbin_`i'_`p'==0, by(bin_`i'_`p')	
		replace reweightingfxn = v005*transferpreg_`i'_`p'/transfernonpreg_`i'_`p' if dropbin_`i'_`p'==0
		
		
	}
	
	
}


drop dropbin_pregnant

svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)

svy: mean bmi, over(groups6 parity)


matrix T = r(table)
local ncols = colsof(T)

matrix result = J(`ncols', 4, .)

forvalues i = 1/`ncols' {
    matrix result[`i', 1] = T[1, `i']   // mean (b)
    matrix result[`i', 2] = T[5, `i']   // lower bound (ll)
    matrix result[`i', 3] = T[6, `i']   // upper bound (ul)
}




gen dropbin_pregnant = dropbin*100 if preg==1

mean dropbin_pregnant, over(groups6 parity)

matrix T = r(table)
local ncols = colsof(T)

forvalues i=1/`ncols' {
	
	matrix result[`i', 4] = T[1, `i']   // mean (b)
	
}


svmat result, names(col)



rename c1 mean
rename c2 ll
rename c3 ul
rename c4 percent_drop


input str30 rowname
"Forward: parity 0"
"Forward: parity 1"
"Forward: parity 2"
"Forward: parity 3"
"Forward: parity 4+"
"OBC: parity 0"
"OBC: parity 1"
"OBC: parity 2"
"OBC: parity 3"
"OBC: parity 4+"
"Dalit: parity 0"
"Dalit: parity 1"
"Dalit: parity 2"
"Dalit: parity 3"
"Dalit: parity 4+"
"Adivasi: parity 0"
"Adivasi: parity 1"
"Adivasi: parity 2"
"Adivasi: parity 3"
"Adivasi: parity 4+"
"Muslim: parity 0"
"Muslim: parity 1"
"Muslim: parity 2"
"Muslim: parity 3"
"Muslim: parity 4+"
end



gen pct_drop = round(percent_drop, 0.01)

gen ci = string(mean, "%4.1f") + " (" + string(ll, "%4.1f") + ", " + string(ul, "%4.1f") + ")" if !missing(mean)

keep rowname ci pct_drop

drop if missing(rowname)


#delimit ;
listtex row ci_3 ci_4 ci_5 using $out_tex, replace ///
  rstyle(tabular) ///
  head("\begin{tabular}{lccc}" ///
       "\toprule" ///
       "Group & Percent underweight & Percent of pregnant sample dropped \\\\" ///
       "\midrule") ///
  foot("\bottomrule" ///
       "\end{tabular}"); ///


// TESTING CODE
// egen bin = group(age edu rural hasboy c_user) if groups6==1 & parity==2
//
// collapse (sum) counter (mean) age edu rural hasboy, by(bin preg)
// drop if bin == .
// reshape wide counter, i(bin) j(preg)
//
// qui replace counter0 = 0 if counter0 == .
// qui replace counter1 = 0 if counter1 == .
		


