
/* this dofile generates a dataset that has 

rows: 5 social groups + 1 all groups + 4 parity + 3 birth spacing + 4 wealth = 17
columns: mean ll ul for every outcome

*/





** clean up this part so that there's consistent variable naming 

//
// * right now, the varnames in bootstrap results dataset are coded according to the old groups6 variable
// * let's fix that
//
// use "data/bootstrapresults_full.dta", clear
//
// foreach outcome in bmi underweight weight nineweighthat coeffhat gainhat preg pct_drop bins dropbins pct_zero count9plus {
//	
//	
// 	// forward 
// 	rename `outcome'_group1 `outcome'_temp4
//	
// 	// OBC
// 	rename `outcome'_group2 `outcome'_temp3
//	
// 	// Dalit
// 	rename `outcome'_group3 `outcome'_temp2
//	
// 	// Adivasi
// 	rename `outcome'_group4 `outcome'_temp1
//	
//	
//	
//	
// 	rename `outcome'_temp1 `outcome'_group1
// 	rename `outcome'_temp2 `outcome'_group2
// 	rename `outcome'_temp3 `outcome'_group3
// 	rename `outcome'_temp4 `outcome'_group4
//	
//	
//	
// }
//
// save, replace







//
// label define grouplbl ///
//     1 "Adivasi" ///
//     2 "Dalit" ///
//     3 "OBC" ///
//     4 "Forward" ///
//     5 "Muslim" 
// label values group grouplbl
//
//
// label define groups6lbl ///
//     1 "Forward" ///
//     2 "OBC" ///
//     3 "Dalit" ///
//     4 "Adivasi" ///
//     5 "Muslim" 
// label values groups6 groups6lbl
//




* todo: add the other outcomes: overweight, obesity, weight gain method 1, weight gain method 2
local outcomes bmi weight underweight 


matrix results = J(17, `=3 * wordcount("`outcomes'")', .)

local colnames
foreach outcome in `outcomes' {
    local colnames `colnames' `outcome'_mean `outcome'_ll `outcome'_ul
}

matrix colnames results = `colnames'


* end clean up

// *** testing code ***
// matrix results = J(17, 3, .)
// local outcome gainhat
// *** testing code ***


local row = 1

foreach overvar in allfivegroups group parity bs wealth {
	
	levelsof(`overvar'), local(levels)
	
	
	
	foreach i in `levels' {
		
		local col = 1
		foreach outcome in `outcomes' {

			qui sum `outcome' if `overvar'==`i' & preg==0 [aw=reweightingfxn]
			
			matrix results[`row', `col'] = r(mean)
			
					
			
			preserve
			
			
			use "data/bootstrapresults_full.dta", clear
			
			qui sum `outcome'_`overvar'`i', detail
		
			
			matrix results[`row', `col'+1] = r(p5)
			matrix results[`row', `col'+2] = r(p95)
			
			
			restore
			local col = `col' + 3
			
		}
		
		local ++row
		
		
		
	}
	
	
	
}




input str100 rows
"All five social groups"
"Forward"
"OBC"
"Dalit"
"Adivasi"
"Muslim"
"Parity 1"
"Parity 2"
"Parity 3"
"Parity 4"
"\textless{}2y birth spacing"
"2-3y birth spacing"
"\textgreater{}3y birth spacing"
"Wealth quartile 1"
"Wealth quartile 2"
"Wealth quartile 3"
"Wealth quartile 4"
end

svmat results, names(col)

keep rows-gainhat_ul

drop if missing(rows)

*local outcomes bmi weight underweight gainhat
*local last_outcome : word `=wordcount("`outcomes'")' of `outcomes'
*keep rows-`last_outcome'_ul

save "data/results.dta", replace
