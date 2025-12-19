* Please edit this file to reflect your system paths to the NFHS and IHDS datasets needed in this paper. It also sets the working directory as this project folder. If your working directory changes, some code files might fail, but you can just rerun this to reset it. 
do "$paths"


* Note to Diane: every file in here runs self sufficiently, so the order isn't really important. 

* 1 : Create dataset for analysis
do "dofiles/010_assemble data.do"

* 1.1: Table A1: Women reporting one or two months of pregnancy are different than those reporting three or more months of pregnancy (regress 1 or 2 months pregnant on important covariates to show bias)
do "dofiles/011 appendix tableA1 - 3+mopreg regression.do"

* 1.2: Table A2: Distribution of self-reported gestational ages (to show underreporting of 1 or 2 month gestational duration)
do "dofiles/012_appendix tableA2 distribution of gestational ages.do"

* 2: Table 1: Descriptive statistics by social group and pregnancy status (means of variables later used in reweighting within all 5 social groups pregnant and nonpregnant women)
do "dofiles/020_table1 summary statistics.do"

* 3: Table A4: Variables used in the nonparametric reweighting predict pregnancy (regress pregnancy indicator on reweighting variables)
do "dofiles/030_tableA4 regression predicting pregnancy.do"

* 4: Panels ACE of Figure 2: Differences in parity, birth spacing, and wealth quartile by social group, and the relationship between these characteristics and prepregnancy underweight (stacked bars showing distribution of covariates within each social group)
do "dofiles/040_figure2 panels ACE showing distribution of pregnant women by predictors.do"


* 6 : Get bootstrapped confidence intervals for pre-pregnancy outcomes (takes 2-3 hours to run)
do "dofiles/060_bootstrapped cis for pp nutrition by subgroup.do"

* 7: Compile a results dataset of various maternal nutrition indicators with confidence intervals within each social group to use in tables and figures
do "dofiles/070_pp nutrition estimates by subgroup.do"

* 8: Figure 1: Prepregnancy underweight by social group (plotted with confidence intervals)
do "dofiles/080_figure1 pp underweight by subgroup.do"

* 9: Panels BDE of Figure 2: Differences in parity, birth spacing, and wealth quartile by social group, and the relationship between these characteristics and prepregnancy underweight (plotting all social group means of prepregnancy underweight within covariate categories with confidence intervals)
do "dofiles/090_figure2 panels BDE showing pp outcomes by predictors.do"

* 10: Combine panels ACE and BDE to get Figure 2: Differences in parity, birth spacing, and wealth quartile by social group, and the relationship between these characteristics and prepregnancy underweight
do "dofiles/100 figure2 six panels.do"

* 11: Table 2: Decomposition of social group differences in the prevalence of prepregnancy underweight (Kitagawa results)
do "dofiles/110 table2 kitagawa results.do"

* 12: Table A6: Fertility rates by social group
do "dofiles/for Diane to review/120_appendix table TFRs by social group.do"

* 13: Table A3: Sample sizes of 3+ month pregnant women in each subgroup and the % of pregnant women dropped to estimate pre-pregnancy underweight
do "dofiles/for Diane to review/130_appendix table with percent pregnant women dropped.do"

* 15: Table A7: Means and 95% CIs for additional maternal nutrition indicators by social group
do "dofiles/for Diane to review/150_appendix table additional maternal nutrition indicators.do"
