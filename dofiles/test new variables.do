
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
* s726a = milk/curd
* s726b = pulses/beans
* s726e = eggs
* s726f = fish
* s726g = chicken/meat
*------------------------------------------------------------

* recode to ordered scale (higher = more frequent)
foreach v in s726a s726b s726e s726f s726g {
    
    gen freq_`v' = .
    replace freq_`v' = 0 if `v' == 0   // never
    replace freq_`v' = 1 if `v' == 3   // occasionally
    replace freq_`v' = 2 if `v' == 2   // weekly
    replace freq_`v' = 3 if `v' == 1   // daily

}

* highest frequency across protein-rich foods
egen protein_freq = rowmax(freq_s726a freq_s726b freq_s726e freq_s726f freq_s726g)

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


do "dofiles/050_weights to estimate pp nutrition.do"
