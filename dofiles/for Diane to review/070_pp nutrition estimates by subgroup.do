
/* this dofile generates a dataset that has 

rows: 5 social groups + 1 all groups + 4 parity + 3 birth spacing + 4 wealth = 17


rows: 1 all groups + 5 social groups + 4 parity + 3 birth spacing + 10 parity and birth spacing + 4 wealth = 27
columns: mean ll ul for every outcome

*/

* initialize results matrix
local outcomes bmi weight underweight overweight obesity gainhatm1 gainhatm2

matrix results = J(27, `=3 * wordcount("`outcomes'")', .)

local colnames
foreach outcome in `outcomes' {
    local colnames `colnames' `outcome'_mean `outcome'_ll `outcome'_ul
}

matrix colnames results = `colnames'


* calculate means and confidence intervals for all subgroups

local row = 1

foreach overvar in group allfivegroups parity bs parity_bs wealth  {
	
	levelsof(`overvar'), local(levels)
	
	foreach i in `levels' {
		
		local col = 1
		foreach outcome in `outcomes' {
			
			
			* weight gain method 1
/*
The weight gain regression controls for age fixed effects, years of schooling fixed effects, number of living children fixed effects, an urban fixed effect, wealth quinitile FEs, and state interacted with month of interview.  This is the most controlled specification of the regression from Coffey,2015. 
*/
			if "`outcome'"=="gainhatm1" {
				matrix results[`row', `col'] = .
				
				qui reg weight gestdur i.v012 i.v133 i.v218 i.rural i.v190 i.v024##v006 [aw=v005] ///
				if `overvar'==`i' & inrange(gestdur,3,9)
				local coeffhat_`overvar'`i' = _b[gestdur]
				
				// Method 1: 6 months * beta, plus 10% first trimester assumption
				local gainhatm1_`overvar'`i' = 1.1 * 6 * `coeffhat_`overvar'`i''
				
				matrix results[`row', `col'] = `gainhatm1_`overvar'`i''
				
				
			}
			
			
			* weight gain method 2
			if "`outcome'"=="gainhatm2" {
				
				qui sum weight [aw=reweightingfxn] if preg==0 & `overvar'==`i' & dropbin!=1
				local weight_`overvar'`i' = r(mean)
				
				* calculate weight at 9+ mopreg
				qui sum weight [aw=v005] if gestdur>=9 & gestdur!=. & `overvar'==`i'
				local nineweighthat_`overvar'`i' = r(mean)
				
				* get beta from weight on mopreg regression
				qui reg weight gestdur i.v012 i.v133 i.v218 i.rural i.v190 i.v024##v006 [aw=v005] if `overvar'==`i'& inrange(gestdur,3,9)
				local coeffhat_`overvar'`i' = _b[gestdur]
				
				local gainhatm2_`overvar'`i' = `nineweighthat_`overvar'`i''-`weight_`overvar'`i''+(0.5)*`coeffhat_`overvar'`i''
				
				matrix results[`row', `col'] = `gainhatm2_`overvar'`i''
				
			}
			
			* all other outcomes
			if strpos("`outcome'", "gainhat")==0 {

				sum `outcome' if `overvar'==`i' & preg==0 [aw=reweightingfxn]	
				matrix results[`row', `col'] = r(mean)
			
			}
					

			* get confidence intervals for all variables from bootstrap results dataset
			preserve
			
			use "data/bootstrapresults_test.dta", clear
			
			if "`outcome'"!="gainhatm1" sum `outcome'_`overvar'`i', detail
				
			matrix results[`row', `col'+1] = r(p5)
			matrix results[`row', `col'+2] = r(p95)
	
			
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

save "data/results.dta", replace
