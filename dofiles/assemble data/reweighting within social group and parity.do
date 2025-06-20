* this file generates reweights within social group and parity

// qui do "dofiles/assemble data/00_assemble prepreg sample.do"

qui do "dofiles/assemble data/prepare nfhs3 data.do"

* generate bins for reweighting (within social group and parity)
egen bin = group(c_user agebin less_edu rural hasboy groups6 parity childdied)
gen counter=1


preserve
collapse ///
    (sum) bin_preg = preg ///
    (sum) bin_women = counter, ///
    by(bin)

* Step 3: define dropbin and zerobin at the bin level
gen dropbin = bin_preg == bin_women & bin_women > 0
gen zerobin = bin_preg == 0 & bin_women > 0
drop if bin==.

tempfile bininfo
save `bininfo'
restore

* Step 4: merge back to full data
merge m:1 bin using `bininfo', nogen

* create new weights
egen pregweight = sum(v005) if preg==1, by(bin)
egen nonpregweight = sum(v005) if preg==0, by(bin)
egen transferpreg = mean(pregweight), by(bin) // should assign to everyone
egen transfernonpreg = mean(nonpregweight), by(bin) // should assign to everyone
* the first four are bin level characteristics


gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0


/*


pregweight goes to only pregnant women


*/


/*

same answer when you take pp underweight at each parity * fraction at each parity to get group level pre-pregnancy
 
 
sanity check

 



*/
