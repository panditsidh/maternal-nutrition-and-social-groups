/* STILL WIP

this dofile is to be run immediately after 010 and before anything else

the reason is that all other analyses drop women who are not of the 5 social groups we study

but here we want to get national estimates to compare with coffey 2015



issues currently: 
this doesn't directly replicate coffey 2015, we have diff reweighting vars, so i still need to do that

i dropped the 0.37% where group is missing

kept christian sikh jain as group 6 and this drops it at the end 


*/




do "$paths"

// 1 : create dataset for analysis 
do "dofiles/for Diane to review/010_assemble data.do"



//This file creates the weights that are applied to non-pregnant women to compute pre-pregnancy nutrition estimates.
do "$paths"

* ----------- PARAMETERS-----------
local binvars not_c_user agebin rural less_edu noboy wealth parity_bs group
* ----------------------------------------------------

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



sum underweight if preg==0 [aw=reweightingfxn]

* this gives 0.2211



use "$dataset", clear

drop if group==6 | group==.

save "$dataset", replace



