do "$paths"
use "$dataset", clear
do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"


eststo clear
local outcome underweight
local overvars parity_bs wealth

local overvar parity_bs
levelsof `overvar', local(over)


foreach g in 1 2 3 5 {
	
	
	* dummy regression for esttab formatting
	eststo `outcome'`g': reg v201 v201 
	
	
	* calculate quantities and add as scalars under the dummy model
	sum underweight [aw=reweightingfxn] if group==4
	local fwd_`outcome' = r(mean)
	
	
	* overall prepreg outcome for social group g
	sum underweight [aw=reweightingfxn] if group==`g'
	local `g'_`outcome' = r(mean)
	
	* gap to be explained
	local `outcome'_diff = (``g'_`outcome'' - `fwd_`outcome'')*100
	eststo `outcome'`g': estadd scalar `outcome'_diff = ``outcome'_diff'
	
	
	* do the decomposition for predictors: parity + birth spacing and wealth quartiles
	foreach overvar in parity_bs wealth {
	
	levelsof `overvar', local(over)
	
	local within_group = 0
	local between_group = 0
	
	* loop over levels of the predictor (ie ...parity 2, birth spacing >3yrs, parity 3 birth spacing <2 years...)
	foreach p in `over' {
		
		* proportion of fwd caste pregnant women at that predictor level (weight)
		sum `overvar'`p' if group==4 & preg==1 [aw=v005]
		local fwd_wt_`p' = r(mean)
		
		* proportion of group g pregnant women at that predictor level (weight)
		sum `overvar'`p' if group==`g' & preg==1 [aw=v005]
		local g_wt_`p' = r(mean)
		
		* prepreg outcome of forward caste women at that predictor level
		sum `outcome' if group==4 & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		local fwd_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local fwd_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		* prepreg outcome of group g women at that predictor level
		sum `outcome' if group==`g' & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		
		local g_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local g_outcome_`p' = r(mean)*100 // rescale to % for underweight		
		
		* within group (unexplained) difference contributed at this predictor level
		local within_group_`p' = (`g_outcome_`p''-`fwd_outcome_`p'')*(`g_wt_`p''+`fwd_wt_`p'')/2
		
		* between group/compositional (explained) difference contributed at this predictor level
		local between_group_`p' = (`g_wt_`p''-`fwd_wt_`p'')*(`g_outcome_`p''+`fwd_outcome_`p'')/2
		
		* add to overall explained/unexplained components
		local within_group = `within_group' + `within_group_`p''
		local between_group = `between_group' + `between_group_`p''
		


		
	}
	
	* scale to percent and format in table
	eststo `outcome'`g': estadd scalar within_`overvar' = `within_group'
	eststo `outcome'`g': estadd scalar between_`overvar' = `between_group'
	eststo `outcome'`g': estadd scalar pct_`overvar' = (`between_group'/``outcome'_diff')*100

	}
}


local labels `"  "percentage point difference in pre-pregnancy underweight" " " "\textbf{Panel A: Decompositions of parity + birthspacing}" "pp difference within parity + birthspacing category" "pp difference across parity + birthspacing category" "\% explained by parity + birthspacing" " "  "\textbf{Panel B. Decompositions of wealth}"  "pp difference within wealth category"  "pp difference across wealth category"  "\% explained by wealth"  "'

#delimit ;
esttab underweight1 underweight2 underweight3 underweight5, 
	stats(underweight_diff blank blank within_parity_bs between_parity_bs pct_parity_bs blank blank within_wealth between_wealth pct_wealth, labels(`labels') fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
	;

esttab underweight1 underweight2 underweight3 underweight5 using "tables/table_kitagawa_results.tex",  replace
	stats(underweight_diff blank blank within_parity_bs between_parity_bs pct_parity_bs blank blank within_wealth between_wealth pct_wealth, labels(`labels') fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("Adivasi-Forward" "Dalit-Forward" "OBC-Forward" "Muslim-Forward")
	booktabs
	;

	
