/*

**************DESCRIPTION***********************************************************************************************

FILE:       	us_hhresp_vars.ado
PURPOSE:    	Lots of individual programs, each one setting up a particular variable from  Understanding Society hhsamp dataset
AUTHOR:     	Peter Levell (based on BHPS version by Jonathan Shaw)

THIS VERSION:   06/12/2014
DETAILS:	You're most likely to want to use "variable programs - driver.do", which calls programs from this file.

TYPICAL USE:

**************LOG*******************************************************************************************************

03/12/2014      - Created

**************NOTES*****************************************************************************************************

[Date]				[Note]

************************************************************************************************************************
*/

program define us_hhsamp_vars

    # delimit;
    syntax,                     wave(numlist integer max=1 >=1 <=$numwaves)
                                [
                                htype(name)
                                rawvars(namelist)
								neednotexist
                                mindic
                                ];

    # delimit cr

    local hhsampvars "htype"

    local wi = `wave'
    local w = char(96+`wi') + "_"


    * Find out what raw variables are required
    ******************************************

    local idvars "`w'hidp"
    local rawvars : list idvars | rawvars

    local othvars ""
    foreach hhsampvar of local hhsampvars {
        if "``hhsampvar''" != "" {
            hhsamp_`hhsampvar', wave(`wi') whatvars
            local othvars "`othvars' `r(vars)'"
        }
    }
    local othvars : list uniq othvars
    local othvars : list othvars - rawvars


    * Create variables
    ******************

    if (`: list rawvars === idvars' & "`othvars'" == "") {
    }
    else {

        * Open variables
        useundersoc `rawvars' `othvars' using "$data\\`w'hhsamp.dta", clear `neednotexist'

        * Create finished variables
        if "`htype'" != "" {
            hhsamp_htype, wave(`wi') htype(`htype') `mindic'
        }

        if "`othvars'" != "" {
            drop `othvars'
        }
        sort `w'hidp

    }

end

*************
*-----------*
*- Housing -*
*-----------*
*************

* Type of accommodation
***********************

program define hhsamp_htype, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars htype(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' < 7) return local vars "`w'_dweltyp"
        if (`wave' >= 7) return local vars "`w'_dweltyp `w'_ff_all_moved"
    }
    else {

        if "`htype'" == "" local htype "htype"

        qui gen byte `htype' = `w'_dweltyp if inlist(`w'_dweltyp,1,2,3)
        qui replace `htype' = 3 if `w'_dweltyp==4
        qui replace `htype' = 4 if inlist(`w'_dweltyp,5,6)
        qui replace `htype' = 5 if inlist(`w'_dweltyp,7,8)
        qui replace `htype' = 6 if `w'_dweltyp==9
        qui replace `htype' = 7 if inrange(`w'_dweltyp,10,12)
        qui replace `htype' = 8 if (`w'_dweltyp==97|`w'_dweltyp==15)
        qui replace `htype' = 9 if inlist(`w'_dweltyp,13,14)

        label variable `htype' "Type of accommodation"
        label define `htype' 1 "Detached" 2 "Semi-detatched" 3 "Terraced" 4 "Purpose-built flat" 5 "Converted flat" 6 "Business premises" 7 "Bedsit" 8 "Other" 9 "Institutional"
        label values `htype' `htype'

        if "`mindic'" == "mindic" {
        qui replace `htype' = .a if inlist(`w'_dweltyp,-1,-2,-7,-9) & `htype' == .
        if (`wave'==6) {
            qui replace `htype' = .b if `w'_dweltyp==16 & `htype' == .
        }

        if (`wave'>=7) {
            qui replace  `htype' = .c if `w'_dweltyp==-8 & `htype' == .
        }

        assert (`htype' != .)

        label define `htype' .a "hstype invalid" .b "house type unknown (dweltyp ==16)" .c "dweltyp asked in previous wave", add
        }

    }

end
