
* CHANGE TO IHDS FILEPATH
use "/Users/sidhpandit/Desktop/IHDS/IHDS-2/DS0003/36151-0003-Data.dta", clear


replace GROUPS=2 if GROUPS==1

drop if GROUPS==7

gen eat_last = GR25==3


collapse (mean) mean_eatlast=eat_last (sd) sd_eatlast=eat_last (count) n=eat_last [aw=WT], by(GROUP)


generate hi = mean_eatlast + invttail(n-1,0.025)*(sd_eatlast / sqrt(n))
generate low = mean_eatlast - invttail(n-1,0.025)*(sd_eatlast / sqrt(n))

* Example assumes you already have mean_eatlast, hi, low by GROUP
#delimit ;
twoway
    (bar mean_eatlast GROUP, barw(0.6) fcolor(gs12) lcolor(black))
    (rcap hi low GROUP, lcolor(black))
    (scatter mean_eatlast GROUP, msymbol(none) mlabel(mean_eatlast) mlabformat(%4.2f) mlabpos(4) mlabsize(small) mlabcolor(black)),
    ///
    xlabel( 2 "Fwd caste" 3 "OBC" 4 "Dalit" 5 "Adivasi" 6 "Muslim")
	xtitle("Social group")
    ytitle("Women eating last (proportion)")
    title("Proportion of women eating last by social group")
    legend(off)
    graphregion(color(white));


graph export "figures/appendix ihds.png", as(png) name("Graph") replace;
