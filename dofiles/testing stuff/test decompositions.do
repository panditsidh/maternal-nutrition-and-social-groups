local overvar parity_bs



// local outfile "tables/kitagawa by animal protein score quartile.tex"

// local note "\parbox[t]{0.95\linewidth}{The decomposition variable is the protein score quartile where the protein score is +30 for every ANIMAL protein food daily, +5 for every protein food weekly, and +1 for every protein food occaisionally. So only milk/curd, fish, eggs, meat - no pulses/beans.}"'


*********************** First do the reweighting including the new variable ***********************

do "$paths"

use "$dataset", clear

foreach i in 1 2 3 4 {
	
	gen psu_od_besideshh_q4`i' = psu_od_besideshh_q4==`i'
}



cap drop pregweight nonpregweight transferpreg transfernonpreg reweightingfxn counter dropbin zerobin bin


local binvars agebin rural less_edu noboy group `overvar'

drop if missing(preg)



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





*********************** Now test the decomposition ***********************


eststo clear

local outcome underweight


* group labels
local group1 "Adivasi"
local group2 "Dalit"
local group3 "OBC"


* get levels of decomposition variable
levelsof `overvar' if !missing(`overvar'), local(over)

foreach g in 1 2 3  {
    
    * dummy regression for esttab formatting
    eststo `outcome'`g': reg v201 v201
    
    * forward caste overall prepregnancy outcome
    sum `outcome' [aw=reweightingfxn] if group==4 & preg==0
    local fwd_outcome = r(mean)*100
    
    * group g overall prepregnancy outcome
    sum `outcome' [aw=reweightingfxn] if group==`g' & preg==0
    local g_outcome = r(mean)*100
    
    * total gap in percentage points
    local total_gap = `g_outcome' - `fwd_outcome'
    
    local within_group = 0
    local between_group = 0
    
    * add headline quantities
    estadd scalar fwd_mean = `fwd_outcome'
    estadd scalar group_mean = `g_outcome'
    estadd scalar total_gap = `total_gap'
    
    foreach p in `over' {
        
        * shares among pregnant women
        sum `overvar' if group==4 & preg==1 [aw=v005]
        local fwd_total = r(N)
        
        sum `overvar' if group==`g' & preg==1 [aw=v005]
        local g_total = r(N)

		
		sum `overvar'`p' if group==`g' & preg==1 [aw=v005]
		local g_wt = r(mean)
		
		sum `overvar'`p' if group==4 & preg==1 [aw=v005]
		local fwd_wt = r(mean)
        
        * prepregnancy outcomes within category
        sum `outcome' if group==4 & `overvar'==`p' & preg==0 [aw=reweightingfxn]
        local fwd_cat_outcome = r(mean)*100
        
        sum `outcome' if group==`g' & `overvar'==`p' & preg==0 [aw=reweightingfxn]
        local g_cat_outcome = r(mean)*100
        
        * Kitagawa components
        local within_p = (`g_cat_outcome' - `fwd_cat_outcome') * ///
            (`g_wt' + `fwd_wt') / 2
            
        local between_p = (`g_wt' - `fwd_wt') * ///
            (`g_cat_outcome' + `fwd_cat_outcome') / 2
        
        local within_group = `within_group' + `within_p'
        local between_group = `between_group' + `between_p'
        
        * category-specific details
        estadd scalar fwd_share_`p' = `fwd_wt' * 100
        estadd scalar group_share_`p' = `g_wt' * 100
        estadd scalar fwd_rate_`p' = `fwd_cat_outcome'
        estadd scalar group_rate_`p' = `g_cat_outcome'
        estadd scalar within_`p' = `within_p'
        estadd scalar between_`p' = `between_p'
    }
    
    estadd scalar within_total = `within_group'
    estadd scalar between_total = `between_group'
    estadd scalar pct_explained = (`between_group' / `total_gap') * 100
}

local labels `" "Forward mean" "Group mean" "Total gap" "Within-category component" "Composition component" "\% explained by composition" "'

#delimit ;
esttab underweight1 underweight2 underweight3,
    stats(
        fwd_mean
        group_mean
        total_gap
        within_total
        between_total
        pct_explained,
        labels(`labels')
        fmt(1)
    )
    drop(v201 _cons)
    nonumbers nostar noobs not
    mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
;
#delimit cr


#delimit ;
esttab underweight1 underweight2 underweight3 using "`outfile'" , replace tex
    stats(
        fwd_mean
        group_mean
        total_gap
        within_total
        between_total
        pct_explained,
        labels(`labels')
        fmt(1)
    )
    drop(v201 _cons)
    nonumbers nostar noobs not
	addnote("`note'")
    mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
;
#delimit cr
