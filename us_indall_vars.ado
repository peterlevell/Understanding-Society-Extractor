/*

**************DESCRIPTION***********************************************************************************************

FILE:       	us_indall_vars.ado
PURPOSE:    	Lots of individual programs, each one setting up a particular variable from Understanding Society indall dataset
AUTHOR:     	Peter Levell (based on BHPS programme by Jonathan Shaw)
THIS VERSION:   06/12/2014

DETAILS:			You're most likely to want to use "variable programs - driver.do", which calls programs from this file.

TYPICAL USE:  Too many individual programs to list here, but important common program options:
							- whatvars = lists which raw BHPS variables are used to create the derived variable (rather than actually creating it)
							- mindic   = use extended missing values (.a, .b, etc) to explain why variable is missing

**************LOG*******************************************************************************************************

**************NOTES*****************************************************************************************************

[Date]				[Note]

UPDATED TO US
depkid
female
couple
married
numkids
nkids
age
ageband
ageyng
kidage
numleq12resp
parentinhh
parentsinhh
numothads
numothads18
hbrooms



************************************************************************************************************************

May 2016	added: ownkids
 
August 2016	added: parentpids (David Sturrock)

*/

****************************************************************
*--------------------------------------------------------------*
*- Driver program to create indall varaibles in a single wave -*
*--------------------------------------------------------------*
****************************************************************

