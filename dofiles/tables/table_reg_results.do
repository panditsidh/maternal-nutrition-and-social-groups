


#delimit ;
reghdfe preg
	i.c_user
	i.less_edu
	i.rural
	i.hasboy
	i.agebin
	i.parity_bs
	i.wealth [aw=v005], cluster(psu);
#delimit cr
eststo model0


foreach g of numlist 1/5 {
	

#delimit ;
reghdfe preg
	i.c_user
	i.less_edu
	i.rural
	i.hasboy
	i.agebin
	i.parity_bs
	i.wealth [aw=v005] if groups6==`g', cluster(psu);
#delimit cr	


eststo model`g'
	
	
	
}



#delimit ;
esttab model4 model3 model2 model5 model1 model0,
    drop(0.c_user 0.less_edu 0.rural 0.hasboy 1.agebin 1.parity_bs 1.wealth) 
	refcat(1.c_user "\textbf{Binary predictors of pregnancy and underweight}" 2.agebin "\textbf{Age categories}" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
	nonumbers 
    label se star(* 0.1 ** 0.05 *** 0.01)
	b(%9.3g) se(%9.3g)
	mtitle("Adivasi" "Dalit" "OBC" "Muslim" "Forward" "All 5 Social Groups");
	
	
#delimit ;
esttab model4 model3 model2 model5 model1 model0 using "tables/predictor_regression.tex",
	replace
	refcat(1.c_user "\textbf{Binary predictors of pregnancy and underweight}" 2.agebin "\textbf{Age categories}" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
    drop(0.c_user 0.less_edu 0.rural 0.hasboy 1.agebin 1.parity_bs 1.wealth) 
	nonumbers 
    label se star(* 0.1 ** 0.05 *** 0.01)
	b(%9.3g) se(%9.3g)
	mtitle("Adivasi" "Dalit" "OBC" "Muslim" "Forward" "All 5 Social Groups")
	booktabs;
	
