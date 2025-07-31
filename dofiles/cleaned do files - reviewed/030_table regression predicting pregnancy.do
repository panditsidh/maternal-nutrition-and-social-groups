* this file creates the regression table

use "$dataset", clear


#delimit ;
reghdfe preg
	i.not_c_user
	i.less_edu
	i.rural
	i.noboy
	i.agebin
	i.parity_bs
	i.wealth , cluster(psu);
#delimit cr
eststo model0


foreach g of numlist 1/5 {
	

#delimit ;
reghdfe preg
	i.not_c_user
	i.less_edu
	i.rural
	i.noboy
	i.agebin
	i.parity_bs
	i.wealth if group==`g', cluster(psu);
#delimit cr	


eststo model`g'
	
	
	
}


#delimit ;
esttab model1 model2 model3 model4 model5 model0,
    drop(1.agebin 1.parity_bs 1.wealth) 
	refcat("\textbf{Binary predictors of pregnancy and underweight}" 2.agebin "\textbf{Age categories}" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
	nonumbers 
    label se star(* 0.05 ** 0.01)
	b(a3) se(a4)
	stats(N, fmt(%15.0fc) label(N))
	mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "All 5 Social Groups");

/*
#delimit ;
esttab model1 model2 model3 model4 model5 model0,
    drop(0.not_c_user 0.less_edu 0.rural 0.noboy 1.agebin 1.parity_bs 1.wealth) 
	refcat(1.not_c_user "\textbf{Binary predictors of pregnancy and underweight}" 2.agebin "\textbf{Age categories}" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
	nonumbers 
    label se star(* 0.05 ** 0.01)
	b(a3) se(a3)
	stats(N, fmt(%15.0fc) label(N))
	mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "All 5 Social Groups");
*/
	

#delimit ;
esttab model1 model2 model3 model4 model5 model0 using "tables/predictor_regression.tex",
	replace
	refcat(1.not_c_user "\textbf{Binary predictors of pregnancy and underweight}" 2.agebin "\textbf{Age categories}  (15-19 omitted)" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
    drop(0.not_c_user 0.less_edu 0.rural 0.noboy 1.agebin 1.parity_bs 1.wealth) 
	nonumbers 
    label se star(* 0.5 ** 0.01)
	b(a3) se(a4)
	stats(N, fmt(%15.0fc) label("\textbf{N}"))
	mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "\shortstack{All five\\social groups}")
	booktabs 
	substitute("not using modern contraception" "\hspace*{1em}Not using modern contraception" ///
           "less than primary education" "\hspace*{1em}Less than primary education" ///
           "rural resident" "\hspace*{1em}Rural resident" ///
           "does not have boy child" "\hspace*{1em}Does not have boy child" ///
           "20–24" "\hspace*{1em}20–24" ///
           "25–29" "\hspace*{1em}25–29" ///
           "30–34" "\hspace*{1em}30–34" ///
           "1 birth, below 2y spacing" "\hspace*{1em}1 birth, below 2y spacing" ///
           "1 birth, 2–3y spacing" "\hspace*{1em}1 birth, 2–3y spacing" ///
           "1 birth, 3+y spacing" "\hspace*{1em}1 birth, above 3y spacing" ///
           "2 births, below 2y spacing" "\hspace*{1em}2 births, below 2y spacing" ///
           "2 births, 2–3y spacing" "\hspace*{1em}2 births, 2–3y spacing" ///
           "2 births, 3+y spacing" "\hspace*{1em}2 births, above 3y spacing" ///
           "3+ births, below 2y spacing" "\hspace*{1em}3+ births, below 2y spacing" ///
           "3+ births, 2–3y spacing" "\hspace*{1em}3+ births, 2–3y spacing" ///
           "3+ births, 3+y spacing" "\hspace*{1em}3+ births, above 3y spacing" ///
           "2nd quartile" "\hspace*{1em}2nd quartile" ///
           "3rd quartile" "\hspace*{1em}3rd quartile" ///
           "4th quartile" "\hspace*{1em}4th quartile" ///
           "Constant" "\hspace*{1em}Constant");
	
