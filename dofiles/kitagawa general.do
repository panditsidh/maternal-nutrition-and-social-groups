// do "dofiles/assemble data/reweighting.do"
eststo clear

local outcome underweight

local overvars parity_bs parity birth_space_cat wealth

foreach overvar in `overvars' {
	
levelsof `overvar', local(over)

foreach outcome in underweight {


foreach g of numlist 2/5 {


	qui {
	* get weights and group outcomes
	foreach p in `over' {

		display(`p')
		
		eststo `overvar'`p': reg v201 v201 // dummy regressison for eststo
		
		sum `overvar'`p' if groups6==1 & preg==1 [aw=v005]
		local fwd_wt_`p' = r(mean)
		
		eststo `overvar'`p': estadd scalar fwd_wt = r(mean)
		
		sum `overvar'`p' if groups6==`g' & preg==1 [aw=v005]
		local g_wt_`p' = r(mean)
		eststo `overvar'`p': estadd scalar g_wt = r(mean)
		
		sum `outcome' if groups6==1 & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		local fwd_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local fwd_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		eststo `overvar'`p': estadd scalar fwd_outcome = `fwd_outcome_`p''
		
		sum `outcome' if groups6==`g' & `overvar'==`p' & preg==0 [aw=reweightingfxn]
		local g_outcome_`p' = r(mean)
		
		if "`outcome'"=="underweight" local g_outcome_`p' = r(mean)*100 // rescale to % for underweight
		
		eststo `overvar'`p': estadd scalar g_outcome = `g_outcome_`p''
		
		eststo `overvar'`p': estadd scalar total_diff = (`g_outcome_`p''-`fwd_outcome_`p'')
		
		local within_group_`p' = (`g_outcome_`p''-`fwd_outcome_`p'')*(`g_wt_`p''+`fwd_wt_`p'')/2
		eststo `overvar'`p': estadd scalar within_group = `within_group_`p''
		
		local between_group_`p' = (`g_wt_`p''-`fwd_wt_`p'')*(`g_outcome_`p''+`fwd_outcome_`p'')/2
		eststo `overvar'`p': estadd scalar between_group = `between_group_`p''
		
		
		
		
	}


	display("breakdown decomp")
	
	* get total/between/within group differences 

	eststo total: reg v201 v201 // dummy regression for eststo
	
	display(`fwd_outcome_1')

	* the number at the end indexes parity
// 	local fwd_outcome = `fwd_outcome_1'*`fwd_wt_1'+`fwd_outcome_2'*`fwd_wt_2'+`fwd_outcome_3'*`fwd_wt_3'
	
	local fwd_outcome = 0
	local g_outcome = 0
	local within_group = 0
	local between_group = 0

	foreach p of local over {
		local fwd_outcome = `fwd_outcome' + `fwd_outcome_`p'' * `fwd_wt_`p''
		local g_outcome   = `g_outcome'   + `g_outcome_`p'' * `g_wt_`p''
		local within_group = `within_group' + `within_group_`p''
		local between_group = `between_group' + `between_group_`p''
	}

	
	eststo total: estadd scalar fwd_outcome = `fwd_outcome'

// 	local g_outcome = `g_outcome_1'*`g_wt_1'+`g_outcome_2'*`g_wt_2'+`g_outcome_3'*`g_wt_3'
	
	eststo total: estadd scalar g_outcome = `g_outcome'

	local total_diff = `g_outcome'-`fwd_outcome'
	eststo total: estadd scalar total_diff = `total_diff'

	* get component of difference explained/unexplained
// 	local within_group = `within_group_1'+`within_group_2'+`within_group_3'
	
	eststo total: estadd scalar within_group = `within_group'

	
	
// 	local between_group = `between_group_1'+`between_group_2'+`between_group_3'
	eststo total: estadd scalar between_group = `between_group'

	
	display("overall decomp")
	
	* get percent of difference explained/unexplained
	eststo pct: reg v201 v201 // dummy regression for eststo
	
	
	eststo pct: estadd scalar within_group = (`within_group'/`total_diff')*100 
	eststo pct: estadd scalar between_group = (`between_group'/`total_diff')*100
	

	* format and export table
	if `g'==2 local group "OBC"
	if `g'==3 local group "Dalit"
	if `g'==4 local group "Adivasi"
	if `g'==5 local group "Muslim"

	local labels `" "Prop. preg (Fwd)" "Avg pre-preg `outcome' (Fwd)" "Prop. preg (`group')" "Avg pre-preg `outcome' (`group')"  "Difference in `outcome' (`group'-Forward)" "Within group difference" "Between group difference" "'
	}
	
	if "`overvar'"=="parity_bs" {
		local mtitles1 `" "p1" "p2 <2yrs" "p2 2-3yrs" "p3 >3yrs" "p3 <2yrs" "p3 2-3yrs" "p3 >3yrs" "p4+ <2yrs" "p4+ 2-3yrs" "p4+ >3yrs" "'
		
		local mtitles2 `" "p1" "p2 \textless2yrs" "p2 2-3yrs" "p2 \textgreater3yrs" "p3 \textless2yrs" "p3 2-3yrs" "p3 \textgreater3yrs" "p4+ \textless2yrs" "p4+ 2-3yrs" "p4+ \textgreater3yrs" "'

	}
	
	if "`overvar'"=="parity" {
		
		local mtitles1 `" "parity 1" "parity 2" "parity 3" "parity 4+" "Total" "Percent" "'
		
		local mtitles2 `" "parity 1" "parity 2" "parity 3" "parity 4+" "Total" "Percent" "'

	}
	
	if "`overvar'"=="birth_space_cat" {
		
		local mtitles1 `" "under 2 yrs" "2-3 years" "over 3 years" "Total" "Percent" "'
		
		local mtitles2 `" "under 2 yrs" "2-3 years" "over 3 years" "Total" "Percent" "'
	}
	
	if "`overvar'"=="wealth" {
		
		local mtitles1 `" "Wealth 1st Q" "Wealth 2nd Q" "Wealth 3rd Q" "Wealth 4th Q" "Total" "Percent" "'
		
		local mtitles2 `" "Wealth 1st Q" "Wealth 2nd Q" "Wealth 3rd Q" "Wealth 4th Q" "Total" "Percent" "'
	}
	
	

	#delimit ;
	esttab `overvar'* total pct,
		stats(fwd_wt fwd_outcome g_wt g_outcome total_diff within_group between_group, labels(`labels') fmt(2))
		drop(v201 _cons)
		nonumbers nostar noobs not
		mtitles(`mtitles1')
		addnote("fwd caste and `group'");

	esttab `overvar'* total pct using "tables/kitagawa_`outcome'_`g'_`overvar'.tex",
		replace
		stats(fwd_wt fwd_outcome g_wt g_outcome total_diff within_group between_group, labels(`labels') fmt(2))
		drop(v201 _cons)
		nonumbers nostar noobs not
		mtitles(`mtitles2')
		booktabs;

	#delimit cr
	
	eststo clear
	
} // comparison group loop



} // outcome loop

} // overvars loop
