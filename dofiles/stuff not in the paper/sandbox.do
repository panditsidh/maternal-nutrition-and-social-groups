*SANDBOX!

/*

okay so we have parity of each woman
and we have hasboy as well

so we want to compare pre-pregnancy BMI of hasboy=0 & parity==2 to hasboy==1 & parity==2

also considering birth spacing? 

how long did mother breastfeed bord1 daughter vs bord1 son

*/



local labels `"  "All social groups" "Adivasi" "Dalit" "OBC" "Forward" "Muslim"   "'

foreach g in 0 1 {
	
eststo dummy`g': reg v201 v201
sum underweight [aw=reweightingfxn] if hasboy==`g' & preg==0 & parity==2
eststo dummy`g': estadd scalar underweight0= r(mean)*100

foreach i of numlist 1/5 {

	sum underweight [aw=reweightingfxn] if hasboy==`g' & group==`i' & preg==0 & parity==2
	eststo dummy`g': estadd scalar underweight`i' = r(mean)*100
	
	
}

}


#delimit ;
esttab dummy0 dummy1,
	stats(underweight0 underweight1 underweight2 underweight3 underweight4 underweight5, labels(`labels') fmt(2))
	drop(v201 _cons)
	nonumbers nostar noobs not
	mtitles("Firstborn daughter" "Firstborn son")
	title("Prepregnancy underweight at parity 2");
