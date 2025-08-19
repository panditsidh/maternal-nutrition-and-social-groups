

// use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 using $nfhs5ir, clear


use "$dataset", clear


/*


ASFRs in 5 year age groups?

in the 5 years before a women was surveyed, 
   - she contributes 2 person-years lived and 1 child born to age group 15-20 
   - and 3 person-years lived and 1 child born to age group 20-25 
      

then you can get a table that is, by age group:
   - total person years lived
   - number of births	  

at that point, get ASFR by number of births/ total person years lived
then, 5 times the sum of ASFRs gives you TFR 
   
standard errors for TFR?





*/





matrix results = J(6, 3, .)


local row = 1
foreach i of numlist 1/6 {
	

	preserve
	
	if `i'!=6 keep if group==`i'
	
	tfr2 [pweight=v005], len(5) ageg(5) bvar(b3_*) dates(v008) wbirth(v011)
	
	matrix tfr_results = r(table)
	
	
	matrix results[`row', 1] = tfr_results[1,8]
	
	matrix results[`row', 2] = tfr_results[5,8]
	
	matrix results[`row', 3] = tfr_results[6,8]
	
	restore
	
	local row = `row'+1
}


matrix colnames results = tfr tfr_ll tfr_ul

* use svmat to bring the matrix into the stata data environment and edit strings from there
input str100 rows
"Adivasi"
"Dalit"
"OBC"
"Forward"
"Muslim"
"All five social groups"
end


