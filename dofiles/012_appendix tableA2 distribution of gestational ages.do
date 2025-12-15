* this dofile creates appendix table A2
* it simply shows the number of women at each gestational duration
* and the proportion of all pregnant women at each gestational duration
* we show that there are notably fewer women at gestational durations of 1 or 2, suggesting that we do not observe the full sample since it should be evenly distributed 
* we define pregnant based on v213 self reported currently pregnant
* and we define gestational duration on months since last period (if available) and if it's not available then we use self reported gestational duration

use "$dataset", clear

keep if v213==1 // self reports pregnant
eststo clear
estpost tabulate gestdur [aw=v005]

#delimit ;
esttab using "tables/tableA2 distribution of gestational duration.tex", ///
    cells("b(fmt(%9.0fc)) pct(fmt(%6.2f))") ///
    collabels(none) noobs nonum nomtitle label ///
    booktabs alignment(lcc) replace ///
    prehead("\begin{tabular}{lcc} \toprule Month of gestation & Number of women & Percent of pregnant women \\ \midrule") ///
    postfoot("\bottomrule \end{tabular}");
