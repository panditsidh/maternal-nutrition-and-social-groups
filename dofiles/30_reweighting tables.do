if "`c(username)'" == "sidhpandit" {
	
	global out_tex"/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_"

}

if "`c(username)'" == "dc42724" {
	global out_tex "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\tables\rw_"
	
}



capture drop dropbin_pregnant

svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)

preserve

svy: mean underweight, over(groups6 parity)

matrix T = r(table)
local ncols = colsof(T)

matrix result = J(`ncols', 4, .)

forvalues i = 1/`ncols' {
    matrix result[`i', 1] = T[1, `i']*100   // mean (b)
    matrix result[`i', 2] = T[5, `i']*100   // lower bound (ll)
    matrix result[`i', 3] = T[6, `i']*100   // upper bound (ul)
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
listtex rowname ci pct_drop using $out_tex, replace ///
  rstyle(tabular) ///
  head("\begin{tabular}{lccc}" ///
       "\toprule" ///
       "Group & \% underweight & \% pregnant sample dropped \\\\" ///
       "\midrule") ///
  foot("\bottomrule" ///
       "\end{tabular}"); ///

restore
