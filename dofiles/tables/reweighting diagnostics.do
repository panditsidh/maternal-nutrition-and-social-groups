* this code creates a table of every group in all kitagawa decompositions and their number of pregnant women, non-pregnant women, and % of pregnant women dropped 

* to easily see groups where too many pregnant women are dropped, you will see this in the console (if any)

/*

. list if pct_drop_preg>3

     +----------------------------------------------------------------+
     | group_~e   over_name   n_preg   n_nonp~g   pc~_preg   pc~npreg |
     |----------------------------------------------------------------|
 28. |  Forward   2-3 years      307       4598       3.58      54.68 |
 36. |    Dalit   2-3 years      595       6267       3.36      51.41 |
 44. |   Muslim   2-3 years      454       4420       5.29      53.85 |
     +----------------------------------------------------------------+

*/


// 1. Create a matrix large enough
matrix diagnostics = J(80, 7, .) // (5 groups × ~16 levels) and 6 columns


// 2. Define labels (for svmat use later)
local colnames group category n_preg n_nonpreg pct_drop_preg pct_drop_nonpreg over_counter
matrix colnames diagnostics = `colnames'


* get diagnostics for all india
qui count if preg==1 
local n_preg = r(N)

qui count if preg==0 
local n_nonpreg = r(N)

qui sum dropbin if preg==1 
local pct_drop_preg = r(mean)*100

qui sum zerobin if preg==0 
local pct_drop_nonpreg = r(mean)*100

matrix diagnostics[1, 1] =  .
matrix diagnostics[1, 2] =  . 
matrix diagnostics[1, 3] = `n_preg'
matrix diagnostics[1, 4] = `n_nonpreg'
matrix diagnostics[1, 5] = `pct_drop_preg'
matrix diagnostics[1, 6] = `pct_drop_nonpreg'



local row = 2

* get diagnostics by social group
foreach g of numlist 1/5 {
	
	qui count if preg==1 & groups6==`g' 
	local n_preg = r(N)

	qui count if preg==0 & groups6==`g' 
	local n_nonpreg = r(N)

	qui sum dropbin if preg==1 & groups6==`g' 
	local pct_drop_preg = r(mean)*100
	
	qui sum zerobin if preg==0 & groups6==`g' 
	local pct_drop_nonpreg = r(mean)*100
	
	// Fill matrix
	matrix diagnostics[`row', 1] = `g'
	matrix diagnostics[`row', 2] =  . 
	matrix diagnostics[`row', 3] = `n_preg'
	matrix diagnostics[`row', 4] = `n_nonpreg'
	matrix diagnostics[`row', 5] = `pct_drop_preg'
	matrix diagnostics[`row', 6] = `pct_drop_nonpreg'
	
	local ++row
}



local over_counter = 1
* get diagnostics by social group and kitagawa variable
foreach overvar in parity birth_space_cat wealth {
	
	
	
	levelsof `overvar', local(over)

	foreach g of numlist 1/5 {
		
		foreach i in `over' {
			qui count if preg==1 & groups6==`g' & `overvar'==`i'
			local n_preg = r(N)

			qui count if preg==0 & groups6==`g' & `overvar'==`i'
			local n_nonpreg = r(N)

			qui sum dropbin if preg==1 & groups6==`g' & `overvar'==`i'
			local pct_drop_preg = r(mean)*100
			
			qui sum zerobin if preg==0 & groups6==`g' & `overvar'==`i'
			local pct_drop_nonpreg = r(mean)*100
			
			// Fill matrix
			matrix diagnostics[`row', 1] = `g'
			matrix diagnostics[`row', 2] = `i'
			matrix diagnostics[`row', 3] = `n_preg'
			matrix diagnostics[`row', 4] = `n_nonpreg'
			matrix diagnostics[`row', 5] = `pct_drop_preg'
			matrix diagnostics[`row', 6] = `pct_drop_nonpreg'
			matrix diagnostics[`row', 7] = `over_counter'
			
			local ++row
		}
	}
	
	local ++over_counter

}


capture drop group-over_counter
capture drop group_name-pct_drop_nonpreg
svmat diagnostics, names(col)

* Step 1: Create string variable 'group_name' and initialize empty
gen str15 group_name = ""

* Step 2: Apply group name based on the 'group' variable
replace group_name = "All India" if missing(group) & missing(cat)
replace group_name = "Forward"  if group == 1
replace group_name = "OBC"      if group == 2
replace group_name = "Dalit"    if group == 3
replace group_name = "Adivasi"  if group == 4
replace group_name = "Muslim"   if group == 5


* Step 1: Create string variable 'group_name' and initialize empty
gen str15 over_name = ""

* Step 2: Apply group name based on the 'group' variable
replace group_name = "All India" if missing(group) & missing(cat)
replace over_name = "Parity 1"  if over_counter==1 & cat==1
replace over_name = "Parity 2"  if over_counter==1 & cat==2
replace over_name = "Parity 3"  if over_counter==1 & cat==3
replace over_name = "Parity 4+"  if over_counter==1 & cat==4

replace over_name = "Below 2 years"  if over_counter==2 & cat==1
replace over_name = "2-3 years"  if over_counter==2 & cat==2
replace over_name = "Above 3 years"  if over_counter==2 & cat==3
replace over_name = "1st birth"  if over_counter==2 & cat==9

replace over_name = "Quartile 1"  if over_counter==3 & cat==1
replace over_name = "Quartile 2"  if over_counter==3 & cat==2
replace over_name = "Quartile 3"  if over_counter==3 & cat==3
replace over_name = "Quartile 4"  if over_counter==3 & cat==4


capture drop group-over_counter

svmat diagnostics, names(col)

drop group category over_counter

replace pct_drop_nonpreg = round(pct_drop_nonpreg, 0.01)
replace pct_drop_preg = round(pct_drop_preg, 0.01)

preserve

keep group_name-pct_drop_nonpreg

drop if missing(n_preg)


#delimit ;
listtex group_name over_name n_preg n_nonpreg pct_drop_preg pct_drop_nonpreg using "tables/rw_diagnostics_full.tex", replace ///
  rstyle(tabular) ///
  head("\begin{tabular}{lccc}" ///
       "\toprule" ///
       "Social Group & Decomposition group & N pregnant & N non-pregnant & \% dropped pregnant & \% dropped non-pregnant \\\\" ///
       "\midrule") ///
  foot("\bottomrule" ///
       "\end{tabular}"); ///
#delimit cr

list if pct_drop_preg>3

restore
