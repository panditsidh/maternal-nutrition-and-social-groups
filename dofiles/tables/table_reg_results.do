


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
esttab model0 model4 model3 model2 model5 model1,
    drop(0.c_user 0.less_edu 0.rural 0.hasboy 1.agebin 1.parity_bs 1.wealth) 
	nonumbers 
    label se star(* 0.1 ** 0.05 *** 0.01)
	b(2) se(2)
	mtitle("All India" "Adivasi" "Dalit" "OBC" "Muslim" "Forward");
	
	
#delimit ;
esttab model0 model4 model3 model2 model5 model1 using "tables/predictor_regression.tex",
	replace
    drop(0.c_user 0.less_edu 0.rural 0.hasboy 1.agebin 1.parity_bs 1.wealth) 
	nonumbers 
    label se star(* 0.1 ** 0.05 *** 0.01)
	b(2) se(2)
	mtitle("All India" "Adivasi" "Dalit" "OBC" "Muslim" "Forward")
	booktabs;
	
