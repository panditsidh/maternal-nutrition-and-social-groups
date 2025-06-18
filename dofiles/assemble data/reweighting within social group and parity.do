* this file generates reweights within social group and parity

qui do "dofiles/assemble data/00_assemble prepreg sample.do"

* generate bins for reweighting (within social group and parity)
egen bin = group(age edu rural hasboy c_user groups6 parity)
gen counter=1
		
* number of pregnant women in each bin (_n==1 to run faster at bin level)
bysort bin (preg): gen bin_preg = sum(preg) if _n==1

* total women in each bin
bysort bin (preg): gen bin_women = sum(counter) if _n==1


* which bins have only pregnant women
gen dropbin = bin_preg==bin_women if !missing(bin_preg)

* which bins have only nonpregnant women
gen zerobin = bin_preg==0 & bin_women>0 if !missing(bin_preg)

* propogate dropbin/zerobin to all women in bin
bysort bin (dropbin): replace dropbin = dropbin[1]
bysort bin (zerobin): replace zerobin = zerobin[1]

* create new weights
egen pregweight = sum(v005) if preg==1 & dropbin!=1, by(bin)
egen nonpregweight = sum(v005) if preg==0 & dropbin!=1, by(bin)
egen transferpreg = mean(pregweight) if dropbin!=1, by(bin)
egen transfernonpreg = mean(nonpregweight) if dropbin!=1, by(bin)
gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0

/*

same answer when you take pp underweight at each parity * fraction at each parity to get group level pre-pregnancy
 
 
sanity check
 
 



*/
