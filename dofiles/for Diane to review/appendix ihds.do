
* CHANGE IHDS FILEPATH
use "/Users/sidhpandit/Desktop/IHDS/IHDS-2/DS0003/36151-0003-Data.dta", clear

replace GROUPS=2 if GROUPS==1

gen eat_last = GR25==3

graph bar (mean) eat_last [aw=WTEW], over(GROUPS, relabel(1 "Fwd caste" 2 "OBC" 3 "Dalit" 4 "Adivasi" 5 "Muslim" 6 "CSJ")) ///
    blabel(bar, format(%4.2f)) ///
    ytitle("Percent women eating last") ///
    title("Women eating last by caste & religion group") ///
    ylabel(0(.1)1)

	
graph export "figures/appendix ihds.png", as(png) name("Graph")
