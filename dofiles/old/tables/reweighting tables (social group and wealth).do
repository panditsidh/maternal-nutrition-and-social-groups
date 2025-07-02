/*

This file makes a table like this


social group + wealth | mean bmi (ll, ul) | % of pregnant sample dropped 


run this after having run 00 and reweighting

*/


capture drop dropbin_pregnant

svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)


foreach outcome in bmi underweight weight {
	
preserve

svy: mean `outcome' if preg==0, over(groups6 wealth)

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

mean dropbin_pregnant, over(groups6 wealth)

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
// "Forward: wealth 0"
// "Forward: wealth 1"
// "Forward: wealth 2"
// "Forward: wealth 3+"
// "OBC: wealth 0"
// "OBC: wealth 1"
// "OBC: wealth 2"
// "OBC: wealth 3"
// "OBC: wealth 4+"
// "Dalit: wealth 0"
// "Dalit: wealth 1"
// "Dalit: wealth 2"
// "Dalit: wealth 3+"
// "Adivasi: wealth 0"
// "Adivasi: wealth 1"
// "Adivasi: wealth 2"
// "Adivasi: wealth 3+"
// "Muslim: wealth 0"
// "Muslim: wealth 1"
// "Muslim: wealth 2"
// "Muslim: wealth 3+"
// end




gen str30 rowname = ""

replace rowname = "Forward: wealth 0" in 1
replace rowname = "Forward: wealth 1" in 2
replace rowname = "Forward: wealth 2" in 3
replace rowname = "Forward: wealth 3+" in 4
replace rowname = "OBC: wealth 0" in 5
replace rowname = "OBC: wealth 1" in 6
replace rowname = "OBC: wealth 2" in 7
replace rowname = "OBC: wealth 3+" in 8
replace rowname = "Dalit: wealth 0" in 9
replace rowname = "Dalit: wealth 1" in 10
replace rowname = "Dalit: wealth 2" in 11
replace rowname = "Dalit: wealth 3+" in 12
replace rowname = "Adivasi: wealth 0" in 13
replace rowname = "Adivasi: wealth 1" in 14
replace rowname = "Adivasi: wealth 2" in 15
replace rowname = "Adivasi: wealth 3+" in 16
replace rowname = "Muslim: wealth 0" in 17
replace rowname = "Muslim: wealth 1" in 18
replace rowname = "Muslim: wealth 2" in 19
replace rowname = "Muslim: wealth 3+" in 20




gen pct_drop = round(percent_drop, 0.01)

gen ci = string(mean, "%4.1f") + " (" + string(ll, "%4.1f") + ", " + string(ul, "%4.1f") + ")" if !missing(mean)

keep rowname ci pct_drop

drop if missing(rowname)


#delimit ;
listtex rowname ci pct_drop using "/tables/12_`outcome'.tex", replace ///
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
