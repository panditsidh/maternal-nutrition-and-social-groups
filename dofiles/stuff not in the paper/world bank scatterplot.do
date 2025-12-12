
* 1960 starts at v5 - not able to import csv perfectly so we hard code this

local year = 2019
local sub = `year'-1960+5

* world bank nnm data
import delimited "data/API_SH.DYN.NMRT_DS2_en_csv_v2_1034803.csv", varnames(4) numericcols(5 6 7 8 9 10) clear 

rename v1 country_name
rename v2 country_code
rename v`sub' nnm

keep country_name country_code nnm


tempfile nnm 
save `nnm'


import delimited "data/API_NY.GDP.PCAP.CD_DS2_en_csv_v2_1076250.csv", clear

rename v1 country_name
rename v2 country_code
rename v`sub' gdppc

keep country_name country_code gdppc

// drop if missing(gdppc_2023)


tempfile gdp_pc
save `gdp_pc'


* un total births data
import delimited "data/unpopulation_dataportal_20250929180007.csv", varnames(1) clear


rename iso3 country_code
rename location country_name
rename time year
keep if year==`year'


rename value total_births

keep country_name country_code total_births

drop if inlist(country_code, "SID", "LLD", "ANZ", "LMC")

tempfile births 
save `births'




* world bank population data
import delimited "data/API_SP.POP.TOTL_DS2_en_csv_v2_1075736.csv", varnames(4)clear

rename v1 country_name
rename v2 country_code
rename v`sub' pop


keep country_name country_code pop


* merge
merge 1:1 country_code using `nnm', gen(m1)
merge 1:1 country_code using `gdp_pc', gen(m2)

drop if m1!=3 | m2!=3

drop m1 m2


* get rid of non countries 
#delimit ;
drop if inlist(country_name,
"Africa Eastern and Southern", "Africa Western and Central", "Arab World",
"Caribbean small states", "Central Europe and the Baltics",
"East Asia & Pacific (excluding high income)", "East Asia & Pacific",
"Europe & Central Asia (excluding high income)", "Europe & Central Asia")
| inlist(country_name,
"Euro area", "European Union", "Fragile and conflict affected situations",
"Heavily indebted poor countries (HIPC)", "High income", "IBRD only",
"IDA & IBRD total", "IDA total", "IDA blend")
| inlist(country_name,
"IDA only", "Latin America & Caribbean (excluding high income)",
"Latin America & Caribbean", "Least developed countries: UN classification",
"Low income", "Lower middle income", "Low & middle income",
"Late-demographic dividend", "Middle East, North Africa, Afghanistan & Pakistan")
| inlist(country_name,
"Middle East, North Africa, Afghanistan & Pakistan (excluding high income)",
"Middle income", "North America", "OECD members", "Other small states",
"Pacific island small states", "Post-demographic dividend",
"Pre-demographic dividend", "South Asia")
| inlist(country_name,
"Sub-Saharan Africa (excluding high income)", "Sub-Saharan Africa", "Small states",
"East Asia & Pacific (IDA & IBRD countries)",
"Europe & Central Asia (IDA & IBRD countries)",
"Latin America & the Caribbean (IDA & IBRD countries)",
"Middle East, North Africa, Afghanistan & Pakistan (IDA & IBRD)",
"South Asia (IDA & IBRD)", "Sub-Saharan Africa (IDA & IBRD countries)")
| inlist(country_name,
"Upper middle income", "World", "Not classified", "Country Name", "Early-demographic dividend");

drop if inlist(country_name, "Andorra", "Antigua and Barbuda", "Aruba", "Bahamas, The", "Barbados", "Belize", "Bermuda", "Bhutan", "Brunei Darussalam");

drop if inlist(country_name, "Cabo Verde", "Comoros", "Curacao", "Dominica", "Faroe Islands", "Fiji", "Grenada", "Guam", "Iceland");

drop if inlist(country_name, "Isle of Man", "Liechtenstein", "Luxembourg", "Maldives", "Malta", "Marshall Islands", "Micronesia, Fed. Sts.", "Monaco", "Nauru");

drop if inlist(country_name, "Palau", "San Marino", "Seychelles", "Solomon Islands", "St. Kitts and Nevis", "St. Lucia", "St. Martin (French part)", "St. Vincent and the Grenadines", "Samoa");

drop if inlist(country_name, "Suriname", "Tonga", "Trinidad and Tobago", "Tuvalu", "Vanuatu");
#delimit cr


merge 1:1 country_code using `births'
keep if _merge==3
drop _merge


gen log_gdppc = log(gdppc)
qui reg nnm log_gdppc
predict predicted_nnm


qui sum log_gdppc

local xmin = r(min)
local xmax = r(max)


if `year'==2019 replace nnm = 24.9 if country_name == "India" 


* get some formatting stuff for our focus countries - you can change the names if you want
foreach country in India Nigeria Pakistan {
	
	qui sum log_gdppc if country_name=="`country'"
	local x_`country' = r(mean)+0.2
	
	qui sum nnm if country_name=="`country'"
	local y_`country' = r(mean)
	local y_`country'_str: display %9.2f `y_`country''
	local y_`country'_str = subinstr("`y_`country'_str'"," ","",.)
	
	local excess_`country'_label = r(mean)-2.5 
	
	qui sum predicted_nnm if country_name=="`country'"
	local yhat_`country' = r(mean)
	local yhat_`country'_str: display %9.2f `yhat_`country''
	local yhat_`country'_str = subinstr("`yhat_`country'_str'"," ","",.)

	
	local excess_`country' = `y_`country''-`yhat_`country''
	local excess_`country'_str: display %9.2f `excess_`country''
	local excess_`country'_str = subinstr("`excess_`country'_str'"," ","",.)

	
	qui sum total_births if country_name=="`country'"
	local total_births = r(mean)
	
	local totalexcess_`country' = `excess_`country''/1000*`total_births'
	local totalexcess_`country'_str: display %15.0fc `totalexcess_`country''
	local totalexcess_`country'_str = subinstr("`totalexcess_`country'_str'"," ","",.)

}


