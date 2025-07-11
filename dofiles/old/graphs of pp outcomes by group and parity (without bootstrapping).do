* need to fix export function here

if "`c(username)'" == "sidhpandit" {
	global path_bmi "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/figures/prepreg_bmi_combined.png"
	global path_underweight "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/figures/prepreg_underweight_combined.png"
}

if "`c(username)'" == "dc42724" {
	global path_bmi "C:\Users\dc42724\Documents\GitHub\trends-in-health-in-pregnancy-overleaf-\figures\maternal nutrition by social group\prepreg_bmi_combined.png"
	
	global path_underweight"C:\Users\dc42724\Documents\GitHub\trends-in-health-in-pregnancy-overleaf-\figures\maternal nutrition by social group\prepreg_underweight_combined.png"
	
	
}



svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)

capture graph drop _all
capture drop m ll ul m_*

* Define outcome list
local outcomes underweight bmi

* Clear any existing graph names
graph drop _all

foreach outcome of local outcomes {
    
    * Create new variables for mean and CI
    gen m = .
    gen ll = .
    gen ul = .
	
	gen m_overall_outcome = .
	gen m_overall_parity = .

    * Estimate mean and CI by group and parity
    foreach i of numlist 1/5 {
        foreach p of numlist 0/3 {
            quietly svy: mean `outcome' if groups6==`i' & parity==`p' & preg==0
            
            replace m = r(table)[1,1] if groups6==`i' & parity==`p'
            replace ll = r(table)[5,1] if groups6==`i' & parity==`p'
            replace ul = r(table)[6,1] if groups6==`i' & parity==`p'
        }
		
		quietly svy: mean `outcome' if groups6==`i' & preg==0
		replace m_overall_outcome = r(table)[1,1] if groups6==`i' & preg==0
		
		quietly svy: mean parity if groups6==`i' & preg==0
		replace m_overall_parity = r(table)[1,1] if groups6==`i' & preg==0
    }

    * Create plots: each non-forward group vs forward caste
    foreach i of numlist 2/5 {

        local groupname : label grouplbl `i'
		
		* set marker shapes based on the comparison social group 
		local shape square_hollow
		if `i'==3 local shape triangle_hollow
		if `i'==4 local shape diamond_hollow
		if `i'==5 local shape circle_hollow
		
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
		
		
		preserve
		
		duplicates drop groups6 m ll ul, force
		
        qui twoway ///
			(scatter m_overall_outcome m_overall_parity if groups6==1, msymbol(X) mcolor(gs8) msize(large)) ///
            (rcap ll ul parity if groups6==1, color(gs8)) ///
            (scatter m parity if groups6==1, msymbol(circle) mcolor(gs8)) ///
			(scatter m_overall_outcome m_overall_parity if groups6==`i', msymbol(X) mcolor(black) msize(large)) ///
            (rcap ll ul parity if groups6==`i', color(black)) ///
            (scatter m parity if groups6==`i', msymbol(`shape') mcolor(black)), ///
            xlabel(0 "0" 1 "1" 2 "2" 3 "3+") ///
            ytitle("estimated prevalence of pre-pregnancy `outcome'", size(small)) ///
            xtitle("number of living children", size(small)) ///
            title("`groupname'", size(medium)) ///
			`ylabel' ///
			`yscale' ///
            legend(order(1 "Forward Caste" 4 "Comparison Social Group") rows(1)) ///
            name(`outcome'_fwd_vs_group`i', replace)
        * Export graph as PNG
//         graph export "`outcome'_fwd_vs_group`i'.png", replace width(1200)
		
		graph export "${path}`outcome'_fwd_vs_group`i'.png", replace width(1200)
		
		restore
		
    }

    * Drop variables to avoid conflict in next loop
    drop m ll ul m*
}


#delimit ;
grc1leg underweight_fwd_vs_group2 underweight_fwd_vs_group3 underweight_fwd_vs_group4 underweight_fwd_vs_group5,
	ycommon iscale(.6) name(grc1leg1, replace);
	
gr draw grc1leg1, ysize(3) xsize(3);

graph export $path_underweight, as(png) replace;
	
	
#delimit ;
grc1leg bmi_fwd_vs_group2 bmi_fwd_vs_group3 bmi_fwd_vs_group4 bmi_fwd_vs_group5,
	ycommon iscale(.6) name(grc1leg2, replace);
	

gr draw grc1leg2, ysize(3) xsize(3);

graph export $path_bmi, as(png) replace;


#delimit cr


* stacked bar graph

gen parity0 = parity==0
gen parity1 = parity==1
gen parity2 = parity==2
gen parity3 = parity==3


*** only pregnant women

graph bar parity0 parity1 parity2 parity3 if preg==1, ///
    over(groups6, label(angle(45))) ///
    stack ///
    legend( ///
        label(1 "0") ///
        label(2 "1") ///
        label(3 "2") ///
        label(4 "3+") ///
        title("number of living children before pregnancy", size(small)) ///
        rows(5) ///
    )

graph export "${path}stackedbar_parity_socialgroup.png", as(png) replace
