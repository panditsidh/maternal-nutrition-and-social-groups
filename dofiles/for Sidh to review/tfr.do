

// use caseid s930b s932 s929 v743a* v044 d105a-d105j d129 s909 s910 s920 s116 v* s236 s220b* ssmod sb* sb18d sb25d sb29d sb18s sb25s sb29s v404 bord* v190 v191 b3* s731a-s731i v731 using $nfhs5ir, clear


use "$dataset", clear

// tabexp [pweight=v005], length(5) ageg(5) bvar(b3_*) dates(v008) wbirth(v011)

tfr2 [pweight=v005], len(5) ageg(5) bvar(b3_*) dates(v008) wbirth(v011)

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
