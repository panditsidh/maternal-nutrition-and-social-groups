use "data/results/bootstrap_grouplevel_all.dta", clear
* iteration, estimate_level, level, bmi, underweight, weight, overweight, obesity
gen interaction "india"
gen interactionlevel = 1


use "data/results/bootstrap_decomplevel_all.dta", clear
* iteration, decompvar, decompvarlevel, grouplevel, underweight


rename decompvar estimate_level
rename decompvarlevel level
gen interaction = "group"
rename grouplevel interactionlevel


use "data/results/bootstrap_cutofflevel_all.dta", clear
* iteration, cutoff, group, underweight

gen estimate_level = "cutoff"
rename cutoff level
gen interaction = "group"
rename grouplevel interactionlevel







    #delimit ;
    postfile `grouplevel' 
        int         iteration
        str100      estimate
        int         estimate_level
		str100		interaction
		int			interaction_level
        double      bmi underweight weight overweight obesity
        using "`group_file'", replace;

    postfile `decomplevel'
        int         iteration
        str100      estimate
        int         estimate_level
		str100		interaction
        int         interaction_level
        double      underweight
        using "`decomp_file'", replace;

    postfile `cutofflevel'
        int         iteration
		str100		estimate
		
        double      cutoff
        int         group
        double      underweight
        using "`cutoff_file'", replace;
    #delimit cr
