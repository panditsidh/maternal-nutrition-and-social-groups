/* this dofile generates a stata dataset that has

rows:
1 all groups + 5 social groups + 4 parity + 3 birth spacing
+ 10 parity and birth spacing + 4 wealth = 27

columns:
mean for every outcome
*/

* prepare dataset
qui do "$paths"
use "$dataset", clear
qui do "dofiles/050_weights to estimate pp nutrition.do"

drop if group==6 | group==.

* initialize results matrix
local outcomes bmi weight underweight overweight obesity

matrix results = J(27, `=wordcount("`outcomes'")', .)

local colnames
foreach outcome in `outcomes' {
    local colnames `colnames' `outcome'_mean
}

matrix colnames results = `colnames'

* calculate means for all subgroups
local row = 1

foreach overvar in group allfivegroups parity bs parity_bs wealth {

    levelsof `overvar', local(levels)

    foreach i in `levels' {

        local col = 1

        foreach outcome in `outcomes' {

            quietly summarize `outcome' if `overvar'==`i' & preg==0 [aw=reweightingfxn]
            matrix results[`row', `col'] = r(mean)

            local col = `col' + 1
        }

        local ++row
    }
}

* convert matrix into a dataset using svmat
input str100 rows
"Adivasi"
"Dalit"
"OBC"
"Forward"
"Muslim"
"All five social groups"
"Parity 1"
"Parity 2"
"Parity 3"
"Parity 4"
"\textless{}2y birth spacing"
"2-3y birth spacing"
"\textgreater{}3y birth spacing"
"No births"
"1 birth, \textless{}2y spacing"
"1 birth, 2–3y spacing"
"1 birth, \textgreater{}3y spacing"
"2 births, \textless{}2y spacing"
"2 births, 2–3y spacing"
"2 births, \textgreater{}3y spacing"
"3+ births, \textless{}2y spacing"
"3+ births, 2–3y spacing"
"3+ births, \textgreater{}3y spacing"
"Wealth quartile 1"
"Wealth quartile 2"
"Wealth quartile 3"
"Wealth quartile 4"
end

svmat results, names(col)

drop if missing(rows)

local last_outcome : word `=wordcount("`outcomes'")' of `outcomes'
keep rows-`last_outcome'_mean

save "data/results nfhs4.dta", replace