program define us_indall_vars

	* Remove the comma (for options)
	local 0 : subinstr local 0 "," ""

    # delimit;

	* Option specification (note: assumed to be optional);
	* This doesn't use the Stata syntax command because there is a limit of 70 options (both in the option specification and when the program is called);
	local optionspec	wave(numlist integer max=1 >=1 <=$numwaves)
						depkid(name)
						female(name)
						couple(name)
						married(name)
						ptrpid(name)
						numkids(name)
						nkids(name)
						ownkids(name)
						age(name)
						ageband(name)
						ageyng(name)
						kidage(name)
						numleq12resp(name)
						parentinhh(name)
						parentsinhh(name)
						parentpids(string)
						numothads(name)
						numothads18(name)
						hbrooms(name)
						eqscale(name)
						rawvars(namelist)
						neednotexist
						mindic
						;

						check_option_syntax, optionspec(`optionspec') optionlist(`0');


    * Tidy up compound options;
    local parentpids_syntax    "dadpid(name)
                                mumpid(name)
								dadpidp(name)
                                mumpidp(name)";

    # delimit cr
    local indallvars "depkid female couple married ptrpid numkids nkids ownkids age ageband ageyng kidage numleq12resp parentinhh parentpids numothads numothads18 hbrooms eqscale"

    local wi = `wave'
    local w = char(96+`wi') + "_"

    * Find out what raw variables are required
    ******************************************

    local idvars "`w'hidp `w'buno_dv `w'pno pidp"
    local rawvars : list idvars | rawvars

    local othvars ""
    foreach indallvar of local indallvars {
        if "``indallvar''" != "" {
            indall_`indallvar', wave(`wi') whatvars
            local othvars "`othvars' `r(vars)'"
        }
    }
    local othvars : list uniq othvars
    local othvars : list othvars - rawvars

    * Create variables
    ******************

	di "`rawvars'"
	di "`othvars'"
    if (`: list rawvars === idvars' & "`othvars'" == "") {
    }
    else {

        * Open variables
        useundersoc `rawvars' `othvars' using "$data\\`w'indall.dta", clear `neednotexist'
		
        * Create finished variables
        if "`depkid'" != "" {
            indall_depkid, wave(`wi') depkid(`depkid')
            * depkid is needed by calling program
            c_local depkid `depkid'
        }
		
        if "`female'" != "" {
            indall_female, wave(`wi') female(`female') `mindic'
        }
        if "`couple'" != "" {
            indall_couple, wave(`wi') couple(`couple') depkid(`depkid')
        }
        if "`married'" != "" {
            indall_married, wave(`wi') married(`married') couple(`couple') `mindic'
        }

        if "`ptrpid'" != "" {
            indall_ptrpid, wave(`wi') ptrpid(`ptrpid') couple(`couple') depkid(`depkid') `mindic'
        }

        if "`ptrempstat'" != "" {
            indall_ptrempstat, wave(`wi') ptrempstat(`ptrempstat') couple(`couple') depkid(`depkid') `mindic'
        }
        if "`numkids'" != "" {
            indall_numkids, wave(`wi') numkids(`numkids') depkid(`depkid')
        }
        if "`nkids'" != "" {
            indall_nkids, wave(`wi') nkids(`nkids') depkid(`depkid')
        }
        if "`ownkids'" != "" {
            indall_ownkids, wave(`wi') ownkids(`ownkids')
        }
        if "`age'" != "" {
            indall_age, wave(`wi') age(`age') `mindic'
        }
        if "`ageband'" != "" {
            indall_ageband, wave(`wi') ageband(`ageband') `mindic'
        }
        if "`ageyng'" != "" {
            indall_ageyng, wave(`wi') ageyng(`ageyng') age(`age') depkid(`depkid') numkids(`numkids') `mindic'
        }
        if "`kidage'" != "" {
            indall_kidage, wave(`wi') kidage(`kidage') age(`age') depkid(`depkid') `mindic'
        }
        if "`numleq12resp'" != "" {
            indall_numleq12resp, wave(`wi') numleq12resp(`numleq12resp') age(`age')
        }
        if "`parentinhh'" != "" {
            indall_parentinhh, wave(`wi') parentinhh(`parentinhh')
		}
        if "`parentpids'" != "" {
            local 0 ", `parentpids'"
            syntax [, `parentpids_syntax']
            indall_parentpids, wave(`wi') dadpid(`dadpid') mumpid(`mumpid') dadpidp(`dadpidp') mumpidp(`mumpidp') `mindic'
        }
        if "`numothads'" != "" {
            indall_numothads, wave(`wi') numothads(`numothads') depkid(`depkid')
        }
        if "`numothads18'" != "" {
            indall_numothads18, wave(`wi') numothads18(`numothads18') depkid(`depkid') age(`age')
        }
        if "`hbrooms'" != "" {
            indall_hbrooms, wave(`wi') hbrooms(`hbrooms') depkid(`depkid') age(`age') female(`female') `mindic'
        }

        if "`eqscale'" != "" {
            indall_eqscale, wave(`wi') eqscale(`eqscale') age(`age') `mindic'
        }

        if "`othvars'" != "" {
            drop `othvars'
        }
		
        sort `w'hidp `w'pno `w'buno_dv
		
    }

end

* Dependent child indicator
***************************



program define indall_depkid, rclass


    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars depkid(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_depchl_dv"
    }
    else {
        if "`depkid'" == "" local depkid "depkid"
        assert inlist(`w'_depchl_dv,1,2)
        gen byte `depkid' = (`w'_depchl_dv == 1)
        label variable `depkid' "Dependent child indicator"
    }

end



* Female indicator
******************

program define indall_female, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars female(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_sex"
    }
    else {
		
		*Obtain consistent sex from cross-wave file if possible
		merge 1:1 pidp using "$data/xwavedat", keepusing(sex_dv) 
		assert _merge==2|_merge==3 
		drop if _merge==2
		drop _merge
		replace `w'_sex = sex_dv if sex_dv>0
		drop sex_dv

        if "`female'" == "" local female "female"

        qui gen byte `female' = 1 if `w'_sex== 2
        qui replace `female' = 0 if `w'_sex == 1
        label variable `female' "Female indicator"

        if "`mindic'" == "mindic" {
            qui replace `female' = .a if inlist(`w'_sex,-1,-2,-3,-4,-8,-9) & `female' >= .
            label define `female' .a "sex invalid"
            assert (`female' != .)
            label values `female' `female'
        }

    }

end



* Couple indicator
******************

* indall_couple must be called AFTER indall_depkid (it uses depkid)

program define indall_couple, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars depkid(varname) couple(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`depkid'" == "" local depkid "depkid"
        if "`couple'" == "" local couple "couple"

        assert `w'_hidp > 0 & `w'_hidp < .
        assert `w'_buno_dv > 0 & `w'_buno_dv < .
        egen byte numads = total(!`depkid'), by(`w'_hidp `w'_buno_dv)
        gen byte `couple' = (numads == 2 & !`depkid')
        label variable `couple' "Couple indicator"
        drop numads

    }

end


* Married indicator
*******************

* indall_married must be called AFTER indall_depkid (it uses depkid)

program define indall_married, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars married(name) couple(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv `w'_mastat_dv"
    }
    else {

        if "`married'" == "" local married "married"
        if "`couple'" == "" local couple "couple"

        qui gen byte `married' = (`w'_mastat_dv == 2 & `couple' == 1) if (`w'_mastat_dv >= 0  | `couple' == 0)

        * count number of married people in BU
        egen byte nmarried = total(`married'), by(`w'_hidp `w'_buno_dv)
        assert inlist(nmarried,0,2)
        drop nmarried
        label variable `married' "married indicator"

        if "`mindic'" == "mindic" {
            qui replace `married' = .a if (`w'_mastat_dv < 0  & `couple' == 1 & `married' >= .)
            label define `married' .a "mastat invalid"
            assert (`married' != .)
            label values `married' `married'
        }
        return local newvars "`married'"

    }

end

* Partner's pid number
**********************

program define indall_ptrpid, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars couple(varname) depkid(varname) ptrpid(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_pno `w'_ppno"
    }
    else {

        if "`couple'" == "" local couple "couple"
        if "`ptrpid'" == "" local ptrpid "ptrpid"

        su `w'_pno, meanonly
        local maxpno = r(max)

        gen byte `ptrpid' = .

        forval i = 1/`maxpno' {
                qui bys `w'_hidp (`w'_pno): replace `ptrpid' = pid[`i'] if (`w'_ppno == `w'_pno[`i']) & (`i' <= _N)
        }

        qui replace `ptrpid' = . if couple == 0
        assert (`couple' == 0) + (`ptrpid' < .) == 1
        label variable `ptrpid' "Partner's personal identifier"

        if "`mindic'" == "mindic" {
            qui replace `ptrpid' = .a if `depkid'
            qui replace `ptrpid' = .b if !`depkid' & !`couple'
            label define `ptrpid' .a "Dependent" .b "Single"
            label values `ptrpid' `ptrpid'
            assert (`ptrpid' != .)
        }

    }

end


* Partner employment status
***************************

/*CRASHES AT THE ASSERT BECAUSE COUPLES THAT AREN'T MARRIED DON'T HAVE A HGPART NUMBER*/

program define indall_ptrempstat, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ptrempstat(name) couple(varname) depkid(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv `w'_pno `w'_ppno `w'_employ"
    }

    else {

        if "`ptrempstat'" == "" local ptrempstat "ptrempstat"
        if "`couple'" == "" local couple "couple"
        if "`depkid'" == "" local depkid "depkid"

        qui gen byte `ptrempstat' = .

        su `w'_pno, meanonly
        local maxpno = r(max)


        forval i = 1/`maxpno' {
                qui bys `w'_hidp (`w'_pno): replace `ptrempstat' = `w'_employ[`i'] if (`w'_ppno == `w'_pno[`i']) & (`i' <= _N)
        }

        qui replace `ptrempstat' = . if couple == 0
        assert (`couple' == 0) + (`ptrempstat' < .) == 1
        label define `ptrempstat' 1 "Employment" 2 "No employment"
        label values `ptrempstat' `ptrempstat'
        label variable `ptrempstat' "Partner employment status"

        if "`mindic'" == "mindic" {
            qui replace `ptrempstat' = .a if `depkid'
            qui replace `ptrempstat' = .b if !`depkid' & !`couple'
            qui replace `ptrempstat' = .c if !`depkid' & `couple' & `ptrempstat' == -1
            qui replace `ptrempstat' = .d if !`depkid' & `couple' & !inlist(`ptrempstat',-1,1,2)
            assert (`ptrempstat' != .)
            label define `ptrempstat' .a "Dependent" .b "Single" .c "employ unknown" .d "employ invalid", add
        }
        else qui replace `ptrempstat' = . if !inlist(`ptrempstat',1,2)

        return local newvars "`ptrempstat'"

    }

end



* Number of kids in benefit unit
********************************

* indall_numkids must be called AFTER indall_depkid (it uses depkid)

program define indall_numkids, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars numkids(name) depkid(varname)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`numkids'" == "" local numkids "numkids"
        if "`depkid'" == "" local depkid "depkid"

        egen byte `numkids' = total(`depkid'), by(`w'_hidp `w'_buno_dv)
        qui replace `numkids' = 0 if `depkid'
        label variable `numkids' "Number of kids"
        return local newvars "`numkids'"

    }

end


* Censored number of kids in benefit unit
*****************************************

* indall_nkids must be called AFTER indall_depkid (it uses depkid)

program define indall_nkids, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars nkids(name) depkid(varname)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`nkids'" == "" local nkids "nkids"
        if "`depkid'" == "" local depkid "depkid"

        egen byte `nkids' = total(`depkid'), by(`w'_hidp `w'_buno_dv)
        capture confirm variable numads
        if !_rc {
            bys `w'_hidp `w'_buno_dv: assert numads + `nkids' == _N
            drop numads
        }
        qui replace `nkids' = min(`nkids',2)
        qui replace `nkids' = 0 if `depkid'
        label define `nkids' 0 "0 kids" 1 "1 kid" 2 "2+ kids"
        label values `nkids' `nkids'
        label variable `nkids' "Censored number of kids"
        return local newvars "`nkids'"

    }

end

* Number of own children in household
*************************************

program define indall_ownkids, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ownkids(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_nchild_dv"
    }
    else {

        if "`ownkids'" == "" local ownkids "ownkids"

        qui gen int `ownkids' = `w'_nchild_dv
        label variable `ownkids' "Number of own children in household"

        return local newvars "`ownkids'"

    }

end


* Age
*****

program define indall_age, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars age(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_dvage"
    }
    else {

        if "`age'" == "" local age "age"

        qui gen int `age' = `w'_dvage if inrange(`w'_dvage,0,120)
        label variable `age' "Age"

        if "`mindic'" == "mindic" {
            qui replace `age' = .a if inlist(`w'_dvage,-1,-2,-3,-4,-8,-9)
                capture assert (`age' != .)
                if _rc==9 {
                di in red "there are missing ages (us_indallvars)"
                exit
                }
            label define `age' .a "age missing"
            label values `age' `age'
        }
        return local newvars "`age'"

    }

end


* Age band
**********

program define indall_ageband, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ageband(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_dvage"
    }
    else {

        if "`ageband'" == "" local ageband "ageband"

        qui gen byte `ageband' = 1 if inrange(`w'_dvage,25,39)
        qui replace `ageband' = 2 if inrange(`w'_dvage,40,54)
        qui replace `ageband' = 3 if inrange(`w'_dvage,16,24) | (`w'_dvage >= 55 & `w'_dvage < .)
        qui replace `ageband' = 4 if inrange(`w'_dvage,0,15)
        label define `ageband' 1 "25-39" 2 "40-54" 3 "16-24 or 55+" 4 "0-15"
        label values `ageband' `ageband'
        label variable `ageband' "Banded age"

        if "`mindic'" == "mindic" {
            qui replace `ageband' = .a if inlist(`w'_dvage,-1,-2,-3,-4,-8,-9)
            assert (`ageband' != .)
            label define `ageband' .a "age missing", add
            label values `ageband' `ageband'
        }
        return local newvars "`ageband'"

    }

end



* Age of youngest child in benefit unit
***************************************

program define indall_ageyng, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ageyng(name) age(varname) depkid(varname) numkids(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`ageyng'" == "" local ageyng "ageyng"
        if "`age'" == "" local age "age"
        if "`depkid'" == "" local depkid "depkid"
        if "`numkids'" == "" local numkids "numkids"

        tempvar tempageyng tempage_m
        qui egen int `tempageyng' = min(`age') if `depkid', by(`w'_hidp `w'_buno_dv)
        qui egen int `ageyng' = min(`tempageyng'), by(`w'_hidp `w'_buno_dv)
        qui egen byte `tempage_m' = total(`depkid' & `age' >= .), by(`w'_hidp `w'_buno_dv)
        qui replace `ageyng' = . if `tempage_m'
        qui replace `ageyng' = . if `depkid'
        label variable `ageyng' "Age of youngest child in BU"
        drop `tempageyng'

        if "`mindic'" == "mindic" {
            qui replace `ageyng' = .a if `depkid' & `ageyng' == .
            qui replace `ageyng' = .b if !`depkid' & `numkids' == 0 & `ageyng' == .
            qui replace `ageyng' = .c if !`depkid' & `numkids' > 0 & `numkids' < . & `tempage_m' & `ageyng' == .
            assert (`ageyng' != .)
            label define `ageyng' .a "Dependent child" .b "No dependent kids" .c "Missing age of dependent kid"
            label values `ageyng' `ageyng'
        }
        drop `tempage_m'
        return local newvars "`ageyng'"

    }

end




* Age of children in benefit unit
*********************************

program define indall_kidage, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars numkids(name) kidage(name) age(varname) depkid(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`kidage'" == "" local kidage "kidage"
        if "`age'" == "" local age "age"
        if "`depkid'" == "" local depkid "depkid"
        if "`numkids'" == "" local numkids "numkids"

        sort `w'_hidp `w'_buno_dv `w'_pno
        tempfile temp
        qui save `temp'
        qui keep if `depkid' == 1
        keep `w'_hidp `w'_buno_dv `age'
        bysort  `w'_hidp `w'_buno_dv (`age'): gen byte kidnum = _n
        qui reshape wide `age', i(`w'_hidp `w'_buno_dv) j(kidnum)
        foreach var of varlist `age'* {
            if regexm("`var'","age([0-9]+)") {
                local num = regexs(1)
                label variable `var' "Age of child `num'"
                rename `var' kid`var'
            }
        }

        tempfile temp2
        qui save `temp2'
        use `temp'
        qui merge `w'_hidp `w'_buno_dv using `temp2', uniqusing
        assert _merge != 2
        drop _merge

        if "`mindic'" == "mindic" {
        qui su `numkids', meanonly
        local maxkids = `r(max)'
        label define `kidage' .a "age missing" .b "No kid"
        forval i = 1/`maxkids' {
            replace `kidage'`i' = .b if `numkids'<=`i'-1 & `kidage'`i' ==.
            label values `kidage'`i' `kidage'
        }
        foreach var of varlist `kidage'* {
            assert `var'!=.
        }

        }

    }

