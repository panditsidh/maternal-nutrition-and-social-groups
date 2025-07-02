/*



varname | india | forward | dalit | adivasi | obc | muslim
----------------------------------------------------------

sample size

contraceptive user

age 
- bin categories?

education
- 2 categories?

urban 

has boy child

parity
- average # of live births?

birth spacing
- time in months?
- categories

wealth 
- categories

child died




*/



foreach i of numlist 0/5 {
	
	if `i'==0 {
		
		eststo india: reg v201 v201
		
	}
	
	foreach var in c_user agebin lessedu urban hasboy parity birth_space wealth childdied
	
	
	local grouplabel : label grouplbl `g'
	eststo grouplabel: 
	
}
