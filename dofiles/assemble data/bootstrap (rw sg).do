set more off 
clear all

set seed 8062011
local B = 1000 //how many times to bootstrap

/*
	
every bootstrap iteration: 

what bins have no pregnant women in them

- reweight again
- get % pregnant women within each reweighting group
- get # dropped bins per reweighting group 
- get % of pregnant women dropped within reweighting group

- get outcomes (bmi, underweight, weight)

- get 9/10 month pregnant women weights

- get mopreg beta from regression of weight on mopreg, age, edu, # living children, wealth index, state/month interaction (sample, mopreg 3-9)

*/

* clear results dataset and initialize results variables we want from each iteration
set obs 20000

foreach g of numlist 1/5 {
	* reweighting diagnostics
	gen preg`g' = .
	gen pct_drop`g' = .
	gen bins`g' = .
	gen dropbins`g' = .
	gen pct_zero`g' = .
	gen count9plus`g' = .
	
	* outcomes
	gen bmi`g' = .
	gen underweight`g' = .
	gen weight`g' = .
	gen nineweighthat`g' = .
	gen coeffhat`g' = .
	gen gainhat`g' = .
	
	

}


save "data/bootstrapresults_full.dta", replace


* starting point for each bootstrap iteration
qui do "dofiles/assemble data/00_assemble prepreg sample.do"
tempfile prepared_dataset
replace strata = 7 if strata==8
save `prepared_dataset'

* bootstrapping loop
forvalues i = 1(1)`B'{ 

	di `i', " of ", `B'
	
	qui {
		
	use `prepared_dataset', clear
	
// 	* testing code
// 	qui do "${assemble}"
// 	replace strata = 7 if strata==8
// 	local i = 1
// 	* testing code
	
	* get bootstrap sample
	bsample, strata(strata) cluster(psu) 

	* generate bins for reweighting (within social group)
	egen bin = group(v012 edu rural hasboy c_user groups6)
	gen counter=1
	
	* the following loop gets reweighting diagnostics, these are helper variables
	gen dropbin = 0
	gen zerobin = 0
	gen bin_preg = .
	gen bin_women = .
	
	foreach g of numlist 1/5 {
		
		* number of bins per social group
		distinct bin if groups6==`g'
		local bins`g' = r(ndistinct)
		
		* percent pregnant per social group
		sum preg if groups6==`g'
		local preg`g' = r(mean)

		* number of pregnant women in each bin (_n==1 bc bin level)
		bysort bin (preg): replace bin_preg = sum(preg) if groups6==`g' & _n==1 
		
		* total number of women in each bin
		bysort bin (preg): replace bin_women = sum(counter) if groups6==`g' & _n==1
		
		replace dropbin = 1 if !missing(bin_preg) & bin_preg==bin_women & groups6==`g'
		replace zerobin = 1 if !missing(bin_preg) & bin_preg==0 & bin_women>0 & groups6==`g'

		* number of bins that need to be dropped for having only pregnant women
		count if dropbin==1 & groups6==`g'
		local dropbins`g' = r(N)
		
		* propogate dropbin and zerobin to all individuals if needed
		bysort bin (dropbin): replace dropbin = dropbin[1] if dropbin[1]==1 & groups6==`g' 
		bysort bin (zerobin): replace zerobin = zerobin[1] if zerobin[1]==1 & groups6==`g'
		
		* percent of nonpregnant women in bins without pregnant women (reweighted to zero)
		sum zerobin if groups6==`g' & preg==0
		local pct_zero`g' = r(mean)		
		
		* percent pregnant dropped within social group
		sum dropbin if preg==1 & groups6==`g'
		local pct_drop`g' = r(mean)
		
		* count of nine plus pregnant women per social group
		count if mopreg>=9 & mopreg!=. & groups6==`g'
		local count9plus`g' = r(N)
		
	}
	
	* create new weights
// 	drop if dropbin==1
	egen pregweight = sum(v005) if preg==1 & dropbin!=1, by(bin)
	egen nonpregweight = sum(v005) if preg==0 & dropbin!=1, by(bin)
	egen transferpreg = mean(pregweight) if dropbin!=1, by(bin)
	egen transfernonpreg = mean(nonpregweight) if dropbin!=1, by(bin)
	gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1
	
	
	* calculate prepregnancy outcomes 
	foreach g of numlist 1/5 {
		foreach var of varlist bmi underweight weight {
			qui sum `var' [aw=reweightingfxn] if preg==0 & groups6==`g' & dropbin!=1
			local `var'`g' = r(mean)
		}
		
		
		* calculate weight at 9+ mopreg
		qui sum weight [aw=v005] if mopreg>=9 & mopreg!=. & groups6==`g'
		local nineweighthat`g' = r(mean)
		
		
		* get beta from weight on mopreg regression
		qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if groups6==`g'& inrange(mopreg,3,9)
		local coeffhat`g' = _b[mopreg]
	}
	
	use "data/bootstrapresults_full.dta", clear
	foreach g of numlist 1/5 {
				
		* Reweighting diagnostics
		replace preg`g'       = `preg`g''       if _n == `i'
		replace pct_drop`g'   = `pct_drop`g''   if _n == `i'
		replace bins`g'       = `bins`g''       if _n == `i'
		replace dropbins`g'   = `dropbins`g''   if _n == `i'
		replace pct_zero`g'   = `pct_zero`g''   if _n == `i'
		replace count9plus`g' = `count9plus`g'' if _n == `i'

		* Prepregnancy outcomes for non-pregnant women
		
		replace bmi`g' = `bmi`g'' if _n == `i'
		replace underweight`g' = `underweight`g'' if _n == `i'
		replace weight`g' = `weight`g'' if _n == `i'
		
		* late pregnancy weight
		replace nineweighthat`g' = `nineweighthat`g'' if _n == `i'
		
		* beta from weight on mopreg regression
		replace coeffhat`g' = `coeffhat`g'' if _n == `i'
		
		* weight gain from method 2
		replace gainhat`g' = nineweighthat`g'-weight`g'+(0.5)*coeffhat`g' if _n==`i'
	}
	
	save, replace
	
	}
	
}

* Tell us what happened
sum bmihat, detail
sum underweighthat, detail
sum weighthat, detail

centile bmihat underweighthat weighthat, centile(2.5 97.5)
