
* figure a

preserve

keep if preg==1

replace parity1 = parity1*100
replace parity2 = parity2*100
replace parity3 = parity3*100
replace parity4 = parity4*100	

graph hbar (mean) parity1 parity2 parity3 parity4 [aw=v005], ///
    over(groups6, label(angle(0))) ///
    stack ///
    legend(order(1 "Parity 1" 2 "Parity 2" 3 "Parity 3" 4 "Parity 4+") ///
       cols(4) pos(6) region(lstyle(none))) ///
    blabel(bar, format(%4.1f) position(inside) ) ///
    ytitle("Percent") ///
    title("Distribution of parity by social group - NFHS-5 pregnant women") ///
    note("parity defined as # of live births, proportions weighted by v005. all nfhs-5 pregnant women")

graph export "figures/parity distribution of pregnant women by social group.png", replace

restore

	
* figure b


preserve


replace bs_below2 = bs_below2*100
replace bs_2to3 = bs_2to3*100
replace bs_above3 = bs_above3*100

keep if parity>=2	
keep if preg==1

graph hbar (mean) bs_below2 bs_2to3 bs_above3 [aw=v005], ///
    over(groups6) ///
    stack /// 
	legend(order(1 "below 2 years" 2 "2-3 years" 3 "above 3 years") ///
       cols(4) pos(6) region(lstyle(none))) ///
	blabel(bar, format(%4.1f) position(inside) ) ///
	ytitle("Percent") ///
    title("Distribution of birth spacing by social group - NFHS-5 pregnant women", size(medlarge)) ///
    note("proportions weighted by v005. all nfhs-5 pregnant women of parity 2+ (defined as # of live births)")
	
graph export "figures/birth spacing distribution of pregnant women by social group.png", replace

	
restore


* figure c




preserve

keep if preg==1

replace wealth1 = wealth1*100
replace wealth2 = wealth2*100
replace wealth3 = wealth3*100
replace wealth4 = wealth4*100

graph hbar (mean) wealth1 wealth2 wealth3 wealth4 [aw=v005], ///
    over(groups6) ///
    stack /// 
	legend(order(1 "1st quartile" 2 "2nd quartile" 3 "3rd quartile" 4 "4th quartile") ///
       cols(4) pos(6) region(lstyle(none))) ///
	blabel(bar, format(%4.1f) position(inside) ) ///
	ytitle("Percent") ///
    title("Distribution of wealth by social group - nfhs-5 pregnant women") ///
    note("proportions weighted by v005. all nfhs-5 pregnant women")

graph export "figures/wealth distribution of pregnant women by social group.png", replace


restore
