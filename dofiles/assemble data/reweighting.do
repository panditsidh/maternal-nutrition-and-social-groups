* ----------- PARAMETERS (change here only) -----------
local binvars c_user agebin less_edu rural hasboy groups6 parity childdied
* ----------------------------------------------------

* this file generates reweights within social group and parity

// qui do "dofiles/assemble data/00_assemble prepreg sample.do"
qui do "dofiles/assemble data/prepare nfhs3 data.do"

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
