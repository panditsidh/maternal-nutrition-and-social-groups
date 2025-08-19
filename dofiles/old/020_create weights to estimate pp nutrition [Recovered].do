//This file creates the weights that are used to create the synthetic cohort of prepregnant women.

* ----------- PARAMETERS-----------
local binvars c_user agebin less_edu rural hasboy wealth parity_bs groups6
* ----------------------------------------------------

* generate bins for reweighting
egen bin = group(`binvars')
gen counter=1

* collapse to bin-level counts of pregnant and total women
preserve
collapse ///
    (sum) bin_preg = preg ///
    (sum) bin_women = counter, ///
    by(bin)

* tag bins that only have pregnant (dropbin) or only non-pregnant women (zerobin)
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


