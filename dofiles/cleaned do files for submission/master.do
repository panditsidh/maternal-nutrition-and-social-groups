
// 0, 1 : create dataset for analysis 
do "dofiles/cleaned do files for submission/010_assemble data.do"
do "dofiles/cleaned do files for submission/020_create weights to estimate pp nutrition.do"




// 2 : get bootstrap results (alr have them)

* this one takes like 5 hours 
// do "dofiles/cleaned do files for submission/030_pp outcomes with bootstrapped CIs.do"


// 3 : main result graph

do "dofiles/cleaned do files for submission/031_fig_ppUW_by_socialgroup.do"



// 4 : six panel figure



* first, refresh original dataset for analysis (current storage has bootstrap results.dta)
do "dofiles/cleaned do files for submission/010_assemble data.do"
do "dofiles/cleaned do files for submission/020_create weights to estimate pp nutrition.do"

* @DIANE: I've just been re-running these two dofiles everytime I want to refresh the dataset (since they run so fast). Would it make more sense to save it in the project folder given the order of the dofiles? I was just trying to avoid copies of NFHS wherever possible, so as to preserve storage, but we can do this if it makes it simpler!


do "dofiles/cleaned do files for submission/040_distributions of pregnant women by predictors.do"


do "dofiles/cleaned do files for submission/041_pp outcomes by predictors.do"
