/*
Table 1: Descriptive statistics by social group and pregnancy status

Goal
- Produce Table 1 means for the covariates used in the nonparametric reweighting bins.
- Report means separately for:
    (i) pregnant women (3+ months) and (ii) nonpregnant women
  within:
    5 social groups (Adivasi, Dalit, OBC, Forward, Muslim) + an "All five groups" column.

Output
- LaTeX table saved to: tables/table1 sumstats.tex
- Optional: browse() view in Stata for quick checking.

Notes on mechanics
- "All five groups" is created by duplicating observations and assigning group = 0 for the
  duplicated copy. After collapsing, group==0 is relabeled as group==6 for display ordering.
- Weighted means use DHS sampling weights (v005) via [pw=v005].
- "N" row uses the *true unweighted count* (no duplication) merged back after collapse.
*/

*do "$paths"
use "$dataset", clear

drop if group==. | group==6
*------------------------------------------------------------*
* 1) Define the covariates shown in Table 1
*------------------------------------------------------------*
#delimit ;
local varlist ///
    less_edu rural noboy ///
    age1519 age2024 age2529 age3049 ///
    parity_bs1 parity_bs2 parity_bs3 parity_bs4 parity_bs5 ///
    parity_bs6 parity_bs7 parity_bs8 parity_bs9 parity_bs10 ///
    wealth1 wealth2 wealth3 wealth4 ;
#delimit cr

*------------------------------------------------------------*
* 2) Keep only what is needed for Table 1
*    - preg: pregnancy indicator (pregnant 3+ months vs nonpreg)
*    - group: social group code
*    - v005: sampling weight
*    - varlist: covariates displayed as means
*------------------------------------------------------------*
keep preg group v005 `varlist'
gen ones = 1   // helper variable for counts

*------------------------------------------------------------*
* 3) Compute true (unweighted) N by pregnancy status and group
*    Important: do this BEFORE duplicating observations for "All five groups"
*------------------------------------------------------------*
preserve
collapse (count) ones, by(preg group)
tempfile Ntrue
drop if preg==.
save `Ntrue', replace
restore

*------------------------------------------------------------*
* 4) Add "All five groups" columns by duplicating the data
*    - expand 2 creates a duplicate copy flagged by dup==1
*    - set group=0 for the duplicate copy so collapse treats it as pooled India
*------------------------------------------------------------*
expand 2, gen(dup)
replace group = 0 if dup==1
drop dup

*------------------------------------------------------------*
* 5) Collapse to weighted means (and weighted totals of ones)
*    - Means: displayed entries in Table 1
*    - rawsum ones: (weighted) sum of weights; true unweighted N is merged in next step
*------------------------------------------------------------*
collapse (mean) `varlist' (rawsum) ones [pw=v005], by(preg group)

drop if preg==.

* Merge true unweighted N back (so the N row reflects real sample size)
merge 1:1 preg group using `Ntrue', nogen

*------------------------------------------------------------*
* 6) Fix group codes for final table ordering
*    - drop group==6 if it exists (avoids clashes)
*    - relabel group==0 (pooled "All five") to group==6 for display placement
*------------------------------------------------------------*
drop if group==6
replace group = 6 if group==0

* Arrange rows so pregnant block appears first, then nonpregnant
gen pregorder = (preg==0)
sort pregorder group

*------------------------------------------------------------*
* 7) Reshape for LaTeX export: one row per variable, 12 columns total
*------------------------------------------------------------*
xpose, clear varname
drop if inlist(_varname, "group", "preg", "pregorder")
gen order = _n

*------------------------------------------------------------*
* 8) Insert blank/header rows to match the paper's Table 1 layout
*    (These offsets create space for section titles and separators.)
*------------------------------------------------------------*
replace order = order+2 if order>=1
replace order = order+2 if order>=5
replace order = order+2 if order>=8
replace order = order+2 if order>=18
replace order = order+2 if order==23

* For selected variables, create extra blank lines / spacing in the LaTeX table
expand 3 if inlist(_varname, "less_edu", "noboy", "age3049", "parity_bs10", "wealth4")

bysort _varname: gen dupnum = _n
sort order dupnum
replace order = _n

*------------------------------------------------------------*
* 9) Create the left-hand "row labels" exactly as they should appear in LaTeX
*------------------------------------------------------------*
input str100 rows
""
"\textbf{Binary Predictors of Pregnancy and Underweight}"
"\hspace*{2em}less than primary education"
"\hspace*{2em}rural resident"
"\hspace*{2em}does not have boy child"
""
"\textbf{Age Categories}"
"\hspace*{2em}15 to 19"
"\hspace*{2em}20 to 24"
"\hspace*{2em}25 to 29"
"\hspace*{2em}30 to 49"
""
"\textbf{Categories for parity and spacing from last birth}"
"\hspace*{2em}No births"
"\hspace*{2em}1 birth, \textless{}2y spacing"
"\hspace*{2em}1 birth, 2–3y spacing"
"\hspace*{2em}1 birth, \textgreater{}3y spacing"
"\hspace*{2em}2 births, \textless{}2y spacing"
"\hspace*{2em}2 births, 2–3y spacing"
"\hspace*{2em}2 births, \textgreater{}3y spacing"
"\hspace*{2em}3+ births, \textless{}2y spacing"
"\hspace*{2em}3+ births, 2–3y spacing"
"\hspace*{2em}3+ births, \textgreater{}3y spacing"
""
"\textbf{Wealth Categories}"
"\hspace*{2em}1st (bottom) quartile"
"\hspace*{2em}2nd quartile"
"\hspace*{2em}3rd quartile"
"\hspace*{2em}4th quartile" 
""
"\textbf{N}"
end

* Ensure the "N" label appears only on the final row where counts are printed
replace rows = "" if rows=="\textbf{N}"
replace rows = "\textbf{N}" if _n==33

order rows
keep v* rows

*------------------------------------------------------------*
* 10) Create display strings:
*     - For rows with labels: show %4.2f (trim leading 0 for aesthetics)
*     - For the N row: show integer count (stored in v# on that row)
*------------------------------------------------------------*
foreach i of numlist 1/12 {
    gen disp_v`i' = string(v`i', "%15.0fc") if _n==33
    replace disp_v`i' = subinstr(string(v`i', "%6.2f"), "0.", ".", 1) if (rows!="" & strmatch(rows, "\textbf{*")==0) & _n<33 
	}


drop v*
drop if _n==1   // drop the first blank spacer row used for formatting

*------------------------------------------------------------*
* 11) Export to LaTeX (tabular) with a custom header grouping columns by pregnancy status
*------------------------------------------------------------*
#delimit ;
listtex rows disp_v1 disp_v2 disp_v3 disp_v4 disp_v5 disp_v6 disp_v7 disp_v8 disp_v9 disp_v10 disp_v11 disp_v12 ///
    using "tables/table1 sumstats.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{1.2cm}}@{\hspace{3em}}*{6}{>{\centering\arraybackslash}p{1.2cm}}}" ///
         "\toprule" ///
         "& \multicolumn{6}{c}{Pregnant women (3+ months)} & \multicolumn{6}{c}{Nonpregnant women} \\\\" ///
         "Social Group & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny \shortstack{All five \\\\ social groups} & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny \shortstack{All five \\\\ social groups} \\\\" ///
         "\midrule") ///
    foot("\bottomrule" ///
         "\end{tabular}");
#delimit cr

*------------------------------------------------------------*
* 12) Quick manual check: open the final dataset used for export
*------------------------------------------------------------*
display("BROWSE DATA EDITOR TO SEE RESULTS IN STATA DIRECTLY")
browse