end


* Number of children aged 12 or under adult is responsible for
**************************************************************

program define indall_numleq12resp, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars numleq12resp(name) age(varname)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_pno `w'_adresp15_dv"
    }
    else {

        if "`numleq12resp'" == "" local numleq12resp "numleq12resp"
        if "`age'" == "" local age "age"

        *assert (`w'_hgra > 0 & `w'_hgra < .) if inrange(`age',0,12)

        qui gen byte `numleq12resp' = .
        qui su `w'_adresp15_dv, meanonly
        local maxra = `r(max)'
        forval i = 1/`maxra' {
            egen byte `numleq12resp'`i' = total(`w'_adresp15_dv == `i' & inrange(`age',0,12)), by(`w'_hidp)
            qui replace `numleq12resp' = `numleq12resp'`i' if `w'_pno == `i'
            drop `numleq12resp'`i'
        }
        qui replace `numleq12resp' = 0 if `numleq12resp' >= .
*        assert (`age' >= 16) if (`numleq12resp' > 0 & `numleq12resp' < .)
        label variable `numleq12resp' "Number of kids <= 12 adult is responsible for"
        return local newvars "`numleq12resp'"

    }

end



* Indicator for parent in household
***********************************

program define indall_parentinhh, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars parentinhh(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_adresp15_dv `w'_hgbiom `w'_hgbiof `w'_hgadoptf `w'_hgadoptm"
    }
    else {

        if "`parentinhh'" == "" local parentinhh "parentinhh"

        * use responsible adult, father number, mother number
        gen byte `parentinhh' = (inrange(`w'_adresp15_dv,1,50) | inrange(`w'_hgbiom,1,50) | inrange(`w'_hgbiof,1,50)| inrange(`w'_hgadoptf,1,50)| inrange(`w'_hgadoptm,1,50))
        label variable `parentinhh' "Parent/responsible adult in HH"
        return local newvars "`parentinhh'"

    }

