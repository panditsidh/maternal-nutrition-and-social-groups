


keep if forward==1 & parity ==1

* generate bins for reweighting
egen bin=group(c_user agebin less_edu urban hasboy wealth)

gen counter=1

preserve
collapse (sum) counter (mean) c_user agebin less_edu urban hasboy wealth, by(bin preg)

drop if bin==.

reshape wide counter, i(bin) j(preg)
replace counter0=0 if counter0==.
replace counter1=0 if counter1==.
sum counter1 if counter0==0
di r(mean)*r(N)

*There are 1414 forward caste, parity 1 pregnant women.
*di ans/1414

gen dropbin=1 if counter0==0&counter1>0
tab dropbin, m
save "data\bins_to_drop_forward_p1.dta", replace
restore

cap drop _merge
merge m:1 bin using "data\bins_to_drop_forward_p1.dta"

count if dropbin == 1
global dropped = r(N)
drop if dropbin==1
drop dropbin

egen pregweight = sum(v005) if preg == 1, by(bin)
egen nonpregweight = sum(v005) if preg == 0, by(bin)
egen transferpreg = mean(pregweight), by(bin)
egen transfernonpreg = mean(nonpregweight), by(bin)

gen reweightingfxn = v005*transferpreg/transfernonpreg
sum underweight [aweight=reweightingfxn] if preg == 0

