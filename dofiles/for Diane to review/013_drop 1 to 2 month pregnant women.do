

use "dataset", clear

//for the purpose of computing synthetic prepregnancy underweight, we will count women as pregnant if they have gestational duration as 3 or more months.  Those who report 1 or 2 months, or no duration, are a select sample who know about their pregnancies earlier than others.
drop if gestdur == 1 & v213==1
drop if gestdur == 2 & v213==1
drop if gestdur==. & v213==1

save "dataset", clear
