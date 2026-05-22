* this dofile creates appendix tableA1
* it reports results from a regression on the sample of women who report being pregnant
* the outcome variable is "reports being 1 or 2 months pregnant"
* and the covariates are things like SES, contraception use, birth spacing
* we show that these variables are systematically different for women who report being 1 or 2 months pregnant because those who detect pregnancy early are a select sample
* we define gestational duration as months since last period and if that's not available we use the self-reported gestational duration

use "$dataset", clear

eststo clear

keep if v213==1 // self reports pregnant
keep if !missing(gestdur)

*drop women who are not part of the 5 social groups we study
drop if group==6

gen gestdur_1or2 = inlist(gestdur,1,2) // self reports 1 or 2 months pregnant


* removed //     i.not_c_user

* run model for that group
#delimit ;
reghdfe gestdur_1or2
    i.less_edu
    i.rural
    i.noboy
    i.agebin
    i.parity_bs
    i.wealth_index
	i.psu_od_besideshh_q4, cluster(psu);
#delimit cr
eststo model_g


do "$paths"
*--------------------------
* Console display
*--------------------------

#delimit ;
esttab model_g,
    drop(1.agebin 1.parity_bs 1.wealth_index 1.psu_od_besideshh_q4)
    refcat(2.agebin "\textbf{Age categories}" ///
           2.parity_bs "\textbf{Parity \& time since last live birth categories}" ///
           2.wealth_index "\textbf{Wealth quintile}" ///
           2.psu_od_besideshh_q4 "\textbf{Fraction of neighboring households that defecate in the open}", nolabel)
    nonumbers 
    label se wide star(* 0.05 ** 0.01 *** 0.001)
    b(3) se(4)
    stats(N, fmt(%15.0fc) label(N))
    mtitle("reports 1 or 2" "months of pregnancy")
    substitute("no education or primary only" "\hspace*{1em}No education or primary only" ///
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
               "Poorer" "\hspace*{1em}Poorer" ///
               "Middle" "\hspace*{1em}Middle" ///
               "Richer" "\hspace*{1em}Richer" ///
			   "Richest" "\hspace*{1em}Richest" ///
               "Second PSU OD exposure quartile" "\hspace*{1em}Second PSU OD exposure quartile" ///
               "Third PSU OD exposure quartile" "\hspace*{1em}Third PSU OD exposure quartile" ///
               "Highest PSU OD exposure quartile" "\hspace*{1em}Highest PSU OD exposure quartile" ///
               "Constant" "\hspace*{1em}Constant");
#delimit cr

*--------------------------
* LaTeX export
*--------------------------

#delimit ;
esttab model_g using "tables/tableA1 predicting first quarter pregnancy NEW.tex",
    replace
    refcat(2.agebin "\textbf{Age categories} \\ (15–19 omitted)" ///
           2.parity_bs "\textbf{Parity \& time since last live birth categories} \\ (No prior births omitted)" ///
           2.wealth_index "\textbf{Wealth quintiles} \\ (Poorest quintile omitted)" ///
           2.psu_od_besideshh_q4 "\textbf{Percent of neighboring households that defecate in the open} \\ (Quartile 1 0% omitted)", nolabel)
    drop(0.less_edu 0.rural 0.noboy ///
         1.agebin 1.parity_bs 1.wealth_index 1.psu_od_besideshh_q4) 
    nonumbers nonote 
    label se wide star(* 0.05 ** 0.01 *** 0.001)
    b(3) se(4)
    stats(N, fmt(%15.0fc) label("\textbf{N}"))
    mtitle("\shortstack{reports of 1 or 2 months of pregnancy}")
    booktabs 
    substitute("no education or primary only" "\hspace*{1em}No education or primary only" ///
               "rural resident" "\hspace*{1em}Rural resident" ///
               "does not have boy child" "\hspace*{1em}Does not have boy child" ///
               "20–24" "\hspace*{1em}20–24" ///
               "25–29" "\hspace*{1em}25–29" ///
               "30–49" "\hspace*{1em}30–49" ///
               "1 birth, below 2y spacing" "\hspace*{1em}1 birth, below 2y spacing" ///
               "1 birth, 2–3y spacing" "\hspace*{1em}1 birth, 2--3y spacing" ///
               "1 birth, 3+y spacing" "\hspace*{1em}1 birth, above 3y spacing" ///
               "2 births, below 2y spacing" "\hspace*{1em}2 births, below 2y spacing" ///
               "2 births, 2–3y spacing" "\hspace*{1em}2 births, 2--3y spacing" ///
               "2 births, 3+y spacing" "\hspace*{1em}2 births, above 3y spacing" ///
               "3+ births, below 2y spacing" "\hspace*{1em}3+ births, below 2y spacing" ///
               "3+ births, 2–3y spacing" "\hspace*{1em}3+ births, 2--3y spacing" ///
               "3+ births, 3+y spacing" "\hspace*{1em}3+ births, above 3y spacing" ///
               "Poorer" "\hspace*{1em}Poorer" ///
               "Middle" "\hspace*{1em}Middle" ///
               "Richer" "\hspace*{1em}Richer" ///
			   "Richest" "\hspace*{1em}Richest" ///
               "Quartile 2: 4\% - 10\%" "\hspace*{1em}Quartile 2: 4\% - 10\%" ///
               "Quartile 3: 10\% - 33.3\%" "\hspace*{1em}Quartile 3: 10\% - 33.3\%" ///
			   "Quartile 4: 33.3\% - 100\%" "\hspace*{1em}Quartile 4: 33.3\% - 100\%" ///
               "Constant" "\hspace*{1em}Constant");
#delimit cr
