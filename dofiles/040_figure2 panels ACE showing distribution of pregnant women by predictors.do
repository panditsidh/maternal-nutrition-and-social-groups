* 4: Panels ACE of Figure 2: Differences in parity, birth spacing, and wealth quartile by social group, and the relationship between these characteristics and prepregnancy underweight (stacked bars showing distribution of covariates within each social group)

do "$paths"
use "$dataset", clear

drop if group==6 | group==.

************* FIGURE A: distribution of pregnant women by parity ***************
preserve

* rescale outcome variables so they show up as percents
replace parity1 = parity1*100
replace parity2 = parity2*100
replace parity3 = parity3*100
replace parity4 = parity4*100	

keep if preg==1


* for displaying the sample size in the graph
count
local sample_size : display %15.0fc r(N)


#delimit ;
graph hbar (mean) parity1 parity2 parity3 parity4 [aw=v005], 
    over(group, label(angle(0))) 
    stack 
    legend(order(1 "parity 0" 2 "parity 1" 3 "parity 2" 4 "parity 3+") 
       cols(4) pos(6) region(lstyle(none))) 
    blabel(bar, format(%4.1f) position(inside) ) 
    ytitle("Percent") 
	title("A. Distribution of parity among pregnant women")
	note("n=`sample_size' (3+ month married pregnant women)", size(medsmall)) name(c, replace);
#delimit cr 

graph save "figures/figure2a.gph", replace
// graph export "figures/parity distribution of pregnant women by social group.png", replace

restore

************* FIGURE C: distribution of partiy 2+ pregnant women by birth spacing***************
preserve

replace bs_below2 = bs_below2*100
replace bs_2to3 = bs_2to3*100
replace bs_above3 = bs_above3*100

keep if parity>=2	
keep if preg==1
keep if gestdur>=3



* for displaying the sample size in the graph
count
local sample_size : display %15.0fc r(N)


# delimit ;
graph hbar (mean) bs_below2 bs_2to3 bs_above3 [aw=v005], 
    over(group) 
    stack 
	legend(order(1 "below 2 years" 2 "2-3 years" 3 "above 3 years") 
       cols(4) pos(6) region(lstyle(none))) 
	blabel(bar, format(%4.1f) position(inside) ) 
	ytitle("Percent") 
	title("C. Distribution of birth spacing among pregnant women")
    note("n=`sample_size' (3+ month married pregnant women" "who have at least 1 live birth)", size(medsmall)) ;
# delimit cr



graph save "figures/figure2c.gph", replace
graph export "figures/birth spacing distribution of pregnant women by social group.png", replace
	
restore


********** FIGURE E: distribution of pregnant women by wealth quartile ***********

preserve

keep if preg==1
keep if gestdur>=3

replace wealth1 = wealth1*100
replace wealth2 = wealth2*100
replace wealth3 = wealth3*100
replace wealth4 = wealth4*100

* for displaying the sample size in the graph
count
local sample_size : display %15.0fc r(N)

#delimit ;
graph hbar (mean) wealth1 wealth2 wealth3 wealth4 [aw=v005], 
    over(group) 
    stack 
	legend(order(1 "1st quartile" 2 "2nd quartile" 3 "3rd quartile" 4 "4th quartile") 
       cols(4) pos(6) region(lstyle(none))) 
	blabel(bar, format(%4.1f) position(inside) ) 
	ytitle("Percent") 
	note("n=`sample_size' (3+ month married pregnant women)", size(medsmall)) name(c, replace) 
	title("E. Distribution of wealth among pregnant women");
	
# delimit cr
graph save "figures/figure2e.gph", replace
// graph export "figures/wealth distribution of pregnant women by social group.png", replace

restore


