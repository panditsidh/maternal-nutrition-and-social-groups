/********************************************************************
Purpose:
    Protein-only stacked bar figure among pregnant women,
    then combine with protein-only underweight scatter figure.

Output:
    figures/protein_q4_distribution.gph
    figures/combined_protein_distribution_underweight.pdf
********************************************************************/

clear all
set more off

do "$paths"
use "$dataset", clear

drop if group == 6 | group == .

capture mkdir "figures"

*------------------------------------------------------------
* Protein distribution among pregnant women
*------------------------------------------------------------

keep if preg == 1
keep if !missing(protein_q4, group)

count
local sample_size : display %15.0fc r(N)

local colors "eltblue%55 ebblue%55 emidblue%55 navy%55"

local vallab : value label protein_q4

local dummies ""
local legend_order ""
local baropts ""

levelsof protein_q4, local(levels)

local i = 1
foreach level of local levels {

    gen protein_q4_`level' = (protein_q4 == `level') * 100

    local dummies `dummies' protein_q4_`level'

    if "`vallab'" != "" {
        local lab : label `vallab' `level'
    }
    else {
        local lab "`level'"
    }

    local lab = subinstr(`"`lab'"', "\%", "%", .)

    local legend_order `legend_order' `i' `"`lab'"'

    local thiscolor : word `i' of `colors'
    local baropts `baropts' bar(`i', color("`thiscolor'") lcolor(none))

    local ++i
}

#delimit ;

graph hbar (mean) `dummies' [aw=v005],
    over(group, label(angle(0) labsize(tiny)))
    stack
    `baropts'
    legend(order(`legend_order')
           cols(2)
           pos(6)
           size(vsmall)
           symxsize(small)
           symysize(small)
           region(lstyle(none)))
    blabel(bar, format(%4.0f) position(inside) size(tiny))
    ytitle("Percent", size(vsmall))
    ylabel(0(20)100, labsize(vsmall))
    title("A. Protein consumption distribution", size(small))
    note("n=`sample_size' (3+ month married pregnant women)", size(vsmall))
    graphregion(color(white))
    plotregion(color(white))
    name(protein_q4_distribution, replace);

#delimit cr

graph save "figures/protein_q4_distribution.gph", replace

graph export "figures/protein_q4_distribution.pdf", ///
    replace as(pdf) name(protein_q4_distribution)


*------------------------------------------------------------
* Combine with protein-only scatter graph
* Run the scatter dofile first if the .gph file does not exist yet.
*------------------------------------------------------------

graph use "figures/protein_q4_underweight.gph", name(protein_q4_underweight, replace)

graph combine ///
    protein_q4_distribution ///
    protein_q4_underweight, ///
    cols(1) ///
    xsize(7.5) ///
    ysize(10) ///
    graphregion(color(white)) ///
    name(protein_distribution, replace)

graph export "figures/combined_protein_distribution_underweight.pdf", ///
    replace as(pdf)

graph export "figures/combined_protein_distribution_underweight.png", ///
    replace as(png) width(2400)
