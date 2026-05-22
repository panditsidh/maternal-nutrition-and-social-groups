* this table gets Table A4: Variables used in the nonparametric reweighting predict pregnancy
* only binary predictors and age bins

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
    i.agebin, cluster(psu);
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
        i.agebin if group==`g', cluster(psu);
    #delimit cr
    eststo model`g'
}

*==========================
* Display in console
*==========================
#delimit ;
esttab model1 model2 model3 model4 model5 model0,
    drop(1.agebin) 
    refcat(2.agebin "\textbf{Age categories}", nolabel)
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
esttab model1 model2 model3 model4 model5 model0 using "tables/tableA3 predict pregnancy NEW.tex",
    replace
    refcat(2.agebin "\textbf{Age categories} \\ (15–19 omitted)", nolabel)
    drop(0.less_edu 0.rural 0.noboy 1.agebin) 
    nonumbers nonote nolegend
    label se star(* 0.05 ** 0.01 *** 0.001)
    b(3) se(4)
    stats(N, fmt(%15.0fc) label("\textbf{N}"))
    mtitle("Adivasi" "Dalit" "OBC" "Forward" "Muslim" "\shortstack{All five\\social groups}")
    booktabs 
    substitute("no education or primary only" "\hspace*{1em}No education or primary only" ///
               "rural resident" "\hspace*{1em}Rural resident" ///
               "does not have boy child" "\hspace*{1em}Does not have boy child" ///
               "20–24" "\hspace*{1em}20–24" ///
               "25–29" "\hspace*{1em}25–29" ///
               "30–49" "\hspace*{1em}30–49" ///
               "Constant" "\hspace*{1em}Constant");
#delimit cr
