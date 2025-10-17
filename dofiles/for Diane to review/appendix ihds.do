
* @Diane, please add your ihds2 filepath to the 000_paths for this to work
use $ihds2, clear

* combine Brahmins into Forward
replace GROUPS=2 if GROUPS==1

* no Christian, Jain, Sikh in our analysis
drop if GROUPS==7

* eat last variable
drop if missing(GR25)
gen eat_last = GR25==3

* age variable
keep if inrange(EW6, 15,49)

collapse (mean) mean_eatlast=eat_last (sd) sd_eatlast=eat_last (count) n=eat_last [aw=WT], by(GROUP)

* construct confidence intervals
generate hi = mean_eatlast + invttail(n-1,0.025)*(sd_eatlast / sqrt(n))
generate low = mean_eatlast - invttail(n-1,0.025)*(sd_eatlast / sqrt(n))

#delimit ;
twoway
    (bar mean_eatlast GROUP, barw(0.6) fcolor(gs12) lcolor(black))
    (rcap hi low GROUP, lcolor(black))
    (scatter mean_eatlast GROUP, msymbol(none) mlabel(mean_eatlast) mlabformat(%4.2f) mlabpos(4) mlabsize(small) mlabcolor(black)),
    ///
    xlabel( 2 "Forward caste" 3 "OBC" 4 "Dalit" 5 "Adivasi" 6 "Muslim")
	xtitle("Social group")
    ytitle("Women eating last (proportion)")
    legend(off)
    graphregion(color(white));

graph export "figures/appendix ihds.png", as(png) name("Graph") replace;

