do "dofiles/figures/pp underweight by social group with cis/panels bdf.do"

do "dofiles/figures/distributions of predictors of underweight by social group/panels ace.do"


count 

local sample_size = r(N)


local orig_dir = c(pwd)
cd figures/

graph combine a.gph parity.gph c.gph bs.gph e.gph wealth.gph, cols(2) ///
    scale(0.7) iscale(0.5) imargin(5 5 5 5) ///
    xsize(6) ysize(8) graphregion(color(white)) note("Base sample used in all figures is NFHS-5 women, N=`sample_size'")


cd "`orig_dir'"
graph export "figures/six panel figure.png", replace
	

