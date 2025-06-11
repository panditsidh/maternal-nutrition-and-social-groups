if "`c(username)'" == "sidhpandit" {
	
	global out_tex "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_"
	
	global rw_11 "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/11_reweight single year age.do"
	
	global rw_12 "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/12_reweight 2yr age bins.do"
	
}

if "`c(username)'" == "dc42724" {
	global out_tex "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\tables\rw_"
	
	global rw_11 "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\11_reweight single year age.do"
	
	global rw_12 "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\12_reweight 2yr age bins.do"
	
}


do "${rw_12}"

capture drop dropbin_pregnant



svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)


foreach outcome in bmi underweight weight {
	
preserve

svy: mean `outcome', over(groups6 parity)

matrix T = r(table)
local ncols = colsof(T)

matrix result = J(`ncols', 4, .)

forvalues i = 1/`ncols' {
	
	if "`outcome'"=="underweight"{
		matrix result[`i', 1] = T[1, `i']*100   // mean (b)
		matrix result[`i', 2] = T[5, `i']*100   // lower bound (ll)
		matrix result[`i', 3] = T[6, `i']*100   // upper bound (ul)
		
	}
    
	else {	
		matrix result[`i', 1] = T[1, `i']   // mean (b)
		matrix result[`i', 2] = T[5, `i']   // lower bound (ll)
		matrix result[`i', 3] = T[6, `i']   // upper bound (ul)
	}
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


// input str30 rowname
// "Forward: parity 0"
// "Forward: parity 1"
// "Forward: parity 2"
// "Forward: parity 3+"
// "OBC: parity 0"
// "OBC: parity 1"
// "OBC: parity 2"
// "OBC: parity 3"
// "OBC: parity 4+"
// "Dalit: parity 0"
// "Dalit: parity 1"
// "Dalit: parity 2"
// "Dalit: parity 3+"
// "Adivasi: parity 0"
// "Adivasi: parity 1"
// "Adivasi: parity 2"
// "Adivasi: parity 3+"
// "Muslim: parity 0"
// "Muslim: parity 1"
// "Muslim: parity 2"
// "Muslim: parity 3+"
// end




gen str30 rowname = ""

replace rowname = "Forward: parity 0" in 1
replace rowname = "Forward: parity 1" in 2
replace rowname = "Forward: parity 2" in 3
replace rowname = "Forward: parity 3+" in 4
replace rowname = "OBC: parity 0" in 5
replace rowname = "OBC: parity 1" in 6
replace rowname = "OBC: parity 2" in 7
replace rowname = "OBC: parity 3+" in 8
replace rowname = "Dalit: parity 0" in 9
replace rowname = "Dalit: parity 1" in 10
replace rowname = "Dalit: parity 2" in 11
replace rowname = "Dalit: parity 3+" in 12
replace rowname = "Adivasi: parity 0" in 13
replace rowname = "Adivasi: parity 1" in 14
replace rowname = "Adivasi: parity 2" in 15
replace rowname = "Adivasi: parity 3+" in 16
replace rowname = "Muslim: parity 0" in 17
replace rowname = "Muslim: parity 1" in 18
replace rowname = "Muslim: parity 2" in 19
replace rowname = "Muslim: parity 3+" in 20


* Now loop over the labels
local i = 1
foreach label of local labels {
    replace rowname = "`label'" in `i'
    local ++i
}

gen pct_drop = round(percent_drop, 0.01)

gen ci = string(mean, "%4.1f") + " (" + string(ll, "%4.1f") + ", " + string(ul, "%4.1f") + ")" if !missing(mean)

keep rowname ci pct_drop

drop if missing(rowname)


#delimit ;
listtex rowname ci pct_drop using "${out_tex}12_`outcome'.tex", replace ///
  rstyle(tabular) ///
  head("\begin{tabular}{lccc}" ///
       "\toprule" ///
       "Group & \`outcome' & \% pregnant sample dropped \\\\" ///
       "\midrule") ///
  foot("\bottomrule" ///
       "\end{tabular}"); ///
#delimit cr

restore


}
