/*
Todo 
- change this to be cutoffs


*/


do "$paths"



local overvars v190 parity_bs psu_od_besideshh_q4 protein_q4 allgroups


capture postclose handle

tempfile results

postfile handle /// 
str100 overvar /// 
str100 level /// 
double n_allgroups /// 
double pctdrop_allgroups ///
double n_adivasi ///
double pctdrop_adivasi ///
double n_dalit ///
double pctdrop_dalit ///
double n_obc ///
double pctdrop_obc ///
double n_forward ///
double pctdrop_forward ///
double n_muslim ///
double pctdrop_muslim ///
using `results', replace



foreach overvar in `overvars' {
	
	
	*----------------------------------------------------
    * Do the reweighting
    *----------------------------------------------------
	
	qui  {
		
		use "$dataset", clear
		gen allgroups = 1
		
		local binvars agebin rural less_edu noboy group `overvar'

		drop if missing(preg)

		egen bin = group(`binvars')
		gen counter=1

		preserve
		collapse ///
			(sum) bin_preg = preg ///
			(sum) bin_women = counte r, ///
			by(bin)

		gen dropbin = bin_preg == bin_women & bin_women > 0
		gen zerobin = bin_preg == 0 & bin_women > 0
		drop if bin==.

		tempfile bininfo
		save `bininfo'
		restore

		merge m:1 bin using `bininfo', nogen

		egen pregweight = sum(v005) if preg==1, by(bin)
		egen nonpregweight = sum(v005) if preg==0, by(bin)
		egen transferpreg = mean(pregweight), by(bin)
		egen transfernonpreg = mean(nonpregweight), by(bin)
		gen reweightingfxn = v005*transferpreg/transfernonpreg if dropbin!=1 & preg==0

	}
	
	
	levelsof `overvar', local(levels)
	
	foreach level in `levels' {
		
		
		*----------------------------------------------------
        * Dynamic row label
        *----------------------------------------------------
        
		if "`overvar'" == "allgroups" {
			local overlabel "Overall"
			local overlevel ""
		}
		
		else {
			* Variable label
			local overlabel : variable label `overvar'

			* If variable has no label, fall back to variable name
			if `"`overlabel'"' == "" {
				local overlabel "`overvar'"
			}

			* Value label name attached to overvar
			local vallab : value label `overvar'

			* Level label
			if "`vallab'" != "" {
				local overlevel : label `vallab' `level'
			}
			else {
				local overlevel "`level'"
			}

			* Clean up empty level labels just in case
			if `"`overlevel'"' == "" {
				local overlevel "`level'"
			}
		}
		
		
		*----------------------------------------------------
        * Get the estimates
        *----------------------------------------------------
		
		foreach g of numlist 0/5 {
			
			if `g'==0 qui count if preg==1 & `overvar'==`level'
			else qui count if preg==1 & group==`g' & `overvar'==`level'
			
			local n_group`g' = r(N)
			
			
			if `g'==0 qui sum dropbin if preg==1 & `overvar'==`level'
			else qui sum dropbin if preg==1 & group==`g' & `overvar'==`level'
			
			local pctdrop_group`g' = round(r(mean)*100, .01)
			
			
		}
		
		
		*----------------------------------------------------
        * Post them to results file
        *----------------------------------------------------
		
		
		if "`overvar'"=="pct_psu_higher_bins" {
			
			local n_group4 = .
			local n_group5 = .
			local pctdrop_group4 = .
			local pctdrop_group5 = . 
		}
		
		post handle ///
		(`"`overlabel'"') (`"`overlevel'"') ///
		(`n_group0') (`pctdrop_group0') ///
		(`n_group1') (`pctdrop_group1') ///
		(`n_group2') (`pctdrop_group2') ///
		(`n_group3') (`pctdrop_group3') ///
		(`n_group4') (`pctdrop_group4') ///
		(`n_group5') (`pctdrop_group5')
		
		
		
	}
	
}


*----------------------------------------------------
* Cutoff rows for share of higher-caste households in PSU
* Instead of bins, restrict sample to pct_psu_higher <= cutoff
*----------------------------------------------------

foreach cutoff in 1 .75 .5 .25 .1 {

    qui {

        use "$dataset", clear
        gen allgroups = 1

        keep if pct_psu_higher <= `cutoff'

        global binvars agebin rural less_edu noboy group
        do "dofiles/00 resubmission/040 reweighting.do"

    }

    * Row labels
    local overlabel "Share of higher-caste households in PSU"
    local overlevel "\(\leq `cutoff'\)"

    * Make labels prettier
    if `cutoff' == 1 {
        local overlevel "\(\leq 1.00\)"
    }
    else if `cutoff' == .75 {
        local overlevel "\(\leq 0.75\)"
    }
    else if `cutoff' == .5 {
        local overlevel "\(\leq 0.50\)"
    }
    else if `cutoff' == .25 {
        local overlevel "\(\leq 0.25\)"
    }
    else if `cutoff' == .1 {
        local overlevel "\(\leq 0.10\)"
    }

    * Get N and percent dropped by group
    foreach g of numlist 0/5 {

        if `g' == 0 {
            qui count if preg == 1
            local n_group`g' = r(N)

            qui sum dropbin if preg == 1
            local pctdrop_group`g' = round(r(mean) * 100, .01)
        }
        else {
            qui count if preg == 1 & group == `g'
            local n_group`g' = r(N)

            qui sum dropbin if preg == 1 & group == `g'
            local pctdrop_group`g' = round(r(mean) * 100, .01)
        }

    }
	
	* Do not report Forward or Muslim for cutoff rows
    local n_group4 = .
    local n_group5 = .
    local pctdrop_group4 = .
    local pctdrop_group5 = .
	
    post handle ///
        (`"`overlabel'"') (`"`overlevel'"') ///
        (`n_group0') (`pctdrop_group0') ///
        (`n_group1') (`pctdrop_group1') ///
        (`n_group2') (`pctdrop_group2') ///
        (`n_group3') (`pctdrop_group3') ///
        (`n_group4') (`pctdrop_group4') ///
        (`n_group5') (`pctdrop_group5')

}


postclose handle


use `results', clear





*------------------------------------------------------------
* Format table A4: percent dropped under reweighting specs
* Run this after loading the postfile output
*------------------------------------------------------------

* Preserve original order from postfile
gen orig_order = _n
bys overvar (orig_order): gen over_first = orig_order[1]

* Within-overvar row order
bys overvar (orig_order): gen level_order = _n

*------------------------------------------------------------
* Create display variables
*------------------------------------------------------------

foreach g in allgroups adivasi dalit obc forward muslim {
    
    gen disp_n_`g' = ""
    replace disp_n_`g' = strtrim(string(n_`g', "%15.0fc")) if !missing(n_`g')
    
    gen disp_pctdrop_`g' = ""
    replace disp_pctdrop_`g' = strtrim(string(pctdrop_`g', "%9.2f")) if !missing(pctdrop_`g')
}

* Rename / copy to group-numbered names for listtex
gen disp_n_group1       = disp_n_adivasi
gen disp_pctdrop_group1 = disp_pctdrop_adivasi

gen disp_n_group2       = disp_n_dalit
gen disp_pctdrop_group2 = disp_pctdrop_dalit

gen disp_n_group3       = disp_n_obc
gen disp_pctdrop_group3 = disp_pctdrop_obc

gen disp_n_group4       = disp_n_forward
gen disp_pctdrop_group4 = disp_pctdrop_forward

gen disp_n_group5       = disp_n_muslim
gen disp_pctdrop_group5 = disp_pctdrop_muslim


*------------------------------------------------------------
* Create body rows
*------------------------------------------------------------

gen row = ""

replace row = "\hspace*{2em}" + level if overvar != "Overall"

* Clean up specific labels for LaTeX/readability
replace row = subinstr(row, "below 2y spacing", "\textless{}2y spacing", .)
replace row = subinstr(row, "&", "\&", .)

* Overall row: bold label, keep stats in same row
replace row = "\textbf{Overall}" if overvar == "Overall"

gen rowtype = 2

tempfile body
save `body', replace


*------------------------------------------------------------
* Create header rows: one before each overvar except Overall
*------------------------------------------------------------

preserve

    keep if overvar != "Overall"
    keep overvar over_first
    duplicates drop

    gen row = ""

    replace row = "\textbf{Wealth quartile}" ///
        if overvar == "Wealth quartile"

    replace row = "\textbf{Parity and time since last live birth categories}" ///
        if overvar == "Parity & time since last birth (10 category)"

    replace row = "\textbf{PSU open defecation exposure quartile}" ///
        if overvar == "PSU open defecation exposure quartile"

    replace row = "\textbf{Protein-rich food consumption intensity/diversity}" ///
        if overvar == "Protein-rich food consumption intensity/diversity"

    replace row = "\textbf{Share of higher-caste households in PSU}" ///
        if overvar == "Share of higher-caste households in PSU"

    * Fallback, in case some overvar name was not manually specified
    replace row = "\textbf{" + overvar + "}" if row == ""

    gen rowtype = 1
    gen level_order = 0

    foreach var in ///
        disp_n_allgroups disp_pctdrop_allgroups ///
        disp_n_group1 disp_pctdrop_group1 ///
        disp_n_group2 disp_pctdrop_group2 ///
        disp_n_group3 disp_pctdrop_group3 ///
        disp_n_group4 disp_pctdrop_group4 ///
        disp_n_group5 disp_pctdrop_group5 {
        
        gen `var' = ""
    }

    tempfile headers
    save `headers', replace

restore


*------------------------------------------------------------
* Create blank rows: one after each overvar except Overall
*------------------------------------------------------------

preserve

    keep if overvar != "Overall"
    keep overvar over_first
    duplicates drop

    gen row = ""
    gen rowtype = 3
    gen level_order = 999

    foreach var in ///
        disp_n_allgroups disp_pctdrop_allgroups ///
        disp_n_group1 disp_pctdrop_group1 ///
        disp_n_group2 disp_pctdrop_group2 ///
        disp_n_group3 disp_pctdrop_group3 ///
        disp_n_group4 disp_pctdrop_group4 ///
        disp_n_group5 disp_pctdrop_group5 {
        
        gen `var' = ""
    }

    tempfile blanks
    save `blanks', replace

restore


*------------------------------------------------------------
* Stack header rows, body rows, and blank rows
*------------------------------------------------------------

use `body', clear
append using `headers'
append using `blanks'

* Put Overall at the end
replace over_first = 999999 if overvar == "Overall"

sort over_first rowtype level_order orig_order

* listtex variable is called rows in your existing code
capture drop rows
gen rows = row

* Keep only variables needed for LaTeX export
keep rows ///
    disp_n_allgroups disp_pctdrop_allgroups ///
    disp_n_group1    disp_pctdrop_group1 ///
    disp_n_group2    disp_pctdrop_group2 ///
    disp_n_group3    disp_pctdrop_group3 ///
    disp_n_group4    disp_pctdrop_group4 ///
    disp_n_group5    disp_pctdrop_group5
	
do "$paths"
	

	
#delimit ;
listtex rows ///
    disp_n_allgroups disp_pctdrop_allgroups ///
    disp_n_group1    disp_pctdrop_group1 ///
    disp_n_group2    disp_pctdrop_group2 ///
    disp_n_group3    disp_pctdrop_group3 ///
    disp_n_group4    disp_pctdrop_group4 ///
    disp_n_group5    disp_pctdrop_group5 ///
    using "tables/tableA4 percent dropped NEW.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{12}{>{\centering\arraybackslash}p{1.2cm}}}" ///
         "\toprule" ///
         "& \multicolumn{2}{c}{\shortstack{All five \\\\ social groups}} & \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Forward} & \multicolumn{2}{c}{Muslim} \\\\" ///
         "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9} \cmidrule(lr){10-11} \cmidrule(lr){12-13}" ///
         "Predictor Group & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped & N & \% dropped \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr




