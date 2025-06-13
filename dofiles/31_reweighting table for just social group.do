if "`c(username)'" == "sidhpandit" {
	
	global out_tex "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/tables/rw_"
	
	
	global rw_01 "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/01_reweight within social group.do"
	
	global assemble "/Users/sidhpandit/Documents/GitHub/maternal-nutrition-and-social-groups/dofiles/assemble data/00_assemble prepreg sample.do"
	
	
	
}

if "`c(username)'" == "dc42724" {

	
	global rw_01 "C:\Users\dc42724\Documents\GitHub\maternal-nutrition-and-social-groups\dofiles\assemble data\01_reweight within social group.do"
	
}


do "${assemble}"
do "${rw_01}"

* Set up survey design
svyset psu [pw=reweightingfxn], strata(strata) singleunit(centered)

* Initialize an empty matrix to store results
matrix results = J(5, 4, .)

* Define group labels
local groups "Forward OBC Dalit Adivasi"
local row = 1

* Loop over the 4 social groups (groups6 codes 1 to 4)
foreach g of numlist 1/5 {
    
    * Run svy mean for underweight in each group (preg == 0)
    svy, subpop(if groups6 == `g' & preg == 0): mean underweight

    * Pull the mean, ll, ul from r(table)
    matrix rtab = r(table)
    local mean = rtab[1,1]*100
    local ll   = rtab[5,1]*100
    local ul   = rtab[6,1]*100
	
	
	
    
    * Store in matrix
    matrix results[`row', 1] = `mean'
    matrix results[`row', 2] = `ll'
    matrix results[`row', 3] = `ul'
	
	sum pct_drop if groups6==1
	matrix results[`row', 4] = r(mean)*100

    local ++row
}


* Assign row and column names
matrix rownames results = Forward OBC Dalit Adivasi
matrix colnames results = Mean LL UL percent_drop

* Display the final table
matlist results, format(%6.2f) rowtitle(Group)

svmat results, names(col)

gen str30 rowname = ""

replace rowname = "Forward" in 1
replace rowname = "OBC" in 2
replace rowname = "Dalit" in 3
replace rowname = "Adivasi" in 4
replace rowname = "Muslim" in 5


gen pct_drop = round(percent_drop, 0.01)


gen ci = string(Mean, "%4.1f") + " (" + string(LL, "%4.1f") + ", " + string(UL, "%4.1f") + ")" if !missing(Mean)

keep rowname ci pct_drop

drop if missing(rowname)


