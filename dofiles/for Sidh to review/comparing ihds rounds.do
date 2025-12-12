*==========================================================
* Build 4x6 matrix of means & 95% CIs for ET/EL by religion
* Rows: Hindu IHDS1 | Muslim IHDS1 | Hindu IHDS2 | Muslim IHDS2
* Cols: ET_mean ET_ll ET_ul EL_mean EL_ll EL_ul
*==========================================================
tempname OUT
matrix `OUT' = J(6,6,.)
matrix colnames `OUT' = ET_mean ET_ll ET_ul EL_mean EL_ll EL_ul
matrix rownames `OUT' = ///
    Hindu_IHDS1 Muslim_IHDS1 Total_IHDS1 ///
    Hindu_IHDS2 Muslim_IHDS2 Total_IHDS2

*-------------------------*
* IHDS-1 (household ET/EL)
*-------------------------*
use "$ihds1_household", clear
keep if !missing(EW3) & EW3>0
keep IDHH ID14 GR13 URBAN STATEID SWEIGHT IDPSU
tempfile hh1
save `hh1'

use "$ihds1_individual", clear
merge m:1 IDHH using `hh1', keep(3) nogen

* Religion flags
gen hindu  = (ID14==1)
gen muslim = (ID14==2)

* Outcomes (GR13: 1=together, 2=women first, 3=men first, 4=varies)
recode GR13 (-7/-1=. )
drop if missing(GR13)
gen eat_together = (GR13==1)
gen eat_last     = (GR13==3)   // women eat after men

* Survey design
egen strata1 = group(STATEID URBAN)
svyset IDPSU [pw=SWEIGHT], strata(strata1) singleunit(centered)

* Row 1: Hindu IHDS1
quietly svy: mean eat_together if hindu
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last if hindu
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[1,1] = `et_mean'
matrix `OUT'[1,2] = `et_ll'
matrix `OUT'[1,3] = `et_ul'
matrix `OUT'[1,4] = `el_mean'
matrix `OUT'[1,5] = `el_ll'
matrix `OUT'[1,6] = `el_ul'

* Row 2: Muslim IHDS1
quietly svy: mean eat_together if muslim
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last if muslim
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[2,1] = `et_mean'
matrix `OUT'[2,2] = `et_ll'
matrix `OUT'[2,3] = `et_ul'
matrix `OUT'[2,4] = `el_mean'
matrix `OUT'[2,5] = `el_ll'
matrix `OUT'[2,6] = `el_ul'

* Row 3: Total IHDS1
quietly svy: mean eat_together
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[3,1] = `et_mean'
matrix `OUT'[3,2] = `et_ll'
matrix `OUT'[3,3] = `et_ul'
matrix `OUT'[3,4] = `el_mean'
matrix `OUT'[3,5] = `el_ll'
matrix `OUT'[3,6] = `el_ul'



*-------------------------*
* IHDS-2 (ewomen ET/EL)
*-------------------------*
use "$ihds2_ewomen", clear

* Outcomes (GR25 coded like GR13)
drop if missing(GR25)
gen eat_together = (GR25==1)
gen eat_last     = (GR25==3)   // women eat after men

* Religion flags
gen hindu  = (ID11==1)
gen muslim = (ID11==2)

* Survey design (your spec)
egen strata2 = group(STATEID URBAN2011)
svyset IDPSU [pw=WTEW], strata(strata2) singleunit(centered)

* Row 3: Hindu IHDS2
quietly svy: mean eat_together if hindu
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last if hindu
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[4,1] = `et_mean'
matrix `OUT'[4,2] = `et_ll'
matrix `OUT'[4,3] = `et_ul'
matrix `OUT'[4,4] = `el_mean'
matrix `OUT'[4,5] = `el_ll'
matrix `OUT'[4,6] = `el_ul'

* Row 4: Muslim IHDS2
quietly svy: mean eat_together if muslim
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last if muslim
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[5,1] = `et_mean'
matrix `OUT'[5,2] = `et_ll'
matrix `OUT'[5,3] = `et_ul'
matrix `OUT'[5,4] = `el_mean'
matrix `OUT'[5,5] = `el_ll'
matrix `OUT'[5,6] = `el_ul'


* Row 6: Total IHDS2
quietly svy: mean eat_together
matrix T = r(table)
local et_mean = T[1,1]
local et_ll   = T[5,1]
local et_ul   = T[6,1]

quietly svy: mean eat_last
matrix U = r(table)
local el_mean = U[1,1]
local el_ll   = U[5,1]
local el_ul   = U[6,1]

matrix `OUT'[6,1] = `et_mean'
matrix `OUT'[6,2] = `et_ll'
matrix `OUT'[6,3] = `et_ul'
matrix `OUT'[6,4] = `el_mean'
matrix `OUT'[6,5] = `el_ll'
matrix `OUT'[6,6] = `el_ul'


* Display nicely
matlist `OUT', format(%6.3f)



