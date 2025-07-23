do "dofiles/figures/pp underweight by social group with cis/panels bdf.do"

do "dofiles/figures/distributions of predictors of underweight by social group/panels ace.do"


count if preg==1 
local sample_size_ae = r(N)


count if preg==1 & parity>=2
local sample_size_c = r(N)


count if preg==0
local sample_size_bf = r(N)


count if preg==0 & parity>=2
local sample_size_e = r(N)


local orig_dir = c(pwd)
cd figures/

graph combine a.gph c.gph e.gph parity.gph bs.gph  wealth.gph, cols(3) ///
    scale(0.7) iscale(0.5) imargin(5 5 5 5) ///
    xsize(8) ysize(6) graphregion(color(white)) note("NFHS-5 data.  In panels A and E, n=`sample_size_ae' (3+ months pregnant women), in panel C, n=`sample_size_c' (3+ months pregnant women who have at least one live birth), in panels B and F, n=`sample_size_bf' (non-pregnant women), and in panel E, n=`sample_size_e' (non-pregnant women who have at least one live birth).")

	


cd "`orig_dir'"
graph export "figures/six panel figure.png", replace
	

