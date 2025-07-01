* stuff from Diane's original 

*STATUS OF YOUNGEST CHILD.
*no children
*less than 2 and BF
*less than 2 and not BF
*2-5
*5+
*last child died

// preserve
// clear all
// // use "C:\Users\diane\Documents\Data\NFHS\NFHS06\all india birth recode\IABR52FL.dta"
// use $nfhs3br
// sort caseid
// by caseid: egen maxbord=max(bord)
// gen youngest = bord==maxbord
// by caseid: egen noalive=total(b5)
// tab noalive
// *b5 if alive
// *b7 if age in months at death
// *b8 is current age of child
// *m4 is duration of breastfeeding--includes still breastfeeding
// *b0 is twin
// keep if youngest == 1
// keep caseid v213 youngest noalive bord b0 b3 b5 b7 b8 m4
// // save "C:\Users\diane\Documents\2012to2013\pregnancy\stata data\india\nfhs3_youngest.dta", replace
//
// tempfile nfhs3_youngest
// save `nfhs3_youngest'
// restore
// // merge 1:1 caseid using "C:\Users\diane\Documents\2012to2013\pregnancy\stata data\india\nfhs3_youngest.dta" 
// merge 1:1 caseid using `nfhs3_youngest'
//
// drop if _merge == 2

// *STATUS OF YOUNGEST LIVING CHILD-for pregnant women
// **For pregnant women, you need the status of the child when she got pregnant.  
// gen youngest_status=.
// *0 no children
// replace youngest_status = 0 if v213==1 & v218==0 
// *1 less than two and BF
// gen agetoday=v008-b3
// gen ageatpreg=.
// replace ageatpreg=agetoday-mopreg if mopreg>3 & v213==1 
// gen bfatpreg=.
// replace bfatpreg=1 if youngest==1 & m4==95 & v213==1
// replace bfatpreg=1 if m4>=ageatpreg & m4<61 & v213==1
// replace youngest_status = 1 if v213==1 & youngest==1 & ageatpreg<24 & bfatpreg==1 & v218!=0
//
// *2 less than two and not BF 
// replace youngest_status = 2 if v213==1 & youngest==1 & ageatpreg<24 & bfatpreg==. & v218!=0
//
// *3 two to five
// replace youngest_status = 3 if v213==1 & youngest==1 & ageatpreg>=24 & v218!=0
//
// /*
// *4 five plus 
// replace youngest_status = 4 if v213==1 & youngest==1 & ageatpreg>=60 & v218!=0
// */
//
// **For non-pregnant women, you need the status of the child now.  
// *0 no children
// replace youngest_status = 0 if v213==0 & v218==0 
//
// *1 less than two and BF
// gen bfnow=.
// replace bfnow=1 if youngest==1 & m4==95 & v213==0
// replace youngest_status = 1 if v213==0 & youngest==1 & agetoday<24 & bfnow==1 & v218!=0
//
// *2 less than two and not BF 
// replace youngest_status = 2 if v213==0 & youngest==1 & agetoday<24 & bfnow==. & v218!=0
//
// *3 two plus
// replace youngest_status = 3 if v213==0 & youngest==1 & agetoday>=24 & v218!=0
//
// /*
// *4 five plus 
// replace youngest_status = 4 if v213==0 & youngest==1 & agetoday>=60 & v218!=0
// */
 
*CHILD DEATH
preserve
clear all

use $nfhs5br
sort caseid
gen timeagodied = v008-b3
gen diedpastfiveyr= timeagodied<60 & b5==0
by caseid: egen diedpast5yr= max(diedpastfiveyr)
collapse diedpast5yr, by(caseid)
tab diedpast5yr, m

tempfile nfhs5_dead
save `nfhs5_dead'
restore
merge 1:1 caseid using `nfhs5_dead'
drop if _merge == 2
*0 no child died in past 5 years (including those who never had a child)
*1 child died in last 5 years
gen childdied = diedpast5yr==1

*NUMBER OF LIVING CHILDREN.
gen noliving = v218
replace noliving = 4 if v218>3
replace noliving = . if v218==.
