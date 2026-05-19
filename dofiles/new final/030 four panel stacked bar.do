do "$paths"
use "$dataset", clear

drop if group == 6 | group == .

*------------------------------------------------------------
* Four-panel stacked bar figure:
* distribution of reweighting predictors among pregnant women
*------------------------------------------------------------

local panels wealth parity bs psu_od_besideshh_q4

local title_wealth "A. Wealth"
local title_parity "B. Parity"
local title_bs "C. Time since last live birth"
local title_psu_od_besideshh_q4 "D. PSU open defecation exposure"


local note_wealth "n=`sample_size' (3+ month married pregnant women)"
local note_parity "n=`sample_size' (3+ month married pregnant women)"
local note_psu_od_besideshh_q4 "n=`sample_size' (3+ month married pregnant women)"
local note_bs "n=`sample_size' (3+ month married pregnant women who have at least 1 live birth)"


local outfile "figures/distribution of reweighting predictors among pregnant women.png"

* Ordered translucent blue palettes
* Same color logic across all panels:
* category 1 = eltblue, category 2 = ebblue, category 3 = emidblue, category 4 = navy
local colors3 "eltblue%55 ebblue%55 emidblue%55"
local colors4 "eltblue%55 ebblue%55 emidblue%55 navy%55"




local graphlist ""

foreach panel of local panels {
    
    *--------------------------------------------------------
    * Reset panel-specific locals
    *--------------------------------------------------------
    
    local overvar "`panel'"
    local overtitle "`title_`panel''"
    local over_dummies ""
    local legend_order ""
    local baropts ""
    
    * Get value label attached to this variable
    local vallab : value label `overvar'
    
    * Get levels among pregnant women only
    levelsof `overvar' if preg == 1, local(over)
    
    * Number of categories
    local n_categories : word count `over'
    
    * Pick palette
    if `n_categories' == 3 {
        local colors `colors3'
        local n_legend_cols = 3
    }
    else if `n_categories' == 4 {
        local colors `colors4'
        local n_legend_cols = 2
		
		if "`panel'"=="psu_od_besideshh_q4" {
			local n_legend_cols = 2
			
		}
    }
    else {
        di as error "Panel `overvar' has `n_categories' categories; define a color palette for this case."
        exit 198
    }
    
    local i = 1
    
    foreach level of local over {
        
        * Dummy variable for this category
        local dummy `overvar'_`level'
        
        capture drop `dummy'
        gen `dummy' = (`overvar' == `level') * 100 if !missing(`overvar')
        
        * Add dummy to stacked bar variable list
        local over_dummies `over_dummies' `dummy'
        
        * Get value label for this category
        if "`vallab'" != "" {
            local lab : label `vallab' `level'
        }
        else {
            local lab "`level'"
        }
        
        * Clean labels for graph legend
        local lab = subinstr(`"`lab'"', "\%", "%", .)
        
        * Add to legend order
        local legend_order `legend_order' `i' `"`lab'"'
        
        * Assign consistent ordered blue shading
        local thiscolor : word `i' of `colors'
        local baropts `baropts' bar(`i', color("`thiscolor'") lcolor(none))
        
        local ++i
    }
    
    preserve
        
        keep if preg == 1
        
        count if !missing(`overvar')
        local sample_size : display %15.0fc r(N)
		local note_wealth "n=`sample_size' (3+ month married pregnant women)"
		local note_parity "n=`sample_size' (3+ month married pregnant women)"
		local note_psu_od_besideshh_q4 "n=`sample_size' (3+ month married pregnant women)"
		local note_bs "n=`sample_size' (3+ month married pregnant women" "who have at least 1 live birth)"

        
        #delimit ;
        graph hbar (mean) `over_dummies' [aw=v005],
            over(group, label(angle(0) labsize(tiny)))
            stack
            `baropts'
            legend(order(`legend_order')
                   cols(`n_legend_cols')
                   pos(6)
                   size(vsmall)
				   symxsize(small)
				   symysize(small)
                   region(lstyle(none)))
            blabel(bar, format(%4.0f) position(inside) size(tiny))
            ytitle("Percent", size(vsmall))
            ylabel(0(20)100, labsize(vsmall))
            title("`overtitle'", size(small))
			note("`note_`overvar''", size(vsmall))
            name(g_`panel', replace);
        #delimit cr
        
    restore
    
    local graphlist `graphlist' g_`panel'
}

*------------------------------------------------------------
* Combine panels
*------------------------------------------------------------

graph combine `graphlist', ///
    cols(2) ///
    xsize(10) ///
    ysize(8) ///
    name(combined_reweighting_predictors, replace)

graph export "`outfile'", replace as(pdf) name(combined_reweighting_predictors)
