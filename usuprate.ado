/*

************************************************************************************************************************
**************DESCRIPTION***********************************************************************************************

FILE:       	usuprate
PURPOSE:    	Uprate monetary variables to a given year and month's prices
AUTHOR:     	Peter Levell (based on bhpsuprate by Jonathan Shaw)
THIS VERSION:	 04/12/2014

DETAILS:		[Description of file contents]

TYPICAL USE:  	[List of commands]

**************LOG*******************************************************************************************************

04/12/2014    Created (from bhpsuprate file)

**************NOTES*****************************************************************************************************

[Date]			[Note]

************************************************************************************************************************
************************************************************************************************************************

*/



* Program to uprate a variable to a given month's prices
program define usuprate, rclass


	* Syntax checking
	*----------------

    syntax [varlist(default=none)] [if], year(numlist integer max=1 >=1987 <=2050) month(numlist integer max=1 >=1 <=12) [datevar(varname) yearvar(varname) monthvar(varname) char(name) missing]

	* Check that either datevar has been specified or yearvar and monthvar have been specified
	if (("`datevar'" != "") + ("`yearvar'" != "" & "`monthvar'" != "") != 1) {
		di as error "You must specify either datevar() or both yearvar() and monthvar()"
		exit 198
	}

	* Parsing if variable characteristics are used
	if "`varlist'" == "" {

		* Check that "char" option has been specified if variable list has been omitted
		if ("`char'" == "") {
			di as error `"You can only omit the variable list if option "char" is specified"'
		}

		* Accumulate list of variables to uprate
		foreach var of varlist _all {
			if ("`: char `var'[`char']'" != "") local varlist "`varlist' `var'"
		}

		* Check that we now have a variable list
		if ("`varlist'" == "") {
			di as error "No variables were found with char `char' set"
			exit 198
		}
	}


	* Import price index
	*-------------------

	* Import the price index (it's stored as CSV so that version control can keep track of it better)
    preserve
	quietly import delimited using "$do\RPIMonthlySeries.csv", clear

	* Check that year and month to uprate to are found in price index data
	qui su rpi if year == `year' & month == `month'
    if r(N) == 0 {
        di as error "Month not found in rpi data"
        exit
    }

	* Check there's only one match
    assert r(N) == 1
    local rpinew = r(min)

	* Save price index so we don't need to import it again later
	tempfile rpidata
	sort year month
	quietly save `rpidata'


	* Merge price index into existing data
	*-------------------------------------

    restore
    if "`datevar'" != "" {
        qui gen int year = year(`datevar')
        qui gen byte month = month(`datevar')
    }
    else {
        rename `yearvar' year
        rename `monthvar' month
    }
    sort year month
    qui merge year month using "`rpidata'", uniqusing nokeep
    if "`datevar'" != "" {
        drop year month
    }
    else {
        rename year `yearvar'
        rename month `monthvar'
    }
    drop _merge


	* Uprate variables
	*-----------------

	local mth : word `month' of `c(Mons)'
    local yr = substr("`year'",3,.)

    foreach var of local varlist {
        qui replace `var' = `var'*`rpinew'/rpi `if'
		qui label variable `var' "`: variable label `var'' (`mth' `yr' prices)"
    }
    if "`missing'" == "missing" gen byte indexmissing = (rpi >= .)
    drop rpi


	* Return information
	*-------------------

    return local prices "`mth' `yr'"
	return local uprated "`varlist'"

end
