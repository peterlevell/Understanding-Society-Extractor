/*

**************DESCRIPTION***********************************************************************************************

FILE:           us_xwave_vars.ado
PURPOSE:        Programs to extract variables from the official UKHLS cross-wave file (xwavedat.dta)
                and merge them into an individual-level dataset by pidp.
AUTHOR:         Peter Levell
THIS VERSION:   27/03/26

DETAILS:        You're most likely to want to call this from usextract via the wavedatoptions() option,
                or call us_xwave_vars directly after building a wave-level dataset.

                Each sub-program follows the same pattern as us_indresp_vars etc:
                    - whatvars branch: returns the raw xwavedat variables needed
                    - main branch:     creates the derived variable and labels it
                    - mindic option:   uses extended missing values to explain missingness

TYPICAL USE:
                us_xwave_vars, rawvars(pid) mindic

VARIABLES AVAILABLE: (none yet)

**************LOG*******************************************************************************************************

23/3/2026        Created by PSL

**************NOTES*****************************************************************************************************

The xwavedat file is identified at the individual level by pidp only (no wave dimension).
It is merged 1:1 on pidp into the calling dataset, which must already contain pidp.

************************************************************************************************************************
*/


************************************************************************************************************************
* Driver program                                                                                                       *
************************************************************************************************************************

program define us_xwave_vars

    # delimit;
    syntax,     [
                mindic
				rawvars(namelist)
                neednotexist
                ];
    # delimit cr
	
	local xwavevars ""

    * Find out what raw variables are required
    ******************************************

    local idvars "pidp"
    local rawvars : list idvars | rawvars

    local othvars ""
    foreach xwavevar of local xwavevars {
        if "``xwavevar''" != "" {
            xwave_`xwavevar', whatvars
            local othvars "`othvars' `r(vars)'"
        }
    }
    local othvars : list uniq othvars
    local othvars : list othvars - rawvars

    * Open xwavedat and create variables
    *************************************
    if (`: list rawvars === idvars' & "`othvars'" == "") {
        * Nothing to do
    }
    else {
        * Open required variables from xwavedat
        use `rawvars' `othvars' using "$data\xwavedat.dta", clear

        * Create derived variables
        foreach xwavevar of local xwavevars {
            if "``xwavevar''" != "" {
                xwave_`xwavevar', `xwavevar'(``xwavevar'') `mindic'
            }
        }
		
        * Drop raw variables that are not in the final output
        if "`othvars'" != "" drop `othvars'

    }

end



