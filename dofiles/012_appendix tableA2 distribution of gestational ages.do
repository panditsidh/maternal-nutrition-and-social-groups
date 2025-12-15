* this dofile creates appendix table A2
* it simply shows the number of women at each self reported gestational duration
* and the proportion of all self reported pregnant women at each self reported gestational duration
* we show that there are notably fewer women at self reported gestational durations of 1 or 2, suggesting that we do not observe the full sample since it should be evenly distributed 

use "$dataset", clear

eststo clear
estpost tabulate v214 [aw=v005]

#delimit ;
esttab using "tables/tableA2 distribution of gestational duration.tex", 
    cells("b(fmt(%9.0fc)) pct(fmt(%6.2f))") 
    collabels(none) noobs nonum nomtitle label 
    booktabs alignment(lrr) replace 
    prehead("\begin{tabular}{lrr} \toprule Month of gestation & Number of women & Percent of pregnant women \\ \midrule")
    postfoot("\bottomrule \end{tabular}");
