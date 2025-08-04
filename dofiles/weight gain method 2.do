* this dofile gets weight gain method 2


foreach g of numlist 1/5 {
	
	qui sum weight [aw=reweightingfxn] if preg==0 & group==`g' & dropbin!=1
	local weight`g' = r(mean)
	
	
	* calculate weight at 9+ mopreg
	qui sum weight [aw=v005] if mopreg>=9 & mopreg!=. & group==`g'
	local nineweighthat`g' = r(mean)
	
	* get beta from weight on mopreg regression
	qui reg weight mopreg i.v012 i.v133 i.v218 i.urban i.v190 i.v024##v006 [aw=v005] if group==`g'& inrange(mopreg,3,9)
	local coeffhat`g' = _b[mopreg]
	
	
	local gainhat_group`g' = `nineweighthat_`g''-`weight`g''+(0.5)*`coeffhat_`g'' if _n==`i'
	
	matrix results[`row', `col'] = `gainhat_group`g''
	

} 
