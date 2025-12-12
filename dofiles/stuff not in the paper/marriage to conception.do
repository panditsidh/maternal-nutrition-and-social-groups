 


keep if bord_01==1

keep if v238==1


drop if v221==996

gen marriagetoconception = v221-9
sum marriagetoconception [aw=v005]


