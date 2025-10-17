* This dofile generates the individual panels of the 6 panel figure and combines them


do "$paths"
use "$dataset", clear


* calculate sample sizes for figure notes
count if preg==1 
local sample_size_ae = r(N)

count if preg==1 & parity>=2
local sample_size_c = r(N)


count if preg==0
local sample_size_bf = r(N)


count if preg==0 & parity>=2
local sample_size_e = r(N)

* for easier file references
local orig_dir = c(pwd)
cd figures/

graph combine a.gph c.gph e.gph b.gph d.gph f.gph, cols(3) ///
    scale(0.7) iscale(0.55) imargin(6 6 6 6) ///
    xsize(10) ysize(6) graphregion(color(white)) 

	
cd "`orig_dir'"
graph export "figures/fig_predictors_by_social_group_and_gradients.pdf", replace



* REMOVED THIS SO THAT WE CAN EDIT IT IN OVERLEAF

// ///
//     note("Note: NFHS-5 data. In panels A and E, n=`sample_size_ae' (3+ months pregnant women), in panel C,  n=`sample_size_c' (3+ months pregnant women who have at least one live" "birth). In panels B and F, n=`sample_size_bf' (non-pregnant women), and in panel E, n=`sample_size_e' (non-pregnant women who have at least one live birth). Social groups are defined based on self-reported constitutional categories and religion as follows: Adivasi (ST), Dalit (SC), Muslim (non‐SC/ST), OBC (Hindu/Sikh OBC), and Forward caste (Hindus not SC/ST/OBC).", size(small))
