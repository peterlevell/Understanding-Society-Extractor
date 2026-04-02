/*

**************DESCRIPTION***********************************************************************************************

FILE:       	sort bhps buno etc.do
PURPOSE:    	This program sorts out benefit unit number using the indall dataset
AUTHOR:     	Peter Levell (based on bhps extractor by Jonathan Shaw)
THIS VERSION:   08/2022


DETAILS:			The key program is useundersoc. The things it does are:
							* 1. Puts partners in the same buno
							* 2. Puts children 0-15 in the same buno as their responsible adult
							* 3. Puts dependents 16-18 in the same buno as their mother or (if mother is absent) father
							* 4. Deals with benefit units that contain no non-dependents
							* 5. Checks that there are either 1 or 2 non-dependents in each benefit unit
							* 6. Checks that bunos with 2 non-dependents are couples
							* It also makes a few changes to responsible adult number
							* And you can get it to drop the `w' prefix

							* What useundersoc program should do:
								* if buno is specified when opening indresp or indall, clean up buno
								* if responsible adult is specified, minor changes made
								* deal with missing interview date
								* create doiy4 and hhyoi4 variables for wave 1

							* After this program is run, you can be confident that:
								* 1.  hid, pno and buno are non-missing
								* 2.  Partners are in the same benefit unit as each other
								* 3.  Partners have the same marital status as each other and spouse numbers are consistent
								* 4.  Dependent child indicator is never missing
								* 5.  Age is consistent with dependent child indicator (in a VERY small number of cases, age is missing (remember also that raw variable is imputed))
								* 6.  For children 0-15, responsible adult number equals mother number (if present) or father/father's partner number (if present but mother not)
											* Note: not all children have a responsible adult
								* 7.  Responsible adult number is always 0 for anyone 16+
								* 8.  Children 0-15 are always in the same benefit unit as their responsible adult
								* 9.  Dependents 16-18 are always in the same benefit unit as their mother if present, or father if mother is not present but father is
								* 10. Almost all dependents are in a benefit unit that contains at least one adult (non-dependent)
								* 11. Benefit units contain no more than 2 adults
								* 12. Adults in two-adult benefit units are couples


TYPICAL USE:  useundersoc [varlist] using "$data\\`w'indall.dta", clear


**************LOG*******************************************************************************************************

08/08/22 PL ADDED WAVES J AND K, Changes to the way inconsistent relationships are corrected

**************NOTES*****************************************************************************************************


************************************************************************************************************************

*/

**********************************************************************
* fnameinfo: return file name, wave, wave prefix and BHPS identifier *
**********************************************************************
* Syntax:
	* using = file path

capture program drop fnameinfo
program define fnameinfo

    syntax using/

		* Look for file names with a file extension
    if regexm(`"`using'"',`"([^\\/:*?"<>|]+)(\.[a-zA-Z0-9]+)$"') {
        local fname "`=regexs(1)'`=regexs(2)'"
    }
		* Look for file names without a file extension
    else if regexm(`"`using'"',`"([^\\/:*?"<>|]+)$"') {
        local fname = regexs(1)
    }
		* Invalid file names
    else {
        di as error "file info could not be determined"
        exit 198
    }

    * Store wave letter
    local w = substr("`fname'",1,1)
    local w "`w'_"

    * Recover wave number
    wave `w', locname(wave)

    c_local w "`w'"
    c_local wave = `wave'
    c_local fname "`fname'`ext'"

end

***********************************************
* wave: work out wave number from wave letter *
***********************************************
* Syntax:
	* name    = wave letter/prefix (e.g. q or q_)
	* locname = name of local in which to store the wave number

capture program drop wave
program define wave

    syntax name(name=w) [, locname(name local)]

		* Recover just wave letter (i.e. remove "_" if Understanding Society)
		local wlet = substr("`w'",1,1)

		* Check wave letter is valid
    if !regexm("`wlet'","[a-z]") {
        di as error "unknown wave prefix `w'"
        exit 198
    }

		* Recover wave number and write to local namespace of calling program
    if "`locname'" == "" local locname wave
    local alpha = c(alpha)
    c_local `locname' : list posof "`wlet'" in alpha

end


****************************************************
* addw: add the wave letter to a list of variables *
****************************************************

* Syntax
	* namelist = list of variable names to add a wave letter to
	* w        = wave prefix (e.g. q or q_)
	* locname  = name of local to return modified varlist in

capture program drop addw
program define addw

    syntax namelist, w(name) [locname(name local)]

		* Matches lower-case wave letter followed by optional underscore (for Understanding Society)
    if !regexm("`w'","^[a-z]_?$") {
        di as error "unknown wave letter `w'"
        exit 198
    }
    if "`locname'" == "" local locname wnamelist

    foreach var of local namelist {
        if inlist("`var'","pid","pidp") local wnamelist "`wnamelist' `var'"
        else local wnamelist "`wnamelist' `w'`var'"
    }
    c_local `locname' : list retok wnamelist

end



*********************************************************
* cutw: remove the wave letter from a list of variables *
*********************************************************

* Syntax
	* namelist = list of variable names to remove a wave letter from
	* w        = wave prefix (e.g. q or q_)
	* locname  = name of local to return modified varlist in

capture program drop cutw
program define cutw

    syntax namelist(name=wnamelist), w(name) [locname(name local)]

		* Matches lower-case wave letter followed by optional underscore (for Understanding Society)
    if !regexm("`w'","^[a-z]_?$") {
        di as error "unknown wave letter `w'"
        exit 198
    }
    if "`locname'" == "" local locname namelist

    foreach var of local wnamelist {
        if regexm("`var'","^`w'(.+)") {
            local namelist "`namelist' `=regexs(1)'"
        }
        else {
            local namelist "`namelist' `var'"
        }
    }
    c_local `locname' : list retok namelist

end



***************************************************************************
* unabnew: unabbreviate a varlist, without the variables needing to exist *
***************************************************************************

* It was created to allow other commands to have a syntax like what is permitted for de [varlist] using

* Syntax
	* tounab   = varlist to unabbreviate
	* allvars  = list of all possible variables
	* filename = file name (not sure what we need this for, except labelling errors!)
	* locname  = name of local to return expanded varlist in

capture program drop unabnew
program define unabnew

    syntax, tounab(string asis) allvars(namelist) filename(string) locname(name local) [neednotexist]

    foreach mask of local tounab {

        local varsthisloop ""

        * Check whether `mask' refers to only one variable
        capture confirm name `mask'

        * If `mask' does refer to only one variable...
        if !_rc {
            foreach var of local allvars {
                if "`var'" == `"`mask'"' {
                    local varsthisloop "`var'"
                    continue, break
                }
            }
            if "`varsthisloop'" == "" & "`neednotexist'" == "" {
                di as error `"variable `mask' not found in file `filename'"'
                exit 111
            }
        }

        * If `mask' contains wildcard characters (*, ? or ~)...
        else {
            * replace "~" with "*" in mask (because "~" isn't recognised in strmatch())
            local tilde = regexm("`mask'","~")
            if `tilde' {
                local newmask = subinstr("`mask'","~","*",.)
            }
            else local newmask "`mask'"
            foreach var of local allvars {
                if strmatch("`var'","`newmask'") local varsthisloop "`varsthisloop' `var'"
            }
			
			if "`neednotexist'" == "" {
				local numvars : list sizeof varsthisloop
				if `numvars' == 0 {
					di as error `"no variables found matching `mask' in file `filename'"'
					exit 111
				}
				else if `numvars' > 1 & `tilde' {
					di as error `"`mask' matches more than one variable in file `filename'"'
					exit 111
				}
			}
        }

        local varlist "`varlist' `varsthisloop'"

    }

    local varlist : list uniq varlist
    c_local `locname' "`varlist'"

end




**********************************************************
* useundersoc: open usoc dataset and sort out buno, etc  *
**********************************************************

