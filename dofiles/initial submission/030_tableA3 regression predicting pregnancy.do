* this table gets Table A4: Variables used in the nonparametric reweighting predict pregnancy (from a regression on an indicator for being pregnant on the covariates we use in reweighting)

do "$paths"
use "$dataset", clear

drop if group==. | group==6

*--------------------------
* Overall model
*--------------------------
#delimit ;
reghdfe preg
    i.less_edu
    i.rural
    i.noboy
    i.agebin
    i.parity_bs
    i.wealth , cluster(psu);
#delimit cr
eststo model0

*--------------------------
* By social group (1..5)
*--------------------------
foreach g of numlist 1/5 {
    #delimit ;
    reghdfe preg
        i.less_edu
        i.rural
        i.noboy
        i.agebin
        i.parity_bs
        i.wealth if group==`g', cluster(psu);
    #delimit cr
    eststo model`g'
}

*==========================
* Display in console (make sure your window is wide enough)
*==========================
#delimit ;
esttab model1 model2 model3 model4 model5 model0,
    drop(1.agebin 1.parity_bs 1.wealth) 
    refcat("\textbf{Predictors of gestation ≥3 months}" 2.agebin "\textbf{Age categories}" 2.parity_bs "\textbf{Parity \& time since last live birth categories}" 2.wealth "\textbf{Wealth categories}", nolabel)
    nonumbers 
    label se star(* 0.05 ** 0.01 *** 0.001)
    b(3) se(4)
    stats(N, fmt(%15.0fc) label(N))
    mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "All 5 Social Groups");
#delimit cr

*==========================
* Export to LaTeX
*==========================
#delimit ;
esttab model1 model2 model3 model4 model5 model0 using "tables/tableA3 predict pregnancy using reweighting variables.tex",
    replace
    refcat(2.agebin "\textbf{Age categories} \\ (15–19 omitted)" ///
           2.parity_bs "\textbf{Parity \& time since last live birth categories} \\ (No prior births omitted)" ///
           2.wealth "\textbf{Wealth quartiles} \\ (1st i.e. bottom quartile omitted)", nolabel)
    drop(0.less_edu 0.rural 0.noboy 1.agebin 1.parity_bs 1.wealth) 
    nonumbers nonote nolegend
    label se star(* 0.05 ** 0.01 *** 0.001)
    b(3) se(4)
    stats(N, fmt(%15.0fc) label("\textbf{N}"))
    mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "\shortstack{All five\\social groups}")
    booktabs 
    substitute("not using modern contraception" "\hspace*{1em}Not using modern contraception" ///
               "less than primary education" "\hspace*{1em}Less than primary education" ///
               "rural resident" "\hspace*{1em}Rural resident" ///
               "does not have boy child" "\hspace*{1em}Does not have boy child" ///
               "20–24" "\hspace*{1em}20–24" ///
               "25–29" "\hspace*{1em}25–29" ///
               "30–49" "\hspace*{1em}30–49" ///
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
#delimit cr
