* this file is to get reweights for kitagawa decomposition by wealth
* so wealth is removed from the bin command

* ----------- PARAMETERS (change here only) -----------
local binvars c_user agebin less_edu urban hasboy parity_bs groups6

* ----------------------------------------------------

qui do "dofiles/assemble data/00_assemble prepreg sample.do"

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


eststo clear 

local overvar birth_space_cat
levelsof groups6, local(groups)
levelsof `overvar', local(over)

foreach v in `over' {
	
	
	eststo over`v': qui reg v201 v201
	
	foreach g in `groups' {
		
		qui sum dropbin if groups6==`g' & `overvar'==`v' & preg==1
		
		local grouplabel : label grouplbl `g'
		
		eststo over`v': estadd scalar `grouplabel' = r(mean)
		
	}
}


#delimit ;
esttab over*,
	stats(Forward OBC Dalit Adivasi Muslim, fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not;

