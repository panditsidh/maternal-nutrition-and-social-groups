* this makes the kitagawa tables

* we use esttab in a clever way to add custom statistics


use "$dataset", clear
do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"


eststo clear
local outcome underweight
local overvars parity_bs wealth

local overvar parity_bs
levelsof `overvar', local(over)


foreach g of numlist 2/5 {
	
	
	* dummy regression for esttab formatting later
	eststo `outcome'`g': reg v201 v201 
	
	
	* calculate quantities and add as scalars under the dummy model
	sum underweight [aw=reweightingfxn] if groups6==1
	local fwd_`outcome' = r(mean)
	
	sum underweight [aw=reweightingfxn] if groups6==`g'
	local `g'_`outcome' = r(mean)
	
	local `outcome'_diff = (``g'_`outcome'' - `fwd_`outcome'')*100
	
	eststo `outcome'`g': estadd scalar `outcome'_diff = ``outcome'_diff'
	
	foreach overvar in parity_bs wealth {
	levelsof `overvar', local(over)

	
	
	
	local within_group = 0
	local between_group = 0
	
	foreach p in `over' {
		
		display(`p')
				
		sum `overvar'`p' if groups6==1 & preg==1 [aw=v005]
		local fwd_wt_`p' = r(mean)
		
		
		sum `overvar'`p' if groups6==`g' & preg==1 [aw=v005]
		local g_wt_`p' = r(mean)
		
		sum `outcome' if groups6==1 & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		local fwd_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local fwd_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		
		sum `outcome' if groups6==`g' & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		
		local g_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local g_outcome_`p' = r(mean)*100 // rescale to % for underweight		
		
		local within_group_`p' = (`g_outcome_`p''-`fwd_outcome_`p'')*(`g_wt_`p''+`fwd_wt_`p'')/2
		
		local between_group_`p' = (`g_wt_`p''-`fwd_wt_`p'')*(`g_outcome_`p''+`fwd_outcome_`p'')/2
		
		local within_group = `within_group' + `within_group_`p''
		local between_group = `between_group' + `between_group_`p''
		


		
	}
	
	eststo `outcome'`g': estadd scalar within_`overvar' = `within_group'
	eststo `outcome'`g': estadd scalar between_`overvar' = `between_group'
	
	eststo `outcome'`g': estadd scalar pct_`overvar' = (`between_group'/``outcome'_diff')*100

	}
}


local labels `"  "percentage point difference in pre-pregnancy underweight" " " "\textbf{Panel A: Decompositions of parity + birthspacing}" "pp difference within parity + birthspacing category" "pp different across parity + birthspacing category" "\% explained by parity + birthspacing" " "  "\textbf{Panel B. Decompositions of wealth}"  "pp difference within wealth category"  "pp different across wealth category"  "\% explained by wealth"  "'

#delimit ;
esttab underweight*, 
	stats(underweight_diff blank blank within_parity_bs between_parity_bs pct_parity_bs blank blank within_wealth between_wealth pct_wealth, labels(`labels') fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
	;

esttab underweight* using "tables/kitagawa_all.tex",  replace
	stats(underweight_diff blank blank within_parity_bs between_parity_bs pct_parity_bs blank blank within_wealth between_wealth pct_wealth, labels(`labels') fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
	booktabs
	;

	
