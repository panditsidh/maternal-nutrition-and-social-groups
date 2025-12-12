/*

ISSUE: not sure how to get only eligible women
read documentation about that
cuz my sample size is like 33k 
desai had like 28k 

and my means and pred probs and stuff are different

*/

use "$ihds1_household", clear


keep if !missing(EW3) & EW3>0
keep IDHH ID14 GR13 FM3 INCOME METRO6 ID9 URBAN

tempfile hh_merge 
save `hh_merge'


use "$ihds1_individual", clear

merge m:1 IDHH using `hh_merge'
keep if _merge==3

keep if inlist(ID14, 1,2) // only hindu and muslims

gen muslim = ID14==2
gen hindu = ID14==1

gen cultivates = FM3==1
gen log_income = log(INCOME)
gen income_negative = INCOME<=0
gen metro = METRO6!=.

gen type_residence = URBAN
replace type_residence = 2 if metro

gen ever_married = inlist(RO6,1,3,4)
* only ever married women ages 15-49 
keep if ever_married & RO3==2 & inrange(RO5, 15,49)

* only valid responses to family meal time
drop if GR13<=0
gen eat_together = GR13==1 if GR13>0
gen eat_last = GR13==2 if GR13>0

* get a "spouses" dataset
preserve

use "$ihds1_individual", clear
rename PERSONID SPOUSEID
rename ED5 ed_husband
rename WKSALARY salary_husband

keep IDHH SPOUSEID ed_husband salary_husband

tempfile spouses_merge
save `spouses_merge'



restore

rename RO7 SPOUSEID
capture drop _merge
merge m:1 IDHH SPOUSEID using `spouses_merge'

keep if _merge==3

gen husb_salaried = (salary_husband >= 240 & salary_husband < .)


logit eat_together i.muslim   ///
      c.ed_husband c.husb_salaried ///
      c.NPERSONS c.NMARRIEDF i.type_residence ///
      cultivates c.log_income income_neg ///
      c.RO5 c.NCHILDREN c.ED5 i.STATEID2 [pw=SWEIGHT], vce(robust)

*------------------------------
* 5. Predicted probabilities
*------------------------------
margins muslim, atmeans



/*

Desai's paper does logit with outcome eats together on 
- muslim indicator (muslim)
- no husband in household
- not married (not_married)
- husband's education 
- husband in salaried job
- no. people in household (NPERSONS)
- no. married women in household (NMARRIEDF)
- place of residence category indicators (urban, more developed village, less developed village)
- household cultivates land (FM3)
- log total income (INCOME)
- income less than 0 (INCOME)
- age of the woman (RO5)
- no. children living with respondent (NCHILDREN)
- years of education of the woman (ED5)
- state fixed effects (STATEID)

then she uses this to get predicted probability of eats together by hindu or muslim

*/
