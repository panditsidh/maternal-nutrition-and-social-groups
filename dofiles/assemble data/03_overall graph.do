if "`c(username)'" == "sidhpandit" {
	
	global out_tex "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_"
	
	
	global rw_01 "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/01_reweight within social group.do"
	
	global assemble "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/00_assemble prepreg sample.do"
	
	
	global path "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/figures/overall_graph.png"
	
	
	
}

if "`c(username)'" == "dc42724" {

	
	global rw_01 "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\01_reweight within social group.do"
	
	global assemble "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\00_assemble prepreg sample.do"
	
}

do "${assemble}"
do "${rw_01}"

svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)



capture graph drop _all
capture drop m ll ul m_*



graph drop _all



gen m = .
gen ll = .
gen ul = .


local outcome underweight

foreach i of numlist 1/5 {
	
	qui svy: mean `outcome' if groups6==`i' & preg==0
	replace m = r(table)[1,1] if groups6==`i' 
	replace ll = r(table)[5,1] if groups6==`i' 
	replace ul = r(table)[6,1] if groups6==`i' 
	
	
// 	local groupname : label grouplbl `i'
//		
// 	* set marker shapes based on the comparison social group 
// 	local shape square_hollow
// 	if `i'==3 local shape triangle_hollow
// 	if `i'==4 local shape diamond_hollow
// 	if `i'==5 local shape circle_hollow
//	
}


* set axis options depending on the outcome
local ylabel ""
local yscale ""

if "`outcome'" == "underweight" {
	local ylabel ylabel(0.1(0.05)0.3, angle(horizontal))
	local yscale yscale(range(0.1 0.3))
}
else if "`outcome'" == "bmi" {
	local ylabel ylabel(20(1)24, angle(horizontal))
	local yscale yscale(range(20 24))
}




local outcome underweight
preserve
		
	duplicates drop groups6 m ll ul, force
	
	qui twoway ///
		(rcap ll ul groups6) ///
		(scatter m groups6, legend(off)), ///
		ytitle("estimated prevalence of pre-pregnancy `outcome'", size(small)) ///
		xtitle("social group", size(small)) ///
		title("overall social group `outcome'", size(medium)) ///
		xlabel(1 "Forward" 2 "OBC" 3 "Dalit" 4 "Adivasi" 5 "Muslim")
		`ylabel' ///
		`yscale' ///
		
  
	
// 		graph export "${path}`outcome'_fwd_vs_group`i'.png", replace width(1200)
	
restore



graph export $path, replace width(1200)
