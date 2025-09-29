
* world bank nnm data
import delimited "data/API_SH.DYN.NMRT_DS2_en_csv_v2_1034803.csv", varnames(4) numericcols(5 6 7 8 9 10) clear 


rename v1 country_name
rename v2 country_code
rename v64 nnm_2019

keep country_name country_code nnm_2019


tempfile nnm 
save `nnm'


import delimited "data/API_NY.GDP.PCAP.CD_DS2_en_csv_v2_1076250.csv", clear

rename v1 country_name
rename v2 country_code
rename v64 gdppc_2019

keep country_name country_code gdppc_2019

// drop if missing(gdppc_2023)


tempfile gdp_pc
save `gdp_pc'


* world bank population data
import delimited "data/API_SP.POP.TOTL_DS2_en_csv_v2_1075736.csv", varnames(4)clear

rename v1 country_name
rename v2 country_code
rename v64 pop_2019


keep country_name country_code pop_2019


* merge
merge 1:1 country_code using `nnm', gen(m1)
merge 1:1 country_code using `gdp_pc', gen(m2)

drop if m1!=3 | m2!=3

drop m1 m2


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

gen log_gdppc_2019 = log(gdppc_2019)

qui sum log_gdppc_2019

local xmin = r(min)
local xmax = r(max)

replace nnm_2019 = 25.9 if country_name == "India"


#delimit ;
twoway (scatter nnm_2019 log_gdppc_2019 [fw=pop_2019], 
			msymbol(Oh) mcolor(black)) 
	   (lfit nnm_2019 log_gdppc_2019, 
			lcolor(black) range(`xmin' `xmax')), 
			legend(off) graphregion(color(white))
	   xtitle("log of GDP per capita in current US dollars")
	   ytitle("neonatal mortality, per 1000 live births");

	   
graph export "figures/world bank data nnm vs gdp_pc.png", as(png) name("Graph") replace;
