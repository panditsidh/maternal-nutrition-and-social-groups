* this file does the reweighting for the main result (social group differences in pre-pregnancy underweight), and all kitagawa decompositions

* ----------- PARAMETERS (change here only) -----------
local binvars c_user agebin less_edu urban hasboy wealth_2 parity_bs groups6
* ----------------------------------------------------

* assemble dataset
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
// qui do "dofiles/assemble data/prepare nfhs3 data.do"

* generate bins for reweighting
egen bin = group(`binvars')
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








* the table generated below is useful but "dofiles/tables/reweighting diagnostics" is better for the same purpose

// * the rest of the code gives you a quick summary of the pregnant women droprate by social group x kitagawa decomposition variable group
// eststo clear 
//
// local overvar birth_space_cat
// levelsof groups6, local(groups)
// levelsof `overvar', local(over)
//
// foreach v in `over' {
//	
//	
// 	eststo over`v': qui reg v201 v201
//	
// 	foreach g in `groups' {
//		
// 		qui sum dropbin if groups6==`g' & `overvar'==`v' & preg==1
//		
// 		local grouplabel : label grouplbl `g'
//		
// 		eststo over`v': estadd scalar `grouplabel' = r(mean)*100
//		
// 	}
// }
//
//
//
// if "`overvar'"=="parity" local mtitles  "1" "2" "3" "4+"
//
//
// if "`overvar'"=="birth_space_cat" local mtitles  "below 2 yrs" "2-3 yrs" "above 3 yrs" "1st birth"
//	
//
// if "`overvar'"=="wealth" local mtitles  "1st" "2nd" "3rd" "4th"
//
//
//
//
// #delimit ;
// esttab over*,
// 	stats(Forward OBC Dalit Adivasi Muslim, fmt(2))
// 	drop(v201 _cons)
// 	nonumbers nostar noobs not
// 	mtitles(`mtitles');
//
