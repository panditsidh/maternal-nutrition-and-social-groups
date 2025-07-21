local outcome underweight

foreach outcome in underweight bmi {

*testing code
local outcome underweight 
*testing code

foreach g of numlist 2/5 {

	* get weights and group outcomes
	foreach p of numlist 0/3 {

		qui {
		
		eststo parity`p': reg v201 v201 // dummy regressison for eststo
		
		sum parity`p' if groups6==1 & preg==1 [aw=v005]
		local fwd_wt_`p' = r(mean)
		
		eststo parity`p': estadd scalar fwd_wt = r(mean)
		
		sum parity`p' if groups6==`g' & preg==1 [aw=v005]
		local g_wt_`p' = r(mean)
		eststo parity`p': estadd scalar g_wt = r(mean)
		
		sum `outcome' if groups6==1 & parity==`p' & preg==0 [aw=reweightingfxn]
		local fwd_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local fwd_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		eststo parity`p': estadd scalar fwd_outcome = `fwd_outcome_`p''
		
		sum `outcome' if groups6==`g' & parity==`p' & preg==0 [aw=reweightingfxn]
		local g_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local g_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		eststo parity`p': estadd scalar g_outcome = `g_outcome_`p''
		
		eststo parity`p': estadd scalar total_diff = (`g_outcome_`p''-`fwd_outcome_`p'')
		
		local within_group_`p' = (`g_outcome_`p''-`fwd_outcome_`p'')*(`g_wt_`p''+`fwd_wt_`p'')/2
		eststo parity`p': estadd scalar within_group = `within_group_`p''
		
		local between_group_`p' = (`g_wt_`p''-`fwd_wt_`p'')*(`g_outcome_`p''+`fwd_outcome_`p'')/2
		eststo parity`p': estadd scalar between_group = `between_group_`p''
		
		}
		
		
	}


	* get total/between/within group differences 
	qui {
	eststo total: reg v201 v201 // dummy regression for eststo

	* the number at the end indexes parity
	local fwd_outcome = `fwd_outcome_0'*`fwd_wt_0'+`fwd_outcome_1'*`fwd_wt_1'+`fwd_outcome_2'*`fwd_wt_2'+`fwd_outcome_3'*`fwd_wt_3'
	eststo total: estadd scalar fwd_outcome = `fwd_outcome'

	local g_outcome = `g_outcome_0'*`g_wt_0'+`g_outcome_1'*`g_wt_1'+`g_outcome_2'*`g_wt_2'+`g_outcome_3'*`g_wt_3'
	eststo total: estadd scalar g_outcome = `g_outcome'

	local total_diff = `g_outcome'-`fwd_outcome'
	eststo total: estadd scalar total_diff = `total_diff'

	* get component of difference explained/unexplained
	local within_group = `within_group_0'+`within_group_1'+`within_group_2'+`within_group_3'
	eststo total: estadd scalar within_group = `within_group'

	local between_group = `between_group_0'+`between_group_1'+`between_group_2'+`between_group_3'
	eststo total: estadd scalar between_group = `between_group'

	* get percent of difference explained/unexplained
	eststo pct: reg v201 v201 // dummy regression for eststo
	eststo pct: estadd scalar within_group = (`within_group'/`total_diff')*100 
	eststo pct: estadd scalar between_group = (`between_group'/`total_diff')*100

	}


	* format and export table
	if `g'==2 local group "OBC"
	if `g'==3 local group "Dalit"
	if `g'==4 local group "Adivasi"
	if `g'==5 local group "Muslim"

	local labels `" "Prop. pregnant women (Fwd)" "Avg pre-pregnancy `outcome' (Fwd)" "Prop. pregnant women (`group')" "Avg pre-pregnancy `outcome' (`group')"  "Difference in `outcome' (`group'-Forward)" "Within parity difference (rate)" "Between parity difference (compositional)" "'

	#delimit ;
	esttab parity0 parity1 parity2 parity3 total pct,
		stats(fwd_wt fwd_outcome g_wt g_outcome total_diff within_group between_group, labels(`labels') fmt(2))
		drop(v201 _cons)
		nonumbers nostar noobs not
		mtitles("Parity 0" "Parity 1" "Parity 2" "Parity 3+" "Total" "Percent");

	
	esttab parity0 parity1 parity2 parity3 total pct using "tables/kitagawa_`outcome'_`g'.tex",
		replace
		stats(fwd_wt fwd_outcome g_wt g_outcome total_diff within_group between_group, labels(`labels') fmt(2))
		drop(v201 _cons)
		nonumbers nostar noobs not
		mtitles("Parity 0" "Parity 1" "Parity 2" "Parity 3+" "Total" "Percent")
		booktabs;

	#delimit cr
	
	eststo clear
	
} // comparison group loop




} // outcome loop