end






* Indicator for both parents of all depkids are still in HH
***********************************************************

* This is to help eliminate missing maintenance information (we will assume 0 maintenance if all natural parents present)

program define indall_parentsinhh, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars parentsinhh(name) depkid(varname) numkids(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv `w'_hgbiom `w'_hgbiof"
    }
    else {

        if "`parentsinhh'" == "" local parentsinhh "parentsinhh"
        if "`depkid'" == "" local depkid "depkid"
        if "`numkids'" == "" local numkids "numkids"


        * 0 for <=12 with hgmno or hgfno missing; 1 otherwise
        gen byte `parentsinhh'temp = 1
        qui replace `parentsinhh'temp = 0 if `depkid' == 1 & !(inrange(`w'_hgbiom,1,50) | inrange(`w'_hgbiof,1,50))
        * Copy minimum across BU
        egen byte `parentsinhh' = min(`parentsinhh'temp), by(`w'_hidp `w'_buno_dv)
        * Set missing if depkid or if depkids bu
        qui replace `parentsinhh' = . if `depkid' == 1 | `numkids' == 0

        if "`mindic'" == "mindic" {
            qui replace `parentsinhh' = .a if `depkid' == 1 & `parentsinhh' == .
            qui replace `parentsinhh' = .b if `numkids' == 0 & `parentsinhh' == .
            label define `parentsinhh' .a "dependent child" .b "no dependent children in BU"
            label values `parentsinhh' `parentsinhh'
        }

        label variable `parentsinhh' "All dependent kids in this BU have both natural parents in household"
        drop `parentsinhh'temp
        return local newvars "`parentsinhh'"

    }

end



* pid indicators for parents in household
*****************************************
/* Updated David Sturrock August 2018: Should now work. Note that using BHPS-style variable on relationships (w_rel_dv). More info in w_relationship. */

program define indall_parentpids, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars dadpid(name) mumpid(name) dadpidp(name) mumpidp(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars ""
    }
    else {

        if "`dadpid'" == "" local dadpid "dadpid"
        if "`mumpid'" == "" local mumpid "mumpid"
		if "`dadpidp'" == "" local dadpidp "dadpidp"
        if "`mumpidp'" == "" local mumpidp "mumpidp"

        tempfile currdata piddata
        qui save `currdata'

        qui use `w'_hidp `w'_pno `w'_rel_dv `w'_asex apidp apid if inlist(`w'_rel_dv,13,14,16,25) using "$data\\`w'_egoalt.dta"

        * Keep best mother and father relationships

        * Order: 1=natural parent, 2=other parent, 3=step parent, 4=grand parent
        gen byte order = (`w'_rel_dv==13) + 2*(`w'_rel_dv==14) + 3*(`w'_rel_dv==25) + 4*(`w'_rel_dv==16)
        qui bys `w'_hidp `w'_pno `w'_asex (order): keep if _n==1
        drop `w'_rel_dv
		recode `w'_asex -9/-1 = 99	// some cases of missing sex. recode and drop as otherwise code crashes
		drop if `w'_asex == 99
		
		if `wave' !=1 {
			qui reshape wide apidp apid order, i(`w'_hidp `w'_pno) j(`w'_asex)
			rename order1 dad_relation
			rename order2 mum_relation
			rename apid1 `dadpid'
			rename apid2 `mumpid'
			label variable `dadpid' "Father pid"
			label variable `mumpid' "Mother pid"
			rename apidp1 `dadpidp'
			rename apidp2 `mumpidp'
			label variable `dadpidp' "Father pidp"
			label variable `mumpidp' "Mother pidp"
			label define parent_type 1 "Natural" 2 "Other" 3 "Step-parent" 4 "Grand parent"
			label values dad_relation parent_type
			label values mum_relation parent_type
			sort `w'_hid `w'_pno
			qui save `piddata'

			use `currdata'
			sort `w'_hidp `w'_pno
			merge `w'_hidp `w'_pno using `piddata', unique
			assert _merge != 2
			drop _merge

			if "`mindic'" == "mindic" {
				qui replace `dadpid' = .a if `dadpid' == .
				qui replace `mumpid' = .a if `mumpid' == .
				qui replace `dadpid' = .b if `dadpid' == -8
				qui replace `mumpid' = .b if `mumpid' == -8
				label define `dadpid' .a "No father present" .b "No BHPS identifier"
				label define `mumpid' .a "No mother present" .b "No BHPS identifier"
				label values `dadpid' `dadpid'
				label values `mumpid' `mumpid'
				qui replace `dadpidp' = .a if `dadpidp' == .
				qui replace `mumpidp' = .a if `mumpidp' == .
				label define `dadpidp' .a "No father present"
				label define `mumpidp' .a "No mother present"
				label values `dadpidp' `dadpidp'
				label values `mumpidp' `mumpidp'
			}
		}
		* in wave 1, no pid so need to write code without this and then create missing parentspid vars *
		else { 
			qui reshape wide apidp order, i(`w'_hidp `w'_pno) j(`w'_asex)
			rename order1 dad_relation
			rename order2 mum_relation
			rename apidp1 `dadpidp'
			rename apidp2 `mumpidp'
			label variable `dadpidp' "Father pidp"
			label variable `mumpidp' "Mother pidp"
			label define parent_type 1 "Natural" 2 "Other" 3 "Step-parent" 4 "Grand parent"
			label values dad_relation parent_type
			label values mum_relation parent_type
			sort `w'_hid `w'_pno
			qui save `piddata'

			use `currdata'
			sort `w'_hidp `w'_pno
			merge `w'_hidp `w'_pno using `piddata', unique
			assert _merge != 2
			drop _merge

			if "`mindic'" == "mindic" {
				qui gen `dadpid' = .a 
				qui gen `mumpid' = .a if `mumpid' == .
				label define `dadpid' .a "No father present" .b "No BHPS identifier"
				label define `mumpid' .a "No mother present" .b "No BHPS identifier"
				label values `dadpid' `dadpid'
				label values `mumpid' `mumpid'
				qui replace `dadpidp' = .a if `dadpidp' == .
				qui replace `mumpidp' = .a if `mumpidp' == .
				label define `dadpidp' .a "No father present"
				label define `mumpidp' .a "No mother present"
				label values `dadpidp' `dadpidp'
				label values `mumpidp' `mumpidp'
			}
		}	
		
        return local newvars "`dadpid' `mumpid' dadpidp' `mumpidp'"

    }

