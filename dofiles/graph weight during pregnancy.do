



svyset psu [pw=v005], strata(strata) singleunit(centered)


preserve

gen m = .
gen ll = .
gen ul = .

local outcome weight
foreach i of numlist 1/5 {
	
	foreach m of numlist 2/9 {
		
		svy: mean `outcome' if groups6==`i' & mopreg==`m'
		
		replace m = r(table)[1,1] if groups6==`i' & mopreg==`m'
		
		replace ll = r(table)[5,1] if groups6==`i' & mopreg==`m'
		
		replace ul = r(table)[6,1] if groups6==`i' & mopreg==`m'

	}
}


if "`outcome'" == "underweight" {
	local ylabel ylabel(0.1(0.05)0.3, angle(horizontal))
	local yscale yscale(range(0.1 0.3))
}
else if "`outcome'" == "bmi" {
	local ylabel ylabel(20(1)24, angle(horizontal))
	local yscale yscale(range(20 24))
}

if "`outcome'" == "weight" {
	local ylabel ylabel(45(5)60, angle(horizontal))
	local yscale yscale(range(45 63))
}


duplicates drop mopreg groups6 m ll ul, force
#delimit ;
twoway
    (scatter m mopreg if groups6==1, msymbol(circle) mcolor(red))
	(rcap ll ul mopreg if groups6==1)
	
    (scatter m mopreg if groups6==2, msymbol(diamond_hollow) mcolor(red))
	(rcap ll ul mopreg if groups6==2)
	
    (scatter m mopreg if groups6==3, msymbol(triangle_hollow) mcolor(blue))
	(rcap ll ul mopreg if groups6==3)
	
    (scatter m mopreg if groups6==4, msymbol(square_hollow) mcolor(green))
	(rcap ll ul mopreg if groups6==4)
	
	
    (scatter m mopreg if groups6==5, msymbol(circle_hollow) mcolor(yellow))
	(rcap ll ul mopreg if groups6==5),
	
	`ylabel'
	`yscale'
    legend(order(1 "Forward Caste"
                 2 "OBC"
                 3 "Dalit"
                 4 "Adivasi"
                 5 "Muslim") rows(5));

restore
