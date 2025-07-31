
/* this dofile generates a dataset that has 

rows: 5 social groups + 1 all groups + 4 parity + 3 birth spacing + 4 wealth = 17
columns: mean ll ul for every outcome

*/


* we're adding gainhatm1 and gainhatm2 so create those in bootstrapresults dta


* todo: add the other outcomes: overweight, obesity, weight gain method 1, weight gain method 2
local outcomes bmi weight underweight gainhat_m1 gainhat_m2


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

foreach overvar in allfivegroups group parity bs wealth  {
	
	levelsof(`overvar'), local(levels)
	
	
	
	foreach i in `levels' {
		
		local col = 1
		foreach outcome in `outcomes' {
			
			
			if "`outcome'"=="gainhat_m1" {
				matrix results[`row', `col'] = .
				
				qui reg weight gestdur i.v012 i.v133 i.v218 i.rural i.v190 i.v024##v006 [aw=v005] ///
				if `overvar'==`i' & inrange(gestdur,3,9)
				local coeffhat_`overvar'`i' = _b[gestdur]
				
				// Method 1: 6 months * beta, plus 10% first trimester assumption
				local gainhat_`overvar'`i' = 1.1 * 6 * `coeffhat_`overvar'`i''
				
				matrix results[`row', `col'] = `gainhat_`overvar'`i''
			}
			
			if "`outcome'"=="gainhat_m2" {
				
				qui sum weight [aw=reweightingfxn] if preg==0 & `overvar'==`i' & dropbin!=1
				local weight_`overvar'`i' = r(mean)
				
				
				* calculate weight at 9+ mopreg
				qui sum weight [aw=v005] if gestdur>=9 & gestdur!=. & `overvar'==`i'
				local nineweighthat_`overvar'`i' = r(mean)
				
				* get beta from weight on mopreg regression
				qui reg weight gestdur i.v012 i.v133 i.v218 i.rural i.v190 i.v024##v006 [aw=v005] if `overvar'==`i'& inrange(gestdur,3,9)
				local coeffhat_`overvar'`i' = _b[gestdur]
				
				
				local gainhat_`overvar'`i' = `nineweighthat_`overvar'`i''-`weight_`overvar'`i''+(0.5)*`coeffhat_`overvar'`i''
				
				matrix results[`row', `col'] = `gainhat_`overvar'`i''
				
			}
			
			if strpos("`outcome'", "gainhat")==0 {

				qui sum `outcome' if `overvar'==`i' & preg==0 [aw=reweightingfxn]
				
				matrix results[`row', `col'] = r(mean)
			
			}
					
			
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


drop if missing(rows)

local outcomes bmi weight underweight gainhat_m1 gainhat_m2
local last_outcome : word `=wordcount("`outcomes'")' of `outcomes'
keep rows-`last_outcome'_ul

save "data/results.dta", replace
