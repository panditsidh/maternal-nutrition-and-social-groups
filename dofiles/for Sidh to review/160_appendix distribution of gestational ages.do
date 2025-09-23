


use "$dataset", clear

	
estpost tabulate v214 [aw=v005]





#delimit ;
esttab using "tables/apdxtabl_gestdur.tex", 
    cells("b(fmt(%9.0fc)) pct(fmt(%6.2f))") 
    collabels(none) noobs nonum nomtitle label 
    booktabs alignment(lrr) replace 
    prehead("\begin{tabular}{lrr} \toprule Month of gestation & Number of women & Percent of pregnant women \\ \midrule")
    postfoot("\bottomrule \end{tabular}");
