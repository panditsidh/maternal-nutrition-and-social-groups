eststo clear
qui do "dofiles/assemble data/00_assemble prepreg sample.do"

* ----------- PARAMETERS (change here only) -----------
// local binvars c_user agebin less_edu urban hasboy parity_bs wealth groups6

local attempt 1

foreach overvar in parity birth_space_cat wealth {

eststo drop over*
* this part is for the group by which you want kitagawa decomposition
// local overvar parity // testing line
levelsof groups6, local(groups)
levelsof `overvar', local(over)

if "`overvar'"=="parity" {
	
	local mtitles Overall "1" "2" "3" "4+"
	
	local binvars c_user agebin less_edu urban hasboy birth_space_cat wealth childdied groups6
	local title "Pregnant women droprate by parity; \\ rw vars: `binvars'"
}

if "`overvar'"=="birth_space_cat" {
	
	local binvars c_user agebin less_edu urban hasboy parity wealth childdied groups6
	
	local mtitles Overall "below 2 yrs" "2-3 yrs" "above 3 yrs" "1st birth"
	local title "Pregnant women droprate by birth spacing; \\ rw vars: `binvars'"
}

if "`overvar'"=="wealth" {
	
	local binvars c_user agebin less_edu urban hasboy parity_bs childdied groups6
	
	local mtitles Overall "1st" "2nd" "3rd" "4th"
	local title "Pregnant women droprate by wealth quartile; \\ rw vars: `binvars'"
}

local fvars
foreach var of local binvars {
    local fvars `fvars' i.`var'
}

qui reg preg `fvars' [aw=v005]
local rsq = e(r2)
eststo `overvar': qui reg v201 v201

eststo `overvar': estadd scalar rsq = `rsq'

// local binvars c_user agebin less_edu urban hasboy parity_bs wealth childdied groups6

* ----------------------------------------------------

* this file generates reweights within social group and parity


// qui do "dofiles/assemble data/prepare nfhs3 data.do"

capture drop bin counter dropbin zerobin pregweight nonpregweight transferpreg transfernonpreg reweightingfxn 
* generate bins for reweighting
egen bin = group(`binvars')
gen counter=1

preserve
collapse ///
    (sum) bin_preg = preg ///
    (sum) bin_women = counter, ///
    by(bin)

gen dropbin = bin_preg == bin_women & bin_women > 0
gen zerobin = bin_preg == 0 & bin_women > 0
drop if bin==.

tempfile bininfo
save `bininfo'
restore

merge m:1 bin using `bininfo', nogen

egen pregweight = sum(v005) if preg==1, by(bin)
egen nonpregweight = sum(v005) if preg==0, by(bin)
egen transferpreg = mean(pregweight), by(bin)
egen transfernonpreg = mean(nonpregweight), by(bin)

gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0



* the rest of the code creates a table of % pregnant women dropped in each reweighting group




foreach v in `over' {
	
	
	eststo over`v': qui reg v201 v201
	
	foreach g in `groups' {
		
		qui sum dropbin if groups6==`g' & `overvar'==`v' & preg==1
		
		local grouplabel : label grouplbl `g'
		
		eststo over_`v': qui estadd scalar `grouplabel' = r(mean)*100
		
		
		
		
		
		
	}
	
	
	
}


eststo over: qui reg v201 v201

foreach g in `groups' {
	
	qui sum dropbin if groups6==`g' & preg==1
	
	local grouplabel : label grouplbl `g'
		
	eststo over: estadd scalar `grouplabel' = r(mean)*100
	
}				



#delimit ;
esttab over over_*,
	stats(Forward OBC Dalit Adivasi Muslim, fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles(`mtitles')
	title(`title');
#delimit cr


#delimit ;
esttab over over_* using "tables/rw diagnostics/rw_droprate_over_`overvar'_`attempt'.tex", replace
	stats(Forward OBC Dalit Adivasi Muslim, fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles(`mtitles')
	note(`title')
	booktabs;
#delimit cr



}

#delimit ;
esttab parity birth_space_cat wealth using "tables/rw diagnostics/rsq_`attempt'",
	replace
	scalar(rsq) drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("parity" "birth space" "wealth quartile")
	note("rsquared of preg on associated analysis' reweighting")
	booktabs;
#delimit cr

#delimit ;
esttab parity birth_space_cat wealth, 
	scalar(rsq) drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("parity" "birth space" "wealth quartile")
	note("rsquared of preg on associated analysis' reweighting");
#delimit cr

* this part gives us regression results 

//
// local binvars c_user agebin less_edu urban hasboy parity_bs wealth childdied groups6
// levelsof groups6, local(groups)
//
// local fvars
// foreach var of local binvars {
//     local fvars `fvars' i.`var'
// }
//
// foreach g in `groups' {
//     di "----------------------------"
//     di "Running regression for group `g'"
//     qui reg preg `fvars' if groups6 == `g' [pw=v005]
//     di "R² for group `g': " %6.4f e(r2)
// }
//
// di "Running regression for all groups"
// qui reg preg `fvars' [pw=v005]
// di "R² for all groups: " %6.4f e(r2)
//
// esttab, scalar(rsq, fmt(3) label("R-squared"))


// * to compare to the bootstrap droprates
// use "data/bootstrapresults_full.dta", clear
//
// foreach i of numlist 1/5 {
//	
// 	qui replace pct_drop`i' = pct_drop`i'*100
// }
//
//
// sum pct_drop*
