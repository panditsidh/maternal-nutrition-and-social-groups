
clear all

// use "$dataset", clear

tempfile results

postfile handle ///
    double cutoff adivasi_ppunderweight dalit_ppunderweight obc_ppunderweight ///
    using `results', replace


forvalues c = 100(-2)0 {
	
	di "Now on cutoff `c'"
	
	qui { 
	
	use "$dataset", clear
	
	local cutoff = `c'/100
	
	keep if pct_psu_higher<= `cutoff'
	
	do "dofiles/050_weights to estimate pp nutrition.do"
	}
	
	foreach group in 1 2 3 {
		
		qui {
		sum underweight  if preg==0 & group==`group' [aw=reweightingfxn]
		local b`group' = r(mean)
		
		sum dropbin if group==`group'
		local pct_dropped = r(mean)*100
		
		}

		if `pct_dropped'>5 {
			
			
			
			di "Warning: for cutoff `cutoff' and group `group', `pct_dropped'% pregnant women are dropped."
		}
		
		
	}
	
	post handle (`cutoff') (`b1') (`b2') (`b3')
	
	
	
}


postclose handle


use `results', clear






*------------------------------------------------------------
* Save line-results dataset
*------------------------------------------------------------
foreach var in adivasi_ppunderweight dalit_ppunderweight obc_ppunderweight {
    capture confirm variable pct_`var'
    if _rc {
        gen pct_`var' = 100 * `var'
    }
}

tempfile line_results
save `line_results', replace


*------------------------------------------------------------
* Build CI dataset from selected cutoff results
*------------------------------------------------------------
tempfile ci_results
clear
save `ci_results', emptyok replace

foreach c in .75 .5 .25 .1 {
    
    use "data/results cutoff `c'.dta", clear
    
    keep if inlist(rows, "Adivasi", "Dalit", "OBC")
    
    gen cutoff = `c'
    
    keep rows cutoff underweight_mean underweight_ll underweight_ul
    
    gen group = .
    replace group = 1 if rows=="Adivasi"
    replace group = 2 if rows=="Dalit"
    replace group = 3 if rows=="OBC"
    
    gen pp_mean = 100 * underweight_mean
    gen pp_ll   = 100 * underweight_ll
    gen pp_ul   = 100 * underweight_ul
    
    keep group cutoff pp_mean pp_ll pp_ul
    
    append using `ci_results'
    save `ci_results', replace
}


*------------------------------------------------------------
* Add cutoff = 1 estimates and CIs from main results file
*------------------------------------------------------------
use "data/results.dta", clear

keep if inlist(rows, "Adivasi", "Dalit", "OBC", "Forward")

gen cutoff = 1

gen group = .
replace group = 1 if rows=="Adivasi"
replace group = 2 if rows=="Dalit"
replace group = 3 if rows=="OBC"
replace group = 4 if rows=="Forward"

gen pp_mean = 100 * underweight_mean
gen pp_ll   = 100 * underweight_ll
gen pp_ul   = 100 * underweight_ul

sum pp_mean if group==4
local forward_ppu = r(mean)

keep group cutoff pp_mean pp_ll pp_ul

append using `ci_results'
save `ci_results', replace


*------------------------------------------------------------
* Merge CI variables into line-results dataset
*------------------------------------------------------------
use `line_results', clear

merge 1:m cutoff using `ci_results', nogen

* Split CI variables by group for easier graphing
gen adivasi_ci_mean = pp_mean if group==1
gen adivasi_ci_ll   = pp_ll   if group==1
gen adivasi_ci_ul   = pp_ul   if group==1

gen dalit_ci_mean = pp_mean if group==2
gen dalit_ci_ll   = pp_ll   if group==2
gen dalit_ci_ul   = pp_ul   if group==2

gen obc_ci_mean = pp_mean if group==3
gen obc_ci_ll   = pp_ll   if group==3
gen obc_ci_ul   = pp_ul   if group==3



gen forward_ci_ll = pp_ll if group==4
gen forward_ci_ul = pp_ul if group==4


twoway ///
    (line pct_adivasi_ppunderweight cutoff, sort lwidth(medthick) lcolor(navy)) ///
    (rcap adivasi_ci_ul adivasi_ci_ll cutoff if !missing(adivasi_ci_ll), ///
        lcolor(navy)) ///
    ///
    (line pct_dalit_ppunderweight cutoff, sort lwidth(medthick) lcolor(maroon)) ///
    (rcap dalit_ci_ul dalit_ci_ll cutoff if !missing(dalit_ci_ll), ///
        lcolor(maroon)) ///
    ///
    (line pct_obc_ppunderweight cutoff, sort lwidth(medthick) lcolor(green)) ///
    (rcap obc_ci_ul obc_ci_ll cutoff if !missing(obc_ci_ll), ///
        lcolor(green)) ///
    ///
    (rcap forward_ci_ul forward_ci_ll cutoff if group==4 & cutoff==1, ///
        lcolor(gs8)) ///
    ///
    , ///
    yline(16, lpattern(dash) lcolor(gs10) lwidth(thin)) ///
    text(16 .08 "Forward caste: 16%", color(gs8) size(small) placement(e)) ///
    xscale(reverse range(0 1)) ///
    xlabel(1(.1)0, angle(0)) ///
    ylabel(, angle(0)) ///
    xtitle("Maximum fraction of PSU" "higher ranking included") ///
    ytitle("Estimated prepregnancy" "underweight (%)") ///
    legend(order(1 "Adivasi" 3 "Dalit" 5 "OBC" 7 "Forward caste CI") ///
           rows(1) position(6)) ///
    title("Prepregnancy underweight by local higher caste-rank exposure") ///
    note("Lines re-estimate prepregnancy underweight after restricting the sample by fraction PSU higher ranking." ///
         "Confidence intervals are shown at selected cutoffs. Dashed line shows forward-caste estimate.")

graph export "figures/ppu_by_pct_psu_higher_cutoff_with_ci.png", replace width(2400)
