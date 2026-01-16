
/*

Reweighting variables | outcome 1 | outcome 2 …. | outcome 5 | # subgroups with % dropped >3% | highest % dropped in subgroup 
—————————————————————————————————————————————————————————————————————— 


*/


* define different specifications
local binvars1 not_c_user agebin rural less_edu noboy wealth parity_bs group
local binvars2 not_c_user agebin2 rural less_edu noboy wealth parity_bs group
local binvars3 not_c_user agebin2 rural noboy wealth parity_bs group
local binvars4 not_c_user agebin2 less_edu noboy wealth parity_bs group
local binvars5 not_c_user agebin2 noboy wealth parity_bs group
local binvars6 not_c_user agebin3 noboy wealth parity_bs group
local binvars7 not_c_user agebin4 noboy wealth parity_bs group

local titles1 "Original spec"
local titles2 "5 cat age"
local titles3 "5 cat age, - less edu"
local titles4 "5 cat age, - rural"
local titles5 "5 cat age, - rural & less edu"
local titles6 "6 cat age, - rural & less edu"
local titles7 "7 cat age, - rural & less edu"


matrix results = J(7, 7, .)

* loop through the different specifications
forvalues i=1/7 {
	
	use "$dataset", clear
    local title `titles`i''
    di as text "Running spec `i': `title'"
    
	qui {
	* generate bins for reweighting
	egen bin = group(`binvars`i'')
	gen counter=1


	* collapse to bin-level counts of pregnant and total women
	* same as the collapse in diane's original code, just shorter
	preserve
	collapse ///
		(sum) bin_preg = preg ///
		(sum) bin_women = counter, ///
		by(bin)

	* tag bins that only have pregnant or non-pregnant women
	gen dropbin = bin_preg == bin_women & bin_women > 0
	gen zerobin = bin_preg == 0 & bin_women > 0
	drop if bin==.

	tempfile bininfo
	save `bininfo'
	restore

	* merge this bin-level information back to the individual dataset
	merge m:1 bin using `bininfo', nogen

	* generate weights by bin
	egen pregweight = sum(v005) if preg==1, by(bin)
	egen nonpregweight = sum(v005) if preg==0, by(bin)
	egen transferpreg = mean(pregweight), by(bin)
	egen transfernonpreg = mean(nonpregweight), by(bin)
	gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0


	* this is the most pct pregnant women dropped in any subgroup 
	local biggest_problem = 0
	
	* this is the number of subgroups for which pct pregnant dropped > 3%
	local problem_counter = 0 
	
	* get the outcome and problem report for each specification 
	forvalues g=1/5 {
		
		sum underweight if preg==0 & group==`g' [aw=reweightingfxn]
		matrix results[`i', `g'] = r(mean)
		
		foreach overvar in parity_bs wealth {
			levelsof(`overvar'), local(levels)
			
			foreach j in `levels' {
				
				sum dropbin if preg==1 & group==`g' & `overvar'==`j'
				local pct_dropped = r(mean)
				
				if `pct_dropped'>3 local problem_counter = `problem_counter'+1
				
				if `pct_dropped'>`biggest_problem' local biggest_problem = `pct_dropped'
				

			}
		}
	}
	
	matrix results[`i', 6] = `problem_counter'
	matrix results[`i', 7] = `biggest_problem'
	
	}
	
}



matrix colnames results = ///
	underweight1 /// 
	underweight2 ///
	underweight3 ///
	underweight4 ///
	underweight5 ///
	num_problems ///
	biggest_problem


drop *	

input str100 rows
"Original specification (4 category age bins)$^a$"
"Replace age bins to 5 category$^b$"
"Replace age bins to 5 category$^b$, remove education"
"Replace age bins to 5 category$^b$, remove rural"
"Replace age bins to 5 category$^b$, remove rural and education"
"Replace age bins to 6 category$^c$, remove rural and education"
"Replace age bins to 7 category$^d$, remove rural and education"
end



svmat results, names(col)


forvalues g=1/5 {
    format underweight`g' %04.2f
}

format num_problems %4.0f
format biggest_problem %4.2f


drop if missing(rows)


#delimit ;
listtex rows ///
    underweight1 underweight2 underweight3 underweight4 underweight5 ///
    using "tables/tableA5 reweighting specifications.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{5}{>{\centering\arraybackslash}p{1.5cm}}}" ///
         "\toprule" ///
         " & \multicolumn{5}{c}{Proportion of prepregnancy underweight} \\\\" ///
         "\cmidrule(lr){2-6}" ///
         "Variables used in reweighting relative to original specification & Adivasi & Dalit & OBC & Forward & Muslim \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr
