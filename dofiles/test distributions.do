* 4: Panels ACE of Figure 2: Differences in parity, birth spacing, and wealth quartile by social group, and the relationship between these characteristics and prepregnancy underweight (stacked bars showing distribution of covariates within each social group)

do "$paths"
// use "$dataset", clear

drop if group==6 | group==.


// local n_legend_cols =3 

local overvar protein_score_quartile_animal
local overtitle "animal protein score quartile"
local outfile "figures/distribution of animal protein score quartile.png"

capture drop `overvar'_*
local vallab : value label `overvar'

distinct `overvar' 
local n_categories = r(ndistinct)

levelsof(`overvar'), local(over)

local i = 1

foreach level of local over {
    
    * create dummy variable
    local dummy `overvar'_`level'
    gen `dummy' = (`overvar' == `level') * 100
    
    * add dummy to bar variable list
    local over_dummies `over_dummies' `dummy'
    
    * get label for this category
    if "`vallab'" != "" {
        local lab : label `vallab' `level'
    }
    else {
        local lab "`level'"
    }
    
    * add to dynamic legend
    local legend_order `legend_order' `i' "`lab'"
    
    local i = `i'+ 1
}

di "`over_dummies'"
di `"`legend_order'"'




************* FIGURE A: distribution among pregnant women ***************
preserve

keep if preg==1

count
local sample_size : display %15.0fc r(N)

#delimit ;
graph hbar (mean) `over_dummies' [aw=v005], 
    over(group, label(angle(0))) 
    stack 
    legend(order(`legend_order') 
       cols(`n_legend_cols') pos(6) region(lstyle(none))) 
    blabel(bar, format(%4.0f) position(inside)) 
    ytitle("Percent") 
    title("Distribution of `overtitle'")
    note("n=`sample_size' (3+ month married pregnant women)", size(medsmall)) 
    name(c, replace);
#delimit cr 

graph export "`outfile'", replace as(png) name("c")

restore
