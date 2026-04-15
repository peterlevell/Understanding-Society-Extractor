/*
**************DESCRIPTION***********************************************************************************************

FILE:       	usextract.ado
PURPOSE:    	Generic programs to set up parts of Understanding Society data
AUTHOR:     	Peter Levell (based on programme by Jonathan Shaw)
THIS VERSION: 	04/12/14


DETAILS:		Comprises 3 programs:

				- usextract: create individual-level dataset across multiple waves
				- us_indiv_dataset: create individual-level dataset (indall, indresp and hhresp variables) for a single wave

				Note: programs creating spell datasets are not complete. bhps_spell_dataset is unfinished and there is
				no spell program across multiple waves corresponding to bhpsextract


TYPICAL USE:  	See example usage.do for more complete examples

				#delimit;
				usextract using "p:\ge tax credits\data\test.dta",
					waves(1(1)3)
					hhrespoptions(...)
					hhsampoptions(...)
					indalloptions(...)
					indrespoptions(...)
					keepdepkid
					keepindwoiv
					dropnohhiv
					b4prevint(name)
					daysbetwint(name)
					daysworked(name)
					ethnic(name)
					;
				#delimit cr;


**************LOG*******************************************************************************************************

04/12/14 Created (PSL)
10/08/18 Sorted cross-wave identifiers (David Sturrock)
16/08/18 Sorted problems with merging of household and individual files
23/03/26 Added in Xwave file - use xwavedat to correct sex before fixing bunos

**************NOTES*****************************************************************************************************

04/12/14 Based on bhpsextract written by Jonathan Shaw

************************************************************************************************************************


*/

pause on

global numwaves = 15

***************************************************************
* Create and append individual-level dataset across all waves *
***************************************************************