capture program drop useundersoc
program define useundersoc

    * Sort syntax
		* -----------
 
    capture syntax [anything] [if] [in] using/ [, clear ivars withoutw dropw neednotexist]
    if _rc {
        * Alternative syntax (like the syntax for use)
        syntax anything [, clear ivars dropw neednotexist]
        local using `anything'
        local anything ""
    }

		* `anything' now contains variable list (blank if no varibles listed)


    * Create list of required variables
		* ---------------------------------

		* Recover file name, wave, wave prefix and BHPS identifier
        fnameinfo using `"`using'"'

		qui de using `"`using'"', short varlist

		* If no variable list specified
		if `"`anything'"' == "" {
        local varlist `"`r(varlist)'"'
        local adoiy4 = ((`wave' == 1) & regexm("`fname'","^`w'indresp"))
        local ahhyoi4 = ((`wave' == 1) & regexm("`fname'","^`w'hhresp"))
    }
	
		* If variable list specified
    else {
        * If variables have been listed without the wave prefix, then add it
        if "`withoutw'" == "withoutw" {
            addw `anything', w(`w') locname(anything)
        }
        if ((`wave' == 1) & regexm("`fname'","^`w'(ind|hh)resp")) {
            if regexm("`fname'","^`w'indresp") {
                local mvar "adoiy4"
                local ahhyoi4 = 0
            }
            else {
                local mvar "ahhyoi4"
                local adoiy4 = 0
            }

            unabnew, tounab(`anything') allvars(`r(varlist)' `mvar') filename(`using') locname(varlist) `neednotexist'
            local `mvar' = (`: list posof "`mvar'" in varlist' > 0)

            if ``mvar'' {
                local varlist : list varlist - mvar
                local mvar ""
            }
        }
        else {
            unabnew, tounab(`anything') allvars(`r(varlist)') filename(`using') locname(varlist) `neednotexist'
            local adoiy4 = 0
            local ahhyoi4 = 0
        }
    }
	

    * At this stage we have:
        * `varlist' lists variables to be opened
        * `using' contains the filename
				* `isbhps' identifies whether to open BHPS or Understanding Society
        * `if' and `in' contain appropriate conditions if specified
        * `w' contains the wave letter
        * `wave' contains wave number
        * `adoiy4' contains 1 (if adoiy4 must be created) or 0 (if not)
        * `ahhyoi4' contains 1 (if ahhyoi4 must be created) or 0 (if not)

    di as text _n %30s "Vars fixed and reason" " {c |} " " Freq"
    di as text "{hline 31}{c +}{hline 6}"
    local first = 1

    * Do buno first and save it in a tempfile (this is because buno always needs to come from indall)
    local fixbuno = (`: list posof "`w'buno_dv" in varlist' > 0)
    if `fixbuno' {

        varsforbuno, wave(`wave')
        use `varsforbuno' using "$data\\`w'indall.dta", `clear'
        fixbuno, wave(`wave')

        keep `w'hidp `w'pno `w'buno_dv bunoi noadsbuno `w'sex
        sort `w'hidp `w'pno
        tempfile bunofile
        qui save `bunofile', replace

        local buno `w'buno_dv
        local varlist : list varlist - buno
        local first = 0
    }

    * Find out which variables are needed to deal with `w'mastat_dv `w'dvage `w'adresp15_dv and `w'depchl_dv
    foreach var in mastat_dv dvage adresp15_dv depchl_dv {
        local fix`var' = (`: list posof "`w'`var'" in varlist' > 0)
        if `fix`var'' {
            varsfor`var', wave(`wave') `=cond("`var'" == "adresp15_dv" & regexm("`fname'","^`w'indall"),"indall","")'
            local othvars : list othvars | varsfor`var'
        }
    }

    local othvars : list othvars - varlist

    use `varlist' `othvars' `if' `in' using `"`using'"', `clear'

    * Deal with `w'mastat_dv `w'dvage `w'adresp15_dv and `w'depchl_dv
    foreach var in mastat_dv dvage adresp15_dv depchl_dv {
        if `fix`var'' {
            if !`first' di as text "{hline 31}{c +}{hline 6}"
            if "`var'" == "depchl_dv" fixdepchl_dv, wave(`wave') `=cond(`fixdvage',"","fixdvage")'
            else fix`var', wave(`wave')
            local tokeep "`tokeep' `var'i"
            local first = 0
        }
    }

    if `fixbuno' {
        sort `w'hidp `w'pno
        qui merge `w'hidp `w'pno using `bunofile', nokeep
        *assert _merge == 3
        drop _merge
        keep `varlist' `w'buno_dv `=cond("`ivars'" == "ivars","`tokeep'","")'
        order `w'hidp `w'pno `w'buno_dv
    }
    else {
        keep `varlist' `=cond("`ivars'" == "ivars","`tokeep'","")'
    }

    foreach mvar in adoiy4 ahhyoi4 {
        if ``mvar'' {
            gen int `mvar' = 1991
            label variable `mvar' "date of interview: year"
        }
    }

    if `first' di as text %30s "(none)" " {c |} "
    di as text "{hline 31}{c BT}{hline 6}"

    * Remove wave prefix
    if "`dropw'" == "dropw" renpfix `w'

end


capture program drop varsforadresp15_dv
program define varsforadresp15_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [indall]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    if "`indall'" == "indall" c_local varsforadresp15_dv "`w'hidp `w'pno `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof `w'depchl_dv `w'mastat_dv `w'ppno"
    else c_local varsforadresp15_dv "`w'hidp `w'pno `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof"

end

capture program drop fixadresp15_dv
program define fixadresp15_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [indall]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "hgra" " {c |} "

    gen byte hgrai = 0
    label variable hgrai "Responsible adult number changed"

    qui gen under15 = inrange(`w'dvage,0,15)| (`w'dvage<0 & `w'ivfio==24)

    qui count if under15 & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    qui replace hgrai = 1 if under15 & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    qui replace `w'adresp15_dv = `w'hgbiom if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    di as text %30s "missing --> mother" " {c |} " as res %5.0g r(N)

    qui count if under15 & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    qui replace hgrai = 1 if under15 & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    qui replace `w'adresp15_dv = `w'hgbiom if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    di as text %30s "non-missing --> mother" " {c |} " as res %5.0g r(N)

    qui count if under15 & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    qui replace hgrai = 1 if under15 & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    qui replace `w'adresp15_dv = `w'hgbiof if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    di as text %30s "missing --> father" " {c |} " as res %5.0g r(N)

    qui count if under15 & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    qui replace hgrai = 1 if under15 & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    qui replace `w'adresp15_dv = `w'hgbiof if under15 & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    di as text %30s "non-missing --> father" " {c |} " as res %5.0g r(N)

    qui count if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    qui replace hgrai = 1 if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    qui replace `w'adresp15_dv = 0 if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    di as text %30s "non-missing --> 0 (>=16)" " {c |} " as res %5.0g r(N)

    *some additional fixes (PL 11/01/17)
    *assign children same responsible adult as other children in the household (if there is only one)
    qui egen maxadresp = max(`w'adresp15_dv), by(`w'hidp)
    qui egen minadresp1 = min(`w'adresp15_dv) if `w'adresp15_dv>0, by(`w'hidp)
    qui egen minadresp = min(minadresp1), by(`w'hidp)
    drop minadresp1

    qui replace hgrai = 1 if maxadresp==minadresp & `w'adresp15_dv<0 & `w'depchl_dv==1 & maxadresp>0 & under15==1
    qui replace `w'adresp15_dv = maxadresp if maxadresp==minadresp & `w'adresp15_dv<0 & `w'depchl_dv==1 & maxadresp>0 & under15==1

    drop maxadresp minadresp

    *assign children to the only adult in the household if there is only one
    qui egen numads = total(`w'depchl_dv == 2), by(`w'hidp)
    qui gen adpnotemp = `w'pno if `w'depchl_dv == 2 & numads==1
    qui egen adpno = min(adpnotemp) if numads==1, by(`w'hidp)
    qui replace hgrai = 1 if numads==1 & `w'depchl_dv==1 & `w'adresp15_dv<0 & under15==1
    qui replace `w'adresp15_dv = adpno if numads==1 & `w'depchl_dv==1 & `w'adresp15_dv<0 & under15==1

    drop numads adpnotemp adpno
    drop under15


    qui count if (inrange(`w'dvage,0,15) & `w'adresp15_dv == 0)
    di as text %30s "<=15 but still missing" " {c |} " as res %5.0g r(N)
    * These children are dependents, but appear in their own buno - they will need to be sorted out later

* This may not work properly if `if' or `in' is specified
    if "`indall'" == "indall" {

        * Check that specified pnos exist for responsible adult, mother and father
        createvars numras nummas numfas, wave(`wi')
        assert inlist(numras,1,.) & inlist(numfas,1,.) & inlist(numfas,1,.)

        * Check responsible adult number is consistent with mother number, or (if mother not present) father/father's partner number
        assert (`w'adresp15_dv == `w'hgbiom) if inrange(`w'dvage,0,15) & inrange(`w'hgbiom,1,50)
        createvars faptrpno, wave(`wi')
        assert ((`w'adresp15_dv == `w'hgbiof) | (`w'adresp15_dv == faptrpno)) if inrange(`w'dvage,0,15) & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)

    }

end

capture program drop varsfordvage
program define varsfordvage

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsfordvage "`w'hidp `w'pno `w'dvage `w'hgbiom `w'hgbiof `w'depchl_dv"

end

capture program drop fixdvage
program define fixdvage

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "age" " {c |} "
    *make x-wave age dataset
    preserve
	local wlet = char(96 + 1)
        use pidp `wlet'_dvage using "$data\\`wlet'_indall.dta", clear
        forval loopwave = 2/$numwaves {
            local wlet = char(96 + `loopwave')
            append using "$data\\`wlet'_indall.dta", keep(pidp `wlet'_dvage)
        }
		
        local i = 1
        foreach var of varlist *_dvage {
            gen ageinwave`i' = .
            qui egen age`i'temp = min(`var'), by(pidp)
            qui replace ageinwave`i' = age`i'temp
            drop age`i'temp
            local ++i

        }

        qui {
            bys pidp: keep if _n==1
        }
        keep pidp age*
		assert pidp<.

        tempfile xwave_age
        save `xwave_age'
    restore

    gen byte agei = 0
    label variable agei "Age changed"

    *identifying people with odd ages (marital status is "child under 16", and classed as depchild but over 18). Checked a few of these and their ages vary from wave to wave
    *merge in ages for subsequent waves
    merge m:1 pidp using `xwave_age', assert(2 3)
    keep if _merge==3
    drop _merge


    qui gen oldage = `w'dvage

    *how different is reported age to age in subsequent waves
    local i = 0
    foreach var of varlist ageinwave? {
        local ++i
        if (`i'==`wi') {
            continue
        }
        qui gen agediff`i' = `w'dvage-`var' - (`wi' - `i')
    }


    qui egen minagediff = rowmin(agediff*)
    qui egen maxagediff = rowmax(agediff*)
    *count number of other waves we observe for people (want at least two other years)
    qui egen nonmissagediff = rownonmiss(agediff*)

    *PL added December 2019
    *fix age if age gap of 5 years or greater observed in multiple waves
    qui replace `w'dvage = `w'dvage - minagediff if abs(maxagediff - minagediff)<=1 & abs(minagediff>=5) & minagediff!=. & nonmissagediff>=2
    qui replace agei = 1 if abs(maxagediff - minagediff)<=1 & abs(minagediff>=5) & minagediff!=. & nonmissagediff>=2

    *less strict criteria for adjusting ages of those classed as dep children who also appear as over 18
    qui replace `w'dvage = `w'dvage - minagediff if abs(maxagediff - minagediff)<=1 & minagediff!=. & nonmissagediff>=2 & `w'depchl_dv==1 & `w'dvage>18 & agei==0
    qui replace agei = 1 if abs(maxagediff - minagediff)<=1 & minagediff!=. & nonmissagediff>=2 & `w'depchl_dv==1 & oldage>18 & agei==0

    *some people assigned negative ages when adjustment is made - set ages to missing in this case
    qui replace `w'dvage = -9 if `w'dvage<0 & agei==1

    *other corrections if too young relative to mother/father

    sort `w'hidp `w'pno
    su `w'pno, meanonly
    local maxpno = r(max)

    capture drop mumage dadage
    qui gen byte mumage = .
    qui gen byte dadage = .
    local mumrhs "`w'dvage[\`i'] if (`w'hgbiom == `w'pno[\`i']) & (\`i' <= _N)"
    local dadrhs "`w'dvage[\`i'] if (`w'hgbiof == `w'pno[\`i']) & (\`i' <= _N)"

    forval i = 1/`maxpno' {
       qui by `w'hidp (`w'pno): replace mumage = `mumrhs'
       qui by `w'hidp (`w'pno): replace dadage = `dadrhs'
    }

    qui gen diffmum = mumage - `w'dvage
    qui gen diffdad = dadage - `w'dvage

    qui gen mumpresent = `w'hgbiom >0 & `w'hgbiom <.
    qui gen dadpresent = `w'hgbiof >0 & `w'hgbiof <.

    *use age from another wave if difference in age with mother is implausible and a dep child

    qui replace `w'dvage = `w'dvage - minagediff if abs(maxagediff - minagediff)<=1 & minagediff!=. & minagediff>0 & `w'depchl_dv==1 & `w'dvage>18 & diffmum<17 & agei==0
    qui replace agei = 1 if abs(maxagediff - minagediff)<=1 & minagediff!=. & minagediff>0 & `w'depchl_dv==1 & oldage>18 & diffmum<17 & agei==0
	
	
	* set parent relationship variables to not identify person as a parent if they are younger than them
	qui replace `w'hgbiom = 0 if mumage < `w'dvage 
	qui replace `w'hgbiof = 0 if dadage < `w'dvage 
	
    drop oldage

    drop ageinwave? agediff* minagediff maxagediff nonmissagediff
    drop mumage dadage diffmum diffdad mumpresent dadpresent

end

capture program drop varsfordepchl_dv
program define varsfordepchl_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsfordepchl_dv "`w'hidp `w'pno `w'dvage `w'depchl_dv `w'mastat_dv `w'hgbiom `w'hgbiof `w'ivfio"

end

capture program drop fixdepchl_dv
program define fixdepchl_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [fixdvage]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "depchl" " {c |} "

    gen byte depchli = 0
    label variable depchli "Dependent child indicator changed"

    if "`fixdvage'" == "fixdvage" {
        qui fixdvage, wave(`wave')
    }

    *people's whose age we have not corrected and are over 18 recode as non-depchild
    qui replace `w'depchl_dv = 2 if `w'dvage>=19 & `w'depchl_dv == 1
    qui replace depchli = 1  if `w'dvage>=19 & `w'depchl_dv == 1

    * Check dependent indicator
    assert inrange(`w'dvage,0,18) | `w'dvage < 0 if `w'depchl_dv == 1

    qui count if inrange(`w'dvage,0,15) & `w'depchl_dv < 0
    qui replace depchli = 1 if inrange(`w'dvage,0,15) & `w'depchl_dv < 0
    qui replace `w'depchl_dv = 1 if inrange(`w'dvage,0,15)  & `w'depchl_dv < 0
    di as text %30s "Set to 1 (because <=15)" " {c |} " as res %5.0g r(N)

    qui gen mumpresent = `w'hgbiom >0 & `w'hgbiom <.
    qui gen dadpresent = `w'hgbiof >0 & `w'hgbiof <.

    *PL added 03/12/2019
    *Change to depchild if 15 or under and biological parent is present
    qui count if inrange(`w'dvage,0,15) & (mumpresent==1|dadpresent==1) & `w'depchl_dv ==2
    qui replace depchli = 1 if inrange(`w'dvage,0,15) & (mumpresent==1|dadpresent==1) & `w'depchl_dv ==2
    qui replace `w'depchl_dv = 1 if inrange(`w'dvage,0,15) & (mumpresent==1|dadpresent==1) & `w'depchl_dv ==2
    di as text %30s "Set to 1 (because <=15 + parent in hh)" " {c |} " as res %5.0g r(N) 
	
	* Change to depchild if aged under 10 even if no parents present 
    qui count if (inrange(`w'dvage,0,9) | `w'ivfio==24) & `w'depchl_dv ==2
    qui replace depchli = 1 if (inrange(`w'dvage,0,9) | `w'ivfio==24) & `w'depchl_dv ==2
    qui replace `w'depchl_dv = 1 if (inrange(`w'dvage,0,9) | `w'ivfio==24) & `w'depchl_dv ==2
    di as text %30s "Set to 1 (because <10)" " {c |} " as res %5.0g r(N) 	

    drop mumpresent dadpresent

    qui count if `w'dvage >= 19 & `w'dvage < . & `w'depchl_dv < 0
    qui replace depchli = 1 if `w'dvage >= 19 & `w'dvage < . & `w'depchl_dv < 0
    qui replace `w'depchl_dv = 2 if `w'dvage >= 19 & `w'dvage < . & `w'depchl_dv < 0
    di as text %30s "Set to 2 (because >=15)" " {c |} " as res %5.0g r(N)

    * Assume not a dependent child if married, or if not living with natural parent (the latter seems a bit dodgy, but it's my best guess as to how the variable is constructed)
    qui count if (inrange(`w'dvage,16,18) | `w'dvage < 0) & `w'depchl_dv < 0 & (`w'mastat_dv == 2 | (`w'hgbiom == 0 & `w'hgbiof == 0))
    qui replace depchli = 1 if (inrange(`w'dvage,16,18) | `w'dvage < 0) & `w'depchl_dv < 0 & (`w'mastat_dv == 2 | (`w'hgbiom == 0 & `w'hgbiof == 0))
    qui replace `w'depchl_dv = 2 if (inrange(`w'dvage,16,18) | `w'dvage < 0) & `w'depchl_dv < 0 & (`w'mastat_dv == 2 | (`w'hgbiom == 0 & `w'hgbiof == 0))
    di as text %30s "Set to 2 (other)" " {c |} " as res %5.0g r(N)

    qui count if inrange(`w'dvage,16,18) & `w'depchl_dv < 0 & (`w'mastat_dv != 2 & ((`w'hgbiom > 0 & `w'hgbiom < .) | (`w'hgbiof > 0 & `w'hgbiof < .)) & !inlist(`w'ivfio,1,2,3))
    qui replace depchli = 1 if inrange(`w'dvage,16,18) & `w'depchl_dv < 0 & (`w'mastat_dv != 2 & ((`w'hgbiom > 0 & `w'hgbiom < .) | (`w'hgbiof > 0 & `w'hgbiof < .)) & !inlist(`w'ivfio,1,2,3))
    qui replace `w'depchl_dv = 1 if inrange(`w'dvage,16,18) & `w'depchl_dv < 0 & (`w'mastat_dv != 2 & ((`w'hgbiom > 0 & `w'hgbiom < .) | (`w'hgbiof > 0 & `w'hgbiof < .)) & !inlist(`w'ivfio,1,2,3))
    di as text %30s "Set to 1 (other)" " {c |} " as res %5.0g r(N)
    assert inlist(`w'depchl_dv,1,2)

end

capture program drop varsformastat_dv
program define varsformastat_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsformastat_dv "`w'hidp `w'pno `w'mastat_dv"

end

capture program drop fixmastat_dv
program define fixmastat_dv

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "mastat_dv" " {c |} "

    gen byte mastati = 0
    label variable mastati "Marital status changed"

    gen byte ppnoi = 0
    label variable ppnoi "Partner changed"

    *PL addition 05/08/2022	
    *hard coded as no easy way to automate	
	
	if `wi'==1 {
		*PL 23/6 - this person had a partner who was in the data in previous versions of the data (up to wave 13). When wave 14 was added their partner (29 year old male), disappeared from the indall data. Change partner status to partner not in hh. 
		qui replace ppnoi = 1 if a_ppno == 6 & a_hidp == 1225760523 & a_pno ==5 
		qui replace `w'ppno = 0 if a_ppno ==  6 & a_hidp == 1225760523 & a_pno ==5 
	}
	
	if `wi'==2 {
		*PL 23/6 - this person had a partner who was in the data in previous versions of the data (up to wave 13). When wave 14 was added their partner, disappeared from the indall data. Change partner status to partner not in hh. 
		qui replace ppnoi = 1 if b_ppno == 4 & b_hidp == 1231214802 & b_pno ==3 
		qui replace `w'ppno = 0 if b_ppno ==  4 & b_hidp == 1231214802 & b_pno ==3 
	}
	
    if `wi'==10 {
		qui replace ppnoi = 1 if j_ppno == -9 & j_hidp == 1226496298 & j_pno ==2 
		qui replace `w'ppno = 1 if j_ppno == -9 & j_hidp == 1226496298 & j_pno ==2 

		*two people married with kids in their hh who do not list each other as partners (in following wave they are married to each other)
		qui replace ppnoi = 2 if j_ppno == 0 & j_hidp == 207026018 & j_pno ==1 
		qui replace `w'ppno = 2 if j_ppno == 0 & j_hidp == 207026018 & j_pno ==1 

		qui replace ppnoi = 1 if j_ppno == 0 & j_hidp == 207026018 & j_pno ==2 
		qui replace `w'ppno = 1 if j_ppno == 0 & j_hidp == 207026018 & j_pno ==2 

		*two people married with kids in their hh who do not list each other as partners (in following wave they are married to each other)
		qui replace ppnoi = 4 if j_ppno == 0 & j_hidp == 213499618 & j_pno ==1 
		qui replace `w'ppno = 4 if j_ppno == 0 & j_hidp == 213499618 & j_pno ==1 

		qui replace ppnoi = 1 if j_ppno == 0 & j_hidp == 213499618 & j_pno ==4 
		qui replace `w'ppno = 1 if j_ppno == 0 & j_hidp == 213499618 & j_pno ==4 
    }
	
	if `wi'==11 {
		*PL 23/6 - in previous vintage (waves 1-13) these people were both listed as married to each other. Now one is living as a couple the other has status unkown. Set them to be partners of each other.
		qui replace ppnoi = 1 if k_ppno == -9 & k_hidp == 210670820 & k_pno ==2 
		qui replace `w'ppno = 1 if k_ppno == -9 & k_hidp == 210670820 & k_pno ==2 
		
	}
	
	if `wi' ==12 {
		* two people living in same hh and say are married. one says married to the other. other says partner not in hh
		qui replace ppnoi =1 if l_ppno == 0 & l_hidp==482038422 & l_pno ==1
		qui replace `w'ppno = 2 if l_ppno == 0 & l_hidp==482038422 & l_pno ==1
	}
	
	if `wi' ==13 {
		* two people living in same hh and partnered in pervious wave - set to be each others' partners
		qui replace ppnoi =1 if m_ppno == 0 & m_hidp==69571504  & inlist(m_pno,1,2)
		qui replace `w'ppno = 1 if m_ppno == 0 & m_hidp==69571504 & m_pno ==2
		qui replace `w'ppno = 2 if m_ppno == 0 & m_hidp==69571504 & m_pno ==1
		
		* two people living in same hh and partnered in pervious wave - set to be each others' partners
		qui replace ppnoi =1 if m_ppno == 0 & m_hidp==547863104 & inlist(m_pno,1,2)
		qui replace `w'ppno = 1 if m_ppno == 0 & m_hidp==547863104 & m_pno ==2
		qui replace `w'ppno = 2 if m_ppno == 0 & m_hidp==547863104 & m_pno ==1
		
		* two male and female adults living in same hh with children - set to be each others' partners
		qui replace ppnoi =1 if m_ppno == 0 & m_hidp==886244704 & inlist(m_pno,1,3)
		qui replace `w'ppno = 1 if m_ppno == 0 & m_hidp==886244704 & m_pno ==3
		qui replace `w'ppno = 3 if m_ppno == 0 & m_hidp==886244704 & m_pno ==1
		
		* two male and female adults living in same hh with children - set to be each others' partners
		qui replace ppnoi =1 if m_ppno == 0 & m_hidp==1499699224 & inlist(m_pno,1,2)
		qui replace `w'ppno = 1 if m_ppno == 0 & m_hidp==1499699224 & m_pno ==2
		qui replace `w'ppno = 2 if m_ppno == 0 & m_hidp==1499699224 & m_pno ==1
		
		*male and female adults of similar ages, one says living in couple the other has status missing
		qui replace ppnoi =1 if m_ppno == 0 & m_hidp==752766824 & m_pno==3
		qui replace `w'ppno = 1 if m_ppno == -9 & m_hidp==752766824 & m_pno ==3

	}
	
	if `wi' ==14 {
		
		* two male and female adults living in same hh with children. married and listed as partners in previous wave
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==274237226 & inlist(n_pno,1,3)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==274237226 & n_pno ==3
		qui replace `w'ppno = 3 if n_ppno == 0 & n_hidp==274237226 & n_pno ==1
		
		* two male and female adults living in same hh with children. married and listed as partners in previous wave
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==139726426 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==139726426 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==139726426 & n_pno ==1
		
		* two male and female adults living in same hh with children and living as partners
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==158950026 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==158950026 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==158950026 & n_pno ==1
		
		* two male and female adults living in same hh with child and living as partners
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==498684826 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==498684826 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==498684826 & n_pno ==1
		
		* two male and female adults living in same hh with child and one says married the other says divorced
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==618494026 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==618494026 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==618494026 & n_pno ==1
		
		* two male and female adults living in same hh with child and both say married but partner no in hh
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==636344026 & inlist(n_pno,1,5)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==636344026 & n_pno ==5
		qui replace `w'ppno = 5 if n_ppno == 0 & n_hidp==636344026 & n_pno ==1
		
		* two male and female adults living in same hh with child and both say married but partner no in hh
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==640220026 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==640220026 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==640220026 & n_pno ==1
		
		* two male and female adults living in same hh with child and both say married but partner no in hh
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==839582426 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==839582426 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==839582426 & n_pno ==1
	
		* two male and female adults living in same hh with child (son of woman) and both say single 
		qui replace ppnoi =1 if n_ppno == 0 & n_hidp==1384969626 & inlist(n_pno,1,2)
		qui replace `w'ppno = 1 if n_ppno == 0 & n_hidp==1384969626 & n_pno ==2
		qui replace `w'ppno = 2 if n_ppno == 0 & n_hidp==1384969626 & n_pno ==1
		
	}
	
	if `wi'==15 {
		
		* mother and father not listed as couple
		qui replace ppnoi =1 if o_ppno == 0 & o_hidp==614543228 & inlist(o_pno,6,7)
		qui replace `w'ppno = 6 if o_ppno == 0 & o_hidp==614543228 & o_pno ==7
		qui replace `w'ppno = 7 if o_ppno == 0 & o_hidp==614543228 & o_pno ==6
		
	}
	

   /* set de facto marital status = living as a couple if person has a partner pno and doesn't reporte being married or in a civil partnership. de facto marital status takes
     legal marital status (`w'marstat) and replaces it with living as a couple for all people who report "yes" as `w'livewith. The problem is that `w'livewith is not consistent wih
    `w'ppno. So some people who report that they have a partner at the relationship grid report "no" at `w'livewith. This program works off `w'ppno so we assume this is correct and change
     `w'marstat to living as couple if ppno>0 (i.e. they have a partner)
     n.b if marital status is DK or RF */

    createvars genptrmastat ptrage ptrdepchl ptrsex, wave(`wi')
    *depchl is fixed with reference to ages in other waves above

    *there are some quite common errors which can be sorted out
    gen tochange = genptrmastat != `w'mastat_dv & `w'ppno > 0

    *set to living as a couple if one reports being married or in a registered civil partnership and the other reports single, separated, widowed or divorced or a surviving civil partner
    qui gen changetolivingascouple = 1  if inlist(`w'mastat_dv,1,4,5,6,9) & inlist(genptrmastat,2,3) & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2 & tochange==1
    qui replace changetolivingascouple = 1  if inlist(`w'mastat_dv,2,3) & inlist(genptrmastat,1,4,5,6,9) & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2 & tochange==1
    qui replace `w'mastat_dv = 10 if changetolivingascouple==1
    qui replace mastati = 1 if changetolivingascouple==1
    drop changetolivingascouple

   *set to living in a couple if one person reports being in a same-sex civil partnership and other says living as a couple, doesn't know refuses, missing or inapplicable and they are of opposite sex
    qui gen changetolivingascouple = 1   if `w'mastat_dv==3 & inlist(genptrmastat,10,-1,-2,-9,-8) & `w'ppno>0 & ptrdepchl==2 & `w'sex!=ptrsex & tochange==1 
    qui replace changetolivingascouple = 1  if inlist(`w'mastat_dv,10,-1,-2,-9,-8) & genptrmastat==3  & `w'ppno>0 & ptrdepchl==2 & `w'sex!=ptrsex & tochange==1 
    qui replace `w'mastat_dv = 10 if changetolivingascouple==1
    qui replace mastati = 1 if changetolivingascouple==1
    drop changetolivingascouple

    drop genptrmastat tochange
    createvars genptrmastat, wave(`wi') 
    gen tochange = genptrmastat != `w'mastat_dv & `w'ppno > 0

    *set to married if one person reports being married and the other doesn't respond, refuses, doesn't know or has inapplicable
    qui replace mastati      = 1  if inlist(`w'mastat_dv,-1,-2,-8,-9) & genptrmastat==2 & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2 & tochange==1 
    qui replace `w'mastat_dv = 2  if inlist(`w'mastat_dv,-1,-2,-8,-9) & genptrmastat==2 & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2 & tochange==1 

    *set to married if one person reports being married and the other reports being under 16 (but is over 16)
    qui replace mastati      = 1  if `w'mastat_dv==0 & `w'dvage>16 & `w'dvage<. & genptrmastat==2 & `w'ppno>0 & tochange==1
    qui replace `w'mastat_dv = 2  if `w'mastat_dv==0 & `w'dvage>16 & `w'dvage<. & genptrmastat==2 & `w'ppno>0 & tochange==1 

    *set to living as a couple if one reports living as a couple and the other reports being married, single, divorced, widowed, separated, separated from former civil partner, former civil partner, doesn't know refuses, missing or inapplicable 
    qui replace mastati      = 1  if inlist(`w'mastat_dv,8,7,6,5,4,2,1,-1,-2,-9,-8) & genptrmastat==10 & `w'ppno>0 & `w'depchl_dv==2|(`w'depchl_dv<0 & `w'dvage>20) & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) & tochange==1 
    qui replace `w'mastat_dv = 10 if inlist(`w'mastat_dv,8,7,6,5,4,2,1,-1,-2,-9,-8) & genptrmastat==10 & `w'ppno>0 & `w'depchl_dv==2|(`w'depchl_dv<0 & `w'dvage>20) & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) & tochange==1 

    *set to living as a couple if one person reports being married and the other reports being under 16 (but is over 16)
    qui replace mastati      = 1  if `w'mastat_dv==0 & `w'dvage>16 & `w'dvage<. & genptrmastat==10 & `w'ppno>0 & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) & tochange==1 
    qui replace `w'mastat_dv = 10  if `w'mastat_dv==0 & `w'dvage>16 & `w'dvage<. & genptrmastat==10 & `w'ppno>0 & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) & tochange==1 

    *set to in a registered same-sex civil partnership if one person reports being married or living in a couple, single, missing or refusal and one reports being in a civil partnership and same sex 
    qui replace mastati      = 1  if inlist(`w'mastat_dv,-9,-2,1,2,10) & genptrmastat==3 & `w'ppno>0 & ptrdepchl==2 & `w'sex==ptrsex & tochange==1 
    qui replace `w'mastat_dv = 3  if inlist(`w'mastat_dv,-9,-2,1,2,10) & genptrmastat==3 & `w'ppno>0 & ptrdepchl==2 & `w'sex==ptrsex & tochange==1 

    *set to married if one person reports being in a same-sex civil partnership and other says married and they are of opposite sex
    qui replace mastati      = 1 if `w'mastat_dv==3 & genptrmastat==2 & `w'ppno>0 & ptrdepchl==2 & `w'sex!=ptrsex & tochange==1 
    qui replace `w'mastat_dv = 2 if `w'mastat_dv==3 & genptrmastat==2 & `w'ppno>0 & ptrdepchl==2 & `w'sex!=ptrsex & tochange==1 

    *couples who are living together as a couple according to ppno but who haven't had their de facto marital status changed to living as couple (this happens because livewith = no) but
    *neither report being married or living together and so aren't picked up above (e.g. one widowed one single)

    qui replace mastati      = 1  if !inlist(`w'mastat_dv,2,3,10) & `w'ppno>0 & !inlist(genptrmastat,2,3,10) & tochange==1 & `w'depchl_dv==2 & ptrdepchl==2 
    qui replace `w'mastat_dv = 10 if !inlist(`w'mastat_dv,2,3,10) & `w'ppno>0 & !inlist(genptrmastat,2,3,10) & tochange==1 & `w'depchl_dv==2 & ptrdepchl==2 

    *set to living as a couple if both report same status (e.g widowed) but are partnered with each other
    *these ones have tochange= 0 because they have the same marital status
    qui replace mastati      = 1  if inlist(`w'mastat_dv,-9,-8,-2,-1,1,4,5,6,7,8,9) & inlist(genptrmastat,-9,-8,-2,-1,1,4,5,6,7,8,9) & `w'mastat_dv==genptrmastat & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) 
    qui replace `w'mastat_dv = 10 if inlist(`w'mastat_dv,-9,-8,-2,-1,1,4,5,6,7,8,9) & inlist(genptrmastat,-9,-8,-2,-1,1,4,5,6,7,8,9) & `w'mastat_dv==genptrmastat & `w'ppno>0 & `w'depchl_dv==2 & ptrdepchl==2|(ptrdepchl<0 & ptrage>20) 

    drop tochange
    drop genptrmastat
    drop ptrage
    drop ptrdepchl
    drop ptrsex

    createvars genptrmastat, wave(`wi')
    gen tochange = genptrmastat != `w'mastat_dv & `w'ppno > 0

    if _rc==9 {
        noisily di in red "Partners give inconsistent marital statuses"
        stop
    }
	
    drop tochange
    drop genptrmastat
	

end

capture program drop varsforbuno
program define varsforbuno

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    #delimit ;
    c_local varsforbuno "`w'hidp pidp `w'pno `w'buno_dv `w'sex `w'mastat_dv `w'ppno `w'depchl_dv `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof
    `w'ivfio `w'hgadoptm `w'hgadoptf  `w'nnssib_dv  `w'nnsib_dv `w'grfpno `w'grmpno `w'ngrp_dv";
    #delimit cr


end

capture program drop fixbuno
program define fixbuno

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    assert `w'hidp > 0 & `w'pno > 0

    di as text %30s "buno" " {c |} "
	
	*obtain sex from xwavedat file to correct it 
	*Assumes a value of 1 if all information in the study suggests the respondent is male, 2 if all information in the study suggests the respondent is female and 0 if the information is inconsistent and the forename listed in the survey administration database also does not suggest a particular gender. 
	merge 1:1 pidp using "$data/xwavedat", keepusing(sex_dv) 
	assert _merge==2|_merge==3 
	drop if _merge==2
	drop _merge
	replace `w'sex = sex_dv if sex_dv>0
	
    * 1. Clean marital status, age, responsible adult number and dependent child indicator
    **************************************************************************************
	
    * In wave 1, some marital status responses are not consistent within couples
    qui fixmastat_dv, wave(`wi')

    * Check age variable
    qui fixdvage, wave(`wi')

    * Check dependent indicator
    qui fixdepchl_dv, wave(`wi')

    * Correct responsible adult number using mother and father number (note: this doesn't sort out all cases where there are problems)
    qui fixadresp15_dv, wave(`wi')

    * 2. Deal with missing buno
    ***************************

    gen byte bunoi = 0
    label variable bunoi "Benefit unit number changed"
	
    * Just put everyone whose buno is missing in separate bunos, and leave the later code to sort it out
    qui count if `w'buno_dv < 0
    qui replace bunoi = 1 if `w'buno_dv < 0
    qui replace `w'buno_dv = `w'pno if `w'buno_dv < 0
*    di as text r(N) " individuals assigned buno = pno"
    di as text %30s "missing --> pno" " {c |} " as res %5.0g r(N)

    assert `w'buno_dv > 0

    * 3. Put partners in the same buno
    **********************************

    * Create buno of partner, etc
    createvars ptrmastat ptrptrpno ptrbuno newbuno, wave(`wi')

    * Partners are not always in the same buno - move everyone in the higher numbered buno into the lower numbered one
    qui count if newbuno < .
    local numnewbuno = r(N)
    qui replace `w'buno_dv = newbuno if newbuno < .
    qui replace bunoi = 1 if newbuno < .
    drop newbuno
    *di as text `numnewbuno' " buno(s) changed to avoid partners being split across bunos"
    di as text %30s "Spouse --> partner" " {c |} " as res %5.0g `numnewbuno'
	
    * Re-create buno of partner, etc
    createvars ptrmastat ptrptrpno ptrbuno, wave(`wi')

    * Check spouses both say same status (married or living as couple)
    egen byte look1 = max(ptrmastat != `w'mastat_dv & `w'ppno > 0), by(`w'hidp)

    capture assert look1 == 0
     if _rc==9 {
     di in red "spouse relationships need fixing in useundersoc.ado"
     stop
     }

    drop look1
    * Check spouse numbers are consistent between partners
    egen byte look2 = max(ptrptrpno != `w'pno & `w'ppno > 0), by(`w'hidp)
    capture assert look2 == 0
        if _rc==9 {
        di in red "spouse relationships need fixing in useundersoc.ado"
        stop
        }
    drop look2

    * Check spouses are in the same buno
    egen byte look3 = max(ptrbuno != `w'buno_dv & `w'ppno > 0), by(`w'hidp)
    capture assert look3 == 0
        if _rc==9 {
        di in red "spouse relationships need fixing in useundersoc.ado"
        stop
        }
    drop look3

    * 4. Put children in the same buno as their parent(s)
    *****************************************************
    * Copy buno of responsible adult, natural mother and natural father onto dependent child line
    createvars rabuno mabuno fabuno, wave(`wi')

    *same people have missing ages but we know they are under 15 from the fact they were not interviewed for being under 10
    qui gen under15 = inrange(`w'dvage,0,15)| (`w'dvage<0 & `w'ivfio==24)

    * Children 0-15 should be in the same buno as their responsible adult (= mother if present, if not then father if present, if not then someone else)
    * Fix this if it isn't the case
    * Note: those few children without a responsible adult may still appear in their own benefit unit
    qui count if (`w'buno_dv != rabuno & rabuno < .) & under15==1
    qui replace bunoi = 1 if (`w'buno_dv != rabuno & rabuno < .) & under15==1
    qui replace `w'buno_dv = rabuno if (`w'buno_dv != rabuno & rabuno < .) & under15==1
    assert (`w'buno_dv == rabuno) if under15==1 & rabuno < .
*    di as text r(N) " children <=15 moved into same buno as their responsible adult"
    di as text %30s "Children <=15 --> RA" " {c |} " as res %5.0g r(N)

    * For dependents 16-18, responsible adult doesn't exist. But they should be in the same buno as mother if present, if not then father if present
    * Note: if mother isn't present, responsible adult may be father's new partner. But she must be in same buno as father, so only worry about father's buno
    qui count if (`w'buno_dv != mabuno & mabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    qui replace bunoi = 1 if (`w'buno_dv != mabuno & mabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    qui replace `w'buno_dv = mabuno if (`w'buno_dv != mabuno & mabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    assert (`w'buno_dv == mabuno) if inrange(`w'dvage,16,18) & `w'depchl_dv == 1 & mabuno < .
*    di as text r(N) " dependents 16-18 moved into same buno as their mother"
    di as text %30s "Dependent 16-18 --> mother" " {c |} " as res %5.0g r(N)

    qui count if (`w'buno_dv != fabuno & mabuno >= . & fabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    qui replace bunoi = 1 if (`w'buno_dv != fabuno & mabuno >= . & fabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    qui replace `w'buno_dv = fabuno if (`w'buno_dv != fabuno & mabuno >= . & fabuno < .) & inrange(`w'dvage,16,18) & `w'depchl_dv == 1
    assert (`w'buno_dv == fabuno) if inrange(`w'dvage,16,18) & `w'depchl_dv == 1 & mabuno >= . & fabuno < .
*    di as text r(N) " dependents 16-18 moved into same buno as their father"
    di as text %30s "Dependent 16-18 --> father" " {c |} " as res %5.0g r(N)
 
    * Sort out cases where there are dependent children in their own benefit unit (even when they don't have a responsible adult)
    * Note: this is not very general. It only works for cases where there is only one other benefit unit in the household.
    qui bys `w'hidp (`w'buno_dv `w'pno): gen byte bunocounter = 1 if _n == 1
    qui by `w'hidp (`w'buno_dv `w'pno): replace bunocounter = bunocounter[_n-1] + (`w'buno_dv != `w'buno_dv[_n-1]) if _n > 1
    egen byte numbunos = max(bunocounter), by(`w'hidp)
    label variable numbunos "Number of bunos in hh"
    drop bunocounter
    egen byte noadshh = min(`w'depchl_dv == 1), by(`w'hidp)
    label variable noadshh "Hh has no adults"

    if !inlist(`wi',3,7,8) {
        *in wave==3 c_hidp == 750455484 has only one 14 y/o (PL (02/01/2020))
        *in wave 7 g_hidp==889344812 has only one 7 y/o (OL 06/01/2020)
        *in wave 8 h_hidp==1433325094 has only one 1 y/o (OL 06/01/2020)
        capture assert noadshh == 0
        if _rc==9 {
           noisily di in red "Error: Some households have no adults"
           stop
        }
    }

    egen byte noadsbuno = min(`w'depchl_dv == 1), by(`w'hidp `w'buno_dv)
    label variable noadsbuno "Buno has no adults"

    *PL (11/01/17) assign kids in their own benefit units to be the same benefit unit
    qui egen numchildren = sum(`w'depchl_dv==1), by(`w'hidp)
    qui egen bunotemp = min(`w'buno_dv) if under15==1 & noadsbuno==1 & numbunos>2 & numchildren>1, by(`w'hidp)
    qui replace bunoi = 1 if under15==1 & noadsbuno==1 & numbunos>2 & numchildren>1
    qui replace `w'buno_dv = bunotemp if under15==1 & noadsbuno==1 & numbunos>2 & numchildren>1
    drop under15 numchildren bunotemp
	
	* DS (06/03/2023) deal with a couples who report children as their mother/father. Assume they are parents of that person
	if `wi' == 12 {
		replace l_hgbiom = 2 if l_hidp == 272340022 & l_pno == 3 
		replace l_hgbiof = 1 if l_hidp == 272340022 & l_pno == 3 
		replace l_hgbiom = 0 if l_hidp == 272340022 & l_pno != 3 
		replace l_hgbiof = 0 if l_hidp == 272340022 & l_pno != 3 
		
		replace l_hgbiom = 2 if l_hidp == 1092610422 & l_pno == 3 
		replace l_hgbiof = 1 if l_hidp == 1092610422 & l_pno == 3 
		replace l_hgbiom = 0 if l_hidp == 1092610422 & l_pno != 3 
		replace l_hgbiof = 0 if l_hidp == 1092610422 & l_pno != 3 	
	}

    *PL (02/01/20) sort out cases where unpartnered non-dep (>= 19 y/o) children are put in same BU as their parents - put into separate bunos
    qui egen byte numadsbuno = total(`w'depchl_dv == 2), by(`w'hidp `w'buno_dv)
    capture drop mumbuno dadbuno
    qui gen byte mumbuno = .
    qui gen byte dadbuno = .
    local mumrhs "`w'buno_dv[\`i'] if (`w'hgbiom == `w'pno[\`i']|`w'hgadoptm ==`w'pno[\`i']) & (\`i' <= _N)"
    local dadrhs "`w'buno_dv[\`i'] if (`w'hgbiof == `w'pno[\`i']|`w'hgadoptf ==`w'pno[\`i']) & (\`i' <= _N)"

    sort `w'hidp `w'pno
    qui su `w'pno, meanonly
    local maxpno = r(max)

    forval i = 1/`maxpno' {
       qui by `w'hidp (`w'pno): replace mumbuno = `mumrhs'
       qui by `w'hidp (`w'pno): replace dadbuno = `dadrhs'
    }

    qui gen numparents = (mumbuno<.) + (dadbuno<.)
    qui gen tochangebuno = 1 if (`w'buno_dv==mumbuno|`w'buno_dv==dadbuno) & `w'buno_dv>0 & `w'buno_dv<. & numadsbuno>1 & `w'depchl_dv == 2
    qui egen maxbuno = max(`w'buno_dv), by(`w'hidp)
    qui replace `w'buno_dv = maxbuno + 1 if (`w'buno_dv==mumbuno|`w'buno_dv==dadbuno) & `w'buno_dv>0 & `w'buno_dv<. & numadsbuno>1 & `w'depchl_dv == 2
    *deal with multiple individuals in this situation
    qui bys `w'hidp (`w'buno_dv): replace `w'buno_dv =  `w'buno_dv -1 + _n if tochangebuno==1
    qui replace bunoi = 1 if tochangebuno==1

    drop mumbuno dadbuno numadsbuno numparents maxbuno tochangebuno

    *recalculate number of bunos
    drop numbunos
    qui bys `w'hidp (`w'buno_dv `w'pno): gen byte bunocounter = 1 if _n == 1
    qui by `w'hidp (`w'buno_dv `w'pno): replace bunocounter = bunocounter[_n-1] + (`w'buno_dv != `w'buno_dv[_n-1]) if _n > 1
    egen byte numbunos = max(bunocounter), by(`w'hidp)
    label variable numbunos "Number of bunos in hh"
    drop bunocounter

    qui bys `w'hidp (noadsbuno): replace bunoi = 1 if noadsbuno & numbunos == 2
    qui bys `w'hidp (noadsbuno): replace `w'buno_dv = `w'buno_dv[1] if noadsbuno & numbunos == 2

    qui gen cantassignbuno = 0

    *PL hard coded corrections to BUNO (03/12/2019)
    if `wi'==1 {

        *PL household where all appear to be siblings - eldest is 19
        qui replace `w'buno_dv = 1 if a_hidp==1428833003
        qui replace `w'buno_dv = 2 if a_hidp==1428833003 & a_pno==2
        qui replace bunoi = 1 if a_hidp==1428833003

        *PL household where children appear siblings - 37 year old is not biologically related to them and they are not included in subsequent waves. Assume 37 year old is responsible
        *for 10 and 14 y/os.
        qui replace `w'buno_dv = 2 if a_hidp==885895843 & a_pno!=1
        qui replace bunoi = 1 if a_hidp==885895843 & a_pno!=1

        *Put 13 y/o in same BU of only person in household who doesn't have siblings (their siblings are 17 and 18 but not classed as depchildren)
        qui replace `w'buno_dv = 3 if a_hidp==818477243 & a_pno==5
        qui replace bunoi = 1 if a_hidp==818477243 & a_pno==5

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if a_hidp==1497635403 & a_pno==3
        qui replace bunoi = 1 if a_hidp==1497635403 & a_pno==3

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 4 if a_hidp==614026403 & a_pno==2
        qui replace bunoi = 1 if a_hidp==614026403 & a_pno==2

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 17 if a_hidp==546530963 & a_pno==5
        qui replace bunoi = 1 if a_hidp==546530963 & a_pno==5

        *Not sure what to do with this HH a_hidp==817810843

        *Not sure what to do with this HH a_hidp==748898283

        *Not sure what to do with this HH a_hidp==137865923

        *Not sure what to do with this HH a_hidp==1430524843. HH members are all siblings so not clear whom to assign the 13 y/o to. In following wave a mother and father appear.

        *Not sure what to do with this HH a_hidp==1633258003. 13 y/o who appears unrelated to all other HH members. Not in subsequent wave.
		
		* Put <10 depkid in BU with 55 year old male 
        qui replace `w'buno_dv = 1 if a_hidp==136843883 & a_pno==3
        qui replace bunoi = 1 if a_hidp==136843883 & a_pno==3	
		
		* Put <10 depkid in BU with couple  
        qui replace `w'buno_dv = 1 if a_hidp==204507963 & a_pno==5
        qui replace bunoi = 1 if a_hidp==204507963 & a_pno==5
		
		* Put <10 depkid in BU with couple  
        qui replace `w'buno_dv = 1 if a_hidp==478654723 & a_pno==4
        qui replace bunoi = 1 if a_hidp==478654723 & a_pno==4
		
		* Put 2 times <10 depkid in BU with married 40 year old 
        qui replace `w'buno_dv = 2 if a_hidp==749672871 & a_pno==3
        qui replace bunoi = 1 if a_hidp==749672871 & a_pno==3
        qui replace `w'buno_dv = 2 if a_hidp==749672871 & a_pno==4
        qui replace bunoi = 1 if a_hidp==749672871 & a_pno==4

        qui replace cantassignbuno = inlist(a_hidp,68442683,817810843,748898283,137865923,1430524843,1633258003)

    }

    if `wi'==2 {

        *13 y/o in own BUNO - put with 42 y/o adult
        qui replace `w'buno_dv = 1 if b_hidp==144146402 & b_pno==3
        qui replace bunoi = 1 if b_hidp==144146402 & b_pno==3

        *Child under 16 (in own BU) is plausible sibling of child in BU == 1
        qui replace `w'buno_dv = 1 if b_hidp==310372402 & b_pno==4
        qui replace bunoi = 1 if b_hidp==310372402 & b_pno==4

        *Child under 16 (in own BU) is plausible sibling of child in BU == 1
        qui replace `w'buno_dv = 1 if b_hidp==749904002 & b_pno==5
        qui replace bunoi = 1 if b_hidp==749904002 & b_pno==5

       *Child under 16 (in own BU) is plausible sibling of child in BU == 1
        qui replace `w'buno_dv = 1 if b_hidp==749904002 & b_pno==5
        qui replace bunoi = 1 if b_hidp==749904002 & b_pno==5

        *Child under 16 (in own BU) - put in BU of oldest adult (other adult is 12 years older)
        qui replace `w'buno_dv = 1 if b_hidp==752814402 & b_pno==3
        qui replace bunoi = 1 if b_hidp==752814402 & b_pno==3

        *Child under 16 (in own BU) - put in BU of oldest adult (other adult is only 12 years older than them)
        qui replace `w'buno_dv = 1 if b_hidp==823990002 & b_pno==3
        qui replace bunoi = 1 if b_hidp==823990002 & b_pno==3

        *Child under 16 (in own BU) - put in BU of 35 y/o women (rather than 59 y/o female)
        qui replace `w'buno_dv = 2 if b_hidp==824384402 & b_pno==3
        qui replace bunoi = 1 if b_hidp==824384402 & b_pno==3

        *Child under 16 (in own BU) is plausible sibling of children in other BU == 1
        qui replace `w'buno_dv = 1 if b_hidp==825397602 & b_pno==6
        qui replace bunoi = 1 if b_hidp==825397602 & b_pno==6

        *Child under 16 (in own BU) - put in BU of married couple
        qui replace `w'buno_dv = 1 if b_hidp==887950802 & b_pno==3
        qui replace bunoi = 1 if b_hidp==887950802 & b_pno==3

        *Child under 16 (in own BU) are siblings of 20 y/o and 17 y/o assume the 20 y/o is responsible for them
        qui replace `w'buno_dv = 1 if b_hidp==1432270402 & b_pno>=3
        qui replace bunoi = 1 if b_hidp==1432270402 & b_pno>=3

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 8 if b_hidp==340129202 & b_pno==8
        qui replace bunoi = 1 if b_hidp==340129202 & b_pno==8

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 3 if b_hidp==483242002 & b_pno==3
        qui replace bunoi = 1 if b_hidp==483242002 & b_pno==3

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 3 if b_hidp==648203202 & b_pno==2
        qui replace bunoi = 1 if b_hidp==648203202 & b_pno==2

    }

    if `wi'==3 {

        *Child under 16 assign to BU of 43 y/o adult
        qui replace `w'buno_dv = 1 if c_hidp==144629204 & c_pno==3
        qui replace bunoi = 1 if c_hidp==144629204 & c_pno==3

        *Child under 16 assign to BU of 55 y/o adult
        qui replace `w'buno_dv = 1 if c_hidp==753195204 & c_pno==3
        qui replace bunoi = 1 if c_hidp==753195204 & c_pno==3

        *Child under 16 assign to BU of 73 y/o adult
        qui replace `w'buno_dv = 1 if c_hidp==817890404 & c_pno==3
        qui replace bunoi = 1 if c_hidp==817890404 & c_pno==3

        *Child under 16 assign to BU of 73 y/o adult
        qui replace `w'buno_dv = 2 if c_hidp==824785604 & c_pno==3
        qui replace bunoi = 1 if c_hidp==824785604 & c_pno==3

        *Child under 16 assign to BU of 54 y/o adult
        qui replace `w'buno_dv = 1 if c_hidp==1297569204 & c_pno==3
        qui replace bunoi = 1 if c_hidp==1297569204 & c_pno==3

        *Child under 16 (in own BU) are siblings of 18 y/o and 16 y/o assume the 18 y/o is responsible for them
        qui replace `w'buno_dv = 1 if c_hidp==1432413204 & inlist(c_pno,3,4)
        qui replace bunoi = 1 if c_hidp==1432413204 & inlist(c_pno,3,4)

        *Child under 16 (in own BU) assume responsibilty of 50 y/o
        qui replace `w'buno_dv = 1 if c_hidp==1504391204 & inlist(c_pno,4,6)
        qui replace bunoi = 1 if c_hidp==1504391204 & inlist(c_pno,4,6)

    }

    if `wi'==4 {

        *Child under 16 assign to BU of 44 y/o adult
        qui replace `w'buno_dv = 1 if d_hidp==144051206 & d_pno==3
        qui replace bunoi = 1 if d_hidp==144051206 & d_pno==3

        *0 old child of 15 year old. Put in BU of grandparent
        qui replace `w'buno_dv = 1 if d_hidp==340170006 & d_pno==5
        qui replace bunoi = 1 if d_hidp==340170006 & d_pno==5

        *Child under 16 assign to BU of 55 and 50 y/o adults
        qui replace `w'buno_dv = 1 if d_hidp==418750806 & d_pno==3
        qui replace bunoi = 1 if d_hidp==418750806 & d_pno==3

        *Child under 16 assign to BU of 56 and 53 y/o adults
        qui replace `w'buno_dv = 1 if d_hidp==689669606 & d_pno==5
        qui replace bunoi = 1 if d_hidp==689669606 & d_pno==5

        *Child under 16. Put in BU of 56 y/o.
        qui replace `w'buno_dv = 1 if d_hidp==752930006 & d_pno==3
        qui replace bunoi = 1 if d_hidp==752930006 & d_pno==3

        *Child under 16. Put in BU of 61 y/o.
        qui replace `w'buno_dv = 1 if d_hidp==824302806 & d_pno==3
        qui replace bunoi = 1 if d_hidp==824302806 & d_pno==3

        *Child under 16. Put in BU of 55 y/o.
        qui replace `w'buno_dv = 1 if d_hidp==1297154406 & d_pno==3
        qui replace bunoi = 1 if d_hidp==1297154406 & d_pno==3

        *Children under 16 with no adult relations. Put in BU of 55 y/o.
        qui replace `w'buno_dv = 1 if d_hidp==1503779206 & inlist(d_pno,4,6,7)
        qui replace bunoi = 1 if d_hidp==1503779206 & inlist(d_pno,4,6,7)

        *19 year old put in same BU as 19 y/o sibling. Put in own BU.
        qui replace `w'buno_dv = 7 if d_hidp==688364006 & d_pno==4
        qui replace bunoi = 1 if d_hidp==688364006 & d_pno==4

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 12 if d_hidp==1504085206 & d_pno==12
        qui replace bunoi = 1 if d_hidp==1504085206 & d_pno==12

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 12 if d_hidp==483092406 & d_pno==5
        qui replace bunoi = 1 if d_hidp==483092406 & d_pno==5

        *Put 20 y/o in own benefit unit
        qui replace `w'buno_dv = 6 if d_hidp==1027106006 & d_pno==9
        qui replace bunoi = 1 if d_hidp==1027106006 & d_pno==9

        *impossible to assign children among many possible adult heads in these bunos
        qui replace cantassignbuno = inlist(d_hidp,1503922006,1027711206)

    }

    if `wi'==5 {

        *Put 14 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==142405608 & e_pno==4
        qui replace bunoi = 1 if `w'hidp==142405608 & e_pno==4

        *Put 10 y/o in BU of couple (one of whom is mother)
        qui replace `w'buno_dv = 1 if `w'hidp==612428408 & e_pno==3
        qui replace bunoi = 1 if `w'hidp==612428408 & e_pno==3

        *Put 13 y/o in BU of couple (one of whom is mother)
        qui replace `w'buno_dv = 1 if `w'hidp==688228008 & e_pno==6
        qui replace bunoi = 1 if `w'hidp==688228008 & e_pno==6

        *Put 14 y/o in BU of 57 y/o (who has one child in hh)
        qui replace `w'buno_dv = 1 if `w'hidp==752154808 & e_pno==3
        qui replace bunoi = 1 if `w'hidp==752154808 & e_pno==3

        *Put 12 y/o in BU of 38 y/o
        qui replace `w'buno_dv = 2 if `w'hidp==822861208 & e_pno==3
        qui replace bunoi = 1 if `w'hidp==822861208 & e_pno==3

        *Put 11 y/o in BU of 56 y/o
        qui replace `w'buno_dv = 2 if `w'hidp==1296542408 & e_pno==3
        qui replace bunoi = 1 if `w'hidp==1296542408 & e_pno==3

        *Put 11 y/o in BU of 56 y/o
        qui replace `w'buno_dv = 5 if `w'hidp==1431869208 & e_pno==4
        qui replace bunoi = 1 if `w'hidp==1431869208 & e_pno==4

        *Put unassigned kids in BUNO of 52 y/o (other 19 and 18 y/o are her daugthers)
        qui replace `w'buno_dv = 1 if `w'hidp==1503051608 & inlist(e_pno,4,6,7)
        qui replace bunoi = 1 if `w'hidp==1503051608 & inlist(e_pno,4,6,7)

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if e_hidp==1295141608 & e_pno==2
        qui replace bunoi = 1 if e_hidp==1295141608 & e_pno==2

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 5 if e_hidp==1366079208 & e_pno==5
        qui replace bunoi = 1 if e_hidp==1366079208 & e_pno==5
		
		* Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 5 if e_hidp==1230262808 & e_pno==9
        qui replace bunoi = 1 if e_hidp==1230262808 & e_pno==9

    }

    if `wi'==6 {

        *Put 15 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==141827610 & f_pno==4
        qui replace bunoi = 1 if `w'hidp==141827610 & f_pno==4

        *Put 11 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==612374010 & f_pno==3
        qui replace bunoi = 1 if `w'hidp==612374010 & f_pno==3

        *Put 15 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==751821610 & f_pno==3
        qui replace bunoi = 1 if `w'hidp==751821610 & f_pno==3

        *set all to same BU (parents put their children as their parents!)
        qui replace `w'buno_dv = 1 if `w'hidp==819644810
        qui replace bunoi = 1 if `w'hidp==819644810

        *Put 15 y/o in BU of 39 y/o
        qui replace `w'buno_dv = 2 if `w'hidp==822330810 & f_pno==3
        qui replace bunoi = 1 if `w'hidp==822330810 & f_pno==3

        *set all to same BU (obviously couple and kids)
        qui replace `w'buno_dv = 1 if `w'hidp==1026480410
        qui replace bunoi = 1 if `w'hidp==1026480410

        *set all to same BU (obviously couple and kids)
        qui replace `w'buno_dv = 1 if `w'hidp==1099702810
        qui replace bunoi = 1 if `w'hidp==1099702810

        *Put 12 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==1296134410 & f_pno==3
        qui replace bunoi = 1 if `w'hidp==1296134410 & f_pno==3

        *Put 12 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==1305912810 & f_pno==4
        qui replace bunoi = 1 if `w'hidp==1305912810 & f_pno==4

        *Put child of unknown age in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==1431372810 & f_pno==4
        qui replace bunoi = 1 if `w'hidp==1431372810 & f_pno==4

        *Put unassigned children in BU of oldest adult (she has two 20 y/o kids - relationship with under 16s unknown)
        qui replace `w'buno_dv = 1 if `w'hidp==1502324010 & inlist(f_pno,4,6,7)
        qui replace bunoi = 1 if `w'hidp==1502324010 & inlist(f_pno,4,6,7)

        *Put 20 y/o in own benefit unit
        qui replace `w'buno_dv = 5 if `w'hidp==549623610 & f_pno==5
        qui replace bunoi = 1 if `w'hidp==549623610 & f_pno==5

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 7 if `w'hidp==1100342010 & f_pno==5
        qui replace bunoi = 1 if `w'hidp==1100342010 & f_pno==5

        *Put 20 y/o in own benefit unit
        qui replace `w'buno_dv = 5 if `w'hidp==1509069610 & f_pno==3
        qui replace bunoi = 1 if `w'hidp==1509069610 & f_pno==3
		
		* Put under 10 y/ow with married couple 
        qui replace `w'buno_dv = 3 if `w'hidp==275719610 & f_pno==2
        qui replace bunoi = 1 if `w'hidp==275719610 & f_pno==2
		
		*unable to assign children to adults in this buno
        qui replace cantassignbuno = inlist(f_hidp,144173610,622662410,685521610,1365623610)


    }

    if `wi'==7 {

        *Put 11 y/o in BU of oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==76112412 & g_pno==5
        qui replace bunoi = 1 if `w'hidp==76112412 & g_pno==5

        *Put unassigned children in BU of oldest adult (relationship with kids unknown)
        qui replace `w'buno_dv = 1 if `w'hidp==141433212 & inlist(g_pno,8,9)
        qui replace bunoi = 1 if `w'hidp==141433212 & inlist(g_pno,8,9)

        *Put 16 y/o in BU of couple
        qui replace `w'buno_dv = 1 if `w'hidp==212207612 & g_pno==6
        qui replace bunoi = 1 if `w'hidp==212207612 & g_pno==6

        *Put 12 y/o in BU of couple
        qui replace `w'buno_dv = 1 if `w'hidp==612367212 & g_pno==3
        qui replace bunoi = 1 if `w'hidp==612367212 & g_pno==3

        *Put 14 y/o in BU of 40 y/o
        qui replace `w'buno_dv = 2 if `w'hidp==822126812 & g_pno==3
        qui replace bunoi = 1 if `w'hidp==822126812 & g_pno==3

        *Put 14 y/o in BU of couple + other kids
        qui replace `w'buno_dv = 1 if `w'hidp==1229888812 & g_pno==6
        qui replace bunoi = 1 if `w'hidp==1229888812 & g_pno==6

        *Put under 16 y/o in BU of couple
        qui replace `w'buno_dv = 1 if `w'hidp==1431175612 & g_pno==4
        qui replace bunoi = 1 if `w'hidp==1431175612 & g_pno==4

        *Put 5 y/o in BU possible single parent
        qui replace `w'buno_dv = 1 if `w'hidp==1566713212 & g_pno==4
        qui replace bunoi = 1 if `w'hidp==1566713212 & g_pno==4

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 4 if `w'hidp==1434058812 & g_pno==4
        qui replace bunoi = 1 if `w'hidp==1434058812 & g_pno==4

        *unable to assign children to adults in this buno
        qui replace cantassignbuno = inlist(g_hidp,755936292)

    }

    if `wi'==8 {

        *Put 14 y/o in BU with oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==141467214 & h_pno==4
        qui replace bunoi = 1 if `w'hidp==141467214 & h_pno==4

        *Put 13 y/o in BU with couple
        qui replace `w'buno_dv = 1 if `w'hidp==547821614 & h_pno==5
        qui replace bunoi = 1 if `w'hidp==547821614 & h_pno==5

        *Put 10 y/o in BU with couple
        qui replace `w'buno_dv = 1 if `w'hidp==753168014 & h_pno==8
        qui replace bunoi = 1 if `w'hidp==753168014 & h_pno==8

        *Put 12 y/o in BU with couple
        qui replace `w'buno_dv = 1 if `w'hidp==753589614 & h_pno==5
        qui replace bunoi = 1 if `w'hidp==753589614 & h_pno==5

        *Put 15 y/o in BU 65 y/o
        qui replace `w'buno_dv = 1 if `w'hidp==821814014 & h_pno==3
        qui replace bunoi = 1 if `w'hidp==821814014 & h_pno==3

        *Put 8 y/o in BU with couple
        qui replace `w'buno_dv = 1 if `w'hidp==1430998814 & h_pno==4
        qui replace bunoi = 1 if `w'hidp==1430998814 & h_pno==4

        *Put 6 y/o in BU with 27 y/o
        qui replace `w'buno_dv = 1 if `w'hidp==1566468414 & h_pno==4
        qui replace bunoi = 1 if `w'hidp==1566468414 & h_pno==4

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 4 if `w'hidp==1093786814 & h_pno==4
        qui replace bunoi = 1 if `w'hidp==1093786814 & h_pno==4

    }

    if `wi'==9 {

        *Put 15 y/o in BU with oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==140977616 & i_pno==3
        qui replace bunoi = 1 if `w'hidp==140977616 & i_pno==3

        *Put 11 y/o in BU with oldest adult
        qui replace `w'buno_dv = 1 if `w'hidp==752515216 & i_pno==8
        qui replace bunoi = 1 if `w'hidp==752515216 & i_pno==8

        *put 11 and 13 year olds in buno with oldest adult (58 year old woman)
        qui replace `w'buno_dv = 1 if i_hidp==551554816 & inlist(i_pno,4,5)
        qui replace bunoi = 1 if i_hidp==551554816 & inlist(i_pno,4,5)

        *put 11 and 13 year olds in buno with oldest adult (58 year old woman)
        qui replace `w'buno_dv = 1 if i_hidp==551554816 & inlist(i_pno,4,5)
        qui replace bunoi = 1 if i_hidp==551554816 & inlist(i_pno,4,5)

        *put 7 year old in buno with 28 year old 
        qui replace `w'buno_dv = 1 if i_hidp==1566148816 & i_pno==4
        qui replace bunoi = 1 if i_hidp==1566148816 & i_pno==4

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if `w'hidp==1501433216 & i_pno==6
        qui replace bunoi = 1 if `w'hidp==1501433216 & i_pno==6

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if `w'hidp==410597616 & i_pno==2
        qui replace bunoi = 1 if `w'hidp==410597616 & i_pno==2

    }

    if `wi'==10 {

	*Put 15 y/o in BU with oldest adult
	qui replace `w'buno_dv = 1 if `w'hidp==140841618 & j_pno==4
        qui replace bunoi = 1 if `w'hidp==140841618 & j_pno==4

	*Put 12 and 15 y/o in BU married couple
	qui replace `w'buno_dv = 1 if `w'hidp==213499618 & inlist(j_pno,3,5)
        qui replace bunoi = 1 if `w'hidp==213499618 & inlist(j_pno,3,5)

	*Put 13 y/o in BU with oldest adult
	qui replace `w'buno_dv = 1 if `w'hidp==341251218 & j_pno==5
        qui replace bunoi = 1 if `w'hidp==341251218 & j_pno==5

	*Put 8 y/o in BU with married couple 
	qui replace `w'buno_dv = 2 if `w'hidp==545203618 & j_pno==1
        qui replace bunoi = 1 if `w'hidp==545203618 & j_pno==1

	*Put 15 y/o in BU with couple living together 
	qui replace `w'buno_dv = 1 if `w'hidp==547162018 & j_pno==5
        qui replace bunoi = 1 if `w'hidp==547162018 & j_pno==5

	*Put 15 y/o in BU with couple living together 
	qui replace `w'buno_dv = 1 if `w'hidp==547162018 & j_pno==5
        qui replace bunoi = 1 if `w'hidp==547162018 & j_pno==5

	*Put 10 y/o in BU with oldest adult
	qui replace `w'buno_dv = 1 if `w'hidp==551405218 & j_pno==3
        qui replace bunoi = 1 if `w'hidp==551405218  & j_pno==3

	*Put all three in BU together (two living together with 8 y/o child - parents put 8 y/o as biological parent)
	qui replace `w'buno_dv = 1 if `w'hidp==681156018 & inlist(j_pno,1,2,3)
        qui replace bunoi = 1 if `w'hidp==681156018 & inlist(j_pno,1,2,3)

	*Put 15 y/o in BU with married couple 
	qui replace `w'buno_dv = 1 if `w'hidp==1564251618 & j_pno==5
        qui replace bunoi = 1 if `w'hidp==1564251618 & j_pno==5

	*Put 8 y/o in BU with married couple 
	qui replace `w'buno_dv = 2 if `w'hidp==1566046818 & j_pno==4
        qui replace bunoi = 1 if `w'hidp==1566046818 & j_pno==4

	*Put 15 y/o in BU with oldest adult
	qui replace `w'buno_dv = 1 if `w'hidp==1637222418 & j_pno==4
        qui replace bunoi = 1 if `w'hidp==1637222418 & j_pno==4

	*Put 15 y/o in BU with oldest adult (their 19 year old brother)
	qui replace `w'buno_dv = 1 if `w'hidp==1297718818 & j_pno==4
        qui replace bunoi = 1 if `w'hidp==1297718818 & j_pno==4

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if `w'hidp==551731618 & j_pno==5
        qui replace bunoi = 1 if `w'hidp==551731618 & j_pno==5

    }

    if `wi'==11 {
		
        *Put 15 y/o in benefit unit with mother
        qui replace `w'buno_dv = 1 if `w'hidp==69931220 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==69931220 & k_pno==3

        *Put children under 13 in benefit unit oldest hh member
        qui replace `w'buno_dv = 1 if `w'hidp==141446820 & inlist(k_pno,3,4,5)
        qui replace bunoi = 1 if `w'hidp==141446820 & inlist(k_pno,3,4,5)

        *Put father in same BU as children and their mother (and new born in same BU as grandmother as mother is 15)
        qui replace `w'buno_dv = 1 if `w'hidp==211520820 & inlist(k_pno,2,7)
        qui replace bunoi = 1 if `w'hidp==211520820 & inlist(k_pno,2,7)
		*Also since these people live with their biological chidren put them together as a couple
		qui replace k_mastat_dv =10  if `w'hidp==211520820 & inlist(k_pno,1,2)
		qui replace mastati =1  if `w'hidp==211520820 & inlist(k_pno,1,2)
		qui replace k_ppno =1  if `w'hidp==211520820 & k_pno==2
		qui replace k_ppno =2  if `w'hidp==211520820 & k_pno==1
		qui replace ppnoi=1  if `w'hidp==211520820 & inlist(k_pno,1,2)

	*This family seems to be merge of three hhs relative to the previous waves put each of the three hhs in their own BU (in previous wave this person was mother to the kids in buno==5)
	qui replace `w'buno_dv = 5 if `w'hidp==414453220 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==414453220 & k_pno==3

		*Put new born in same BU as 24 year old
		qui replace `w'buno_dv = 3 if `w'hidp==415194420 & k_pno==2
        qui replace bunoi = 1 if `w'hidp==415194420 & k_pno==2

		*Put 9 year old in same buno as 46 and 48 year old couple
		qui replace `w'buno_dv = 2 if `w'hidp==545122020 & k_pno==1
        qui replace bunoi = 1 if `w'hidp==545122020 & k_pno==1

		*Put 8 year old in same buno as oldest hh member
		qui replace `w'buno_dv = 2 if `w'hidp==822719100 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==822719100 & k_pno==3

		*Put 4 year old in same buno as oldest hh member (in previous wave was coded as this person's daughter)
		qui replace `w'buno_dv = 1 if `w'hidp==1024263620 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==1024263620 & k_pno==3

		*Put 7 year old in same bu with 22 y/o man (previous wave he was given as father)
		qui replace `w'buno_dv = 1 if `w'hidp==1158849220 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==1158849220 & k_pno==3

		*Not sure what to do with this one - 1226645220 - not sure who new born belongs to (couple or 19 year old)

		*Not sure what to do with this one - 1292972420- not sure who 2 y.o belongs to (couple or 22 year old)

		*Put all in same BU (male and female who are married with two children not listed as theirs) - also correct relationship status (in previous wave were married to each other which makes sense)
		qui replace `w'buno_dv = 1 if `w'hidp==1360667100
		qui replace bunoi = 1 if `w'hidp==1360667100
		qui replace k_ppno =1  if `w'hidp==1360667100 & k_pno==2
		qui replace k_ppno =2  if `w'hidp==1360667100 & k_pno==1
		qui replace ppnoi =1  if `w'hidp==1360667100 & inlist(k_pno,1,2)

		*Not sure what to do with this one - 1636100420 - two hh members refuse to disclose age

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if `w'hidp==208556020 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==208556020 & k_pno==3

        *Put 19 y/o in own benefit unit
        qui replace `w'buno_dv = 2 if `w'hidp==1225788420 & k_pno==3
        qui replace bunoi = 1 if `w'hidp==1225788420 & k_pno==3

		qui replace cantassignbuno = inlist(k_hidp,1226645220,1292972420,1636100420)
	
    }
	
	if `wi' == 12 {
		
		* Put 15-year-old dependent child in BU with 51-year-old 
		qui replace `w'buno_dv = 1 if `w'hidp == 69190022 & l_pno == 2
		qui replace bunoi = 1 if `w'hidp == 69190022 & l_pno == 2
	
		* Put 0-year-old in BU with 22-year-old 
		qui replace `w'buno_dv = 3 if `w'hidp == 136108822 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 136108822 & l_pno == 4
		
		* Put 13-year-old in BU with 52-year-old 
		qui replace `w'buno_dv = 1 if `w'hidp == 140209222 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 140209222 & l_pno == 3
	
		* Not sure what to do with: 61-y-o female reports divorced, 29-y-o reports single never married, 3 kids (14, 13, 9) reported as siblings but no parents. 61-y-o reports that 29-y-o is their father.
	
		* Put 15-y-o with 47-y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 275950822 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 275950822 & l_pno == 5
		
		* Put 15-y-o with 45/46-y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 413426422 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 413426422 & l_pno == 4
		
		* Put 10-y-o with 47/49-y-o couple 
		qui replace `w'buno_dv = 2 if `w'hidp == 545094822 & l_pno == 1
		qui replace bunoi = 1 if `w'hidp == 545094822 & l_pno == 1
		
		* Put 12 and 14-y-o with 38/48-y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 548324822 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 548324822 & l_pno == 4
		qui replace `w'buno_dv = 1 if `w'hidp == 548324822 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 548324822 & l_pno == 5
		
		* Put 10-y-o with 51-y-o female 
		qui replace `w'buno_dv = 1 if `w'hidp == 681346422 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 681346422 & l_pno == 3
	
		* Put 13-y-o with 41/43-y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 683434022 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 683434022 & l_pno == 4
		
		* Put 3 and ?-y-o with 29/32-y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 683774022 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 683774022 & l_pno == 3
		qui replace `w'buno_dv = 1 if `w'hidp == 683774022 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 683774022 & l_pno == 4
		
		* Put 15-y-o with 53-y-o married male
		qui replace `w'buno_dv = 1 if `w'hidp == 820256822 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 820256822 & l_pno == 5
		
		* Put 16-y-o dep kid with couple 
		qui replace `w'buno_dv = 3 if `w'hidp == 953611622 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 953611622 & l_pno == 3
		
		* Not sure what to do with: 58 y-o, 49 y-o, 23 y-o and 9 y-o, no one reports a partner, parents or kids
	
		* Put 15 and 12 y-o with 44 y-o 
		qui replace `w'buno_dv = 1 if `w'hidp == 956834822 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 956834822 & l_pno == 4
		qui replace `w'buno_dv = 1 if `w'hidp == 956834822 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 956834822 & l_pno == 5
		
		* Put 15 and 11 y-o with 50 and 42 y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 1092025622 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 1092025622 & l_pno == 5
		qui replace `w'buno_dv = 1 if `w'hidp == 1092025622 & l_pno == 6
		qui replace bunoi = 1 if `w'hidp == 1092025622 & l_pno == 6
		
		* Not sure what to do with: one child aged 0 and four single females in their 20s
	
		* Put 12 y-o with 55 and 43 y-o couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 1161018422 & l_pno == 6
		qui replace bunoi = 1 if `w'hidp == 1161018422 & l_pno == 6
	
		* Put 1 and 11 year old with 28 and 31 year old couple 
		qui replace `w'buno_dv = 5 if `w'hidp == 1226339222 & l_pno == 1
		qui replace bunoi = 1 if `w'hidp == 1226339222 & l_pno == 1
		qui replace `w'buno_dv = 5 if `w'hidp == 1226339222 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 1226339222 & l_pno == 4
		
		* Put 2 kids with married couple 
		qui replace `w'buno_dv = 1 if `w'hidp == 1229317622 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 1229317622 & l_pno == 3
		qui replace `w'buno_dv = 1 if `w'hidp == 1229317622 & l_pno == 4
		qui replace bunoi = 1 if `w'hidp == 1229317622 & l_pno == 4
		
		* Not sure what to do with: 13 year old who lives with 5 single adults 
	
		* Put 15 year old with 47 year old female
		qui replace `w'buno_dv = 1 if `w'hidp == 1564380822 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 1564380822 & l_pno == 3	
		
		* Put 12 year old with married couple
		qui replace `w'buno_dv = 3 if `w'hidp == 1565781622 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 1565781622 & l_pno == 3
		
		* Put 8 year old with 47 year old female
		qui replace `w'buno_dv = 1 if `w'hidp == 1633230822 & l_pno == 3
		qui replace bunoi = 1 if `w'hidp == 1633230822 & l_pno == 3
			
		* Put 12 year old with married couple
		qui replace `w'buno_dv = 1 if `w'hidp == 1634944422 & l_pno == 5
		qui replace bunoi = 1 if `w'hidp == 1634944422 & l_pno == 5
		
		* Don't know what to do with : various children under 10 living with multiple adults (final 3 hhs below)
	
		* Put 19 year old in own BU 
		qui replace `w'buno_dv = 2 if `w'hidp==409115222 & l_pno==4
        qui replace bunoi = 1 if `w'hidp==409115222 & l_pno==4
		
		* Put 19 year old in own BU 
		qui replace `w'buno_dv = 2 if `w'hidp==1568719222 & l_pno==4
        qui replace bunoi = 1 if `w'hidp==1568719222 & l_pno==4
		
		* Put 19 year old in own BU 
		qui replace `w'buno_dv = 2 if `w'hidp==1024229622 & l_pno==2
        qui replace bunoi = 1 if `w'hidp==1024229622 & l_pno==2
		
		* Put 16 year old depchild in BU of married couple 
		qui replace `w'buno_dv = 1 if `w'hidp==953611622 & l_pno==3
		qui replace bunoi = 1 if `w'hidp==953611622 & l_pno==3
		
		* Put 11 and 1 year old depchild in BU of couple 
		qui replace `w'buno_dv = 2 if `w'hidp==1226339222 & l_pno==1
        qui replace bunoi = 1 if `w'hidp==1226339222 & l_pno==1
		qui replace `w'buno_dv = 2 if `w'hidp==1226339222 & l_pno==4
        qui replace bunoi = 1 if `w'hidp==1226339222 & l_pno==4
	
		* Put 15 year old depchild in BU of married couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1565781622 & l_pno==3
        qui replace bunoi = 1 if `w'hidp==1565781622 & l_pno==3
		
		qui replace cantassignbuno = inlist(l_hidp,141106822,956780422,1090842422,1292061222,1362250822,1362992022,1499842022)
	
	}
	
	if `wi' == 13 {

		* Put 14 year old depchild in BU of adult
		qui replace `w'buno_dv = 1 if `w'hidp==139957624 & m_pno==3
		qui replace bunoi = 1 if `w'hidp==139957624 & m_pno==3
		
		*put 14 year old and 44 year old man in same bu as 42 year old female
		qui replace `w'buno_dv = 1 if `w'hidp==683311624 & m_pno==4
		qui replace bunoi = 1 if `w'hidp==683311624 & m_pno==4
		
		*put 13 year old in same buno as 50 year old woman (too old to be child of 25 y/o)
		qui replace `w'buno_dv = 1 if `w'hidp==683406824 & m_pno==4
		qui replace bunoi = 1 if `w'hidp==683406824 & m_pno==4
		
		*put 9 year in bu with their father
		qui replace `w'buno_dv = 2 if `w'hidp==1228970824 & m_pno==4
		qui replace bunoi = 1 if `w'hidp==1228970824 & m_pno==4
		
		*put 14 y/o in bu with couple
		qui replace `w'buno_dv = 1 if `w'hidp==1229222424 & m_pno==3
		qui replace bunoi = 1 if `w'hidp==1229222424 & m_pno==3
		
		*put 20 y/o in own bu
		qui replace `w'buno_dv = 2 if `w'hidp==548161624 &  m_pno==3
		qui replace bunoi = 1 if `w'hidp==548161624  & m_pno==3
		
		qui replace cantassignbuno = inlist(m_hidp,1292061224,1633244424,1292061224,1294162424,205836024)
		
	}
	
	if `wi' == 14 {
		
		* Put children in BU of married couple (were in same BU in previous wave)
		qui replace `w'buno_dv = 1 if `w'hidp==274237226 & inlist(n_pno,2,4,5,6,7,8,10,11,12)
		qui replace bunoi = 1 if `w'hidp==274237226 & inlist(n_pno,2,4,5,6,7,8,10,11,12)
		
		* Put 12 y/o in BU with married adult couple
		qui replace `w'buno_dv = 3 if `w'hidp==1383296826 & n_pno==5 
		qui replace bunoi = 1 if `w'hidp==1383296826 & n_pno==5
		
		* Put 12 y/o in BU with married adult
		qui replace `w'buno_dv = 1 if `w'hidp==95206826 & n_pno==3 
		qui replace bunoi = 1 if `w'hidp==95206826 & n_pno==3
		
		* Put 5 y/o in BU with married couple (same as last wave)
		qui replace `w'buno_dv = 1 if `w'hidp==139726426 & n_pno==5 
		qui replace bunoi = 1 if `w'hidp==139726426 & n_pno==5
		
		* Put 15 y/o in BU with older woman (other person  is their sister)
		qui replace `w'buno_dv = 1 if `w'hidp==139746826 & n_pno==3 
		qui replace bunoi = 1 if `w'hidp==139746826 & n_pno==3
		
		* Put 14 y/o in BU with older woman 
		qui replace `w'buno_dv = 1 if `w'hidp==139746826 & n_pno==3 
		qui replace bunoi = 1 if `w'hidp==139746826 & n_pno==3
		
		* Put children in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1113547626 & inlist(n_pno,4,5) 
		qui replace bunoi = 1 if `w'hidp==1113547626 & inlist(n_pno,4,5)
		
		* Put 14 y/o in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1115240826 & n_pno==4 
		qui replace bunoi = 1 if `w'hidp==1115240826 & n_pno==4
		
		* Put 14 y/o in BU with older woman 
		qui replace `w'buno_dv = 1 if `w'hidp==784692826 & n_pno==3 
		qui replace bunoi = 1 if `w'hidp==784692826 & n_pno==3
		
		* Put 8 y/o in BU with couple
		qui replace `w'buno_dv = 1 if `w'hidp==839582426 & n_pno==3 
		qui replace bunoi = 1 if `w'hidp==839582426 & n_pno==3
		
		* Put 4 y/o in BU with only adult woman
		qui replace `w'buno_dv = 1 if `w'hidp==1227910026 & n_pno==4 
		qui replace bunoi = 1 if `w'hidp==1227910026 & n_pno==4
		
		* Put 10 y/o in BU with only parents
		qui replace `w'buno_dv = 2 if `w'hidp==1228991226 & n_pno==4 
		qui replace bunoi = 1 if `w'hidp==1228991226 & n_pno==4
		
		* Put children in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1250479226 & inlist(n_pno,4,5) 
		qui replace bunoi = 1 if `w'hidp==1250479226 & inlist(n_pno,4,5)
		
		* Put child in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1456009226 & n_pno==7
		qui replace bunoi = 1 if `w'hidp==1456009226 & n_pno==7
		
		* Put children in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1657200826 & inlist(n_pno,6,7) 
		qui replace bunoi = 1 if `w'hidp==1657200826 & inlist(n_pno,6,7)
		
		qui replace cantassignbuno = inlist(n_hidp,232709626,572226826,580726826,683298026,683406824,750230426,683386426,753549506,1227876024,1229249626,1292061226,1362964826,1386275226,1499699226)
		
	}
	
	if `wi'==15 {
		* Put children in BU with female and male in bu with female member of couple
		qui replace `w'buno_dv = 6 if `w'hidp==614543228 & inlist(o_pno,6,8,9) 
		qui replace bunoi = 1 if `w'hidp==614543228 & inlist(o_pno,6,8,9)
		
		* Put children in BU with couple 
		qui replace `w'buno_dv = 1 if `w'hidp==1637902428 & inlist(o_pno,6,7) 
		qui replace bunoi = 1 if `w'hidp==1637902428 & inlist(o_pno,6,7)
		
		* Put child in BU with mother
		qui replace `w'buno_dv = 2 if `w'hidp==1228896028 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==1228896028 & inlist(o_pno,4)
		
		* Put child in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==1227794428 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==1227794428 & inlist(o_pno,4)
		
		* Put child in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==824690428 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==824690428 & inlist(o_pno,4)
		
		* Put child in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==683318428 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==683318428 & inlist(o_pno,4)
		
		* Put child in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==137591228 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==137591228 & inlist(o_pno,4)
		
		* Put children in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==73072828 & inlist(o_pno,4,5) 
		qui replace bunoi = 1 if `w'hidp==73072828 & inlist(o_pno,4,5)
		
		* Put child in BU with couple
		qui replace `w'buno_dv = 1 if `w'hidp==74235628 & inlist(o_pno,4) 
		qui replace bunoi = 1 if `w'hidp==74235628 & inlist(o_pno,4)
		
		* Put child in BU with couple
		qui replace `w'buno_dv = 1 if `w'hidp==138318828 & inlist(o_pno,3) 
		qui replace bunoi = 1 if `w'hidp==138318828 & inlist(o_pno,3)
		
		* Put children in BU with oldest man (18 y/o)
		qui replace `w'buno_dv = 1 if `w'hidp==753494428 & inlist(o_pno,3,4) 
		qui replace bunoi = 1 if `w'hidp==753494428 & inlist(o_pno,3,4)
		
		* Put children in BU with oldest woman
		qui replace `w'buno_dv = 1 if `w'hidp==954522828 & inlist(o_pno,3,4,5) 
		qui replace bunoi = 1 if `w'hidp==954522828 & inlist(o_pno,3,4,5)
		
		qui replace cantassignbuno = inlist(o_hidp,138318828,545054028,1429774828,750196428,1499665228)
	}
	
    assert bunoi<=1

    *recalculate number of bunos and ads number for checks
    drop noadsbuno
    drop numbunos
    qui bys `w'hidp (`w'buno_dv `w'pno): gen byte bunocounter = 1 if _n == 1
    qui bys `w'hidp (`w'buno_dv `w'pno): replace bunocounter = bunocounter[_n-1] + (`w'buno_dv != `w'buno_dv[_n-1]) if _n > 1
    egen byte numbunos = max(bunocounter), by(`w'hidp)
    label variable numbunos "Number of bunos in hh"
    drop bunocounter

    egen byte noadsbuno = min(`w'depchl_dv == 1), by(`w'hidp `w'buno_dv)
    label variable noadsbuno "Buno has no adults"

    if !inlist(`wi',3,7,8) {
            *in wave==3 c_hidp == 750455484 has only one 14 y/o (PL (02/01/2020))
            *in wave 7 g_hidp==889344812 has only one 7 y/o (PL 06/01/2020)
            *in wave 8 h_hidp==1433325094 has only one 1 y/o (PL 06/01/2020)
             capture assert numbunos == 2 if noadsbuno & cantassignbuno==0
             if _rc==9 {
                   noisily di in red "Error: households with no adult bunos have more than 2 bunos"
                   stop
             }

            capture assert noadshh == 0
             if _rc==9 {
               noisily di in red "Error: Some households have no adults"
               stop
             }
    }

    drop numbunos

    * 5. Check adults in buno
    *************************

    * Check no more than 2 adults in buno
    egen byte numadsbuno = total(`w'depchl_dv == 2), by(`w'hidp `w'buno_dv)

    if !inlist(`wi',3,7,8) {
            *in wave==3 c_hidp == 750455484 has only one 14 y/o (PL (02/01/2020))
            *in wave==7 g_hidp==889344812 has only one 7 y/o (OL 06/01/2020)
            *in wave 8 h_hidp==1433325094 has only one 1 y/o (OL 06/01/2020)
            capture assert numadsbuno <= 2 & numadsbuno>0 if cantassignbuno==0
            if _rc==9 {
                noisily di in red "Error: More than 2 adults in BU"
                stop
            }

            *When there are 2 adults, check they are partners
            capture assert `w'ppno > 0 & `w'ppno < . if (numadsbuno == 2 & `w'depchl_dv == 2)
            if _rc==9 {
                noisily di in red "Error: There are two adults in buno but they are not partners (usually non-depchild still assigned to parent)"
                stop
            }
    }

	end

******************************************

* This program just copies information across lines in the dataset (e.g. it can find out the marital status of the partner)
capture program drop createvars
program define createvars

    syntax namelist(min=1), wave(numlist integer max=1 >=1 <=$numwaves)

    local wi = `wave'
    local w = char(96+`wi') + "_"

    sort `w'hidp `w'pno
    su `w'pno, meanonly
    local maxpno = r(max)

    foreach var of local namelist {

        * Marital status of spouse
        if "`var'" == "ptrmastat" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'mastat_dv[\`i'] if (inlist(`w'mastat_dv,2,3,10) & (`w'ppno == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Marital status of partner"
        }

        * age of spouse
        else if "`var'" == "ptrage" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'dvage[\`i'] if (`w'ppno == `w'pno[\`i']) & (\`i' <= _N)"
            local label "Age of partner"
        }

        * sex of spouse
        else if "`var'" == "ptrsex" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'sex[\`i'] if (`w'ppno == `w'pno[\`i']) & (\`i' <= _N)"
            local label "Sex of partner"
        }

         * Spouse a depchild
        else if "`var'" == "ptrdepchl" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'depchl_dv[\`i'] if (`w'ppno == `w'pno[\`i']) & (\`i' <= _N)"
            local label "Partner is a depchild"
        }

        * Marital status of partner if one declared (for checking)
        else if "`var'" == "genptrmastat" {
            capture drop `var'
            qui gen int `var' = .
            local rhs "`w'mastat_dv[\`i'] if (`w'ppno == `w'pno[\`i']) & (\`i' <= _N)"
            local label "Marital status of partner (including for unmarried individuals)"
        }

        * Spouse number of spouse
        else if "`var'" == "ptrptrpno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'ppno[\`i'] if (inlist(`w'mastat_dv,2,3,10) & (`w'ppno == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Person number of partner of partner"
        }
        * Buno of spouse
        else if "`var'" == "ptrbuno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'buno_dv[\`i'] if (inlist(`w'mastat_dv,2,3,10) & (`w'ppno == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Buno of partner"
        }
        * New buno for partner (and dependents) when couple is split across bunos
        else if "`var'" == "newbuno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "ptrbuno[\`i'] if (`w'buno_dv == `w'buno_dv[\`i'] & `w'ppno[\`i'] > 0 & `w'buno_dv[\`i'] > ptrbuno[\`i'] & `w'buno_dv[\`i'] < .) & (\`i' <= _N)"
            local label "New buno for those that need changing"
        }
        * Number of responsible adults
        else if "`var'" == "numras" {
            capture drop `var'
            qui gen byte numras = 0 if (`w'adresp15_dv > 0 & `w'adresp15_dv < .)
            local rhs "numras + (`w'adresp15_dv == `w'pno[\`i']) if (`w'adresp15_dv > 0 & `w'adresp15_dv < .) & (\`i' <= _N)"
            local label "Number of responsible adults in household"
        }
        * Number of mothers
        else if "`var'" == "nummas" {
            capture drop `var'
            qui gen byte nummas = 0 if (`w'hgbiom > 0 & `w'hgbiom < .)
            local rhs "nummas + (`w'hgbiom == `w'pno[\`i']) if (`w'hgbiom > 0 & `w'hgbiom < .) & (\`i' <= _N)"
            local label "Number of mothers in household"
        }
        * Number of fathers
        else if "`var'" == "numfas" {
            capture drop `var'
            qui gen byte numfas = 0 if (`w'hgbiof > 0 & `w'hgbiof < .)
            local rhs "numfas + (`w'hgbiof == `w'pno[\`i']) if (`w'hgbiof > 0 & `w'hgbiof < .) & (\`i' <= _N)"
            local label "Number of fathers in household"
        }
        * Natural father's partner number
        else if "`var'" == "faptrpno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'ppno[\`i'] if ((inrange(`w'dvage,0,15) | `w'depchl_dv == 1) & (`w'hgbiof == `w'pno[\`i']) & inlist(`w'mastat_dv[\`i'],2,3,10)) & (\`i' <= _N)"
            local label "Person number of father's partner"
        }
        * Buno of responsible adult (only exists for those 0-15)
        else if "`var'" == "rabuno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'buno_dv[\`i'] if ((inrange(`w'dvage,0,15)| `w'depchl_dv == 1) & (`w'adresp15_dv == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Buno of responsible adult"
        }
        * Buno of natural mother (exists for everyone, but create only for dependents)
        else if "`var'" == "mabuno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'buno_dv[\`i'] if ((inrange(`w'dvage,0,15) | `w'depchl_dv == 1) & (`w'hgbiom == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Buno of mother"
        }
        * Buno of natural father (exists for everyone, but create only for dependents)
        else if "`var'" == "fabuno" {
            capture drop `var'
            qui gen byte `var' = .
            local rhs "`w'buno_dv[\`i'] if ((inrange(`w'dvage,0,15) | `w'depchl_dv == 1) & (`w'hgbiof == `w'pno[\`i'])) & (\`i' <= _N)"
            local label "Buno of father"
        }

        else {
            di as error "Unknown variable specified"
            exit 198
        }

        forval i = 1/`maxpno' {
            qui by `w'hidp (`w'pno): replace `var' = `rhs'
        }
        label variable `var' "`label'"

    }

end

exit

forval i = 1/`maxpno' {
    qui by `w'hidp (`w'pno): replace ptrmastat = `w'mastat_dv[`i'] if (inlist(`w'mastat,2,3,10) & (`w'hgpart == `w'pno[`i'])) & (`i' <= _N)
}


