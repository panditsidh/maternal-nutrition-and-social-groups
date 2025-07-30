
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
