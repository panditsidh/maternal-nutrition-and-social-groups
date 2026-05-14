
/* this dofile generates a stata dataset that has 

rows: 5 social groups + 1 all groups + 4 parity + 3 birth spacing + 4 wealth = 17

rows: 1 all groups + 5 social groups + 4 parity + 3 birth spacing + 10 parity and birth spacing + 4 wealth = 27
columns: mean ll ul for every outcome

*/

local cutoff .75


* the original is "data/results.dta"
local outfile "data/results cutoff `cutoff'.dta"

* the original is "data/bootstrap cis for pp outcomes.dta"
local bootstrap_results "data/bootstrap cis `cutoff' cutoff.dta"



* prepare dataset
qui do "$paths"
use "$dataset", clear
// do "dofiles/new variables.do"



qui do "dofiles/050_weights to estimate pp nutrition.do"

drop if group==6 | group==.

* initialize results matrix
local outcomes bmi weight underweight overweight obesity 

matrix results = J(27, `=3 * wordcount("`outcomes'")', .)

local colnames
foreach outcome in `outcomes' {
    local colnames `colnames' `outcome'_mean `outcome'_ll `outcome'_ul
}

matrix colnames results = `colnames'

* calculate means and confidence intervals for all subgroups (predictor level * social group)
local row = 1

foreach overvar in group allfivegroups  {
// foreach overvar in group allfivegroups parity bs parity_bs wealth  {
	
	levelsof(`overvar'), local(levels)
	
	foreach i in `levels' {
		
		local col = 1
		
		foreach outcome in `outcomes' {
			


			sum `outcome' if `overvar'==`i' & preg==0 [aw=reweightingfxn]	
			matrix results[`row', `col'] = r(mean)
		
			
					

			* now get confidence intervals for all variables except gainhatm1 from bootstrap results dataset
			preserve
			
			use "`bootstrap_results'", clear
			
			
// 				sum `outcome'_`overvar'`i', detail
// 				matrix results[`row', `col'+1] = r(p5)
// 				matrix results[`row', `col'+2] = r(p95)
			_pctile `outcome'_`overvar'`i', p(2.5 97.5)
			matrix results[`row', `col'+1] = r(r1)
			matrix results[`row', `col'+2] = r(r2)

		
			
	
			
			restore
			
			
			
			local col = `col' + 3
			
		}
		
		
		local ++row
		
		
		
	}
	
	
	
}


* convert matrix into a dataset using svmat
input str100 rows
"Adivasi"
"Dalit"
"OBC"
"Forward"
"Muslim"
"All five social groups"
"Parity 1"
"Parity 2"
"Parity 3"
"Parity 4"
"\textless{}2y birth spacing"
"2-3y birth spacing"
"\textgreater{}3y birth spacing"
"No births"  
"1 birth, \textless{}2y spacing"
"1 birth, 2–3y spacing"
"1 birth, \textgreater{}3y spacing"
"2 births, \textless{}2y spacing"
"2 births, 2–3y spacing"
"2 births, \textgreater{}3y spacing"
"3+ births, \textless{}2y spacing"
"3+ births, 2–3y spacing"
"3+ births, \textgreater{}3y spacing"
"Wealth quartile 1"
"Wealth quartile 2"
"Wealth quartile 3"
"Wealth quartile 4"
end

svmat results, names(col)


drop if missing(rows)

local last_outcome : word `=wordcount("`outcomes'")' of `outcomes'
keep rows-`last_outcome'_ul

save "`outfile'", replace
