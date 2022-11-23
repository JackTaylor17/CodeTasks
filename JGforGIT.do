*Title of the Code Task and Institution went here*
clear all 
set more off 
cd //Put pathname for directory here 



*2-Data Cleaning*

*Convert the .csv files to .dta files*

*Price
forvalues i=1990/2018{
	clear
	import delimited Barley_price_`i'.csv
	save Price_`i'.dta, replace
}
*Production*
forvalues i=1990/2018{
	clear
	import delimited Barley_production_`i'.csv
	save Production_`i'.dta, replace
}

*Handle some name inconsistencies, price and production are each called value in their respective data sets so I rename them accordingly*
forvalues i=1990/2018{
	clear
	use Price_`i'
	rename value price
	save Price_`i', replace
}

forvalues i=1990/2018{
	clear
	use Production_`i'
	rename value production
	save Production_`i', replace
}

*Merge and append to make the panel*
forvalues i=1990/2018{
	clear
	use Production_`i'
	merge m:1  state using Price_`i', force
	drop _merge
	save "`i'", replace
}

forvalues i=1990/2018{
	append using "`i'"
}
save barley_panel, replace

sort state year

*Make the panel with the correct specs* 
encode production, generate(Production)
encode(agdistrict), gen(agricultural_district)
encode(state), gen(State)
sort State year
keep year agricultural_district State price Production
order State agricultural_district year price Production
*Note that Alaska and Maine never produced barley and Kansas and Deleware have many missing values for production. If that becomes an issue run these lines*
//drop if agricultural_district==.


*3-Data Exploration*

*Price Plot*

*Generate the weights and variables and also set this data set as a panel* 
egen weight=sum(Production), by(State year)
egen yearly_price_average=wtmean(price), weight(weight) by (year)
gen id=_n
xtset id year 
tsline yearly_price_average, title("Weighted Mean Barley Price in the US, 1990-2018") ytitle("Weighted Mean Barley Price") xtitle("Year") ylabel(1.5 2 2.5 3 3.5 4 4.5 5 5.5 6) xlabel(1990 1992 1994 1996 1998 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018, labsize(7pt)) caption("Weights for each state are defined as the production in bushels in for each state in each year of the panel", size(5pt))

*Production Plot* 

*Find the top 3 states*
egen rank=total(Production) if year==2018, by(State)
gsort -rank State
br //here we see that it is North Dakota, California, and Montana 

*Make the yearly state production*
egen barley_production=total(Production), by(State year)
replace barley_production=(barley_production/1000)
tsline barley_production if State==3 || tsline barley_production if State==13 || tsline barley_production if State==19, title("Yearly Barley Bushel Production, 1990-2018") subtitle("By States with Largest Production in 2018", size(10pt)) legend(label(1 "California") label(2 "Minnesota") label(3 "North Dakota")) xtitle("Years") ytitle("Bushels Produced (in Millions)") ylabel(2.5 5 7.5 10 12.5 15 17.5 20, labsize(8pt)) xlabel(1990 1992 1994 1996 1998 2000 2002 2004 2006 2008 2010 2012 2014 2016 2018, labsize(7pt))


*Summary Table*

*Make column variables*
gen decade=1 if year>=1990 & year<=1999
replace decade=2 if year>=2000 & year<=2009
replace decade=3 if year>=2010 & year<=2018
recode decade (1=1 "1990-1999") (2=2 "2000-2009") (3=3 "2010-2018"), gen(Decade)

*Decade Means*
egen decade_production=mean(barley_production), by(State Decade) //this is already scaled since it used barley_production which was scaled in line 87. I do this to verify the results presented in the table
sort State year
save barley_panel, replace

*Make the Table* 
sort barley_production State
by barley_production: keep if State==6 | State==12 | State==13 | State==19 | State==31
table State Decade, statistic(mean barley_production) nototal //copy table as HTML and input to a LaTex table maker and copy into .tex document



*4-Short Answer*
clear
use barley_panel
sort State year

*Estimate Price elasticity of production for barley for each district in each year of the sample. Estimating the elasticity means we will employ a log-log model. I use reg because there is insufficent observations to use xtreg which is preferable when working with panel data*
gen lnproduction=ln(Production)
gen lnprice=ln(price)
reg lnproduction lnprice
estat hettest //conclude heteroskedasticity is present so use robust standard errors
reg lnproduction lnprice , vce(robust) 
eststo M1
reg lnproduction lnprice i.State i.year, vce(cluster agricultural_district) 
eststo M2
esttab, keep(lnprice _cons) cells("b". "se". "p") stats(r2 N, labels((R-squared))), using BTable.tex