#delimit ;
twoway (scatter nnm log_gdppc [fw=pop], msymbol(Oh) mcolor(black)) 
	   (lfit nnm log_gdppc, lcolor(black) range(`xmin' `xmax')), legend(off) graphregion(color(white))
	   xtitle("log of GDP per capita in current US dollars")
	   ytitle("neonatal mortality, per 1000 live births")  
	   text(`y_India' `x_India' " -------------- India's NNM: `y_India_str'", size(small) placement(east))
	   text(`y_Nigeria' `x_Nigeria' "Nigeria's NNM: `y_Nigeria_str'", size(small) placement(east))
	   text(`y_Pakistan' `x_Pakistan' "Pakistan's NNM: `y_Pakistan_str'", size(small) placement(east))
	   text(`excess_India_label' `x_India' "			 Excess `excess_India_str' neonatal deaths per thousand (`totalexcess_India_str' total)", size(vsmall) placement(east)) 
	   text(`excess_Nigeria_label' `x_Nigeria' "Excess `excess_Nigeria_str' neonatal deaths per thousand (`totalexcess_Nigeria_str' total)", size(vsmall) placement(east)) 
	   text(`excess_Pakistan_label' `x_Pakistan' "Excess `excess_Pakistan_str' neonatal deaths per thousand (`totalexcess_Pakistan_str' total)", size(vsmall) placement(east))
	   ylabel(0(10)60)
	   title(Health and wealth in `year');
	   
	   
graph export "figures/health and wealth `year'.png", as(png) name("Graph") replace;	
	   
	   

#delimit cr
* OLD CODE


//
// qui sum log_gdppc_2019 if country_name=="India" 
// local x_india = r(mean)+0.2
// local x_indiahat = r(mean)+0.2
//
// qui sum log_gdppc_2019 if country_name=="Nigeria"
// local x_nigeria = r(mean)+0.4
//
// qui sum nnm_2019 if country_name=="Nigeria"
// local y_nigeria = r(mean)
// local nigeria_excess_label = r(mean)-2.5
//
// qui sum log_gdppc_2019 if country_name=="Pakistan"
// local x_pakistan = r(mean)+0.45
//
// qui sum nnm_2019 if country_name=="Pakistan"
// local y_pakistan = r(mean)
// local pakistan_excess_label = r(mean)-2.5
//
// qui sum predicted_nnm if country_name=="India"
// local india_yhat = r(mean)
// local india_excess_label = r(mean)-2.5
//
// qui sum predicted_nnm if country_name=="Nigeria"
// local nigeria_yhat = r(mean)
// local nigeria_excess = `y_nigeria' - `nigeria_yhat'
//
//
// qui sum predicted_nnm if country_name=="Pakistan"
// local pakistan_yhat = r(mean)
// local pakistan_excess = `y_pakistan' - `pakistan_yhat'
//
//
//
// /*
//
// * UN says that in 2019 India had 24124983 births 
//                        Pakistan had 6689991 births 
// 					   Nigeria had 7266105 births
//		  
// Step 1. Excess NNM rate
// 24.9 − 19.4 = 5.5 per 1,000 births = 0.0055
//
// Step 2. Apply to births
// Excess neonatal deaths = 24,124,983 × 0.0055 ≈ 132,687
//
//
// * UN says 
// */
// #delimit ;
// twoway (scatter nnm_2019 log_gdppc_2019 [fw=pop_2019],
// 			msymbol(Oh) mcolor(black)) 
// 	   (lfit nnm_2019 log_gdppc_2019, 
// 			lcolor(black) range(`xmin' `xmax')), 
// 			legend(off) graphregion(color(white))
// 	   xtitle("log of GDP per capita in current US dollars")
// 	   ytitle("neonatal mortality, per 1000 live births")
// 	   text(25 `x_india' "------------------------ India's NNM: 24.9", size(small) placement(east))
// 	   text(`y_nigeria' `x_nigeria' "Nigeria's NNM: `=string(`y_nigeria',"%9.2f")'", size(small) placement(east))
// 	   text(`nigeria_excess_label' 8.2 "Excess `=string(`nigeria_excess',"%9.2f")' neonatal deaths per thousand (123,600 total)", size(vsmall) placement(east)) 
//        text(`y_pakistan' `x_pakistan' "Pakistan's NNM: `=string(`y_pakistan',"%9.2f")'", size(small) placement(east))
// 	   text(`pakistan_excess_label' 7.8 "Excess `=string(`pakistan_excess',"%9.2f")' neonatal deaths per thousand (130,800 total)", size(vsmall) placement(east)) 
// 	   text(`india_yhat' `x_indiahat' "------------------------ India's predicted NNM: 19.4", size(small) placement(east))
// 	   text(`india_excess_label' 9.2 "Excess 5.5 neonatal deaths per thousand (132,687 total)", size(vsmall) placement(east));
//
//	   
// graph export "figures/world bank data nnm vs gdp_pc.png", as(png) name("Graph") replace;
