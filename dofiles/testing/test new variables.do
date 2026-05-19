
do "$paths"

use "$dataset", clear


*------------------------------------------------------------
* Protein-rich food consumption frequency
*
* Original coding:
* 0 = Never
* 1 = Daily
* 2 = Weekly
* 3 = Occasionally
*
* Foods:
* s731a = milk/curd
* s731b = pulses/beans
* s731e = eggs
* s731f = fish
* s731g = chicken/meat
*------------------------------------------------------------

* recode to ordered scale (higher = more frequent)
foreach v in s731a s731b s731e s731f s731g {
    
    gen freq_`v' = .
    replace freq_`v' = 0 if `v' == 0   // never
    replace freq_`v' = 1 if `v' == 3   // occasionally
    replace freq_`v' = 2 if `v' == 2   // weekly
    replace freq_`v' = 3 if `v' == 1   // daily

}

* highest frequency across protein-rich foods
egen protein_freq = rowmax(freq_s731a freq_s731b freq_s731e freq_s731f freq_s731g)

* collapse categories: never + occasional together
gen protein_cat = .

replace protein_cat = 0 if inlist(protein_freq, 0, 1)
replace protein_cat = 1 if protein_freq == 2
replace protein_cat = 2 if protein_freq == 3

label define protein_cat_lab ///
    0 "Low: never or occasional" ///
    1 "Moderate: weekly" ///
    2 "High: daily", replace

label values protein_cat protein_cat_lab
label variable protein_cat "Protein-rich food consumption category"



*------------------------------------------------------------
* Protein-rich food diversity: number consumed at least weekly
*------------------------------------------------------------

foreach v in s731a s731b s731e s731f s731g {
    
    gen weekly_`v' = .
    replace weekly_`v' = 0 if inlist(`v', 0, 3)   // never or occasionally
    replace weekly_`v' = 1 if inlist(`v', 1, 2)   // daily or weekly
}

egen protein_weekly_count = rowtotal(weekly_s731a weekly_s731b weekly_s731e weekly_s731f weekly_s731g)
egen protein_weekly_nonmiss = rownonmiss(weekly_s731a weekly_s731b weekly_s731e weekly_s731f weekly_s731g)

replace protein_weekly_count = . if protein_weekly_nonmiss == 0

label variable protein_weekly_count "Number of protein-rich foods consumed at least weekly"

gen protein_div_cat = .

replace protein_div_cat = 0 if protein_weekly_count <= 1
replace protein_div_cat = 1 if protein_weekly_count == 2
replace protein_div_cat = 2 if protein_weekly_count >= 3 & protein_weekly_count < .

label define protein_div_cat_lab ///
    0 "0-1 protein foods weekly" ///
    1 "2 protein foods weekly" ///
    2 "3+ protein foods weekly", replace

label values protein_div_cat protein_div_cat_lab
label variable protein_div_cat "Protein-rich food diversity category"

bys group: tab protein_div_cat [aw=v005], missing
bys group: tab protein_div_cat if preg==1 [aw=v005], missing
bys group: tab protein_div_cat if preg==0 [aw=v005], missing



* open defecation indicator
gen open_defec = .

replace open_defec = 1 if inlist(v116, 30, 31)
replace open_defec = 0 if !inlist(v116, 30, 31) & v116 < .

label define od_lab 0 "Has toilet" 1 "Open defecation"
label values open_defec od_lab
label variable open_defec "Household practices open defecation"

* PSU-level share
bys psu: egen psu_od_share = mean(open_defec)

label variable psu_od_share "Share of PSU practicing open defecation"

gen psu_od_cat = .

replace psu_od_cat = 1 if psu_od_share < 0.10
replace psu_od_cat = 2 if inrange(psu_od_share, 0.10, 0.30)
replace psu_od_cat = 3 if inrange(psu_od_share, 0.30, 0.60)
replace psu_od_cat = 4 if psu_od_share > 0.60

label define psu_od_cat_lab ///
    1 "Low OD (<10%)" ///
    2 "Moderate OD (10–30%)" ///
    3 "High OD (30–60%)" ///
    4 "Very high OD (>60%)"

label values psu_od_cat psu_od_cat_lab
label variable psu_od_cat "PSU open defecation category"



*------------------------------------------------------------
* PSU open defecation quartiles
*------------------------------------------------------------

xtile psu_od_q4 = psu_od_share [aw=v005], nq(4)

label define psu_od_q4_lbl ///
    1 "Lowest PSU open defecation quartile" ///
    2 "Second PSU open defecation quartile" ///
    3 "Third PSU open defecation quartile" ///
    4 "Highest PSU open defecation quartile", replace

label values psu_od_q4 psu_od_q4_lbl
label variable psu_od_q4 "PSU open defecation quartile"

tab psu_od_q4, missing
bys group: tab psu_od_q4 [aw=v005], missing
bys group: tab psu_od_q4 if preg==1 [aw=v005], missing
bys group: tab psu_od_q4 if preg==0 [aw=v005], missing
