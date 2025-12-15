do "$paths"

// 1 : create dataset for analysis 
do "dofiles/010_assemble data.do"

// 1.1: get appendix table A1 (regress 1 or 2 months pregnant on important covariates to show bias)
do "dofiles/011 appendix tableA1 - 3+mopreg regression.do"

// 1.2: get appendix table A2 (distribution of gestational ages to show underreporting of 1 or 2 month gestational duration)
do "dofiles/012_appendix tableA2 distribution of gestational ages.do"

// 2 : summary statistics table
do "dofiles/cleaned do files - reviewed/020_table summary statistics.do"


// 3 : regression predicting pregnancy
do "dofiles/cleaned do files - reviewed/030_table regression predicting pregnancy.do"

// // 4 : figures showing distribution of pregnant women by parity, birth spacing, social group
do "dofiles/cleaned do files - reviewed/040_fig panel ACE showing distribution of pregnant women by predictors.do"

// 5 : reweighting
* use "$dataset", clear // if you are running these two lines for testing and need to reload the original dataset
do "dofiles/cleaned do files - reviewed/050_weights to estimate pp nutrition.do"

// 6 : get bootstrapped confidence intervals for pre-pregnancy outcomes (takes forever to run)
// do "dofiles/for Diane to review/060_bootstrapped cis for pp nutrition by subgroup.do"

// 7 : compile a results dataset
do "dofiles/for Diane to review/070_pp nutrition estimates by subgroup.do"

// 8 : main result figure 
do "dofiles/for Diane to review/080_fig pp underweight by subgroup.do"

// // 9 : figures of pp outcomes by predictors
do "dofiles/for Diane to review/090_fig panels BDE showing pp outcomes by predictors.do"

// 10 : combine the figures from 4 and 9 to get one six panel figure
do "dofiles/for Diane to review/100 fig six panels.do"

// 11 : kitagawa decomposition
do "dofiles/for Diane to review/110 table kitagawa results.do"

* TODO
// 12 : tfrs
do "dofiles/for Diane to review/120_appendix table TFRs by social group.do"

// 13 : reweighting diagnostics
do "dofiles/for Diane to review/130_appendix table with percent pregnant women dropped.do"


// 15 : additional outcomes
do "dofiles/for Diane to review/150_appendix table additional maternal nutrition indicators.do"