program define usextract

    # delimit;


    syntax using/,               waves(numlist integer >=1 <=$numwaves sort)          /*the "/" after using means that the file name is not stored in quotes*/
                                [
                                hhrespoptions(string)
                                hhsampoptions(string)
                                indalloptions(string)
                                indrespoptions(string)
								xwaveoptions(string)
								uprate(string)
                                keepdepkid
                                keepindwoiv
								dropnohhiv
								neednotexist
								mindic
								
                                replace
                                ];


    if "`indrespoptions'" != "" {;    			    * Parse intdate only (needed lower down for uprating);
    local optionspec            intdate(string)         /* intdate(name) intyear(name) intmonth(name) */
								earndate(string)		/* earndate(name) earnmth(name) earnyear(name) */
								jb1earn(string)			/* jb1earn(name) jb1earni(name) */
								jb1wage(string)			/* jb1wage(name) hrscap(numlist integer max=1 >0) */
                                ;

								check_option_syntax, optionspec(`optionspec') optionlist(`indrespoptions') ignore;
	};

    * Tidy up compound intdate options;
    local intdate_syntax        "intdate(name)
                                intyear(name)
                                intmonth(name)";
    local earndate_syntax       "earndate(name)
                                earnmth(name)
                                earnyear(name)";
    local jb1earn_syntax        "jb1earn(name)
                                jb1earni(name)";
    local jb1wage_syntax        "jb1wage(name)
                                hrscap(numlist integer max=1 >0)";
    local uprate_syntax        	"year(numlist integer min=1 max=1  >=1987 <=2020)
                                month(numlist integer min=1 max=1 >=1 <=12)";

	# delimit cr

	local filename "`using'"
    if "`replace'" == "" confirm new file "`filename'"

	foreach cvar in intdate earndate jb1earn jb1wage uprate {
		if "``cvar''" != "" {
			local 0 ", ``cvar''"
			syntax [, ``cvar'_syntax']
		}
		macro drop _`cvar'_syntax
	}


	* Check intdate is specified if uprate is requested
	if ("`uprate'" != "") & ("`intdate'" == "") {
		di as error "intdate must be specified if option uprate() is specified"
		exit 198
	}


	* Check earndate is specified if uprate and jb1earn or jb1wage are specified
	if ("`uprate'" != "") & (("`jb1earn'" != "") | ("`jb1wage'" != "")) & ("`earndate'" == "") {
		di as error "earndate must be specified if option uprate() is specified and either jb1earn or jb1wage are extracted"
		exit 198
	}

	* Make crosswave identifiers dataset (DS: 8/18) *
	clear
	local datasets ""
	foreach dataset in hhresp hhsamp indall indresp {
    	if `"``dataset'options'"' != "" {
    	    local datasets "`datasets' `dataset'"
    	}
	}

    * Remove rawvars() from `dataset'options, but keep a record (in `dataset'raw) of variables listed
	* This is so that we can add the `w' prefix to the variables when creating each wave of data
	* Not needed for wavedat variables (because only one wave of data) nor for cross-wave variables (because solely based on derived variables)
    local hhrespidvars "hidp"
    local hhsampidvars "hidp"
    local indallidvars "hidp pno pidp"
    local indrespidvars "hidp pno pidp"
    foreach dataset in `datasets' {
        if `"``dataset'options'"' != "" {
            local opts : copy local `dataset'options
            local `dataset'options ""
            while `"`opts'"' != "" {
                gettoken opt opts : opts, bind
                if regexm(`"`opt'"',"rawvars\(([0-9a-z_ ]+)\)") {
                    local `dataset'raw = regexs(1)
                }
                else local `dataset'options `"``dataset'options' `opt'"'
            }
            * Make sure idvars are included!
            local `dataset'raw : list `dataset'idvars | `dataset'raw
            local allraw : list allraw | `dataset'raw
        }
    }


    * Work out which waves we need to get intdate from (`prevwaves' = all waves lagged one period; othwaves = previous waves not in `waves')
    foreach wave of local waves {
        local prevwave = `wave' - 1
        if (`prevwave' != 0) local prevwaves "`prevwaves' `prevwave'"
        if (`prevwave' != 0 & !`: list prevwave in waves') local othwaves "`othwaves' `prevwave'"
    }

	di as text "Waves:" _continue
	local firstwave = 1

    * Create cross-sectional dataset for each wave in `waves'
    foreach wave of local waves {
        local w = char(96+`wave') + "_"
		if (`firstwave') {
			di as text " `wave'" _continue
			local firstwave = 0
		}
		else {
			di as text ", `wave'" _continue
		}

        foreach dataset in `datasets' {
            * Add a `w' onto all of the raw variable names
            addw ``dataset'raw', w(`w') locname(`dataset'rawopt)
            local `dataset'rawopt "rawvars(``dataset'rawopt')"
        }

		qui us_indiv_dataset, wave(`wave') hhrespoptions(`hhrespoptions' `hhresprawopt') hhsampoptions(`hhsampoptions' `hhsamprawopt') indalloptions(`indalloptions' `indallrawopt') indrespoptions(`indrespoptions' `indresprawopt') `keepdepkid' `keepindwoiv' `dropnohhiv' `neednotexist' `mindic'
		

        * Drop `w' prefix from all raw variables
        foreach var of local allraw {
			capture confirm variable `w'`var', exact
            if !_rc & "`var'" != "pidp" rename `w'`var' `var'
        }

		* Uprate variables if requested
		if ("`uprate'" != "") {
			tempname upratefromyear upratefrommonth

			* Uprate earnings and wage using earnings date if present
			if ("`jb1earn'" != "") | ("`jb1wage'" != "") {

				* Use earnings date if present
				qui gen long `upratefromyear' = `earnyear'
				qui gen long `upratefrommonth' = `earnmth'

				* If not, use interview date if present
				qui replace `upratefromyear' = `intyear' if (`upratefromyear' >= .)
				qui replace `upratefrommonth' = `intmonth' if (`upratefrommonth' >= .)

				* If not, use December from year of wave
				qui replace `upratefromyear' = 1990 + `wave' if (`upratefromyear' >= .)
				qui replace `upratefrommonth' = 12 if (`upratefrommonth' >= .)

				* Uprate
				usuprate `jb1earn' `jb1wage', year(`year') month(`month') yearvar(`upratefromyear') monthvar(`upratefrommonth') char(touprate) missing
				assert indexmissing == 0
				drop indexmissing `upratefromyear' `upratefrommonth'
			}

			* Uprate everything else using interview date if present
			qui gen long `upratefromyear' = `intyear'
			qui gen long `upratefrommonth' = `intmonth'

			* If not, uprate using December from year of wave
			qui replace `upratefromyear' = 1990 + `wave' if (`upratefromyear' >= .)
			qui replace `upratefrommonth' = 12 if (`upratefrommonth' >= .)

			* Make sure jb1earn and jb1wage are not uprated
			if ("`jb1earn'" != "") char `jb1earn'[touprate]
			if ("`jb1wage'" != "") char `jb1wage'[touprate]

			* Uprate
			usuprate, year(`year') month(`month') yearvar(`upratefromyear') monthvar(`upratefrommonth') char(touprate) missing
			assert indexmissing == 0
			drop indexmissing `upratefromyear' `upratefrommonth'

			* Reset characteristics of jb1earn and jb1wage
			if ("`jb1earn'" != "") char `jb1earn'[touprate] "touprate"
			if ("`jb1wage'" != "") char `jb1wage'[touprate] "touprate"
		}
		else {
			sort hidp
		}
		tempfile wave`wave'data
		qui save `wave`wave'data'

    }
	
    * Now add cross-wave variables and append together
    tempfile temp finaldata
    foreach wave of local waves {

	local prevwave = `wave' - 1


	* Append each year of data together
      capture confirm file `finaldata'
      if !_rc {
           qui append using `finaldata'
       }
       qui save `finaldata', replace

    }

	* Add wavedat variables
	if (`"`xwaveoptions'"' != "") {

		us_xwave_vars, `xwaveoptions' `mindic'

		* Get list of wavedat variables 
		local wavedatvars "`r(varlist)'"

		* Merge into extracted dataset
		tempfile wavedatdata
		qui save `wavedatdata'
		qui use `finaldata'
		qui merge m:1 pidp using `wavedatdata', keep(match master)

		/*Currently redundant as no derived variables based on the cross-wave file (PSL 27/03/26)*/
		* Label missing values where there's no match
		/*
		if regexm(`"`xwaveoptions'"',"mindic") {
			foreach var of local wavedatvars {
				qui replace `var' = .z if (_merge == 1)
                local labname: value label `var'
				if ("`labname'" == "") local labname "`var'"
				label define `labname' .z "Not interviewed", modify
			}
		}
		*/
		drop _merge
	}

	* Sort and save
	if ("`indrespoptions'" != "")|("`indalloptions'" != "") {
        order pidp wave
        sort pidp wave
    }
    else {
        order hidp wave
        sort hidp wave
    }
	compress
    qui save "`filename'", `replace'


end

*****************************************************************
* Create hhresp, indall and indresp varaibles for a single wave *
*****************************************************************

program define us_indiv_dataset

    # delimit;
    syntax,                     wave(numlist integer max=1 >=1 <=$numwaves)
                                [
                                hhrespoptions(string)
                                hhsampoptions(string)
                                indalloptions(string)
                                indrespoptions(string)
                                keepdepkid
                                keepindwoiv
								dropnohhiv
								neednotexist
								mindic
                                ];
    # delimit cr

    local wi = `wave'

    local w = char(96+`wi') + "_"
    if `"`hhrespoptions'"' != "" {
        us_hhresp_vars, wave(`wi') `hhrespoptions' `neednotexist' `mindic'
        tempfile hhrespdata
        qui save `hhrespdata'
        local hhdata "hhrespdata"
    }

    if `"`indalloptions'"' != "" {
        us_indall_vars, wave(`wi') `indalloptions' `neednotexist' `mindic'
        tempfile indalldata
        qui save `indalldata'
        local indivdata "indalldata"
    }

    if `"`indrespoptions'"' != "" {
        us_indresp_vars, wave(`wi') `indrespoptions' `neednotexist' `mindic'
        tempfile indrespdata
        qui save `indrespdata'
        local indivdata "indrespdata"
    }

    if `"`hhsampoptions'"' != "" {
        us_hhsamp_vars, wave(`wi') `hhsampoptions' `neednotexist' `mindic'
        tempfile hhsampdata
        qui save `hhsampdata'
        local hhdata "hhsampdata"
    }
	
    * Merge hhresp and hhsamp data (if relevant)
    if (`"`hhsampoptions'"' != "" & `"`hhrespoptions'"' != "") {
        qui use `hhsampdata', clear
        qui merge `w'hidp using `hhrespdata', uniqmaster
        *everyhoushold in hhsamp should be in hhresp
        assert _merge != 2
        *drop if _m==1 /*drop households which are not in the hhresp file. They are not useful*/
        di as text "hhresp and hhsamp merged"

        drop _merge

        sort `w'hidp
        tempfile hhbothdata
        qui save `hhbothdata'
        local hhdata "hhbothdata"

    }

     * Merge indall and indresp data (if relevant)
    if (`"`indalloptions'"' != "" & `"`indrespoptions'"' != "") {

        qui use `indalldata', clear
        qui merge `w'hid `w'pno using `indrespdata', unique
        * Every observation in wINDRESP should be in wINDALL
        assert _merge != 2
        di as text "indall and indresp merged"

        if "`keepindwoiv'" == "keepindwoiv" {
            gen byte noindiv = (_merge != 3)
            label variable noindiv "Individual not interviewed"
            di as text "Individuals not interviewed NOT dropped"

            unab allvar: _all
            foreach var of varlist `allvar' {
                replace `var' = .q if `var'==. & noindiv==1
                local labname: value label `var'
                if "`labname'" ~= "" {
                    label define `labname' .q "Not interviewed", modify
                }
            }
        }
        else {
            qui keep if _merge == 3
            di as text "Individuals not interviewed dropped"
        }
        drop _merge

        sort `w'hid `w'pno
        tempfile indbothdata
        qui save `indbothdata'
        local indivdata "indbothdata"

    }
	
    * Merge hhdata and individual data (if relevant)
    if (`"`hhdata'"' != "" & `"`indivdata'"' != "") {

        qui use ``hhdata'', clear
        qui merge `w'hidp using ``indivdata'', uniqmaster
        * Every individual should have a household
        qui count if _merge == 2
        qui drop if _merge == 2
        di as text "`r(N)' individuals without a household dropped"
*        assert _merge != 2
        di as text "hhdata and `=substr("`indivdata'",1,length("`indivdata'")-4)' merged"

        if ("`keepindwoiv'" == "keepindwoiv") & ("`dropnohhiv'"!="dropnohhiv") {
            gen byte nohh = (_merge != 3)
            label variable nohh "No individuals in household interviewed"
            di as text "Households where noone interviewd NOT dropped"

            unab allvar: _all
            foreach var of varlist `allvar' {		
                replace `var' = .r if `var'==. & nohh==1
                local labname: value label `var'
                if "`labname'" ~= "" {
                    label define `labname' .r "No one in household interviewed", modify
                }
                if "`labname'" == "" {
                    label define `var' .r "No one in household interviewed"
                    label values `var' `var'
                }
            }
        }
        if ("`keepindwoiv'" != "keepindwoiv")|("`dropnohhiv'"=="dropnohhiv") {
            qui keep if _merge == 3
            di as text "Households where no individuals interviewed are dropped"
        }

        drop _merge

        sort `w'hidp `w'pno
		
    }


    if (`"`indivdata'"' != "") {
			
        if ("`keepindwoiv'" == "keepindwoiv") & ("`dropnohhiv'"!="dropnohhiv") {   
		  replace pid = .r if nohh==1
		  label define pid .r "No one in household interviewed", modify
        }

        * Drop dependent children if required
        if "`depkid'" != "" & "`keepdepkid'" == "" {
            qui keep if !`depkid'
            di as text "Dependent children dropped"
            drop `depkid'
        }
        else di as text "Dependent children NOT dropped"

        order pidp `w'hidp `w'buno_dv `w'pno

    }
    else order `w'hidp

    gen byte wave = `wi'
    label variable wave "Wave number"


end

***************
*-------------*
*- Utilities -*
*-------------*
***************

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