end






* Number of other adults in the household (i.e. in other benefit units)
***********************************************************************

program define indall_numothads, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars numothads(name) depkid(varname)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`numothads'" == "" local numothads "numothads"
        if "`depkid'" == "" local depkid "depkid"

        egen byte numadsbu = total(!`depkid'), by(`w'_hidp `w'_buno_dv)
        egen byte numadshh = total(!`depkid'), by(`w'_hidp)

        gen byte `numothads' = numadshh - numadsbu
        label variable `numothads' "No. of adults in other BUs"
        drop numadshh numadsbu

    }

end


* Number of other adults in the household aged 18+ (i.e. in other benefit units)
********************************************************************************

program define indall_numothads18, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars numothads18(name) depkid(varname) age(varname)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`numothads18'" == "" local numothads18 "numothads18"
        if "`depkid'" == "" local depkid "depkid"
        if "`age'" == "" local age "age"

        egen byte numadsbu = total(!`depkid' & `age' >= 18), by(`w'_hidp `w'_buno_dv)
        egen byte numadshh = total(!`depkid' & `age' >= 18), by(`w'_hidp)

        gen byte `numothads18' = numadshh - numadsbu
        label variable `numothads18' "No. of adults 18+ in other BUs"
        drop numadshh numadsbu

    }

end



* Number of rooms allowed for housing benefit
*********************************************

program define indall_hbrooms, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hbrooms(name) depkid(varname) age(varname) female(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_buno_dv"
    }
    else {

        if "`hbrooms'" == "" local hbrooms "hbrooms"
        if "`age'" == "" local age "age"
        if "`female'" == "" local female "female"
        if "`depkid'" == "" local depkid "depkid"

        gen byte room = 0
        gen byte done = 0

        * 1 room for each couple or single non-dependent adult
        bys `w'_hidp `w'_buno_dv: gen byte sumads = sum(`depkid' == 0)
        qui replace room = 1 if sumads == 1 & `depkid' == 0
        qui replace done = 1 if `depkid' == 0
        drop sumads

        * Now one room for each dependent 16+
        qui replace room = 1 if (`depkid' == 1 & `age' >= 16 & `age' < .)
        qui replace done = 1 if (`depkid' == 1 & `age' >= 16 & `age' < .)

        * One room for two children (<=15) of same sex (I think this is in the HOUSEHOLD rather than the BU)
        * Number of male children in hh
        gen int negage = -`age'
        egen byte mkids = total(`depkid' == 1 & `age' <= 15 & `female' == 0), by(`w'_hidp)
        bys `w'_hidp (negage): gen byte summkids = sum(`depkid' == 1 & `age' <= 15 & `female' == 0)
        qui replace summkids = 0 if !(`depkid' == 1 & `age' <= 15 & `female' == 0)
        qui replace room = 1 if inrange(summkids,1,int(mkids/2))
        qui replace done = 1 if inrange(summkids,1,int(mkids/2)*2)
        drop mkids summkids
        * Number of female children in hh
        egen byte fkids = total(`depkid' == 1 & `age' <= 15 & `female' == 1), by(`w'_hidp)
        bys `w'_hidp (negage): gen byte sumfkids = sum(`depkid' == 1 & `age' <= 15 & `female' == 1)
        qui replace sumfkids = 0 if !(`depkid' == 1 & `age' <= 15 & `female' == 1)
        qui replace room = 1 if inrange(sumfkids,1,int(fkids/2))
        qui replace done = 1 if inrange(sumfkids,1,int(fkids/2)*2)
        drop fkids sumfkids negage

        * One room for two children <=9 (at HH level)
        egen byte kidsu10 = total(`depkid' == 1 & `age' <= 9 & done == 0), by(`w'_hidp)
        bys `w'_hidp: gen byte sumkidsu10 = sum(`depkid' == 1 & `age' <= 9 & done == 0)
        qui replace sumkidsu10 = 0 if !(`depkid' == 1 & `age' <= 9 & done == 0)
        qui replace room = 1 if inrange(sumkidsu10,1,int(kidsu10/2))
        qui replace done = 1 if inrange(sumkidsu10,1,int(kidsu10/2)*2)
        drop kidsu10 sumkidsu10

        * One room for any remaining children
        qui replace room = 1 if done == 0
        qui replace done =1 if done == 0

        egen byte `hbrooms' = total(room), by(`w'_hidp)
        drop room done

        * Deal with missing age (age only matters for dependent kids) and sex (sex only matters if 10<=age<=15)
        egen byte missage = max(`age' >= . & `depkid' == 1), by(`w'_hidp)
        egen byte misssex = max(`female' >= . & `age' >= 10 & `age' <= 15), by(`w'_hidp)
        qui replace `hbrooms' = . if missage == 1 | misssex == 1

        * Now additional rooms according to family size: 1 more for 1-3 people, 2 more for 4-6 and 3 more for 7+
        bys `w'_hidp: gen byte hhsize = _N
        qui replace `hbrooms' = `hbrooms' + 1 + (hhsize >= 4) + (hhsize >= 7)
        drop hhsize

        label variable `hbrooms' "No. rooms allowed for HB"

        if "`mindic'" == "mindic" {
            qui replace `hbrooms' = .a if missage == 1 & `hbrooms' == .
            qui replace `hbrooms' = .b if misssex == 1 & `hbrooms' == .
            assert (`hbrooms' != .)
            label define `hbrooms' .a "age missing (depkid)" .b "sex missing (age 10-15)"
            label values `hbrooms' `hbrooms'
        }

        drop missage misssex

    }

end

* Modified OECD Equivalence scale
********************************

program define indall_eqscale, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars eqscale(name) age(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars ""
    }
    else {

        if "`eqscale'" == "" local eqscale "eqscale"
        if "`age'" == "" local age "age"

        qui gen under14 = age<14
        qui egen byte numover14  = total(!under14), by(`w'_hidp)
        qui egen byte numunder14 = total(under14), by(`w'_hidp)
  
        if !inlist(`wave',7,8) {
            *one hh in 7 has no adults (and one 7 y/o) (PL 06/01/2020)
            *one hh in wave 1 has one 1 y/o
            assert numover14>=1 
        }


        qui gen `eqscale' = 0.67+(numover14-1)*0.33 + numunder14*0.2
        label variable `eqscale' "Modified OECD equivalence scale for HH (1 is couple)"

        drop numover14 numunder14

        if "`mindic'" == "mindic" {
            assert (`eqscale'!=.)
        }
    }

end

exit
