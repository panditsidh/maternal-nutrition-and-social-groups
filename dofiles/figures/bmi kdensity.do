if "`c(username)'" == "sidhpandit" {
	global path_bmi_parity "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/figures/bmi_distribution_parity.png"
	
	global path_bmi"/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/figures/bmi_distribution.png"
}

if "`c(username)'" == "dc42724" {
	global path_bmi_parity "C:\Users\dc42724\Documents\GitHub\trends-in-health-in-pregnancy-overleaf-\figures\maternal nutrition by social group\bmi_distribution_parity.png"
	
	global path_bmi "C:\Users\dc42724\Documents\GitHub\trends-in-health-in-pregnancy-overleaf-\figures\maternal nutrition by social group\bmi_distribution.png"
	
}






twoway ///
(kdensity bmi [aw=reweightingfxn] if groups6 == 1 & preg == 0 & bmi<31, lcolor(navy) lpattern(solid) lwidth(medthick) ///
    legend(label(1 "Forward Castes"))) ///
(kdensity bmi [aw=reweightingfxn] if groups6 == 5 & preg == 0 & bmi<31, lcolor(maroon) lpattern(dash) lwidth(medthick) ///
    legend(label(2 "Muslims"))) ///
, ///
title("Pre-Pregnancy BMI Distribution (overall)") ///
xlabel(15(2)30) ///
ylabel(, angle(horizontal)) ///
legend(position(6) ring(0) cols(1)) ///
xtitle("BMI") ///
ytitle("Density") ///
xline(18.5, lpattern(dot) lcolor(black)) ///
graphregion(color(white)) ///
plotregion(margin(zero))




graph export ""





forvalues p = 0/3 {
   
    twoway ///
    (kdensity bmi [aw=reweightingfxn] if groups6 == 1 & preg == 0 & parity == `p' & bmi < 31, ///
        lcolor(navy) lpattern(solid) lwidth(medthick) ///
        legend(label(1 "Forward Castes"))) ///
    (kdensity bmi [aw=reweightingfxn] if groups6 == 5 & preg == 0 & parity == `p' & bmi < 31, ///
        lcolor(maroon) lpattern(dash) lwidth(medthick) ///
        legend(label(2 "Muslims"))) ///
    , ///
    title("Parity `p'") ///
    xlabel(15(2)30) ///
    ylabel(, angle(horizontal)) ///
    legend(position(6) ring(0) cols(2)) ///
    xtitle("BMI") ///
    ytitle("Density") ///
    xline(18.5, lpattern(dot) lcolor(black)) ///
    graphregion(color(white)) ///
    plotregion(margin(zero)) ///
    name(bmi_parity`p', replace)
}


grc1leg bmi_parity0 bmi_parity1 bmi_parity2 bmi_parity3, ///
    rows(2) ///
    title("Pre-Pregnancy BMI: Distribution by Parity") ///
    ycommon ///
    graphregion(color(white))
	

graph export $path_bmi, as(png) replace;
