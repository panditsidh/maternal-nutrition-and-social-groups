/********************************************************************
Purpose:
    Make CDF of fraction PSU higher ranking by social group,
    then combine with prepregnancy-underweight cutoff figure.

Inputs:
    $dataset
    figures/ppu_cutoff_line.gph

Required variables:
    pct_psu_higher
    group
    preg
    v005
********************************************************************/

clear all
set more off

do "$paths"

capture mkdir "figures"

*------------------------------------------------------------
* 1) Load data for CDF
*------------------------------------------------------------
use "$dataset", clear

keep if inlist(group, 1, 2, 3)
keep if preg == 1
keep if !missing(pct_psu_higher, group, v005)

*------------------------------------------------------------
* 2) Social group labels
*------------------------------------------------------------
capture label drop grouplbl
label define grouplbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC", replace

label values group grouplbl

*------------------------------------------------------------
* 3) Build weighted CDF
*------------------------------------------------------------
gen double w = v005

collapse (sum) w, by(group pct_psu_higher)

sort group pct_psu_higher

by group: gen double cumw = sum(w)
by group: egen double totalw = total(w)

gen double cdf = 100 * cumw / totalw

* Optional: make x variable name clearer
gen double cutoff = pct_psu_higher

*------------------------------------------------------------
* 4) CDF graph
*------------------------------------------------------------
twoway ///
    (line cdf cutoff if group == 1, sort lwidth(medthick) lcolor(navy)) ///
    (line cdf cutoff if group == 2, sort lwidth(medthick) lcolor(maroon)) ///
    (line cdf cutoff if group == 3, sort lwidth(medthick) lcolor(green)) ///
    , ///
    xscale(range(0 1)) ///
    xlabel(1(.1)0, angle(0) labsize(vsmall)) ///
    ylabel(0(20)100, angle(0) labsize(vsmall) grid) ///
    xtitle("Fraction of nearby households" "ranked higher in caste than the woman") ///
    ytitle("Cumulative share" "of pregnant women (%)") ///
    title("B. Distribution of share of nearby households" "that are higher ranking in caste", size(medlarge)) ///
    legend(order(1 "Adivasi" 2 "Dalit" 3 "OBC") ///
           rows(1) position(6) size(small)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(cdf_psu_higher, replace)

graph save "figures/cdf_psu_higher.gph", replace
graph export "figures/cdf_psu_higher.pdf", as(pdf) replace


*------------------------------------------------------------
* 5) Combine with existing cutoff graph
*------------------------------------------------------------
graph use "figures/ppu_cutoff_line.gph", name(ppu_cutoff_line, replace)
graph use "figures/cdf_psu_higher.gph", name(cdf_psu_higher, replace)

graph combine ///
    ppu_cutoff_line ///
    cdf_psu_higher, ///
    cols(1) ///
    xsize(7.5) ///
    ysize(10) ///
    graphregion(color(white)) note("Nearby households refer to those in the woman's primary sampling unit. Households are determined" "as higher ranking than Adivasi or Dalit women if their household head is OBC or Forward caste." "Households are determined as higher ranking than OBC women if their household head is forward caste.", size(vsmall)) ///
    name(combined_cutoff_cdf, replace)

graph export "figures/combined_cutoff_cdf.pdf", as(pdf) replace
graph export "figures/combined_cutoff_cdf.png", as(png) width(2400) replace
