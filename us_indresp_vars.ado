/*

**************DESCRIPTION***********************************************************************************************

FILE:       	us_indresp_vars.ado
PURPOSE:    	Lots of individual programs, each one setting up a particular variable from BHPS indresp dataset
AUTHOR:     	Peter Levell (based on BHPS version by Jonathan Shaw)
THIS VERSION:   06/12/2014

DETAILS:			You're most likely to want to use "variable programs - driver.do", which calls programs from this file.

TYPICAL USE:  Too many individual programs to list here, but important common program options:
							- whatvars = lists which raw BHPS variables are used to create the derived variable (rather than actually creating it)
							- mindic   = use extended missing values (.a, .b, etc) to explain why variable is missing

**************LOG*******************************************************************************************************

29/05/2020 		David Sturrock: Corrected coding of edgrp new to put "first degree" (`w'_qfhigh == 2) into "University" rather than "Vocational Higher".
29/06/2020		David Sturrock: Changed upper age limit for ILO unemployment definition to be 74 (not 60/65 female/male) to align with BHPS version
08/08/2022      Peter levell added in wave 11, wave 11 includes furlough and short time work in econstat

**************NOTES*****************************************************************************************************

note that wave 2 introduces phone surveys again, things will probably have to be sorted out in all of the programs to account for this

The following work for waves 1 and 2
ivfio
intdate
gor (region)
mover
edgrp
edgrpnew
agesch
labmktmths
jb1status
jb2status
jbstatus
jb1soc
jb1start
minandmaxdate
jb1tenure
jb1hrs
jb1hrsot
jb2hrsot
jbhrsot
jb1rate
jb1rateot
accstartmth
accendmth
earndate
jb1earn
uprate
jb1wage
benefits
invinc
invinc_old
saved
econstat
ilo_unemp
spelltype
evermarried
rxwgt
disben
maintinc
nonlabinc

--things that can't be done in the current waves but there may be a module later
savings
invests
debts

--things that might in principle be done later (even if there are not the same questions in US as in the BHPS)

selfdisab
disab
unabletowork

--THINGS THAT HAVEN'T BEEN DONE BECAUSE YOU CAN'T WORK OUT SPELL START DATES (EXCEPT FOR THOSE IN WORK) EXCEPT IN WAVE 1
spellstart
b4septly
spelltypely
samejob
b4prevint
daysbetwint
daysworked
jb1annualhrsot


************************************************************************************************************************

*/

program define us_indresp_vars

    # delimit;
    syntax,                     wave(numlist integer max=1 >=1 <=$numwaves)
                                [
                                ivfio(name)
                                hoh(name)
                                intdate(string)         /* intdate(name) intyear(name) intmonth(name) */
                                gor(name)
                                mover(name)
                                disab(name)
                                selfdisab(name)
                                edgrp(name)
                                edgrpnew(name)
                                agesch(string)
                                edtype(name)
                                ftenddate(string)       /* ftendm(name) ftendy(name) ftestill(name) */
                                labmktmths(name)
                                currstat(name)
                                jb1status(name)
                                jb2status(name)
                                jb1soc(name)
                                jb1start(string)        /* jb1startd(name) jb1startm(name) jb1starty(name) */
                                jb1tenure(name)
                                jb1hrs(name)
                                jb1hrsot(name)
                                jbhrsot(name)
                                jb2hrsot(name)
                                jb1rate(name)
                                earndate(string)        /* earndate(name) earnmth(name) earnyear(name) */
                                jb1earn(string)         /* year(numlist integer max=1 >=1900 <=2100) month(numlist integer max=1 >=1 <=12) jb1earn(name) jb1earni(name) */
                                jb1wage(string)         /* jb1wage(name) hrscap(numlist integer max=1 >0) */
                                jb1ccare(name)
                                jb1ccarecost(string)    /* year(numlist integer max=1 >=1900 <=2100) month(numlist integer max=1 >=1 <=12) jb1ccarecost(name) */
                                nonlabinc(name)       /* year(numlist integer max=1 >=1900 <=2100) month(numlist integer max=1 >=1 <=12) nonlabinc(name) */
                                maintinc(name)        /* year(numlist integer max=1 >=1900 <=2100) month(numlist integer max=1 >=1 <=12) maintinc(name) */
                                benefits(string)        /* year(numlist integer max=1 >=1900 <=2100) month(numlist integer max=1 >=1 <=12) cb(name) iwb(name) is(name) ctbccb(name) jsa(name) hb(name) ctc(name) */
                                invinc(name)
                                disben(name)
                                unabletowork(name)
                                savings(name)
                                invests(name)
                                debts(name)
                                saved(name)
                                econstat(name)
                                ilo_unemp(name)
                                finexpect(name)
                                evermarried(name)
                                spelltype(name)
                                b4prevint(name)
                                spellstart(string)      /* startday(name) startmonth(name) startyear(name) */
                                spelltypely(name)
                                currstatly(name)
                                rxwgt(name)
                                rawvars(namelist)
								neednotexist
                                mindic
                                ];



    * Tidy up compound options;
    local intdate_syntax        "intdate(name)
                                intyear(name)
                                intmonth(name)";
    local ftenddate_syntax      "ftendm(name)
                                ftendy(name)
                                ftestill(name)";
    local jb1start_syntax       "jb1startd(name)
                                jb1startm(name)
                                jb1starty(name)";
    local earndate_syntax       "earndate(name)
                                earnmth(name)
                                earnyear(name)";
    local jb1earn_syntax        "year(numlist integer max=1 >=1900 <=2100)
                                month(numlist integer max=1 >=1 <=12)
                                jb1earn(name)
                                jb1earni(name)";
    local jb1wage_syntax        "jb1wage(name)
                                hrscap(numlist integer max=1 >0)";
    local jb1ccarecost_syntax   "year(numlist integer max=1 >=1900 <=2100)
                                month(numlist integer max=1 >=1 <=12)
                                jb1ccarecost(name)";
    local benefits_syntax       "year(numlist integer max=1 >=1900 <=2100)
                                month(numlist integer max=1 >=1 <=12)
                                cb(name)
                                iwb(name)
                                is(name)
                                ctbccb(name)
                                jsa(name)
                                hb(name)
                                ctc(name)";
    local agesch_syntax         "agesch(name)
                                 schstill(name)";

    local spellstart_syntax      "startday(name)
                                startmonth(name)
                                startyear(name)";

    # delimit cr

    local indrespvars "ivfio hoh intdate region gor mover disab selfdisab edgrp edgrpnew agesch edtype ftenddate labmktmths currstat jb1status jb2status jb1soc jb1start jb1tenure jb1hrs jb1hrsot jb2hrsot jbhrsot earndate jb1earn jb1rate jb1ccare jb1ccarecost nonlabinc maintinc benefits invinc disben unabletowork savings invests debts saved econstat ilo_unemp finexpect evermarried spelltype spellstart b4prevint currstatly spelltypely rxwgt"
    local wi = `wave'
    local w = char(96+`wi') + "_"


    * Find out what raw variables are required
    ******************************************

    local idvars "`w'hidp `w'pno pidp `w'buno_dv" 
    local rawvars : list idvars | rawvars

    local othvars ""
    foreach indrespvar of local indrespvars {
       if "``indrespvar''" != "" {
            indresp_`indrespvar', wave(`wi') whatvars
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
        useundersoc `rawvars' `othvars' using "$data\\`w'indresp.dta", clear `neednotexist'

        /**if wave 6 or 7 - merge in ff_everint from indall. In previous waves it used to be in indresp but removed from wave 6**/
       if `wi'>=6 {
        merge 1:1 pidp  using "$data\\`w'indall.dta", keepusing(`w'ff_everint) assert(2 3) keep(3)
        drop _m
        }

        * Create finished variables
        if "`hoh'" != "" {
            indresp_hoh, wave(`wi') hoh(`hoh')
        }

        if "`ivfio'" != "" {
            indresp_ivfio, wave(`wi') ivfio(`ivfio')
        }
        if "`intdate'" != "" {
            local 0 ", `intdate'"
            syntax [, `intdate_syntax']
            indresp_intdate, wave(`wi') intdate(`intdate') intyear(`intyear') intmonth(`intmonth') `mindic'
        }
        if "`ftenddate'" != "" {
            local 0 ", `ftenddate'"
            syntax [, `ftenddate_syntax']
            indresp_ftenddate, wave(`wi') ftendm(`ftendm') ftendy(`ftendy') ftestill(`ftestill') `mindic'
        }
        if "`labmktmths'" != "" {
            indresp_labmktmths, wave(`wi') labmktmths(`labmktmths') intdate(`intdate') `mindic'
        }

        if "`gor'" != "" {
            indresp_gor, wave(`wi') gor(`gor') `mindic'
        }
        if "`mover'" != "" {
            indresp_mover, wave(`wi') mover(`mover') `mindic'
        }
        if "`disab'" != "" {
            indresp_disab, wave(`wi') disab(`disab') `mindic'
        }
        if "`selfdisab'" != "" {
            indresp_selfdisab, wave(`wi') selfdisab(`selfdisab') `mindic'
        }
        if "`edgrp'" != "" {
            indresp_edgrp, wave(`wi') edgrp(`edgrp') `mindic'
        }
        if "`edgrpnew'" != "" {
            indresp_edgrpnew, wave(`wi') edgrpnew(`edgrpnew') `mindic'
        }
        if "`edtype'" != "" {
            indresp_edtype, wave(`wi') edtype(`edtype') `mindic'
        }
        if "`agesch'" != "" {
            local 0 ", `agesch'"
            syntax [, `agesch_syntax']
            indresp_agesch, wave(`wi') agesch(`agesch') schstill(`schstill') `mindic'
        }

        if "`currstat'" != "" {
            indresp_currstat, wave(`wi') currstat(`currstat') `mindic'
        }
        if "`jb1status'" != "" {
            indresp_jb1status, wave(`wi') jb1status(`jb1status') `mindic'
        }
        if "`jb2status'" != "" {
            indresp_jb2status, wave(`wi') jb2status(`jb2status') `mindic'
        }

        if "`jb1soc'" != "" {
            indresp_jb1soc, wave(`wi') jb1soc(`jb1soc') jb1status(`jb1status') `mindic'
        }
        if "`jb1start'" != "" {
            local 0 ", `jb1start'"
            syntax [, `jb1start_syntax']
            indresp_jb1start, wave(`wi') jb1startd(`jb1startd') jb1startm(`jb1startm') jb1starty(`jb1starty') `mindic'
        }
        if "`jb1tenure'" != "" {
            indresp_jb1tenure, wave(`wi') jb1tenure(`jb1tenure') intdate(`intdate') jb1startd(`jb1startd') jb1startm(`jb1startm') jb1starty(`jb1starty') jb1status(`jb1status') `mindic'
        }
        if "`jb1hrs'" != "" {
            indresp_jb1hrs, wave(`wi') jb1hrs(`jb1hrs') jb1status(`jb1status') `mindic'
        }
        if "`jb1hrsot'" != "" {
            indresp_jb1hrsot, wave(`wi') jb1hrsot(`jb1hrsot') jb1status(`jb1status') `mindic'
        }
        if "`jb2hrsot'" != "" {
            indresp_jb2hrsot, wave(`wi') jb2hrsot(`jb2hrsot') jb2status(`jb2status') `mindic'
        }

        if "`earndate'" != "" {
            local 0 ", `earndate'"
            syntax [, `earndate_syntax']
            indresp_earndate, wave(`wi') earndate(`earndate') earnmth(`earnmth') earnyear(`earnyear') intdate(`intdate') jb1status(`jb1status1') `mindic'
        }
        if "`jb1earn'" != "" {
            local 0 ", `jb1earn'"
            syntax [, `jb1earn_syntax']
            indresp_jb1earn, wave(`wi') year(`year') month(`month') jb1earn(`jb1earn') jb1earni(`jb1earni') jb1status(`jb1status') earnmth(`earnmth') earnyear(`earnyear') `mindic'
        }
        if "`jb1wage'" != "" {
            local 0 ", `jb1wage'"
            syntax [, `jb1wage_syntax']
            indresp_jb1wage, wave(`wi') jb1wage(`jb1wage') hrscap(`hrscap') jb1earn(`jb1earn') jb1status(`jb1status') jb1hrs(`jb1hrs') jb1hrsot(`jb1hrsot') `mindic'
        }
        if "`jb1ccare'" != "" {
            indresp_jb1ccare, wave(`wi') jb1ccare(`jb1ccare') jb1status(`jb1status') `mindic'
        }
        if "`jb1ccarecost'" != "" {
            local 0 ", `jb1ccarecost'"
            syntax [, `jb1ccarecost_syntax']
            indresp_jb1ccarecost, wave(`wi') year(`year') month(`month') jb1ccarecost(`jb1ccarecost') jb1ccare(`jb1ccare') jb1status(`jb1status') intdate(`intdate') `mindic'
        }
        if "`nonlabinc'" != "" {
            indresp_nonlabinc,  wave(`wi') nonlabinc(`nonlabinc') intdate(`intdate') `mindic'
        }
        if "`maintinc'" != "" {
            indresp_maintinc,  wave(`wi') maintinc(`maintinc') intdate(`intdate') `mindic'
        }
        if "`benefits'" != "" {
            local 0 ", `benefits'"
            syntax [, `benefits_syntax']
            indresp_benefits,  wave(`wi') year(`year') month(`month') cb(`cb') iwb(`iwb') is(`is') ctbccb(`ctbccb') jsa(`jsa') hb(`hb') ctc(`ctc') intdate(`intdate') `mindic'
        }
        if "`invinc'" != "" {
            indresp_invinc,  wave(`wi') invinc(`invinc') `mindic'
        }
        if "`disben'" != "" {
            indresp_disben,  wave(`wi') disben(`disben') intdate(`intdate') `mindic'
        }

        if "`unabletowork'" != "" {
            indresp_unabletowork,  wave(`wi') unabletowork(`unabletowork') `mindic'
        }

        if "`savings'" != "" {
            indresp_savings,  wave(`wi') savings(`savings') `mindic'
        }
        if "`invests'" != "" {
            indresp_invests,  wave(`wi') invests(`invests') `mindic'
        }
        if "`debts'" != "" {
            indresp_debts,  wave(`wi') debts(`debts') `mindic'
        }

        if "`saved'" != "" {
            indresp_saved,  wave(`wi') saved(`saved') `mindic'
        }

        if "`econstat'" != "" {
            indresp_econstat,  wave(`wi') econstat(`econstat') `mindic'
        }

        if "`ilo_unemp'" != "" {
            indresp_ilo_unemp,  wave(`wi') ilo_unemp(`ilo_unemp') `mindic'
        }

        if "`finexpect'" != "" {
            indresp_finexpect,  wave(`wi') finexpect(`finexpect') `mindic'
        }

        if "`evermarried'" != "" {
            indresp_evermarried,  wave(`wi') evermarried(`evermarried') `mindic'
        }

        if "`spelltype'" != "" {
            indresp_spelltype,  wave(`wi') spelltype(`spelltype') jb1status(`jb1status') `mindic'
        }
        if "`b4prevint'" != "" {
            indresp_b4prevint, wave(`wi') b4prevint(`b4prevint') `mindic'
        }
        if "`spellstart'" != "" {
            local 0 ", `spellstart'"
            syntax [, `spellstart_syntax']
            indresp_spellstart, wave(`wi') startday(`startday') startmonth(`startmonth') startyear(`startyear') jb1status(`jb1status') `mindic'
        }
        if "`b4septly'" != "" {
            indresp_b4septly, wave(`wi') b4septly(`b4septly') startday(`startday') startmonth(`startmonth') startyear(`startyear') jb1status(`jb1status') `mindic'
        }
        if "`spelltypely'" != "" {
            indresp_spelltypely, wave(`wi') spelltypely(`spelltypely') intdate(`intdate') spelltype(`spelltype') startday(`startday') startmonth(`startmonth') startyear(`startyear') b4septly(`b4septly') ivfio(`ivfio') `mindic'
        }

        if "`currstatly'" != "" {
            indresp_currstatly, wave(`wi') currstatly(`currstatly') intdate(`intdate') currstat(`currstat') startday(`startday') startmonth(`startmonth') startyear(`startyear') b4prevint(`b4prevint') ivfio(`ivfio') `mindic'
        }

        if "`rxwgt'" != "" {
            indresp_rxwgt, wave(`wi') rxwgt(`rxwgt')
        }

        if "`othvars'" != "" {
            drop `othvars'
        }

        capture drop `w'_ff_everint
        sort `w'hidp `w'pno

    }

end



* Interview outcome
*******************

program define indresp_ivfio, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ivfio(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio"
    }
    else {

        if "`ivfio'" == "" local ivfio "ivfio"

        gen byte `ivfio' = `w'_ivfio
        assert `ivfio' < .
        label variable `ivfio' "Interview outcome"
        label define `ivfio' 1 "Full interview" 2 "Proxy interview"
        label values `ivfio' `ivfio'

    }

end

* HOH
***************************

*For some reason this is not defined in Understanding Society
*Define in terms as similiar to the BHPS as possible

program define indresp_hoh, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hoh(name)]
    local w = char(96+`wave')

    *In the BHPS this is defined as
    *"Indicator of the head of h/hold as defined, for example by the General Housedhold Survey, i.e. the principal owner or renter of the property,
    *and (where there is more than one), the male taking precedence, and (where there is more than one potential HOH of the same sex), the eldest taking
    *precedence. The BHPS h/hold reference person definition is similar except that only the age criterion is used to distinguish multiple potential HRPs.
    *In the calculation, where any potential information is missing, the HRP definition takes precedence."

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_hidp `w'_pno `w'_ivfio `w'_dvage `w'_sex"
    }

    else {
        if "`hoh'" == "" local hoh "hoh"

        sort `w'_hidp `w'_pno
        tempfile currdata
        qui save `currdata'

        use "$data\\`w'_hhresp", clear

        qui keep `w'_hidp *hsowr*

        qui reshape long `w'_hsowr, i(`w'_hidp) j(pno)

        qui gen `w'_pno = pno - 10

        qui drop pno

        tempfile mergedata
        qui save `mergedata'

        use `currdata'

        qui merge 1:1 `w'_hidp `w'_pno using `mergedata'
	
        qui drop if _merge==2
		
        *count owners per household
        qui egen ownercount = sum(`w'_hsowr==1), by(`w'_hidp)
        qui replace ownercount = . if _merge==1

        *odd observations where some pnos don't merge in but we identify the owners
        egen maxmerge      = max(_merge), by(`w'_hidp)
        egen minownercount = min(ownercount), by(`w'_hidp)

        qui replace `w'_hsowr = 0               if _merge==1 & maxmerge==3
        qui replace ownercount = minownercount  if _merge==1 & maxmerge==3

        drop maxmerge minownercount _merge

        *if only one owner, they are the head
        *****************************************
        qui gen `hoh'     = 1 if ownercount==1  & `w'_hsowr==1
        qui replace `hoh' = 0 if ownercount ==1 & `w'_hsowr!=1

		*Obtain consistent sex from cross-wave file if possible
		merge 1:1 pidp using "$data/xwavedat", keepusing(sex_dv) 
		assert _merge==2|_merge==3 
		drop if _merge==2
		drop _merge
		replace `w'_sex = sex_dv if sex_dv>0
		drop sex_dv

        *Deal with households with two or more owners
        *****************************************
        qui gen maleowner = (`w'_hsowr==1)*(`w'_sex==1)
        egen maleownercount = sum(maleowner),by(`w'_hidp)
        qui gen agetemp = `w'_dvage if ownercount >=2 & `w'_hsowr==1 & ((`w'_sex==1 & maleownercount>1)|(`w'_sex==2 & maleownercount==0))
        qui egen maxage = max(agetemp), by(`w'_hidp)
        *assert inlist(maleownercount,0,1,2)
        *count households where there is a tie in maxage (e.g. two owners of the same sex and same ages) - when this is the case we use the smallest pno to be the head
        qui egen tiecounttemp1 = sum(`w'_dvage==maxage & `w'_sex==1) if maleownercount>1, by(`w'_hidp)
        qui egen tiecounttemp2 = sum(`w'_dvage==maxage & `w'_sex==2) if maleownercount==0, by(`w'_hidp)
        qui gen tiecount = tiecounttemp1 if maleownercount>1
        qui replace tiecount = tiecounttemp2 if maleownercount==0
        qui egen smallestpno = min(`w'_pno) if tiecount>1 & (maleownercount>1|maleownercount==0) & `w'_hsowr==1, by(`w'_hidp `w'_sex)
        qui gen  issmallestpno = `w'_pno==smallestpno
        qui replace issmallestpno = 1 if tiecount==1 & (maleownercount>1|maleownercount==0)
        *take the male if there is only one male
        qui replace `hoh' = 1 if ownercount >=2 & `w'_hsowr==1 & maleownercount==1 &  maleowner==1
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 & maleownercount==1 &  maleowner==0
        *take the eldest if both the same sex (and smallest pno if there is a tie in age)
        qui replace `hoh' = 1 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage == maxage & maxage!=. & maleownercount>1  & issmallestpno==1
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage == maxage & maxage!=. & maleownercount>1  & issmallestpno==0
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage < maxage  & maxage!=. & maleownercount>1
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 &  maleownercount>1   & `w'_sex==2
        qui replace `hoh' = 1 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage == maxage & maxage!=. & maleownercount==0  & issmallestpno==1
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage == maxage & maxage!=. & maleownercount==0  & issmallestpno==0
        qui replace `hoh' = 0 if ownercount >=2 & `w'_hsowr==1 & `w'_dvage < maxage  & maxage!=. & maleownercount==0

        drop agetemp maxage maleowner maleownercount tiecount tiecounttemp1 tiecounttemp2 smallestpno issmallestpno
        qui replace hoh = 0 if ownercount>0 & ownercount!=. & `w'_hsowr==0


        *if no owners then use oldest male (if male is present)
        *****************************************
        qui egen malecount = sum(`w'_sex==1), by(`w'_hidp)
        qui gen agetemp = `w'_dvage if (ownercount ==0|ownercount ==.) & malecount>0 & `w'_sex==1
        qui egen maxage = max(agetemp), by(`w'_hidp)
        *count households where there is a tie in maxage
        qui egen tiecount = sum(`w'_dvage==maxage & `w'_sex==1), by(`w'_hidp)
        qui egen smallestpno = min(`w'_pno) if tiecount>1 & `w'_sex==1 & `w'_dvage==maxage, by(`w'_hidp)
        qui gen  issmallestpno = `w'_pno==smallestpno
        qui replace  issmallestpno = 1 if tiecount==1
        *issmallespno = 1 if there is no tie and 1 if there is a tie and you have the smallest pno
        qui replace `hoh' = 1 if (ownercount ==0|ownercount ==.) & malecount>0 & `w'_dvage == maxage & maxage!=.  & issmallestpno==1
        qui replace `hoh' = 0 if (ownercount ==0|ownercount ==.) & malecount>0 & `w'_dvage == maxage & maxage!=.  & issmallestpno==0
        qui replace `hoh' = 0 if (ownercount ==0|ownercount ==.) & malecount>0 & `w'_dvage <  maxage & maxage!=.
        qui replace `hoh' = 0 if (ownercount ==0|ownercount ==.) & malecount>0 & `w'_sex ==2
        drop agetemp maxage tiecount smallestpno issmallestpno

        *if no owners and no males then use oldest female
        *****************************************
        qui gen agetemp = `w'_dvage if (ownercount ==0|ownercount ==.) & malecount==0
        qui egen maxage = max(agetemp), by(`w'_hidp)
        *count households where there is a tie in maxage
        qui egen tiecount = sum(`w'_dvage==maxage), by(`w'_hidp)
        qui egen smallestpno = min(`w'_pno) if tiecount>1 & `w'_dvage==maxage, by(`w'_hidp)
        qui gen  issmallestpno = `w'_pno==smallestpno
        qui replace  issmallestpno = 1 if tiecount==1
        *issmallespno = 1 if there is no tie and 1 if there is a tie and you have the smallest pno
        qui replace `hoh' = 1 if (ownercount ==0|ownercount ==.) & malecount==0 & `w'_dvage == maxage & maxage!=. & issmallestpno==1
        qui replace `hoh' = 0 if (ownercount ==0|ownercount ==.) & malecount==0 & `w'_dvage == maxage & maxage!=. & issmallestpno==0
        qui replace `hoh' = 0 if (ownercount ==0|ownercount ==.) & malecount==0 & `w'_dvage < maxage & maxage!=.
        drop agetemp maxage malecount tiecount smallestpno issmallestpno

        *assert 1 head per household
        egen headcount = sum(`hoh'==1), by(`w'_hidp)

        assert headcount==1
        drop headcount
        assert (`hoh'==1|`hoh'==0)

        label variable `hoh' "Head of household"
    }

end



* Interview date (we need this for uprating earnings)
*****************************************************

program define indresp_intdate, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars intdate(name) intyear(name) intmonth(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_istrtdatd `w'_istrtdatm `w'_istrtdaty `w'_istrtdatm `w'_istrtdatd `w'_istrtdaty"
        if (`wave'> 1) return local vars "`w'_istrtdatd `w'_istrtdatm `w'_istrtdaty"
    }
    else {

        if "`intdate'" == "" local intdate "intdate"
        if "`intyear'" == "" local intyear "intyear"
        if "`intmonth'" == "" local intmonth "intmonth"

        qui gen long `intdate'  =  mdy(`w'_istrtdatm,`w'_istrtdatd,`w'_istrtdaty ) if `w'_istrtdaty >0 & `w'_istrtdatm >0 & `w'_istrtdatd >0
        qui gen int  `intyear'  = `w'_istrtdaty  if `w'_istrtdaty >0
        qui gen byte `intmonth' = `w'_istrtdatm if `w'_istrtdatm >0

        format %td `intdate'
        label variable `intdate' "Date of interview"
        label variable `intyear' "Year of interview"
        label variable `intmonth' "Date of interview"

        if "`mindic'" == "mindic" {
                qui replace `intdate' = .a if inlist(`w'_istrtdatd,-1,-2,-3,-4,-8,-9) & `w'_ivfio==2 & `intdate' == .
                qui replace `intdate' = .b if inlist(`w'_istrtdatm,-1,-2,-3,-4,-8,-9) & `w'_ivfio==2 & `intdate' == .
                qui replace `intdate' = .c if inlist(`w'_istrtdaty,-1,-2,-3,-4,-8,-9) & `w'_ivfio==2 & `intdate' == .

                qui replace `intmonth' = .b if inlist(`w'_istrtdatm,-1,-2,-3,-4,-8,-9) & `w'_ivfio==2 & `intmonth' == .
                qui replace `intyear'  = .b if inlist(`w'_istrtdaty,-1,-2,-3,-4,-8,-9) & `w'_ivfio==2 & `intyear' == .

            if (`wave'>1) {
                qui replace `intdate'  = .e if `w'_ivfio==1 & inlist(`w'_istrtdatd,-1,-2,-3,-4,-8,-9) & `intdate' == .

                qui replace `intmonth' = .a if `w'_ivfio==1 & `intmonth' == .
                qui replace `intyear'  = .a if `w'_ivfio==1 & `intyear' == .

                qui replace `intdate'  = .d if `w'_ivfio==2 & `intdate' == .
                qui replace `intmonth' = .c if `w'_ivfio==2 & `intmonth' == .
                qui replace `intyear'  = .c if `w'_ivfio==2 & `intyear' == .
            }

            assert (`intdate' != .)
            label define `intdate' .a "istrtdatd invalid (proxy)" .b "istrtdatm invalid (proxy)" .c "istrtdaty invalid (proxy)" .d "Proxy interview (Wave 2+)" .e "date missing(not proxy)"
            label values `intdate' `intdate'

            assert (`intyear' != .)
            assert (`intmonth' != .)
            label define `intmonth' .a "istrtdatm missing (not proxy)" .b "istrtdatm invalid (proxy)" .c "Proxy interview (Wave 2+)"
            label define `intyear'  .a "istrtdaty missing (not proxy)" .b "istrtdaty invalid (proxy)" .c "Proxy interview (Wave 2+)"
            label values `intyear' `intyear'
            label values `intmonth' `intmonth'
        }

    }

end



* Region
********

program define indresp_gor, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars gor(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_gor_dv"
    }
    else {

        if "`region'" == "" local region "region"

        qui gen byte `gor' = `w'_gor_dv if `w'_gor_dv > 0

        capture label drop `gor'
        label define `gor' 1 "North East" 2 "North West and Merseyside" 3 "Yorks and Humberside" 4 "East Midlands" 5 "West Midlands" 6 "Eastern" 7 "London" 8 "South East" 9 "South West" 10 "Wales" 11 "Scotland" 12 "Northern Ireland"
        label values `gor' `gor'
        label variable `gor' "Government office region"

        if "`mindic'" == "mindic" {
            qui replace `gor' = .a if `gor' >= .
            assert (`gor' != .)
            label define `gor' .a "region missing", add
        }

    }

end



* Mover status
**************

program define indresp_mover, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars mover(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' >= 2) return local vars "`w'_origadd"
    }
    else {

        if "`mover'" == "" local mover "mover"

        if (`wave' == 1) {
            qui gen byte `mover' = .
        }
        else {
            qui gen byte `mover' = `w'_origadd==2
            label variable `mover' "Moved since previous wave"
        }

        if "`mindic'" == "mindic" {
            if (`wave' == 1) {
                qui replace `mover' = .a
            }
            label define `mover' .a "Wave 1"
            label values `mover' `mover'
            assert (`mover' != .)
        }

    }

end




* Registered disabled
*********************

/*No exact analogy for this in Understanding society. They do have an FRS question asking if they have a longstanding illness or disability (about 35% of the sample in wave 1) a_health*/


/*
program define indresp_disab, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars disab(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if inrange(`wave',1,11) return local vars "`w'hldsbl"
    }
    else {

        if "`disab'" == "" local disab "disab"

        if inrange(`wave',1,11) qui gen byte `disab' = 2 - `w'hldsbl if inlist(`w'hldsbl,1,2)
        else qui gen byte `disab' = .
        label variable `disab' "Registered disabled"

        if "`mindic'" == "mindic" {
            if inrange(`wave',1,11) {
                qui replace `disab' = .b if inlist(`w'hldsbl,-1,-2,-9)
            }
            else qui replace `disab' = .a
            assert (`disab' != .)
            label define `disab' .a "Wave 12+ not asked" .b "hldsbl invalid"
            label values `disab' `disab'
        }

    }

end
*/


* Too disabled to work
*********************

/*people aren't asked specifically about employment in Understanding society though they are asked about other things that are related ("work" in the US question covers both in and outside the home)*/

/*
program define indresp_unabletowork, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars unabletowork(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'~=9) & (`wave'~=14)  return local vars "`w'hlltw `w'hlltwa `w'hlendw"
        }
    else {


        if "`unabletowork'" == "" local unabletowork "unabletowork"

        if (`wave'==9)|(`wave'==14)  {
            gen byte unabletowork=.
        }
        else {
        qui gen byte  `unabletowork' = 1 if inlist(`w'hlendw,1)  & inlist(`w'hlltwa,1)
        qui replace   `unabletowork' = 0 if inlist(`w'hlendw,2,3) | (inlist(`w'hlendw,1) & inlist(`w'hlltwa,2,3,4))
        qui replace   `unabletowork' = 0 if inlist(`w'hlltw,2)
        }
        label variable `unabletowork' "Unable to work"


        if "`mindic'" == "mindic" {
            if (`wave'==9) | (`wave'==14) {
                qui replace `unabletowork' =  .a
            }
            else qui replace `unabletowork' = .b if inlist(`w'hlendw,-1,-7,-9)|(inlist(`w'hlltw,1,-1,-2,-9) & inlist(`w'hlendw,-8))|inlist(`w'hlltwa,-1,-4,-9)
            label define `unabletowork' .a "Qs not asked in waves 9 and 14" .b "Didn't respond to one of hlltwa, hlltw, hlendw"
            label values `unabletowork' `unabletowork'
            assert (`unabletowork' != .)

        }

    }

end
*/

/*
* Eligible for mobility component of DLA
*********************

program define indresp_mobilprob, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars mobilprob(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
            if (`wave'~=9) & (`wave'~=14)  return local vars "`w'hlltd  `w'hlltb"
            if (`wave'==9) | (`wave'==14)  return local vars "`w'hlsf3i `w'hlsf3e"
    }
    else {

        if "`mobilprob'" == "" local mobilprob "mobilprob"

        if (`wave'~=9) & (`wave'~=14) {
        *some years takes the value 1 if difficulty walking, other years 4
        qui gen byte  `mobilprob' = 1 if inlist(`w'hlltd,1,4) & inlist(`w'hlltb,1,2)
        qui replace   `mobilprob' = 0 if inlist(`w'hlltd,0)|inlist(`w'hlltb,0)
        }

        else {

        qui gen byte  `mobilprob' = 1 if inlist(`w'hlsf3i,1) & inlist(`w'hlsf3e,1)
        qui replace   `mobilprob' = 0 if inlist(`w'hlsf3i,0,2,3)|inlist(`w'hlsf3e,0,2,3)

        }

        label variable `mobilprob' "mobilprob"


        if "`mindic'" == "mindic" {
            if (`wave'~=9) & (`wave'~=14) {
                qui replace `mobilprob' = .a if inlist(`w'hlltd,-1,-7,-8,-9)|inlist(`w'hlltb,-1,-7,-8,-9)
            }
            else qui replace `mobilprob' = .b if inlist(`w'hlsf3i,-1,-7,-8,-9)|inlist(`w'hlsf3e,-1,-7,-8,-9)
            label define `mobilprob' .a "Didn't respond to hlltd or hlltb" .b "Didn't respond to hlsf3i or hlsf3e"
            label values `mobilprob' `mobilprob'
            assert (`mobilprob' != .)
        }

    }

end
*/


* Self-reported disabled
************************

/*Again no exact analogy within the BHPS (see disab above)*/

/*
program define indresp_selfdisab, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars selfdisab(name) mindic]
    local w = char(96+`wave')


    if "`whatvars'" == "whatvars" {
        if (`wave' == 13) return local vars "`w'hldsbl1 `w'hldsbl `w'ivfio"
        else if (`wave' >= 12) return local vars "`w'hldsbl1"
    }
    else {

        if "`selfdisab'" == "" local selfdisab "selfdisab"

        if (`wave' <= 11) qui gen byte `selfdisab' = .
        else {
            qui gen byte `selfdisab' = 2 - `w'hldsbl1 if inlist(`w'hldsbl1,1,2)
            if (`wave' == 13) qui replace `selfdisab' = 2 - `w'hldsbl if inlist(`w'hldsbl,1,2) & `w'ivfio == 2
        }

        if "`mindic'" == "mindic" {
            if (`wave' <= 11) qui replace `selfdisab' = .a
            else {
                qui replace `selfdisab' = .b if inlist(`w'hldsbl1,-1,-2,-9)
                if (`wave' == 13) qui replace `selfdisab' = .c if inlist(`w'hldsbl,-1,-2,-9) & `w'ivfio == 2
            }
            assert (`selfdisab' != .)
            label define `selfdisab' .a "Waves 1-11 not asked" .b "hldsbl1 invalid" .c "hldsbl invalid (proxy w13)"
        }

    }

end
*/



* Highest educational qualification
***********************************

*PL COMMENTED 23/11/2019 - WHY NOT USE QF_HIGH_DV HERE?
*PL: CHANGED THIS TO DEAL WITH THE FACT THAT PEOPLE ARE ONLY RE-ASKED IF NOT INTERVIEWED BEFORE
program define indresp_edgrp, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars edgrp(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if ((`wave'==1) | (`wave'>=6)) return local vars "`w'_qfhigh `w'_school"
        if ((`wave'>1) & (`wave'<6)) return local vars "`w'_qfhigh `w'_school `w'_ff_everint"
    }

    else {


        if (`wave'>=6) {
        *first merge in everint from indall
            qui merge 1:1 `w'_hidp `w'_pno using "$data\\`w'_indall.dta", keepusing(`w'_ff_everint) keep(match master) nogen
        }

        if "`edgrp'" == "" local edgrp "edgrp"

        *Note in BHPS scottish highers and certificates of sixth year are counted as A-levels so they are here too
        *AS levels are put in GCSEs again as in BHPS
        if (`wave'==1) {
            qui gen byte `edgrp' = 0 if `w'_qfhigh==96 & `w'_school!=3
            qui replace  `edgrp' = 1 if inrange(`w'_qfhigh,13,15)
            qui replace  `edgrp' = 2 if inlist(`w'_qfhigh,9,12)
            qui replace  `edgrp' = 3 if inlist(`w'_qfhigh,6,7,8,10,11)
            qui replace  `edgrp' = 4 if inrange(`w'_qfhigh,1,5)
            qui replace  `edgrp' = 5 if `w'_school==3
        }

        if (`wave'>1 & `wave'<=6) {
            qui gen byte `edgrp' = 0 if `w'_qfhigh==96 & `w'_school!=3 & `w'_ff_everint!=1
            qui replace  `edgrp' = 1 if inrange(`w'_qfhigh,13,15) & `w'_ff_everint!=1
            qui replace  `edgrp' = 2 if inlist(`w'_qfhigh,9,12)  & `w'_ff_everint!=1
            qui replace  `edgrp' = 3 if inlist(`w'_qfhigh,6,7,8,10,11) & `w'_ff_everint!=1
            qui replace  `edgrp' = 4 if inrange(`w'_qfhigh,1,5) & `w'_ff_everint!=1
            qui replace  `edgrp' = 5 if `w'_school==3 & `w'_ff_everint!=1
        }

        if (`wave'>=7) {
            qui gen byte `edgrp' = 0 if `w'_qfhigh==96 & `w'_school!=3 & `w'_ff_everint!=1
            qui replace  `edgrp' = 1 if inrange(`w'_qfhigh,13,15) & `w'_ff_everint!=1
            qui replace  `edgrp' = 2 if inlist(`w'_qfhigh,9,12,14,17,18)  & `w'_ff_everint!=1
            qui replace  `edgrp' = 3 if inlist(`w'_qfhigh,6,7,8,10,11,16) & `w'_ff_everint!=1
            qui replace  `edgrp' = 4 if inrange(`w'_qfhigh,1,5) & `w'_ff_everint!=1
            qui replace  `edgrp' = 5 if `w'_school==3 & `w'_ff_everint!=1
        }

        label define `edgrp' 0 "None of the above qualifications" 1 "Less than GCSEs" 2 "GCSEs" 3 "A-levels" 4 "Higher" 5 "Still at school"
        label values `edgrp' `edgrp'
        label variable `edgrp' "Grouped highest qualification"

        if "`mindic'" == "mindic" {
            if (`wave'==1)  {
                qui replace `edgrp' = .a if inlist(`w'_qfhigh,-1,-2,-9) & `w'_school~=3 & `edgrp' == .
                qui replace `edgrp' = .b if inlist(`w'_school,-1,-2,-9) & `edgrp' == .
            }

            if (`wave'>1) {
                qui replace `edgrp' = .a if inlist(`w'_qfhigh,-1,-2,-9) & `w'_school~=3 & `edgrp' == . & `w'_ff_everint!=1
                qui replace `edgrp' = .b if inlist(`w'_school,-1,-2,-8,-9) & `edgrp' == . & `w'_ff_everint!=1
                qui replace `edgrp' = .c if `w'_ff_everint==1
                qui replace `edgrp' = .d if `w'_ff_everint==-10 & `edgrp'==. /*a lot of the new ethnic booster do not have a qfhigh variable. Not sure whether that is a mistake or whether they weren't asked it*/
            }

            if (`wave'>=6) {
                qui replace `edgrp' = .e if `w'_ff_everint==-9 & `edgrp'==.
            }

            if `wave'>=9 {
                qui replace `edgrp' = .f
            }

            assert (`edgrp' != .)
            label define `edgrp' .a "qfhigh invalid" .b "school invalid" .c "Interviewed previously (Wave 2+)" .d "ethnic booster sample - no value" .e "ff_everint missing (Wave 6+)" .f "NOT YET CODED (Wave 9)", add
        }

    }

end



* New highest educational qualification
***************************************

* Slightly more disaggregated than edgrp (old variable kept because Monica's programmes use it)

program define indresp_edgrpnew, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars edgrpnew(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1 | `wave'>=6) return local vars "`w'_qfhigh `w'_school"
        if (`wave'>1 & `wave'<6) return local vars "`w'_qfhigh `w'_school `w'_ff_everint"
    }

    else {

        if "`edgrpnew'" == "" local edgrpnew "edgrpnew"

         if (`wave'>=6) {
        *first merge in everint from indall
            qui merge 1:1 `w'_hidp `w'_pno using "$data\\`w'_indall.dta", keepusing(`w'_ff_everint) keep(match master) nogen
        }

        *AS levels are put in GCSEs again as in BHPS
        if (`wave'==1)  {
            qui gen byte `edgrpnew' = 0 if `w'_qfhigh==96
            qui replace  `edgrpnew' = 1 if inrange(`w'_qfhigh,13,15)
            qui replace  `edgrpnew' = 2 if inlist(`w'_qfhigh,9,12)
            qui replace  `edgrpnew' = 3 if inlist(`w'_qfhigh,6,7,8,10,11)
            qui replace  `edgrpnew' = 4 if inrange(`w'_qfhigh,3,5)
            qui replace  `edgrpnew' = 5 if inlist(`w'_qfhigh,1,2)
        }

         if (`wave'>1 & `wave'<=6) {
            qui gen byte `edgrpnew' = 0 if `w'_qfhigh==96 & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 1 if inrange(`w'_qfhigh,13,15) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 2 if inlist(`w'_qfhigh,9,12) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 3 if inlist(`w'_qfhigh,6,7,8,10,11) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 4 if inrange(`w'_qfhigh,3,5) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 5 if inlist(`w'_qfhigh,1,2) & `w'_ff_everint!=1
        }

        if (`wave'>=7) {
            qui gen byte `edgrpnew' = 0 if `w'_qfhigh==96 & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 1 if inrange(`w'_qfhigh,13,15) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 2 if inlist(`w'_qfhigh,9,12,14,17,18) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 3 if inlist(`w'_qfhigh,6,7,8,10,11,16) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 4 if inrange(`w'_qfhigh,3,5) & `w'_ff_everint!=1
            qui replace  `edgrpnew' = 5 if inlist(`w'_qfhigh,1,2) & `w'_ff_everint!=1
        }


        label define `edgrpnew' 0 "None of the above qualifications" 1 "Less than GCSEs" 2 "GCSEs" 3 "A-levels" 4 "Vocational higher" 5 "University"
        label values  `edgrpnew' `edgrpnew'
        label variable `edgrpnew' "New grouped highest qualification"

        if "`mindic'" == "mindic" {
            if (`wave'==1)  {
                qui replace `edgrpnew' = .a if inlist(`w'_qfhigh,-1,-2,-9) & `edgrpnew' == .
            }
            if (`wave'>1) {
                qui replace `edgrpnew' = .a if inlist(`w'_qfhigh,-1,-2,-8,-9) & `edgrpnew' == . & `w'_ff_everint!=1
                qui replace `edgrpnew' = .b if `w'_ff_everint==1
            }

            if (`wave'>=6) {
                qui replace `edgrpnew' = .c if `w'_ff_everint==-9 & `edgrpnew'==.
            }

            if `wave'>=9 {
                qui replace `edgrpnew' = .f
            }


            assert (`edgrpnew' != .)
            label define `edgrpnew' .a "qfhigh invalid" .b "Interviewed previously (Wave 2+)" .c "ff_everint missing (Wave 6+)" .f "NOT YET CODED (Wave 9)", add
        }

    }

end


* Age left school
*****************

program define indresp_agesch, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars agesch(name) schstill(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_scend `w'_school"
    }
    else {

        if "`agesch'" == "" local agesch "agesch"
        if "`schstill'" == "" local schstill "schstill"

        qui gen byte `agesch' = `w'_scend if (`w'_scend >= 0 & `w'_scend < .)
        label variable `agesch' "Age left school"
        qui gen byte `schstill' = 1 if `w'_school == 3
        qui replace `schstill'  = 0 if inlist(`w'_school,1,2)
        label variable `schstill' "Still at school"

        if "`mindic'" == "mindic" {
            qui replace `agesch' = .a if `w'_school==2 & `agesch'==.
            qui replace `agesch' = .b if `w'_school==3 & `agesch'==.
            qui replace `agesch' = .c if  inlist(`w'_scend,-1,-2,-9) & `agesch'==.
            qui replace `agesch' = .d if  inlist(`w'_scend,-8) & inlist(`w'_school,-1,-2,-9) & `agesch'==.
            qui replace `agesch' = .e if  inlist(`w'_school,-8) & `agesch'==.

            label define `agesch' .a "Never went to school" .b "Still at school" .c "scend invalid" .e "school invalid" .d "Interviewed previously (Wave 2+)"
            label values `agesch' `agesch'
            assert `agesch'!=.

            qui replace `schstill' = .a if inlist(`w'_school,-1,-2,-9) & `schstill'==.
            qui replace `schstill' = .b if inlist(`w'_school,-8) & `schstill'==.
            label define `schstill' .a "school invalid"  .b "Interviewed previously (Wave 2+)"
            label values `schstill' `schstill'
            assert `schstill'!=.
        }
    }

end


* Type educational institution (if currently in education)
**********************************************************

/*Note the coding frame is different to that in the BHPS*/
program define indresp_edtype, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars edtype(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbstat `w'_edtype `w'_ivfio"
    }
    else {

        if "`edtype'" == "" local edtype "edtype"

        qui gen byte `edtype' = 1 if `w'_jbstat==7 & `w'_edtype==1
        replace      `edtype' = 2 if `w'_jbstat==7 & `w'_edtype==2
        replace      `edtype' = 3 if `w'_jbstat==7 & `w'_edtype==3
        replace      `edtype' = 4 if `w'_jbstat==7 & `w'_edtype==4
        replace      `edtype' = 5 if `w'_jbstat==7 & `w'_edtype==5

        label define `edtype' 1 "School" 2 "6th form/tertiary college" 3 "FE college" 4 "HE college" 5 "University"

        label values `edtype' `edtype'
        label variable `edtype' "Type of current educational institution"

        if "`mindic'" == "mindic" {
            * Not in education
            qui replace `edtype' = .a if `w'_ivfio ==2 & `edtype' == .
            qui replace `edtype' = .b if !inlist(`w'_jbstat,7) & `w'_ivfio ==1 & `edtype' == .
            qui replace `edtype' = .c if (inlist(`w'_edtype,-1,-2,-9) & `w'_ivfio ==1) |(inlist(`w'_ivfio,3,-9) & inlist(`w'_edtype,-8)) & `edtype' == .

            label define `edtype' .a "Proxy respondent" .b "Not a full time student" .c "edtype invalid", add
            assert (`edtype' != .)
        }

    }

end


* Age first left FTE (waves 2, 11 and 12)
*****************************************

/*these sorts of questions are not found in US yet*/
/*there are questions about when respondents left fte after their first interview but these are different
to the BHPS questions here which are about when people FIRST left FTE*/

/*
program define indresp_ftenddate, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ftendm(name) ftendy(name) ftestill(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if `wave' == 2 return local vars "`w'ledendm `w'ledeny4 `w'lednow `w'ivfio"
        else if inlist(`wave',11,12) return local vars "`w'ledendm `w'ledeny4 `w'lednow `w'ivfio `w'memorig"
    }
    else {

        if "`ftendm'" == "" local ftendm "ftendm"
        if "`ftendy'" == "" local ftendy "ftendy"
        if "`ftestill'" == "" local ftestill "ftestill"

        * Info only exists for waves 2, 11 and 12
        if !inlist(`wave',2,11,12) {
            qui gen byte `ftendm' = .f
            qui gen byte `ftendy' = .f
            qui gen byte `ftestill' = .f

            label variable `ftendm' "Month first left FTE"
            label variable `ftendy' "Year first left FTE"
            label variable `ftestill' "Still in FTE"
        }

        if inlist(`wave',2,11,12) {

        qui gen byte `ftendm' = `w'ledendm if inrange(`w'ledendm,1,12)
        * Deal with season codes: 13 = winter = jan, 14 = spring = apr, 15 = summer = jul, 16 = autumn = oct
        qui replace `ftendm' = (`w'ledendm - 13)*3 + 1 if inrange(`w'ledendm,13,16)
        label variable `ftendm' "Month first left FTE"

        qui gen int `ftendy' = `w'ledeny4 if inrange(`w'ledeny4,1900,`wave'+1991)
        label variable `ftendy' "Year first left FTE"

        qui gen byte `ftestill' = 1 if `w'lednow == 0
        if `wave' == 2 qui replace `ftestill' = 0 if inlist(`w'lednow,-8,1)
        else if `wave' == 11 qui replace `ftestill' = 0 if inlist(`w'lednow,-8,1) & inlist(`w'memorig,5,6)
        else if `wave' == 12 qui replace `ftestill' = 0 if inlist(`w'lednow,-8,1) & `w'memorig == 7
        label variable `ftestill' "Still in FTE"
        assert `ftestill' == 0 if `ftendm' < .
        assert `ftestill' == 0 if `ftendy' < .

        if "`mindic'" == "mindic" {
            if `wave' == 2 {
                qui replace `ftendm' = .b if inlist(`w'ivfio,2,3) & `ftendm' == .
                qui replace `ftendm' = .c if `w'ivfio == 1 & `ftestill' == 1 & `ftendm' == .
                qui replace `ftendm' = .d if `w'ivfio == 1 & `ftestill' != 1 & `w'ledendm == -1 & `ftendm' == .
                qui replace `ftendm' = .e if `w'ivfio == 1 & `ftestill' != 1 & inlist(`w'ledendm,-1,-2,-3,-4,-9) & `ftendm' == .

                qui replace `ftendy' = `ftendm' if inlist(`ftendm',.b,.c) & `ftendy' == .
                qui replace `ftendy' = .d if `w'ivfio == 1 & `ftestill' != 1 & `w'ledeny4 == -1 & `ftendy' == .
                qui replace `ftendy' = .e if `w'ivfio == 1 & `ftestill' != 1 & inlist(`w'ledeny4,-2,-3,-4,-9) & `ftendy' == .

                qui replace `ftestill' = .b if inlist(`w'ivfio,2,3) & `ftestill' == .
                qui replace `ftestill' = .c if inlist(`w'lednow,-1,-2,-3,-4,-9) & `ftestill' == .
            }

            else if `wave' == 11 {
                qui replace `ftendm' = .a if !inlist(`w'memorig,5,6) & `ftendm' == .
                qui replace `ftendm' = .b if inlist(`w'memorig,5,6) & inlist(`w'ivfio,2,3) & `ftendm' == .
                qui replace `ftendm' = .c if inlist(`w'memorig,5,6) & `w'ivfio == 1 & inlist(`w'lednow,0,1) & `ftendm' == .
                qui replace `ftendm' = .d if inlist(`w'memorig,5,6) & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & `w'ledendm == -1 & `ftendm' == .
                qui replace `ftendm' = .e if inlist(`w'memorig,5,6) & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & inlist(`w'ledendm,-1,-2,-3,-4,-9) & `ftendm' == .

                qui replace `ftendy' = `ftendm' if inlist(`ftendm',.a,.b,.c) & `ftendy' == .
                qui replace `ftendy' = .d if inlist(`w'memorig,5,6) & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & `w'ledeny4 == -1 & `ftendy' == .
                qui replace `ftendy' = .e if inlist(`w'memorig,5,6) & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & inlist(`w'ledeny4,-1,-2,-3,-4,-9, 9998) & `ftendy' == .

                qui replace `ftestill' = `ftendm' if inlist(`ftendm',.a,.b) & `ftestill' == .
                qui replace `ftestill' = .c if inlist(`w'lednow,-1,-2,-3,-4,-9) & `ftestill' == .
            }

            else if `wave' == 12 {
                qui replace `ftendm' = .a if `w'memorig != 7 & `ftendm' == .
                qui replace `ftendm' = .b if `w'memorig == 7 & inlist(`w'ivfio,2,3) & `ftendm' == .
                qui replace `ftendm' = .c if `w'memorig == 7 & `w'ivfio == 1 & inlist(`w'lednow,0,1) & `ftendm' == .
                qui replace `ftendm' = .d if `w'memorig == 7 & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & `w'ledendm == -1 & `ftendm' == .
                qui replace `ftendm' = .e if `w'memorig == 7 & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & inlist(`w'ledendm,-1,-2,-3,-4,-9) & `ftendm' == .

                qui replace `ftendy' = `ftendm' if inlist(`ftendm',.a,.b,.c) & `ftendy' == .
                qui replace `ftendy' = .d if `w'memorig == 7 & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & `w'ledeny4 == -1 & `ftendy' == .
                qui replace `ftendy' = .e if `w'memorig == 7 & `w'ivfio == 1 & !inlist(`w'lednow,0,1) & inlist(`w'ledeny4,-1,-2,-3,-4,-9, 9998) & `ftendy' == .

                qui replace `ftestill' = `ftendm' if inlist(`ftendm',.a,.b) & `ftestill' == .
                qui replace `ftestill' = .c if inlist(`w'lednow,-1,-2,-3,-4,-9) & `ftestill' == .
            }

            assert inrange(`ftendm',1,12) | (`ftendm' > .)
            assert inrange(`ftendy',1900,`wave'+1991) | (`ftendy' > .)
            assert inlist(`ftestill',0,1) | (`ftestill' > .)
            }

            label define `ftendm' .a "Not in booster" .b "Proxy/phone" .c "Still in FTE/never went to school" .d "ledendm unknown" .e "ledendm invalid" .f "No info in this wave"
            label values `ftendm' `ftendm'
            label define `ftendy' .a "Not in booster" .b "Proxy/phone" .c "Still in FTE/never went to school" .d "ledeny4 unknown" .e "ledeny4 invalid" .f "No info in this wave"
            label values `ftendy' `ftendy'
            label define `ftestill' .a "Not in booster" .b "Proxy/phone" .c "lednow invalid"
            label values `ftestill' `ftestill'

            assert `ftendm'!=.
            assert `ftendy'!=.
            assert `ftestill'!=.
        }


    }

end
*/



* Months of labour market experience
************************************

program define indresp_labmktmths, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars labmktmths(name) intdate(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_hidp `w'_pno `w'_fenow `w'_lgaped"
    }
    else {

        if "`labmktmths'" == "" local labmktmths "labmktmths"
        if "`intdate'" == "" local intdate "intdate"

        if (`wave'==1) {

            sort `w'_hidp `w'_pno
            tempfile currdata
            qui save `currdata'

            keep `w'_hidp `w'_pno `intdate'
            tempfile intdatedata
            qui save `intdatedata'

            use `w'_hidp `w'_pno `w'_spellno `w'_leshst `w'_leshem `w'_leshsy4 using "$data\\`w'_empstat.dta"
            order `w'_hidp `w'_pno `w'_spellno `w'_leshst `w'_leshem `w'_leshsy4
            sort `w'_hidp `w'_pno `w'_spellno
            qui merge `w'_hidp `w'_pno using `intdatedata', uniqusing
            assert _merge != 1
            qui keep if _merge == 3
            drop _merge

            *this is start month
            rename `w'_leshem `w'_leshsm
            bys `w'_hidp `w'_pno: gen N = _N

            sort `w'_hidp `w'_pno `w'_spellno
            gen `w'_leshem = `w'_leshsm[_n+1] if `w'_spellno!=N
            gen `w'_leshey = `w'_leshsy4[_n+1] if `w'_spellno!=N
            *drop those who do not reach "current status, no further changes"
            bys `w'_hidp `w'_pno (`w'_spellno):  gen checktemp = inlist(`w'_leshst,0) if _n == _N
            bys `w'_hidp `w'_pno: egen check = min(checktemp)
            drop if check==0

            bys `w'_hidp `w'_pno (`w'_spellno):  assert inlist(`w'_leshst,0) if _n == _N
            *drop the final "spell" which tells us that they reached their current state with their previous answer
            drop if `w'_spellno==N

            * copy the interview date into the most recent spell end date
            qui by `w'_hidp `w'_pno (`w'_spellno): replace `w'_leshem = month(`intdate') if _n == _N
            qui by `w'_hidp `w'_pno (`w'_spellno): replace `w'_leshey = year(`intdate') if _n == _N
            * assume june if month unknown
            qui replace `w'_leshsm = 6 if `w'_leshsm == -1
            qui replace `w'_leshem = 6 if `w'_leshem == -1
            * deal with seasons
            qui replace `w'_leshsm = (`w'_leshsm - 13)*3 + 1 if inrange(`w'_leshsm,13,16)
            qui replace `w'_leshem = (`w'_leshem - 13)*3 + 1 if inrange(`w'_leshem,13,16)
            * deal with missing values
            qui replace `w'_leshsm = . if `w'_leshsm < 0
            qui replace `w'_leshem = . if `w'_leshem < 0
            qui replace `w'_leshsy = . if `w'_leshsy4 < 0
            qui replace `w'_leshey = . if `w'_leshey < 0

            qui gen int mths = ym(`w'_leshey,`w'_leshem) - ym(`w'_leshsy4,`w'_leshsm)
            qui gen int mthsinjob = mths*inlist(`w'_leshst,1,2,3)
            qui replace mthsinjob = 0 if mthsinjob < 0
            egen int `labmktmths' = total(mthsinjob), by(`w'_hidp `w'_pno)
            egen byte missing = max(mthsinjob >= .), by(`w'_hidp `w'_pno)
            qui replace `labmktmths' = . if missing
            if "`mindic'" == "mindic" {
                qui replace `labmktmths' = .c if missing
                assert (`labmktmths' != .)
            }
            keep `w'_hidp `w'_pno `labmktmths'

            qui bys `w'_hidp `w'_pno: keep if _n == 1


            * Merge back into current data
            sort `w'_hidp `w'_pno
            tempfile labmktdata
            qui save `labmktdata'
            use `currdata'
            qui merge `w'_hidp `w'_pno using `labmktdata', uniq
            assert _merge != 2


            *set to zero if in ft education and there was no gap between starting education and working.
            qui replace `labmktmths' = 0 if (`w'_fenow == 3 & `w'_lgaped==2)
        }


        if (`wave'>1) {
            qui gen `labmktmths' = .
        }

        label variable `labmktmths' "Labour market experience (mths)"

        if "`mindic'" == "mindic" {
            if (`wave'==1) {
                qui replace `labmktmths' =.a if `w'_ivfio==2 & `labmktmths'==.
                qui replace `labmktmths' =.b if `w'_ivfio==1 & _merge==1 & `labmktmths'==.
            }

            if (`wave'>1) {
                qui replace `labmktmths' =.c
            }

        label define `labmktmths' .a "Proxy interview" .b "Did not merge" .c "Not asked about in this wave"
        assert `labmktmths'!=.
        label values `labmktmths' `labmktmths'
        }

        if (`wave'==1) drop _merge

    }

end





* Type of first job
*******************

program define indresp_jb1status, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1status(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbhas `w'_jboff `w'_jbsemp"
    }
    else {

        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen byte `jb1status' = 0 if `w'_jbhas == 2 & inlist(`w'_jboff,2,3)
        qui replace `jb1status' = 1 if (`w'_jbhas == 1 | (`w'_jbhas == 2 & `w'_jboff == 1)) & `w'_jbsemp == 1
        qui replace `jb1status' = 2 if (`w'_jbhas == 1 | (`w'_jbhas == 2 & `w'_jboff == 1)) & `w'_jbsemp == 2
        label define `jb1status' 0 "No 1st job" 1 "Employee" 2 "Self-employed"
        label values `jb1status' `jb1status'
        label variable `jb1status' "Type of first job"

        if "`mindic'" == "mindic" {
            qui replace `jb1status' = .a if inlist(`w'_jbhas,-1,-2,-3,-4,-8,-9) & `jb1status' == .
            qui replace `jb1status' = .b if inlist(`w'_jboff,-1,-2,-3,-4,-8,-9) & `jb1status' == .
            qui replace `jb1status' = .c if inlist(`w'_jbsemp,-1,-2,-3,-4,-8,-9) & `jb1status' == .
            assert (`jb1status' != .)
            label define `jb1status' .a "jbhas invalid" .b "jboff invalid" .c "jbsemp invalid", add
        }

    }

end



* Type of second job (many of the missing responses are proxy/telephone interviews)
***********************************************************************************

program define indresp_jb2status, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb2status(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_j2has `w'_j2semp `w'_ivfio"
    }
    else {

        if "`jb2status'" == "" local jb2status "jb2status"

        qui gen byte `jb2status' = 0 if `w'_j2has == 2
        qui replace `jb2status' = 1 if `w'_j2has == 1 & `w'_j2semp == 1
        qui replace `jb2status' = 2 if `w'_j2has == 1 & `w'_j2semp == 2
        label define `jb2status' 0 "No 2nd job" 1 "Employee" 2 "Self-employed"
        label values `jb2status' `jb2status'
        label variable `jb2status' "Type of second job"

        if "`mindic'" == "mindic" {
            qui replace `jb2status' = .a if inlist(`w'_ivfio,2) & `jb2status' == .
            qui replace `jb2status' = .b if inlist(`w'_j2has,-1,-2,-3,-4,-9) & `jb2status' == .
            qui replace `jb2status' = .c if inlist(`w'_j2semp,-1,-2,-3,-4,-9) & `jb2status' == .
            assert (`jb2status' != .)
            label define `jb2status' .a "Proxy respondent" .b "j2has invalid" .c "j2semp invalid", add
        }

    }

end



* Combined type of first and second job (note: 1st job NOT required for individual to be defined as employed/self-employed)
***************************************************************************************************************************

* indresp_jbstatus must be run after indresp_jb1status and indresp_jb2status (it uses both jb1status and jb2status)

program define indresp_jbstatus, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jbstatus(name) jb1status(varname) jb2status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
    }
    else {

        if "`jbstatus'" == "" local jbstatus "jbstatus"
        if "`jb1status'" == "" local jb1status "jb1status"
        if "`jb2status'" == "" local jb2status "jb2status"

        qui gen byte `jbstatus' = 0 if `jb1status' == 0 & `jb2status' == 0
        qui replace `jbstatus' = 1 if (`jb1status' == 1 & inlist(`jb2status',0,1)) | (`jb2status' == 1 & `jb1status' == 0)
        qui replace `jbstatus' = 2 if `jb1status' == 2 & inlist(`jb2status',0,2) | (`jb2status' == 2 & `jb1status' == 0)
        qui replace `jbstatus' = 3 if (`jb1status' == 1 & `jb2status' == 2) | (`jb1status' == 2 & `jb2status' == 1)
        label define `jbstatus' 0 "No job" 1 "Employee" 2 "Self-employed" 3 "Both"
        label values `jbstatus' `jbstatus'
        label variable `jbstatus' "Type of first and other jobs"

        if "`mindic'" == "mindic" {
            qui replace `jbstatus' = .b if `jb1status' == .a & `jbstatus' == .
            qui replace `jbstatus' = .c if `jb1status' == .b & `jbstatus' == .
            qui replace `jbstatus' = .d if `jb1status' == .c & `jbstatus' == .
            qui replace `jbstatus' = .a if `jb2status' == .a & `jbstatus' == .
            qui replace `jbstatus' = .e if `jb2status' == .b & `jbstatus' == .
            qui replace `jbstatus' = .f if `jb2status' == .c & `jbstatus' == .
            assert (`jbstatus' != .)
            label define `jbstatus' .a "Proxy respondent" .b "jbhas invalid" .c "jboff invalid" .d "jbsemp invalid" .e "j2has invalid" .f "j2semp invalid", add
        }

    }

end



* Socio-economic group based on first job
*****************************************

program define indresp_jb1soc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1soc(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbrgsc_dv"
    }
    else {

        if "`jb1soc'" == "" local jb1soc "jb1soc"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen byte `jb1soc' = `w'_jbrgsc_dv if `w'_jbrgsc_dv > 0 & `jb1status' < .
        label variable `jb1soc' "Social class of first job"

        qui tab `w'_jbrgsc_dv, matrow(values)
        forval i = 1/`=rowsof(values)' {
            local labval = values[`i',1]
            if `labval' > 0 {
                label define `jb1soc' `labval' "`: label (`w'_jbrgsc_dv) `labval', strict'", add
            }
        }
        label values `jb1soc' `jb1soc'
        matrix drop values

        if "`mindic'" == "mindic" {
            qui replace `jb1soc' = .a if `jb1status' == 0
            qui replace `jb1soc' = .b if `jb1status' >= . & `jb1soc' == .
            qui replace `jb1soc' = .c if `jb1soc' >= . & `jb1soc' == .
            assert (`jb1soc' != .)
            label define `jb1soc' .a "No first job" .b "jb1status missing" .c "jbrgsc missing", add
        }

    }

end



* Main job start date
*********************

*Prior to wave 13 this just asks about "current job". Not 100% sure how people will have answered this if they had multiple jobs
*Wave 13 onwards the data reported is thier main job if they have mulitple jobs 

program define indresp_jb1start, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1startd(name) jb1startm(name) jb1starty(name)  mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbbgd `w'_jbbgm `w'_jbbgy `w'_jbhas `w'_jboff"
    }
    else {

        if "`jb1startd'" == "" local jb1startd "jb1startd"
        if "`jb1startm'" == "" local jb1startm "jb1startm"
        if "`jb1starty'" == "" local jb1starty "jb1starty"

        qui gen byte `jb1startd' = `w'_jbbgd if (`w'_jbbgd > 0 & `w'_jbbgd <= 31)
        label variable `jb1startd' "Day of month main job started"

        qui gen byte `jb1startm' = `w'_jbbgm if (`w'_jbbgm > 0 & `w'_jbbgm <= 12)
        qui replace `jb1startm' = 1 if  `w'_jbbgm == 13
        qui replace `jb1startm' = 4 if  `w'_jbbgm == 14
        qui replace `jb1startm' = 7 if  `w'_jbbgm == 15
        qui replace `jb1startm' = 10 if `w'_jbbgm == 16

        label variable `jb1startm' "Month main job started"

        qui gen int `jb1starty' = `w'_jbbgy if (`w'_jbbgy > 1900 & `w'_jbbgy <= 2010+`wave')
        label variable `jb1starty' "Year main job started"

        if "`mindic'" == "mindic" {

        qui replace `jb1startd' = .a if (`w'_jbhas!=1 & `w'_jboff!=1) & `jb1startd'==.
        qui replace `jb1startd' = .b if (`w'_jbhas==1 | `w'_jboff==1) & inlist(`w'_jbbgd,0,-1,-2,-8,-9) & `jb1startd'==.
        qui replace `jb1startd' = .c if (`w'_jbhas==1 | `w'_jboff==1) & `w'_jbbgd==-7 & `jb1startd'==.

        label define `jb1startd' .a "No job" .b "jbbgd invalid" .c "jbbgd invalid (proxy interview)"
        label values `jb1startd' `jb1startd'

        qui replace `jb1startm' = .a if (`w'_jbhas!=1 & `w'_jboff!=1) & `jb1startm'==.
        qui replace `jb1startm' = .b if (`w'_jbhas==1 | `w'_jboff==1) & inlist(`w'_jbbgm,0,-1,-2,-8,-9) & `jb1startm'==.
        qui replace `jb1startm' = .c if (`w'_jbhas==1 | `w'_jboff==1) & `w'_jbbgm==-7 & `jb1startm'==.

        label define `jb1startm' .a "No job" .b "jbbgm invalid" .c "jbbgm invalid (proxy interview)"
        label values `jb1startm' `jb1startm'

        qui replace `jb1starty' = .a if (`w'_jbhas!=1 & `w'_jboff!=1) & `jb1starty'==.
        qui replace `jb1starty' = .b if (`w'_jbhas==1 | `w'_jboff==1) & inlist(`w'_jbbgy,0,-1,-2,-8,-9) & `jb1starty'==.
        qui replace `jb1starty' = .c if (`w'_jbhas==1 | `w'_jboff==1) & `w'_jbbgy==-7 & `jb1starty'==.

        label define `jb1starty' .a "No job" .b "jbbgy invalid" .c "jbbgy invalid (proxy interview)"
        label values `jb1starty' `jb1starty'

        assert `jb1startd'!=.
        assert `jb1startm'!=.
        assert `jb1starty'!=.
        }

    }

end



* Min and max dates
*******************

program define indresp_minandmaxdate

    syntax [, mindate(name) maxdate(name) day(varname) month(varname) year(varname)]
    if "`mindate'" == "" local mindate "mindate"
    if "`maxdate'" == "" local maxdate "maxdate"
    if "`day'" == "" local day "day"
    if "`month'" == "" local month "month"
    if "`year'" == "" local year "year"

    qui gen long `mindate' = mdy(cond(`month'<.,`month',1,.),cond(`day'<.,`day',1,.),`year')

    tempvar maxmonth maxday
    gen byte `maxmonth' = cond(`month'<.,`month',12,.)
    qui gen byte `maxday' = `day' if `day' < .
    qui replace `maxday' = 31*inlist(`maxmonth',1,3,5,7,8,10,12) + 30*inlist(`maxmonth',4,6,9,11) + (28 + (!mod(`year',400) | (!mod(`year',4) & mod(`year',100))))*(`maxmonth' == 2) if `year' < . & `day' >= .
    qui gen long `maxdate' = mdy(`maxmonth',`maxday',`year')
    drop `maxday' `maxmonth'

    assert (`mindate' <= `maxdate')
    format %td `mindate' `maxdate'

end


* Main job tenure
*****************

program define indresp_jb1tenure, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1tenure(name) intdate(varname) jb1startd(varname) jb1startm(varname) jb1starty(varname) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio"
    }
    else {

        if "`jb1tenure'" == "" local jb1tenure "jb1tenure"
        if "`intdate'"   == "" local intdate   "intdate"
        if "`jb1startd'" == "" local jb1startd "jb1startd"
        if "`jb1startm'" == "" local jb1startm "jb1startm"
        if "`jb1starty'" == "" local jb1starty "jb1starty"
        if "`jb1status'" == "" local jb1status "jb1status"

        tempvar jb1minstartdate jb1maxstartdate
        *fix meaningless dates
            *31st april, june, september, november
            qui replace jb1startd = 30 if jb1startd==31 & inlist(jb1startm,4,6,9,11)
/*
        if `wave'==2 {
            *31st of September
            qui replace jb1startd = 30 if jb1startd==31 & jb1startm==9
        }

        if `wave'==3 {
            *31st of November
            qui replace jb1startd = 30 if jb1startd==31 & jb1startm==11
        }

        if `wave'==4 {
            *31st of April
            qui replace jb1startd = 30 if jb1startd==31 & jb1startm==4
        }

        if `wave'==5 {
            *31st april, june, september
            qui replace jb1startd = 30 if jb1startd==31 & inlist(jbstartm,4,6,9)
            }
            */

            if `wave'==6 {
                *30th Feb
                qui replace jb1startd = 28 if jb1startd==30 & inlist(jb1startm,2)
                }

        indresp_minandmaxdate, mindate(`jb1minstartdate') maxdate(`jb1maxstartdate') day(`jb1startd') month(`jb1startm') year(`jb1starty')

        * assert `jb1minstartdate' <= `intdate' if `jb1minstartdate' < .
        qui replace `jb1maxstartdate' = `intdate' if `intdate' < `jb1maxstartdate' & `jb1maxstartdate' < .
        * nothing done using b4septly
        qui gen long `jb1tenure' = `intdate' - int((`jb1minstartdate' + `jb1maxstartdate')/2) + 1
        qui replace `jb1tenure' = 0 if `jb1tenure' < 0
        drop `jb1minstartdate' `jb1maxstartdate'
        label variable `jb1tenure' "Tenure in main job"

        if "`mindic'" == "mindic" {
            qui replace `jb1tenure' = .a if `jb1status' == 0 & `jb1tenure' == .
            qui replace `jb1tenure' = .b if `jb1status' >= . & `jb1tenure' == .
            qui replace `jb1tenure' = .c if inlist(`jb1status',1,2) & `intdate' >= . & `jb1tenure' == .
            qui replace `jb1tenure' = .d if inlist(`jb1status',1,2) & `intdate' < . & `jb1starty' >= . & `jb1tenure' == .
            assert (`jb1tenure' != .)
            label define `jb1tenure' .a "No 1st job" .b "jb1status missing" .c "intdate missing" .d "jb1starty missing"
            label values `jb1tenure' `jb1tenure'
        }

    }

end



* Usual hours in first job excluding overtime
*********************************************

* Variable is not perfect because overtime is effectively included in self-employment hours
* Wave 1: proxy self employment hours is recorded in ajshrs; subsequent waves: recorded in wjbhrs
* indresp_jb1hrs must be run after indresp_jb1status (it uses jb1status)
* Hours = 0 for those not working
* Wave 13 + refers to main job (if multiple jobs)

program define indresp_jb1hrs, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1hrs(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
		if `wave'<13 & `wave'!=6 {
			return local vars "`w'_jbhrs `w'_jshrs"
		}
		if `wave'==6 {
			return local vars "`w'_jbhrs `w'_jshrs `w'_jbsemp"
		}
		if `wave'>=13 {
			return local vars "`w'_jbhrs `w'_jshrs `w'_multijobs `w'_jbmain `w'_jbsemp"
		}
    }
	
    else {

        if "`jb1hrs'" == "" local jb1hrs "jb1hrs"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen int `jb1hrs' = 0 if `jb1status' == 0

        qui replace `jb1hrs' = `w'_jbhrs if (`w'_jbhrs >=0 & `w'_jbhrs < .) & `jb1status' == 1
        qui replace `jb1hrs' = `w'_jshrs if (`w'_jshrs >=0 & `w'_jshrs < .) & `jb1status' == 2

        label variable `jb1hrs' "Usual weekly hours in first job excluding overtime"

        if "`mindic'" == "mindic" {
            qui replace `jb1hrs' = .a if `jb1status' >= . & `jb1hrs' == .
            qui replace `jb1hrs' = .b if inlist(`w'_jbhrs,-1,-2,-3,-4,-9) & `jb1status' == 1 & `jb1hrs' == .
            qui replace `jb1hrs' = .c if inlist(`w'_jshrs,-1,-2,-3,-4,-9) & `jb1status' == 2 & `jb1hrs' == .

            if (`wave'==6|`wave'==14|`wave'==15) {
              qui replace `jb1hrs' = .d if `w'_jbhrs==-8 & `w'_jbsemp==1 & `jb1hrs' == . /*in wave 6 there are 582 individuals who I think should have been asked jbhrs but were not**/
              qui replace `jb1hrs' = .d if `w'_jshrs==-8 & `w'_jbsemp==2 & `jb1hrs' == . /*in wave 6 there are 88 individuals who I think should have been asked jshrs but were not (in wave 14 one individual, in wave 15 3 individuals)**/
             }
			 
			if (`wave'>=13) {
              qui replace `jb1hrs' = .e if `w'_jbhrs==-8 & `w'_jbsemp==1 & (`w'_multijobs>1|`w'_multijobs==-8) & inlist(`w'_jbmain,-1,-2) & `jb1hrs' == . 
              qui replace `jb1hrs' = .e if `w'_jshrs==-8 & `w'_jbsemp==2 & (`w'_multijobs>1|`w'_multijobs==-8) & inlist(`w'_jbmain,-1,-2) & `jb1hrs' == . 
			  
			  qui replace `jb1hrs' = .f if `w'_jbhrs==-8 & `w'_jbsemp==1 & `w'_multijobs==-8 & `w'_jbmain>0 & `jb1hrs' == . 
			  qui replace `jb1hrs' = .f if `w'_jshrs==-8 & `w'_jbsemp==2 & `w'_multijobs==-8 & `w'_jbmain>0 & `jb1hrs' == . 
			  
			  qui replace `jb1hrs' = .g if `w'_jbhrs==-8  & (`w'_jshrs>0|inlist(`w'_jshrs,-1,-2)) & `w'_jbsemp==1 & `w'_multijobs==-8 & `jb1hrs' == . 
              qui replace `jb1hrs' = .g if `w'_jshrs==-8  & (`w'_jbhrs>0|inlist(`w'_jbhrs,-1,-2))  & `w'_jbsemp==2  & `w'_multijobs==-8 & `jb1hrs' == . 
			  
             }

            assert (`jb1hrs' != .)
            label define `jb1hrs' .a "jb1status missing" .b "jbhrs invalid" .c "jshrs invalid" .d "incorrect routing W6/W14/W15" .e "Does not identify main job if multiple jobs" .f "Gives main job but multiple jobs inapplicable" .g "Asked self-employed hours when main job is employee or vice versa"
            label values `jb1hrs' `jb1hrs'
        }

    }

end



* Usual hours in first job including overtime (paid or unpaid)
**************************************************************

* Proxy respondents and (before wave 15) telephone respondents are not asked about overtime, so all these are missing
* indresp_jb1hrsot must be run after indresp_jb1status (it uses jb1status)

program define indresp_jb1hrsot, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1hrsot(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio `w'_jbhrs `w'_jshrs `w'_jbot `w'_jboff"
    }
    else {

        if "`jb1hrsot'" == "" local jb1hrsot "jb1hrsot"
        if "`jb1status'" == "" local jb1status "jb1status"

    *    qui gen int `jb1hrsot' = 0 if `jb1status' == 0 & `w'ivfio == 1
        qui gen int `jb1hrsot' = 0 if `jb1status' == 0
        qui replace `jb1hrsot' = `w'_jbhrs + `w'_jbot if (`w'_jbhrs >=0 & `w'_jbhrs < .) & (`w'_jbot >=0 & `w'_jbot < .) & `jb1status' == 1 & `w'_ivfio !=2
        qui replace `jb1hrsot' = `w'_jshrs if (`w'_jshrs >=0 & `w'_jshrs < .) & `jb1status' == 2 & `w'_ivfio !=2
        label variable `jb1hrsot' "Usual weekly hours in first job including all overtime"

        if "`mindic'" == "mindic" {
            qui replace `jb1hrsot' = .a if `w'_ivfio == 2 & `jb1status' != 0 & `jb1hrsot' == .
            qui replace `jb1hrsot' = .b if `jb1status' >= . & `jb1hrsot' == .
            qui replace `jb1hrsot' = .c if inlist(`w'_jbhrs,-1,-2,-3,-4,-8,-9) & (`jb1status' == 1 & `w'_ivfio !=2) & `jb1hrsot' == .
            qui replace `jb1hrsot' = .d if inlist(`w'_jbot,-1,-2,-3,-4,-9)     & (`jb1status' == 1 & `w'_ivfio !=2) & `jb1hrsot' == .
            qui replace `jb1hrsot' = .e if inlist(`w'_jshrs,-1,-2,-3,-4,-8,-9) & (`jb1status' == 2 & `w'_ivfio !=2) & `jb1hrsot' == .

            assert (`jb1hrsot' != .)
            label define `jb1hrsot' .a "Proxy respondent" .b "jb1status missing" .c "jbhrs invalid" .d "jbot invalid" .e "jshrs invalid"
            label values `jb1hrsot' `jb1hrsot'
        }

    }

end



* Usual hours other jobs including overtime
*******************************************

* Proxy/telephone respondents are not asked about overtime, so all these are missing
* indresp_jb2hrsot must be run after indresp_jb2status (it uses jb2status)

program define indresp_jb2hrsot, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb2hrsot(name) jb2status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio `w'_j2hrs"
    }
    else {

        if "`jb2hrsot'" == "" local jb2hrsot "jb2hrsot"
        if "`jb2status'" == "" local jb2status "jb2status"

        qui gen int `jb2hrsot' = 0 if `jb2status' == 0
        qui replace `jb2hrsot' = round(`w'_j2hrs/4) if (`w'_j2hrs >=0 & `w'_j2hrs < .) & inlist(`jb2status',1,2)
        label variable `jb2hrsot' "Usual weekly hours in other jobs including all overtime"

        if "`mindic'" == "mindic" {
            qui replace `jb2hrsot' = .a if inlist(`w'_ivfio,2,3)
            qui replace `jb2hrsot' = .b if `jb2status' >= . & `jb2hrsot' == .
            qui replace `jb2hrsot' = .c if inlist(`w'_j2hrs,-1,-2,-3,-4,-9) & inlist(`jb2status',1,2) & `jb2hrsot' == .
            assert (`jb2hrsot' != .)
            label define `jb2hrsot' .a "Proxy respondent" .b "jb2status missing" .c "jshrs invalid"
            label values `jb2hrsot' `jb2hrsot'
        }

    }

end



* Usual hours in all jobs including overtime
********************************************

* Proxy/telephone respondents are not asked about overtime, so all these are missing
* indresp_jbhrsot must be run after indresp_jb1hrsot and indresp_jb2hrsot (it uses jb1hrsot and jb2hrsot)

program define indresp_jbhrsot, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jbhrsot(name) jb1hrsot(varname) jb2hrsot(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
    }
    else {

        if "`jbhrsot'" == "" local jbhrsot "jbhrsot"
        if "`jb1hrsot'" == "" local jb1hrsot "jb1hrsot"
        if "`jb2hrsot'" == "" local jb2hrsot "jb2hrsot"

        qui gen int `jbhrsot' = `jb1hrsot' + `jb2hrsot'
        label variable `jbhrsot' "Usual weekly hours in all jobs including all overtime"

        if "`mindic'" == "mindic" {
            qui replace `jbhrsot' = .a if `jb1hrsot' >= .
            qui replace `jbhrsot' = .b if `jb2hrsot' >= . & `jbhrsot' == .
            assert (`jbhrsot' != .)
            label define `jbhrsot' .a "jb1hrsot missing" .b "jb2hrsot missing"
            label values `jbhrsot' `jbhrsot'
        }

    }

end



* Basic rate of pay for employees paid hourly
*********************************************

* All these variables only exist from wave 9 onwards
* indresp_jb1rate must be run after indresp_jb1status (it uses jb1status)

program define indresp_jb1rate, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1rate(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
         return local vars "`w'_basrate `w'_paytyp `w'_basnsa `w'_ivfio"
    }
    else {

        if "`jb1rate'"   == "" local jb1rate "jb1rate"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen float `jb1rate' = `w'_basrate if (`w'_basrate >= 0 & `w'_basrate < .) & `jb1status' == 1 & `w'_paytyp == 3
        label variable `jb1rate' "Basic hourly rate for main job if paid hourly"


        if "`mindic'" == "mindic" {
            qui replace `jb1rate' = .a if inlist(`w'_ivfio,2)
            qui replace `jb1rate' = .b if inlist(`jb1status',0,2) & `jb1rate' == .
            qui replace `jb1rate' = .c if `jb1status' >= . & `jb1rate' == .
            qui replace `jb1rate' = .d if `jb1status' == 1 & (inlist(`w'_paytyp,1,2,97)|`w'_basnsa!=0) & `jb1rate' == .
            qui replace `jb1rate' = .e if `jb1status' == 1 & inlist(`w'_paytyp,-1,-2,-3,-4,-9) & `jb1rate' == .
            qui replace `jb1rate' = .f if `jb1status' == 1 & `w'_paytyp == 3 & (inlist(`w'_basrate,-1,-2,-3,-4,-9) | (`w'_basrate < 0 & abs(int(`w'_basrate)-`w'_basrate)>0.0001)) & `jb1rate' == .
            assert (`jb1rate' != .)
            label define `jb1rate' .a "Proxy respondent" .b "Not an employee" .c "jb1status missing" .d "Not paid hourly" .e "paytyp invalid" .f "basrate invalid"

            label values `jb1rate' `jb1rate'
        }

    }

end



* Overtime rate of pay for employees
************************************

* indresp_jb1rate must be run after indresp_jb1status (it uses jb1status)

program define indresp_jb1rateot, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1rateot(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_extrate `w'_paytyp `w'_ovtnsa `w'_ovtrest `w'_ovtrate `w'_pvtpay `w'_basnsa `w'_ivfio"
    }
    else {

        if "`jb1rateot'" == "" local jb1rateot "jb1rateot"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen float `jb1rateot' = 0 if `w'_ovtnsa == 2 & inlist(`w'_paytyp,3) & `jb1status' == 1
        qui replace `jb1rateot' = `w'_extrate if (`w'_extrate >= 0 & `w'_extrate < .) & `w'_extnsa == 0 & `w'_pvtpay==1 & inlist(`w'_paytyp,1,2,97) & `jb1status' == 1
        qui replace `jb1rateot' = `w'_ovtrate if (`w'_ovtrate >= 0 & `w'_ovtrate < .) & `w'_ovtnsa == 0 & `w'_paytyp == 3 & `jb1status' == 1
        label variable `jb1rateot' "Exact/estimated hourly overtime rate for employees"

        if "`mindic'" == "mindic" {
            qui replace `jb1rateot' = .a if inlist(`w'_ivfio,2)
            qui replace `jb1rateot' = .b if inlist(`jb1status',0,2) & `jb1rateot' == .
            qui replace `jb1rateot' = .c if `jb1status' >= . & `jb1rateot' == .
            qui replace `jb1rateot' = .d if `jb1status' == 1 & inlist(`w'_paytyp,-1,-2,-3,-4,-9) & `jb1rateot' == .

            qui replace `jb1rateot' = .e if `jb1status' == 1 & inlist(`w'_paytyp,1,2,97) & `w'_extnsa == 1 & `w'_pvtpay==1 & `jb1rateot' == .
            qui replace `jb1rateot' = .f if `jb1status' == 1 & inlist(`w'_paytyp,1,2,97) & `w'_extnsa == 0 & `w'_pvtpay==1 & inlist(`w'_extrate,-1,-2,-3,-4,-9) & `jb1rateot' == .
            qui replace `jb1rateot' = .g if `jb1status' == 1 & inlist(`w'_paytyp,1,2,97) & inlist(`w'_pvtpay,2,3) & `jb1rateot' == .
            qui replace `jb1rateot' = .h if `jb1status' == 1 & inlist(`w'_paytyp,1,2,97) & inlist(`w'_pvtpay,-1,-2,-3,-4,-9) & `jb1rateot' == .
            qui replace `jb1rateot' = .i if `jb1status' == 1 & inlist(`w'_paytyp,1,2,97) & `w'_pvtpay==1 & inlist(`w'_extnsa,-1,-2,-3,-4,-9) & `jb1rateot' == .

            qui replace `jb1rateot' = .j if `jb1status' == 1 & `w'_paytyp == 3 & `w'_basnsa == -2 & `jb1rateot' == .
            qui replace `jb1rateot' = .k if `jb1status' == 1 & `w'_paytyp == 3 & `w'_ovtnsa==1 & `jb1rateot' == .
            qui replace `jb1rateot' = .l if `jb1status' == 1 & `w'_paytyp == 3 & inlist(`w'_ovtrate,-1,-2,-3,-4,-9) & `jb1rateot' == .
            qui replace `jb1rateot' = .m if `jb1status' == 1 & `w'_paytyp == 3 & inlist(`w'_ovtnsa,-1,-2,-3,-4,-9)  & `jb1rateot' == .
            assert (`jb1rateot' != .)

            label define `jb1rateot' .a "Proxy respondent" .b "Not an employee" .c "jb1status missing" .d "paytyp invalid" .e "No set amount of extrate" .f "extrate invalid" .g "Not paid extra (pvtay)" .h "pvtpay invalid" .i "extnsa invalid" .j "basnsa refused " .k "No set amount of overtime" .l "ovtrate invalid"  .m "ovtnsa invalid"
            label values `jb1rateot' `jb1rateot'
        }

    }

end



* Start date of most recent self-employment accounts
****************************************************

* indresp_accstartmth must be run after indresp_jb1status (it uses jb1status)

program define indresp_accstartmth, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars accstartmth(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
		if `wave'<13 {
			return local vars "`w'_jsprby4 `w'_jsprbm `w'_jsaccs `w'_ivfio" 
		}
		if `wave'>=13 {
			 return local vars "`w'_jsprby4 `w'_jsprbm `w'_jsaccs `w'_ivfio `w'_jbmain `w'_multijobs"
		}
    }
	
    else {

        if "`accstartmth'" == "" local accstartmth "accstartmth"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen long `accstartmth' = ym(`w'_jsprby4, `w'_jsprbm) if `jb1status' == 2 & `w'_jsaccs == 1
        format %tm `accstartmth'
        label variable `accstartmth' "Start month of most recent accounts"

        if "`mindic'" == "mindic" {
            qui replace `accstartmth' = .a if inlist(`jb1status',0,1) & `accstartmth' == .
            qui replace `accstartmth' = .b if `jb1status' >= . & `accstartmth' == .
            qui replace `accstartmth' = .c if `jb1status' == 2 & inlist(`w'_ivfio,2) & `accstartmth' == .
            qui replace `accstartmth' = .d if `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & `accstartmth' == .
            qui replace `accstartmth' = .e if `jb1status' == 2 & inlist(`w'_jsaccs,-1,-2,-3,-4,-9) & `accstartmth' == .
            qui replace `accstartmth' = .f if `jb1status' == 2 & `w'_jsaccs == 1 & inlist(`w'_jsprby4,-1,-2,-3,-4,-9) & `accstartmth' == .
            qui replace `accstartmth' = .g if `jb1status' == 2 & `w'_jsaccs == 1 & inlist(`w'_jsprbm,-1,-2,-3,-4,-9) & `accstartmth' == .

            if (`wave'==6) replace `accstartmth' = .h if `w'_jbsemp==2 & `w'_jsaccs==-8 & `accstartmth' == . /*88 individuals who are self employed but not routed into the jsaccs for some reason**/
			if (`wave'==14|`wave'==15) replace `accstartmth' = .h if `w'_jbsemp==2 & `w'_jsaccs==-8 & `w'_multijobs==-8 & `accstartmth' == . /*69 individuals who are self employed but not routed into the jsaccs for some reason in W14 and 104 in W15*/
			if (`wave'>=13) replace `accstartmth' = .i if `w'_jbsemp==2 & `w'_jsaccs==-8 & inlist(`w'_jbmain,-1,-2) & (`w'_multijobs>1|`w'_multijobs==-8) & `accstartmth' == .

            assert (`accstartmth' != .)
            label define `accstartmth' .a "Not self-employed" .b "jb1status missing" .c "Proxy respondent" .d "Accounts not (yet) prepared" .e "jsaccs invalid" .f "jsprby4 invalid" .g "jsprbm invalid" .h "incorrect routing W6/W14/W15" .i "Does not identify main job if working multiple jobs"
            label values `accstartmth' `accstartmth'
        }

    }

end



* End date of most recent self-employment accounts
**************************************************

* indresp_accendmth must be run after indresp_jb1status (it uses jb1status)
* Perhaps incorporate this into (or call from) the earndate program

program define indresp_accendmth, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars accendmth(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jsprey4 `w'_jsprem `w'_jsaccs `w'_ivfio"
    }
    else {

        if "`accendmth'" == "" local accendmth "accendmth"
        if "`jb1status'" == "" local jb1status "jb1status"


        qui gen long `accendmth' = ym(`w'_jsprey4, `w'_jsprem) if `jb1status' == 2 & `w'_jsaccs == 1
        format %tm `accendmth'
        label variable `accendmth' "End month of most recent accounts"

        if "`mindic'" == "mindic" {
            qui replace `accendmth' = .a if inlist(`jb1status',0,1) & `accendmth' == .
            qui replace `accendmth' = .b if `jb1status' >= . & `accendmth' == .
            qui replace `accendmth' = .c if `jb1status' == 2 & inlist(`w'_ivfio,2) & `accendmth' == .
            qui replace `accendmth' = .d if `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & `accendmth' == .
            qui replace `accendmth' = .e if `jb1status' == 2 & inlist(`w'_jsaccs,-1,-2,-3,-4,-9) & `accendmth' == .
            qui replace `accendmth' = .g if `jb1status' == 2 & `w'_jsaccs == 1 & inlist(`w'_jsprey4,-1,-2,-3,-4,-9) & `accendmth' == .
            qui replace `accendmth' = .h if `jb1status' == 2 & `w'_jsaccs == 1 & inlist(`w'_jsprem,-1,-2,-3,-4,-9) & `accendmth' == .

            if (`wave'==6) replace `accendmth' = .i if `w'_jbsemp==2 & `w'_jsaccs==-8  & `accendmth' == . /*88 individuals who are self employed but not routed into the jsaccs for some reason**/
			if (`wave'==14|`wave'==15) replace `accendmth' = .i if `w'_jbsemp==2 & `w'_jsaccs==-8 & `w'_multijobs==-8 & `accendmth' == . /*69 individuals who are self employed but not routed into the jsaccs for some reason**/
			if (`wave'>=13) replace `accendmth'  = .j if `w'_jbsemp==2 & `w'_jsaccs==-8 & inlist(`w'_jbmain,-1,-2) & (`w'_multijobs>1|`w'_multijobs==-8) & `accendmth' == .

            assert (`accendmth' != .)
            label define `accendmth' .a "Not self-employed" .b "jb1status missing" .c "Proxy respondent" .d "Accounts not (yet) prepared" .e "jsaccs invalid" .g "jsprey4 invalid" .h "jsprem invalid" .i "incorrect routing W6/W14/W15" .j "Does not identify main job if working multiple jobs", modify
            label values `accendmth' `accendmth'
        }

    }

end





* Month of earnings
*******************

program define indresp_earndate, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars earndate(name) earnmth(name) earnyear(name) intdate(varname) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        indresp_accstartmth, wave(`wave') whatvars
        local vars "`r(vars)'"
        indresp_accendmth, wave(`wave') whatvars
        local vars "`vars' `r(vars)'"
        return local vars "`w'_jsaccs `w'_ivfio `vars'"
    }
    else {

        if "`earndate'" == "" local earndate "earndate"
        if "`earnmth'" == "" local earnmth "earnmth"
        if "`earnyear'" == "" local earnyear "earnyear"
        if "`intdate'" == "" local intdate "intdate"
        if "`jb1status'" == "" local jb1status "jb1status"

        local accstartmth accstartmth
        local accendmth accendmth
        indresp_accstartmth, wave(`wave') accstartmth(`accstartmth') mindic
        indresp_accendmth, wave(`wave') accendmth(`accendmth') mindic

        qui gen byte `earnmth' = month(`intdate') if (`w'_ivfio == 1 & `jb1status' == 1) | (inlist(`w'_ivfio,2,3,-9) & inlist(`jb1status',1,2))
        qui gen int `earnyear' = year(`intdate') if (`w'_ivfio == 1 & `jb1status' == 1) | (inlist(`w'_ivfio,2,3,-9) & inlist(`jb1status',1,2))

        qui replace `earnmth' = month(dofm(int((`accstartmth'+`accendmth')/2))) if (`accendmth' >= `accstartmth') & `jb1status' == 2 & `w'_jsaccs == 1 & `w'_ivfio != 2
        qui replace `earnyear' = year(dofm(int((`accstartmth'+`accendmth')/2))) if (`accendmth' >= `accstartmth') & `jb1status' == 2 & `w'_jsaccs == 1 & `w'_ivfio != 2
        * Treat people with missing account dates as though they didn't draw up accounts
        qui replace `earnmth' = (month(`intdate') - 6)*(month(`intdate') > 6) + (month(`intdate') + 6)*(month(`intdate') <= 6) if `jb1status' == 2 & (inlist(`w'_jsaccs,2,3) | `w'_jsaccs == 1 & (`accendmth' >= . | `accstartmth' >= . | `accstartmth' > `accendmth')) & `w'_ivfio != 2
        qui replace `earnyear' = year(`intdate') - (month(`intdate') <= 6) if `jb1status' == 2 & (inlist(`w'_jsaccs,2,3) | `w'_jsaccs == 1 & (`accendmth' >= . | `accstartmth' >= . | `accstartmth' > `accendmth')) & `w'_ivfio != 2
        qui gen int `earndate' = ym(`earnyear',`earnmth')
        label variable `earndate' "Date of earnings"
        label variable `earnmth' "Month of earnings"
        label variable `earnyear' "Year of earnings"

        if "`mindic'" == "mindic" {
            qui replace `earndate' = .a if (`jb1status' == 0 | `jb1status' >= .) & `earndate' == .
            qui replace `earndate' = .b if (`jb1status' == 1 | (`jb1status' == 2 & inlist(`w'_jsaccs,-7,2,3)))& `intdate' >= . & `earndate' == .
            qui replace `earndate' = .c if `jb1status' == 2 & inlist(`w'_jsaccs,-1,-2,-3,-4,-8,-9) & `earndate' == .
            qui replace `earndate' = .d if `jb1status' == 2 & `w'_jsaccs == 1 & `accstartmth' >= . & `earndate' == .
            qui replace `earndate' = .e if `jb1status' == 2 & `w'_jsaccs == 1 & `accstartmth' < . & `accendmth' >= . & `earndate' == .
            qui replace `earndate' = .f if `jb1status' == 2 & `w'_jsaccs == 1 & `accstartmth' < . & `accstartmth' > `accendmth' & `earndate' == .
            * Fix for people with missing account dates
            qui replace `earndate' = . if inlist(`earndate',.d,.e,.f)
            qui replace `earndate' = .g if `jb1status' == 2 & (inlist(`w'_jsaccs,2,3) | `w'_jsaccs == 1 & (`accendmth' >= . | `accstartmth' >= . | `accstartmth' > `accendmth')) & `intdate' >= . & `w'_ivfio == 1 & `earndate' == .
            assert (`earndate' != .)
            qui replace `earnmth' = `earndate' if `earnmth' == . & `earndate' > .
            qui replace `earnyear' = `earndate' if `earnyear' == . & `earndate' > .
            assert (`earnmth' != . & `earnyear' != .)
            label define `earndate' .a "No 1st job or missing jb1status" .b "intdate missing" .c "jsaccs invalid" .d "accstartmth missing" .e "accendmth missing" .f "Account start is after account end" .g "intdate missing"
            label values `earndate' `earndate'
            label values `earnmth' `earndate'
            label values `earnyear' `earndate'
        }
        drop `accstartmth' `accendmth'

    }

end



* Gross usual weekly earnings in main job
*****************************************

program define indresp_jb1earn, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars year(numlist integer max=1 >=1987 <=2013) month(numlist integer max=1 >=1 <=12) jb1earn(name) jb1earni(name) jb1status(varname) earnmth(varname) earnyear(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_paygu_dv `w'_paygu_if `w'_jspayu `w'_jsprf `w'_jsaccs `w'_jspayw `w'_ivfio `w'_prearn `w'_prearnw_w`wave'"
    }
    else {

        assert ("`year'" != "")  - ("`month'" != "") == 0
        if "`year'" != "" local real = 1
        else local real = 0

        if "`jb1earn'" == "" local jb1earn "jb1earn"
        if "`jb1earni'" == "" local jb1earni "jb1earni"
        if "`jb1status'" == "" local jb1status "jb1status"
        if "`earnmth'" == "" local earnmth "earnmth"
        if "`earnyear'" == "" local earnyear "earnyear"
*        if "`earndate'" == "" local earndate "earndate"

        *we want everything in weekly income
        qui gen double `jb1earn' = `w'_paygu_dv*(12/52)  if `jb1status' == 1 & (`w'_paygu_dv >= 0 & `w'_paygu_dv < .) & `w'_ivfio != 2
        qui replace `jb1earn' = `w'_jspayu    if `w'_jspayw==1 & `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & (`w'_jspayu >= 0 & `w'_jspayu < .) & `w'_ivfio != 2
        qui replace `jb1earn' = `w'_jspayu*(12/52) if `w'_jspayw==2 & `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & (`w'_jspayu >= 0 & `w'_jspayu < .) & `w'_ivfio != 2
        qui replace `jb1earn' = `w'_jsprf/52  if `jb1status' == 2 & `w'_jsaccs == 1 & (`w'_jsprf >= 0 & `w'_jsprf < .) & `w'_ivfio != 2


        * The values (0, 12.5, 32, etc) are the midpoints of the income bands
        * The top (open-ended) income band is left missing
        qui replace `jb1earn' = 0     if `w'_prearnw == 0   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 12.5  if `w'_prearnw == 1   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 32    if `w'_prearnw == 2   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 49.5  if `w'_prearnw == 3   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 69.5  if `w'_prearnw == 4   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 89.5  if `w'_prearnw == 5   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 112   if `w'_prearnw == 6   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 137   if `w'_prearnw == 7   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 164.5 if `w'_prearnw == 8   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 194.5 if `w'_prearnw == 9   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 234.5 if `w'_prearnw == 10  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 279.5 if `w'_prearnw == 11  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 339.5 if `w'_prearnw == 12  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)
        qui replace `jb1earn' = 429.5 if `w'_prearnw == 13  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & (`wave' == 1 | `wave' == 2)

        qui replace `jb1earn' = 0     if `w'_prearnw == 0   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 49.5  if `w'_prearnw == 1   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 124.5 if `w'_prearnw == 2   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 194.5 if `w'_prearnw == 3   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 279.5 if `w'_prearnw == 4   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 349.5 if `w'_prearnw == 5   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 419.5 if `w'_prearnw == 6   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 509.5 if `w'_prearnw == 7   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 614.5 if `w'_prearnw == 8   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10
        qui replace `jb1earn' = 764.5 if `w'_prearnw == 9   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & `wave' >2 & `wave' < 10

		qui replace `jb1earn' = 0        if `w'_prearnw == 0   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 34.5     if `w'_prearnw == 1   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 99.5     if `w'_prearnw == 2   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 159.5    if `w'_prearnw == 3   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 219.5    if `w'_prearnw == 4   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 279.5    if `w'_prearnw == 5   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 344.5    if `w'_prearnw == 6   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 429.5    if `w'_prearnw == 7   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 539.5    if `w'_prearnw == 8   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 659.5    if `w'_prearnw == 9   & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 789.5    if `w'_prearnw == 10  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 929.5    if `w'_prearnw == 11  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)
		qui replace `jb1earn' = 1249.5   if `w'_prearnw == 12  & `w'_ivfio == 2  & inlist(`jb1status',1,2) & inrange(`wave',10,14)

        if `real' {
            uprate `jb1earn', year(`year') month(`month') yearvar(`earnyear') monthvar(`earnmth') missing
            label variable `jb1earn' "Real usual weekly gross earnings in main job (`r(prices)' prices)"
        }
*        else label variable `jb1earn' "Usual monthly gross earnings in main job"
        else label variable `jb1earn' "Usual weekly gross earnings in main job"

        qui gen byte `jb1earni' = `w'_paygu_if if `jb1status' == 1 & `jb1earn' < . & inlist(`w'_paygu_if,0,1)
        qui replace  `jb1earni' = 0 if  `w'_ivfio == 2 & `jb1earn' < .  & inrange(`w'_prearnw,0,13)
        qui replace  `jb1earni' = 0 if  `w'_ivfio != 2 & `jb1earn' < .  & `jb1status' == 2

        if `wave'==6 replace `jb1earni' = 0 if `jb1earn'<. & `jb1status'==1 & `w'_paygu_if==-9 /*new code -9 introduced for this variable in wave 6. nothing in documentation so assume not imputed**/

		label variable `jb1earni' "Earnings imputation flag"
        assert (`jb1earn' < .) - (`jb1earni' < .) == 0


        if "`mindic'" == "mindic" {

            qui replace `jb1earn' = .a if `jb1status' == 0 & `jb1earn' == .
            qui replace `jb1earn' = .b if `jb1status' >= . & `jb1earn' == .
            qui replace `jb1earn' = .c if `jb1status' == 1 & inlist(`w'_paygu_dv,-1,-2,-3,-4,-9) & `jb1earn' == .
            qui replace `jb1earn' = .d if `jb1status' == 2 & inlist(`w'_jsaccs,-1,-2,-3,-4,-9) & `jb1earn' == .
            qui replace `jb1earn' = .e if `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & inlist(`w'_jspayu,-1,-2,-3,-4,-9) & `jb1earn' == .
            qui replace `jb1earn' = .f if `jb1status' == 2 & inlist(`w'_jsaccs,2,3) & inlist(`w'_jspayw,-1,-2,-3,-4,-9,97) & `jb1earn' == .
            qui replace `jb1earn' = .g if `jb1status' == 2 & `w'_jsaccs == 1 & inlist(`w'_jsprf,-1,-2,-3,-4,-9) & `jb1earn' == .
	    * LO 24/8/21 - Ensure prearn top band is coded correctly for different waves in next three lines
            qui replace `jb1earn' = .h if `w'_ivfio == 2 & inlist(`jb1status',1,2) & `w'_prearnw == 14 & `jb1earn' == . & (`wave' == 1 | `wave' == 2)
            qui replace `jb1earn' = .h if `w'_ivfio == 2 & inlist(`jb1status',1,2) & `w'_prearnw == 10 & `jb1earn' == . & `wave' >2 & `wave' < 10
            qui replace `jb1earn' = .h if `w'_ivfio == 2 & inlist(`jb1status',1,2) & `w'_prearnw == 13 & `jb1earn' == . & inlist(`wave',10,11)
	    *PL 08/08/22 allowed to be invalid if  _prearnw is -8 (inapplicable) despite being employed and a proxy interview 
            qui replace `jb1earn' = .i if `w'_ivfio == 2 & inlist(`jb1status',1,2) & inlist(`w'_prearnw,-1,-2,-3,-4,-8,-9) & `jb1earn' == .
            qui replace `jb1earn' = .j if `w'_ivfio == 2 & inlist(`jb1status',1,2) & inlist(`w'_prearn,2,-1,-2,-3,-4,-9) & `jb1earn' == .

            if `wave'==6 qui replace `jb1earn' = .d if `jb1status' == 2 & inlist(`w'_jsaccs,-8) /*incorrect routing wave 6*/
			
			if `wave'>=13 {      
				qui replace `jb1earn' = .k if `jb1status' == 1 & `w'_paygu_dv==-8 & inlist(`w'_jbmain,-1,-2) & (`w'_multijobs>1|`w'_multijobs==-8) & `jb1earn' == .
				qui replace `jb1earn' = .k if `jb1status' == 2 & `w'_jsaccs==-8 & inlist(`w'_jbmain,-1,-2) & (`w'_multijobs>1|`w'_multijobs==-8) & `jb1earn' == .
			}
			
			if `wave'>=14 {
				qui replace `jb1earn' = .l if `jb1status' == 2 & inlist(`w'_jsaccs,-8) & (`w'_paygu_dv >= 0 & `w'_paygu_dv < .) & `jb1earn' == .  /*reports pay but self-employed*/
				qui replace `jb1earn' = .m if `jb1status' == 1 & (`w'_jspayu>0|inlist(`w'_jspayu,-1,-2)|`w'_jsprf>=0) & (`w'_paygu_dv ==-8)  & `jb1earn' == . /*employees but answers earnings as self-employed*/
				qui replace `jb1earn' = .n if `jb1status' == 2 & inlist(`w'_jsaccs,-8) & inlist(`w'_jspayu,-8) & `jb1earn' == .
				qui replace `jb1earn' = .o if `jb1status' == 1 & `w'_ivfio==1 & `w'_paygu_dv ==-8 & `w'_jsaccs==-8 & `w'_jspayu==-8 & `jb1earn' == . /*routing error (everything inapplicable)*/
			}

            if `real' {
                qui replace `jb1earn' = .p if ((`jb1status' == 1 & `w'_ivfio == 1 & (`w'_paygu_dv >= 0 & `w'_paygu_dv < .)) | (`jb1status' == 2 & ((inlist(`w'_jsaccs,2,3) & (`w'_jspayu >= 0 & `w'_jspayu < .) & inlist(`w'_jspayw,1,2)) | (`w'_jsaccs == 1 & (`w'_jsprf >= 0 & `w'_jsprf < .))))) & rpimissing == 1 & `jb1earn' == .
                qui replace `jb1earn' = .p if (inlist(`jb1status',1,2) & `w'_ivfio == 2 & inrange(`w'_prearnw,0,13)) & rpimissing == 1 & `jb1earn' == .
            }
            assert (`jb1earn' != .)
            qui replace `jb1earni' = `jb1earn' if (`jb1earni' == . & `jb1earn' > .)
            assert (`jb1earni' != .)
            label define `jb1earn' .a "No 1st job" .b "jb1status missing" .c "paygu_dv invalid" .d "jsaccs invalid" .e "jspayu invalid" .f "jspayw invalid or other" .g "jsprf invalid" .h "prearn top band" .i "prearn invalid" .j "prearn an annual amount or missing/invalid"  .k "Main job missing when multiple jobs" .l "Reports pay but self-employed"  .m "employees but answers earnings as self-employed" .n "jspayu inapplicable but s/e" .o "All pay variables inapplicable (but employed)" .p "rpi missing"
            label values `jb1earn' `jb1earn'

        }
        if `real' drop rpimissing

    }

end


* Program to uprate a variable to a given month's prices
program define uprate, rclass

    syntax varlist [if], year(numlist integer max=1 >=1987 <=2011) month(numlist integer max=1 >=1 <=12) [datevar(varname) yearvar(varname) monthvar(varname) missing]
    assert ("`datevar'" != "") + ("`yearvar'" != "" & "`monthvar'" != "") == 1

    preserve
    use "$save\RPIMonthlySeries.dta", clear
    qui su rpi if year == `year' & month == `month'
    if r(N) == 0 {
        di as error "Month not found in rpi data"
        exit
    }
    assert r(N) == 1
    local rpinew = r(min)

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
    qui merge year month using "$save\RPIMonthlySeries.dta", uniqusing nokeep
    if "`datevar'" != "" {
        drop year month
    }
    else {
        rename year `yearvar'
        rename month `monthvar'
    }
    drop _merge

    foreach var of local varlist {
        qui replace `var' = `var'*`rpinew'/rpi `if'
    }
    if "`missing'" == "missing" gen byte rpimissing = (rpi >= .)
    drop rpi

    local mth : word `month' of `c(Mons)'
    local yr = substr("`year'",3,.)

    return local prices "`mth' `yr'"

end




* Gross hourly wage in main job
*******************************

* Uses jb1status, jb1hrsot jb1hrs and jb1ugrearn
* If jb1hrsot is zero or missing, I use jb1hrs. Not strictly consistent, but proxy/phone respondents weren't asked about overtime in many waves

program define indresp_jb1wage, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1wage(name) hrscap(numlist integer max=1 >0) jb1status(varname) jb1hrs(varname) jb1hrsot(varname) jb1earn(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
    }
    else {

        if "`jb1wage'" == "" local jb1wage "jb1wage"
        if "`jb1status'" == "" local jb1status "jb1status"
        if "`jb1hrsot'" == "" local jb1hrsot "jb1hrsot"
        if "`jb1hrs'" == "" local jb1hrs "jb1hrs"
        if "`jb1earn'" == "" local jb1earn "jb1earn"

*        local label = subinstr("`: var lab `jb1earn''","monthly gross earnings","hourly gross wage",1)
        local label = subinstr("`: var lab `jb1earn''","weekly gross earnings","hourly gross wage",1)
        if "`hrscap'" == "" {
*            qui gen double `jb1wage' = `jb1earn'/(`jb1hrsot'*52/12)
*            qui replace `jb1wage' = `jb1earn'/(`jb1hrs'*52/12) if `jb1wage' >= .
            qui gen double `jb1wage' = `jb1earn'/`jb1hrsot'
            qui replace `jb1wage' = `jb1earn'/`jb1hrs' if `jb1wage' >= .
        }
        else {
*            qui gen double `jb1wage' = `jb1earn'/(min(`jb1hrsot',`hrscap')*52/12) if `jb1hrsot' < .
*            qui replace `jb1wage' = `jb1earn'/(min(`jb1hrs',`hrscap')*52/12) if `jb1wage' >= . & `jb1hrs' < .
            qui gen double `jb1wage' = `jb1earn'/min(`jb1hrsot',`hrscap') if `jb1hrsot' < .
            qui replace `jb1wage' = `jb1earn'/min(`jb1hrs',`hrscap') if `jb1wage' >= . & `jb1hrs' < .
            if regexm("`label'","prices\)") local label = regexr("`label'","prices\)","prices, hrs capped at `hrscap')")
            else local label "`label' (hrs capped at `hrscap')"
        }
        label variable `jb1wage' "`label'"

        if "`mindic'" == "mindic" {
            qui replace `jb1wage' = .a if !inlist(`jb1status',1,2) & `jb1wage' == .
            qui replace `jb1wage' = .b if inlist(`jb1status',1,2) & `jb1earn' >= . & `jb1wage' == .
            * I changed the next two lines to accommodate jb1hrs alteration
            qui replace `jb1wage' = .c if inlist(`jb1status',1,2) & `jb1earn' < . & `jb1hrsot' >= . & (`jb1hrs' == 0 | `jb1hrs' >= .) & `jb1wage' == .
            qui replace `jb1wage' = .d if inlist(`jb1status',1,2) & `jb1earn' < . & `jb1hrsot' == 0 & (`jb1hrs' == 0 | `jb1hrs' >= .) & `jb1wage' == .
            assert (`jb1wage' != .)
            label define `jb1wage' .a "No 1st job, or missing jb1status" .b "jb1earn missing" .c "jb1hrsot missing" .d "jb1hrsot = 0"
            label values `jb1wage' `jb1wage'
        }

    }

end


* Childcare use
***************

/*There are no analagous variables to those used here (and in the following) in US wave 1*/

/*
program define indresp_jb1ccare, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1ccare(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'rach12 `w'jbchc1 `w'jbchc2 `w'jbchc3 `w'ivfio"
    }
    else {

        if "`jb1ccare'" == "" local jb1ccare "jb1ccare"
        if "`jb1status'" == "" local jb1status "jb1status"

        qui gen byte `jb1ccare' = 0 if `w'rach12 == 1 & inlist(`w'jbchc1,1,2,3,4) & inlist(`w'jbchc2,0,1,2,3,4) & inlist(`w'jbchc3,0,1,2,3,4)
        qui replace `jb1ccare' = 1 if `w'rach12 == 1 & (inrange(`w'jbchc1,5,12) | inrange(`w'jbchc2,5,12) | inrange(`w'jbchc3,5,12))
        label variable `jb1ccare' "Uses childcare"

        if "`mindic'" == "mindic" {
            qui replace `jb1ccare' = .a if `jb1status' == 0 & `jb1ccare' == .
            qui replace `jb1ccare' = .b if `jb1status' >= . & `jb1ccare' == .
            if `wave' <= 14 {
                qui replace `jb1ccare' = .c if inlist(`jb1status',1,2) & `w'ivfio == 3 & `jb1ccare' == .
                qui replace `jb1ccare' = .d if inlist(`jb1status',1,2) & inlist(`w'ivfio,1,2) & `w'rach12 == 2 & `jb1ccare' == .
                qui replace `jb1ccare' = .e if inlist(`jb1status',1,2) & inlist(`w'ivfio,1,2) & inlist(`w'rach12,-1,-2,-3,-4,-9) & `jb1ccare' == .
                qui replace `jb1ccare' = .f if inlist(`jb1status',1,2) & inlist(`w'ivfio,1,2) & `w'rach12 == 1 & ((inlist(`w'jbchc1,-1,-2,-3,-4,-8,-9) | inlist(`w'jbchc2,-1,-2,-3,-4,-8,-9) | inlist(`w'jbchc3,-1,-2,-3,-4,-8,-9)) & !(inrange(`w'jbchc1,5,12) | inrange(`w'jbchc2,5,12) | inrange(`w'jbchc3,5,12))) & `jb1ccare' == .
            }
            else {
                qui replace `jb1ccare' = .d if inlist(`jb1status',1,2) & `w'rach12 == 2 & `jb1ccare' == .
                qui replace `jb1ccare' = .e if inlist(`jb1status',1,2) & inlist(`w'rach12,-1,-2,-3,-4,-9) & `jb1ccare' == .
                qui replace `jb1ccare' = .f if inlist(`jb1status',1,2) & `w'rach12 == 1 & ((inlist(`w'jbchc1,-1,-2,-3,-4,-8,-9) | inlist(`w'jbchc2,-1,-2,-3,-4,-8,-9) | inlist(`w'jbchc3,-1,-2,-3,-4,-8,-9)) & !(inrange(`w'jbchc1,5,12) | inrange(`w'jbchc2,5,12) | inrange(`w'jbchc3,5,12))) & `jb1ccare' == .
            }
            assert (`jb1ccare' != .)
            label define `jb1ccare' .a "No 1st job" .b "Missing jb1status" .c "Phone interview (wave <=14)" .d "No kid <= 12" .e "rach12 invalid" .f "jbchc1/jbchc2/jbchc3 invalid"
            label values `jb1ccare' `jb1ccare'
        }

    }

end




* Childcare expenditure
***********************

program define indresp_jb1ccarecost, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars jb1ccarecost(name) year(numlist integer max=1 >=1987 <=2006) month(numlist integer max=1 >=1 <=12) jb1ccare(varname) jb1status(varname) intdate(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'rach12 `w'xpchcf `w'xpchc `w'ivfio"
    }
    else {

        assert ("`year'" != "")  - ("`month'" != "") == 0
        if "`year'" != "" local real = 1
        else local real = 0
        if "`jb1ccarecost'" == "" local jb1ccarecost "jb1ccarecost"
        if "`jb1ccare'" == "" local jb1ccare "jb1ccare"
        if "`jb1status'" == "" local jb1status "jb1status"
        if "`intdate'" == "" local intdate "intdate"

/*
        if `real' {
            preserve
            use "$save\RPIMonthlySeries.dta", clear
            qui su rpi if year == `year' & month == `month'
            if r(N) == 0 {
                di as error "Month not found in rpi data"
                exit
            }
            assert r(N) == 1
            local rpinew = r(min)
            restore

            qui gen int year = year(`intdate')
            qui gen byte month = month(`intdate')
            sort year month
            qui merge year month using "$save\RPIMonthlySeries.dta", uniqusing nokeep
            drop year month _merge
        }
*/

        qui gen double `jb1ccarecost' = 0 if `w'xpchcf == 1 & `w'ivfio == 1
        qui replace `jb1ccarecost' = `w'xpchc if `w'xpchcf == 2 & (`w'xpchc >= 0 & `w'xpchc < .) & `w'ivfio == 1

/*
        if `real' {
            qui replace `jb1ccarecost' = `jb1ccarecost'*`rpinew'/rpi if `jb1ccarecost' > 0
            local mth : word `month' of `c(Mons)'
            local yr = substr("`year'",3,.)
            label variable `jb1ccarecost' "Average real weekly childcare cost (`mth' `yr' prices)"
            drop rpi
        }
        else label variable `jb1ccarecost' "Average weekly childcare cost"
*/
        if `real' {
            uprate `jb1ccarecost', year(`year') month(`month') datevar(`intdate') missing
            label variable `jb1ccarecost' "Average real weekly childcare cost (`r(prices)' prices)"
        }
        else label variable `jb1ccarecost' "Average weekly childcare cost"


        if "`mindic'" == "mindic" {
            qui replace `jb1ccarecost' = .a if `jb1status' == 0 & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .b if `jb1status' >= . & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .c if inlist(`jb1status',1,2) & inlist(`w'ivfio,2,3) & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .d if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 2 & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .e if inlist(`jb1status',1,2) & `w'ivfio == 1 & inlist(`w'rach12,-1,-2,-3,-4,-9) & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .f if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 1 & `jb1ccare' == 0 & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .g if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 1 & `jb1ccare' >= . & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .h if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 1 & `jb1ccare' == 1 & inlist(`w'xpchcf,-1,-2,-3,-4,-8,-9) & `jb1ccarecost' == .
            qui replace `jb1ccarecost' = .i if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 1 & `jb1ccare' == 1 & `w'xpchcf == 2 & inlist(`w'xpchc,-1,-2,-3,-4,-9) & `jb1ccarecost' == .
            if `real' qui replace `jb1ccarecost' = .j if inlist(`jb1status',1,2) & `w'ivfio == 1 & `w'rach12 == 1 & `jb1ccare' == 1 & `w'xpchcf == 2 & (`w'xpchc >= 0 & `w'xpchc < .) & rpimissing == 1 &`jb1ccarecost' == .
            assert (`jb1ccarecost' != .)
            label define `jb1ccarecost' .a "No 1st job" .b "jb1status missing" .c "Proxy/phone interview" .d "No kid <= 12" .e "rach12 invalid" .f "No childcare used" .g "jb1ccare missing" .h "xpchcf invalid" .i "xpchc invalid" .j "intdate missing"
            label values `jb1ccarecost' `jb1ccarecost'
        }
        if `real' drop rpimissing

    }

end
*/




* Information about a subset of non-labour income
*************************************************

program define indresp_nonlabinc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars codes(numlist int >=1 sort) nonlabinc(name) intdate(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio"
    }
    else {

        if "`nonlabinc'" == "" local nonlabinc "nonlabinc"
        if "`intdate'" == "" local intdate "intdate"

        assert ("`year'" != "")  - ("`month'" != "") == 0
        if "`year'" != "" local real = 1
        else local real = 0

        preserve
        keep `w'_hidp `w'_pno `intdate'
        *first merge in buno from indall
        qui merge 1:1 `w'_hidp `w'_pno using "$data\\`w'_indall.dta", keepusing(`w'_buno_dv)
        assert _merge != 1
        keep if _merge==3
        drop _merge
        sort `w'_hidp `w'_pno
        tempfile temp
        qui save `temp'

        use "$data\\`w'_income.dta"
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', uniqusing nokeep


        * Sort out joint receipt flag
        *****************************

        * The result is not perfect. In particular, for a given quality of match, the closeness of the match is not used to decide which of multiple matches to hang onto
        * Not really worth sorting out - too few cases affected

        bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): gen byte buobs = _N
        su buobs, meanonly
        local loops = r(max)
        drop buobs

        gen byte matchtype = 0

        * Exact matches
        gen byte match = 0
        forval i = 1/`loops' {
            * Set variable "match" to 1 for all observations that match observation `i' (i.e. joint receipt, same income type, correct pno reference)
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & `w'_ficode == `w'_ficode[`i'] & ((abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])) < 0.01 & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) | (`w'_frval == `w'_frval[`i'] & `w'_frwc == `w'_frwc[`i'] & `w'_frval < 0 & `w'_frwc <= 0)) & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 1 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Close match, pno consistent (amounts within £5)
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,2) & `w'_ficode == `w'_ficode[`i'] & (inrange(abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frw[`i'])),0.01,4.999) & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hid `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 2 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Not so close match, pno consistent
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,3) & `w'_ficode == `w'_ficode[`i'] & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 3 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * pno inconsistent, otherwise perfect
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,4) & `w'_ficode == `w'_ficode[`i'] & ((abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])) < 0.01 & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) | (`w'_frval == `w'_frval[`i'] & `w'_frwc == `w'_frwc[`i'] & `w'_frval < 0 & `w'_frwc <= 0)) & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 4 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Close match, pno inconsistent (amounts within £5)
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,5) & `w'_ficode == `w'_ficode[`i'] & (inrange(abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])),0.01,4.999) & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 5 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Not so close match, pno inconsistent
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,6) & `w'_ficode == `w'_ficode[`i'] & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 6 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * I think all remaining cases marked as joint must be without a match
        qui replace matchtype = 7 if `w'_frjt == 2 & matchtype == 0

        label define matchtype 0 "Sole" 1 "Exact match" 2 "Match w/in £5, incl pno" 3 "Other match incl pno" 4 "Exact except pno" 5 "Match w/in £5, not pno" 6 "Other match, not pno" 7 "Joint but no match"
        label values matchtype matchtype

        gen byte divisor = inlist(matchtype,1,2,3,4,5,6) + 1


        * deal with joint recipients
*        qui gen double `nonlabinc' = `w'frval*(4.33/`w'frw)/cond(`w'frjt == 1,1,2) if (`w'frval >= 0 & `w'frval < .) & (`w'frw > 0 & `w'frw < .) & inlist(`w'frjt,1,2)
        qui gen double `nonlabinc' = `w'_frval/(`w'_frwc*divisor) if (`w'_frval >= 0 & `w'_frval < .) & (`w'_frwc > 0 & `w'_frwc < .)
        qui replace `nonlabinc' = 0 if (`w'_frval == 0)
        drop matchtype divisor

        * wfrval = -3 means "income included elsewhere"
        qui replace `nonlabinc' = 0 if (`w'_frval == -3)
        * wfrw = -4 means one-off payment
        qui replace `nonlabinc' = `w'_frval if (`w'_frwc == -4) & (`w'_frval >= 0 & `w'_frval < .)

        * get rid of income-related non-labour income
        if "`codes'" != "" {
            foreach num of local codes {
                local ficodes "`ficodes',`num'"
            }
            qui replace `nonlabinc' = 0 if !inlist(`w'_ficode`ficodes')
        }
        else {
            *
            qui replace `nonlabinc' = 0 if !(inrange(`w'_ficode,1,6) | `w'_ficode==18 | inrange(`w'_ficode,26,30))
        }

        qui replace `nonlabinc' = .d if `w'_frval < 0 & `nonlabinc' >= . & `nonlabinc' == .
        qui replace `nonlabinc' = .e if `w'_frwc < 0 & `w'_frval > 0 & `nonlabinc' >= . & `nonlabinc' == .
        assert (`nonlabinc' != .)
        label define `nonlabinc' .d "frval invalid" .e "frwc invalid"
        label values `nonlabinc' `nonlabinc'

        * copy minimum missing value across all observations for an individual
        qui egen byte `nonlabinc'_m = min(`nonlabinc') if `nonlabinc' >= ., by(`w'_hidp `w'_pno)
        qui bys `w'_hidp `w'_pno (`nonlabinc'_m): replace `nonlabinc' = `nonlabinc'_m[_N] if `nonlabinc'_m[_N] > .
        drop `nonlabinc'_m

        * sum non-labour income
        qui egen double tot`nonlabinc' = total(`nonlabinc'), by(`w'_hidp `w'_pno)
        qui replace `nonlabinc' = tot`nonlabinc' if `nonlabinc' < .
        drop tot`nonlabinc'
        assert (`nonlabinc' != .)

        if "`mindic'" == "" {
            qui replace `nonlabinc' = . if `nonlabinc' > .
        }


        * merge back into indresp dataset
        keep `w'_hidp `w'_pno `nonlabinc'
        qui bys `w'_hidp `w'_pno: keep if _n == 1
        sort `w'_hidp `w'_pno
        qui save `temp', replace
        restore
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', unique
        if (`wave'==1) drop if _merge==2
        if (`wave'>1) assert _merge != 2

        * Uprate if required
        if `real' {
            rename _merge _mergeold
            uprate `nonlabinc', year(`year') month(`month') datevar(`intdate')
            label variable `nonlabinc' "Weekly non-labour-related income (`r(prices)' prices)"
            if "`mindic'" == "mindic" {
                qui replace `nonlabinc' = .f if _merge == 3 & `nonlabinc' == .
                label define `nonlabinc' .f "rpi missing", add
            }
            rename _mergeold _merge
        }
        else label variable `nonlabinc' "Weekly non-labour-related income"

        if "`mindic'" == "mindic" {

            if (`wave'==1) {
                qui replace `nonlabinc' = .a if (`w'_ivfio == 2) & `nonlabinc' == .
                qui replace `nonlabinc' = .b if (`w'_ivfio == 1) & _merge == 1 & `nonlabinc' == .
            }

            if (`wave'>1) {
                qui replace `nonlabinc' = .a if (`w'_ivfio == 2) & `nonlabinc' == .
                qui replace `nonlabinc' = .b if inlist(`w'_ivfio,1,3,-9) & _merge == 1 & `nonlabinc' == .
            }

            label define `nonlabinc' .a "Proxy respondent" .b "income data lost", add
            assert (`nonlabinc' != .)
        }
        drop _merge
*        if `real' drop rpi


    }

end






* Information about maintenance payments
****************************************

* This is just a wrapper (it defines the right codes for maintenance payments then calls indresp_nonlabinc)
program define indresp_maintinc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars maintinc(name) *]


    if "`whatvars'" == "whatvars" {
        indresp_nonlabinc, wave(`wave') whatvars
        return local vars "`r(vars)'"
    }
    else {
        indresp_nonlabinc, wave(`wave') codes(26) nonlabinc(`maintinc') `options'
        label variable `maintinc' "Maintenance income"
    }

end





* Amount of key benefits received
*********************************

*Note all questions in US are about current receipt (while in BHPS its since last september - thus we do not need to check for current receipt here.

program define indresp_benefits, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars year(numlist integer max=1 >=1987 <=2012) month(numlist integer max=1 >=1 <=12) cb(name) iwb(name) is(name) ctbccb(name) jsa(name) hb(name) ctc(name) intdate(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio"
    }
    else {

        if "`intdate'" == "" local intdate "intdate"


        * Not all the benefits exist in all waves
        local isif     "`w'_ficode == 15"
        local cbif     "`w'_ficode == 18"
        local iwbif    "`w'_ficode == 20"
        local hbif     "`w'_ficode == 22"
        local ctbccbif "`w'_ficode == 23"
        local jsaif    "`w'_ficode == 16"
        local ctcif    "`w'_ficode == 19"

        * Check that at least one benefit is specified
        local someben = 0
        foreach ben in cb iwb is ctbccb jsa hb ctc {
            if ("``ben''" != "" & "``ben'if'" != "") {
                local someben = 1
                local bens "`bens' `ben'"
                local bennames "`bennames' ``ben''"
            }
        }
        if !`someben' {
            di as error "No benefits specified"
            exit 198
        }

        assert ("`year'" != "")  - ("`month'" != "") == 0
        if "`year'" != "" local real = 1
        else local real = 0


        * Open income data
        ******************

        preserve
        keep `w'_hidp `w'_pno `intdate'
        *first merge in buno from indall
        qui merge 1:1 `w'_hidp `w'_pno using "$data\\`w'_indall.dta", keepusing(`w'_buno_dv)
        assert _merge != 1
        keep if _merge==3
        drop _merge
        sort `w'_hid `w'_pno
        tempfile temp
        qui save `temp'

        use "$data\\`w'_income.dta"
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', uniqusing nokeep
        if (`wave'==1) drop if _merge==1
        if (`wave'>1) assert _merge != 1
        drop _merge

        *there are no incelse cases, unlike in BHPS

        * Sort out joint receipt flag
        *****************************

        * The result is not perfect. In particular, for a given quality of match, the closeness of the match is not used to decide which of multiple matches to hang onto
        * Not really worth sorting out - too few cases affected

        bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): gen byte buobs = _N
        su buobs, meanonly
        local loops = r(max)
        drop buobs

        gen byte matchtype = 0

        * Exact matches
        gen byte match = 0
        forval i = 1/`loops' {
            * Set variable "match" to 1 for all observations that match observation `i' (i.e. joint receipt, same income type, correct pno reference)
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & `w'_ficode == `w'_ficode[`i'] & ((abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])) < 0.01 & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frw[`i'] > 0) | (`w'_frval == `w'_frval[`i'] & `w'_frwc == `w'_frwc[`i'] & `w'_frval < 0 & `w'_frwc <= 0)) & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 1 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Close match, pno consistent (amounts within £5)
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,2) & `w'_ficode == `w'_ficode[`i'] & (inrange(abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])),0.01,4.999) & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 2 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Not so close match, pno consistent
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,3) & `w'_ficode == `w'_ficode[`i'] & `w'_pno == `w'_frjtpn[`i'] & `w'_frjtpn == `w'_pno[`i'] & (_n != `i') & (`i' <= _N)
            by `w'_hid `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 3 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * pno inconsistent, otherwise perfect
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,4) & `w'_ficode == `w'_ficode[`i'] & ((abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])) < 0.01 & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) | (`w'_frval == `w'_frval[`i'] & `w'_frwc == `w'_frwc[`i'] & `w'_frval < 0 & `w'_frwc <= 0)) & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 4 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Close match, pno inconsistent (amounts within £5)
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,5) & `w'_ficode == `w'_ficode[`i'] & (inrange(abs((`w'_frval/`w'_frwc) - (`w'_frval[`i']/`w'_frwc[`i'])),0.01,4.999) & `w'_frval >= 0 & `w'_frwc > 0 & `w'_frval[`i'] >= 0 & `w'_frwc[`i'] > 0) & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 5 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * Not so close match, pno inconsistent
        forval i = 1/`loops' {
            qui bys `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 1 if matchtype == 0 & inlist(matchtype[`i'],0,6) & `w'_ficode == `w'_ficode[`i'] & `w'_pno != `w'_pno[`i'] & (`w'_frjt == 2 | `w'_frjt[`i'] == 2) & (_n != `i') & (`i' <= _N)
            by `w'_hidp `w'_buno_dv `w'_pno (`w'_fiseq): gen byte sumatch = sum(match)
            qui by `w'_hidp `w'_buno_dv (`w'_pno `w'_fiseq): replace match = 0 if match == 1 & sumatch >= 2 & `w'_pno != `w'_pno[`i'] & (`i' <= _N)
            qui assert matchtype == 0 if match == 1
            qui replace matchtype = 6 if match == 1
            qui replace match = 0
            drop sumatch
        }

        * I think all remaining cases marked as joint must be without a match
        qui replace matchtype = 7 if `w'_frjt == 2 & matchtype == 0

        label define matchtype 0 "Sole" 1 "Exact match" 2 "Match w/in £5, incl pno" 3 "Other match incl pno" 4 "Exact except pno" 5 "Match w/in £5, not pno" 6 "Other match, not pno" 7 "Joint but no match"
        label values matchtype matchtype

        gen byte divisor = inlist(matchtype,1,2,3,4,5,6) + 1


        * Deal with joint recipients
*        qui gen double benefits = `w'frval*(4.33/`w'frw)/cond(`w'frjt == 1,1,2) if (`w'frval >= 0 & `w'frval < .) & (`w'frw > 0 & `w'frw < .) & inlist(`w'frjt,1,2)
        qui gen double benefits = `w'_frval/(`w'_frwc*divisor) if (`w'_frval >= 0 & `w'_frval < .) & (`w'_frwc > 0 & `w'_frwc < .)
        qui replace benefits = 0 if (`w'_frval == 0)

        drop matchtype divisor

        * Uprate if required
        if `real' {
            uprate benefits, year(`year') month(`month') datevar(`intdate') missing
            local prices "`r(prices)'"
            label variable benefits "Real weekly benefit income (indiv, `prices' prices)"
        }
        else label variable benefits "Weekly benefit income (indiv)"

        * Now create sums of each of the benefits
        foreach ben of local bens {
            egen double ``ben'' = total(benefits*(``ben'if')), by(`w'_hidp `w'_pno)
            * Label variables
            if `real' label variable ``ben'' "Real weekly ``ben'' income (indiv, `prices' prices)"
            else label variable ``ben'' "Weekly ``ben'' income (indiv)"
        }

        qui replace benefits = .d if `w'_frval < 0 & benefits == .
        qui replace benefits = .e if `w'_frwc < 0 & `w'_frval > 0 & benefits == .
        if `real' {
            qui replace benefits = .f if rpimissing == 1 & `w'_frwc > 0 & `w'_frval >= 0 & benefits == .
            drop rpimissing
        }
        assert (benefits != .)
        label define benefits .d "frval invalid" .e "frwc invalid" .f "rpi missing"
        label values benefits benefits

        * Copy minimum missing value across observations for given benefit
        foreach ben of local bens {
            qui egen byte ``ben''_m = min(benefits) if ``ben'if' & benefits >= ., by(`w'_hidp `w'_pno)
            qui bys `w'_hidp `w'_pno (``ben''_m): replace ``ben'' = ``ben''_m[_N] if ``ben''_m[_N] > . & ``ben'if'
            drop ``ben''_m
            assert (``ben'' != .)
            label values ``ben'' benefits
        }

        if "`mindic'" == "" {
            foreach ben of local bens {
                qui replace ``ben'' = . if ``ben'' > .
            }
        }

        * merge back into indresp dataset
        keep `w'_hidp `w'_pno `bennames'
        qui bys `w'_hidp `w'_pno: keep if _n == 1
        sort `w'_hidp `w'_pno
        qui save `temp', replace
        restore
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', unique
        *one of these in wave 1, drop them
        if (`wave'==1) drop if _merge==2
        if (`wave'>1) assert _merge != 2

        if "`mindic'" == "mindic" label define benefits .a "Proxy/phone respondent" .b "income data lost", add

        foreach ben of local bens {
            if "`mindic'" == "mindic" {
                if (`wave'==1) {
                    qui replace ``ben'' = .a if (`w'_ivfio == 2) & ``ben'' == .
                    qui replace ``ben'' = .b if (`w'_ivfio == 1) & _merge == 1 & ``ben'' == .
                }

                if (`wave'>=2) {
                    qui replace ``ben'' = .a if (`w'_ivfio == 2) & ``ben'' == .
                    qui replace ``ben'' = .b if inlist(`w'_ivfio,1,3,-9) & _merge == 1 & ``ben'' == .
                }

                assert (``ben'' != .)
            }

        }
        drop _merge

    }

end

* Banded information about interest and dividend income
*******************************************************

program define indresp_invinc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars invinc(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
    return local vars "`w'_fiyrdia `w'_fiyrdb1 `w'_fiyrdb2 `w'_fiyrdb6 `w'_ivfio"
    }
    else {

        if "`invinc'" == "" local invinc "invinc"

        * £0
        qui gen byte `invinc'0 = 1 if `w'_fiyrdia == 0
        * £1-£100 (b1=2, b6=2)
        qui gen byte `invinc'1to100 = 1 if inrange(`w'_fiyrdia,1,99)
        qui replace `invinc'1to100 = 1 if (`w'_fiyrdb1 == 2 & `w'_fiyrdb6 == 2)
        * £100-£1000 ((b1=2, b6=1) OR (b1=1, b2=2))
        qui gen byte `invinc'100to1k = 1 if inrange(`w'_fiyrdia,100,999)
        qui replace `invinc'100to1k = 1 if ((`w'_fiyrdb1 == 2 & `w'_fiyrdb6 == 1) | (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 2))
        * £1k+ (b1=1, b2=1)
        qui gen byte `invinc'1kplus = 1 if (`w'_fiyrdia >= 1000 & `w'_fiyrdia < .)
        qui replace `invinc'1kplus = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1)

        egen byte numnonmiss = anycount(`invinc'0 `invinc'1to100 `invinc'100to1k `invinc'1kplus), values(1)
        assert numnonmiss <= 1
        foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to1k `invinc'1kplus {
            qui replace `var' = 0 if `var' >= . & numnonmiss
        }
        drop numnonmiss

        label variable `invinc'0 "£0 annual investment/savings income"
        label variable `invinc'1to100 "£1-£100 annual investment/savings income"
        label variable `invinc'100to1k "£100-£1k annual investment/savings income"
        label variable `invinc'1kplus "£1k+ annual investment/savings income"

        if "`mindic'" == "mindic" {
            foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to1k `invinc'1kplus {
                qui replace `var' = .a if inlist(`w'_ivfio,2) & `var' == .
                qui replace `var' = .b if inlist(`w'_ivfio,1,3,-9) & inlist(`w'_fiyrdia,-2,-9) & `var' == .
                qui replace `var' = .c if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & inlist(`w'_fiyrdb1,-1,-2,-9) & `var' == .
                qui replace `var' = .d if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 2 & inlist(`w'_fiyrdb6,-1,-2,-9) & `var' == .
                qui replace `var' = .e if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 1 & inlist(`w'_fiyrdb2,-1,-2,-9) & `var' == .
                assert (`var' != .)
            }
            label define `invinc' .a "Proxy response" .b "fiyrdia invalid" .c "fiyrdb1 invalid" .d "fiyrdb6 invalid" .e "fiyrdb2 invalid"
            foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to1k `invinc'1kplus {
                label values `var' `invinc'
            }
        }

    }

end



* This above was written to replace this because in the bhps this version works perfectly on waves 3+, but in waves 1 and 2 the banding is less fine. In US might as well always use the "old" version
program define indresp_invinc_old, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars invinc(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
          else return local vars "`w'fiyrdia `w'fiyrdb1 `w'fiyrdb2 `w'fiyrdb6 `w'ivfio"
    }
    else {

        if "`invinc'" == "" local invinc "invinc"

        * £0
        qui gen byte `invinc'0 = 1 if `w'_fiyrdia == 0
        * £1-£100 (b1=2, b6=2)
        qui gen byte `invinc'1to100 = 1 if inrange(`w'_fiyrdia,1,99)
        qui replace `invinc'1to100 = 1 if (`w'_fiyrdb1 == 2 & `w'_fiyrdb6 == 2)
        * £100-£500 (b1=2, b6=1)
        qui gen byte `invinc'100to500 = 1 if inrange(`w'_fiyrdia,100,499)
        qui replace `invinc'100to500 = 1 if (`w'_fiyrdb1 == 2 & `w'_fiyrdb6 == 1)
        * £500-£1k (b1=1, b2=2)
        qui gen byte `invinc'500to1k = 1 if inrange(`w'_fiyrdia,500,999)
        qui replace `invinc'500to1k = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 2)
        * £1k-£2.5k (b1=1, b2=1, b3=2, b4=2)
        qui gen byte `invinc'1kto2p5k = 1 if inrange(`w'_fiyrdia,1000,2499)
        qui replace `invinc'1kto2p5k = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 2 & `w'_fiyrdb4 == 2)
        * £2.5k-£5k (b1=1, b2=1, b3=2, b4=1)
        qui gen byte `invinc'2p5kto5k = 1 if inrange(`w'_fiyrdia,2500,4999)
        qui replace `invinc'2p5kto5k = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 2 & `w'_fiyrdb4 == 1)
        * £5k-£10k (b1=1, b2=1, b3=1, b5=2)
        qui gen byte `invinc'5kto10k = 1 if inrange(`w'_fiyrdia,5000,9999)
        qui replace `invinc'5kto10k = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 1 & `w'_fiyrdb5 == 2)
        * £10k+ (b1=1, b2=1, b3=1, b5=1)
        qui gen byte `invinc'10kplus = 1 if (`w'_fiyrdia >= 10000 & `w'_fiyrdia < .)
        qui replace `invinc'10kplus = 1 if (`w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 1 & `w'_fiyrdb5 == 1)
        egen byte numnonmiss = anycount(`invinc'0 `invinc'1to100 `invinc'100to500 `invinc'500to1k `invinc'1kto2p5k `invinc'2p5kto5k `invinc'5kto10k `invinc'10kplus), values(1)
        assert numnonmiss <= 1
        foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to500 `invinc'500to1k `invinc'1kto2p5k `invinc'2p5kto5k `invinc'5kto10k `invinc'10kplus {
            qui replace `var' = 0 if `var' >= . & numnonmiss
        }

        label variable `invinc'0 "£0 annual interest/savings income"
        label variable `invinc'1to100 "£1-£100 annual interest/savings income"
        label variable `invinc'100to500 "£100-£500 annual interest/savings income"
        label variable `invinc'500to1k "£500-£1k annual interest/savings income"
        label variable `invinc'1kto2p5k "£1k-£2.5k annual interest/savings income"
        label variable `invinc'2p5kto5k "£2.5k-£5k annual interest/savings income"
        label variable `invinc'5kto10k "£5-£10k annual interest/savings income"
        label variable `invinc'10kplus "£10k+ annual interest/savings income"

        if "`mindic'" == "mindic" {
            foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to500 `invinc'500to1k `invinc'1kto2p5k `invinc'2p5kto5k `invinc'5kto10k `invinc'10kplus {
                qui replace `var' = .a if inlist(`w'_ivfio,2) & `var' == .
                qui replace `var' = .b if inlist(`w'_ivfio,1,3,-9) & inlist(`w'_fiyrdia,-2,-9) & `var' == .
                qui replace `var' = .c if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & inlist(`w'_fiyrdb1,-1,-2,-9) & `var' == .
                qui replace `var' = .d if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 2 & inlist(`w'_fiyrdb6,-1,-2,-9) & `var' == .
                qui replace `var' = .e if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 1 & inlist(`w'_fiyrdb2,-1,-2,-9) & `var' == .
                qui replace `var' = .f if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & inlist(`w'_fiyrdb3,-1,-2,-9) & `var' == .
                qui replace `var' = .g if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 2 & inlist(`w'_fiyrdb4,-1,-2,-9) & `var' == .
                qui replace `var' = .h if inlist(`w'_ivfio,1,3,-9) & `w'_fiyrdia == -1 & `w'_fiyrdb1 == 1 & `w'_fiyrdb2 == 1 & `w'_fiyrdb3 == 1 & inlist(`w'_fiyrdb5,-1,-2,-9) & `var' == .
                assert (`var' != .)
            }
            label define `invinc' .a "Proxy response" .b "fiyrdia invalid" .c "fiyrdb1 invalid" .d "fiyrdb6 invalid" .e "fiyrdb2 invalid" .f "fiyrdb3 invalid" .g "fiyrdb4 invalid " .h "fiyrdb5 invalid"
            foreach var of varlist `invinc'0 `invinc'1to100 `invinc'100to500 `invinc'500to1k `invinc'1kto2p5k `invinc'2p5kto5k `invinc'5kto10k `invinc'10kplus {
                label values `var' `invinc'
            }

        }

    }

end



* Receipt of disability benefit(s)
**********************************

program define indresp_disben, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars disben(name) intdate(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ivfio"
    }
    else {

        if "`disben'" == "" local disben "disben"
        if "`intdate'" == "" local intdate "intdate"

        preserve
        keep `w'_hidp `w'_pno  `intdate'
        sort `w'_hidp `w'_pno
        tempfile temp
        qui save `temp'

        use "$data\\`w'_income.dta"
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', uniqusing nokeep

        *severe disablement allowance/DLA
        qui gen byte `disben' = inrange(`w'_ficode,8,10)
        assert (`disben' < .)

        * get maximum disab
        qui egen byte max`disben' = max(`disben'), by(`w'_hidp `w'_pno)
        qui replace `disben' = max`disben'
        assert (`disben' < .)

        * merge back into indresp dataset
        keep `w'_hidp `w'_pno `disben'
        qui bys `w'_hidp `w'_pno: keep if _n == 1
        sort `w'_hidp `w'_pno
        qui save `temp', replace
        restore
        sort `w'_hidp `w'_pno
        qui merge `w'_hidp `w'_pno using `temp', unique
        *one observation in wave 1 in income but not indresp, drop them
        if (`wave'==1) drop if _merge==2
        if (`wave'>1) assert _merge != 2

        if "`mindic'" == "mindic" {
            if (`wave'==1) {
                qui replace `disben' = .a if (`w'_ivfio == 2) & `disben' == .
                qui replace `disben' = .b if (`w'_ivfio == 1) & _merge == 1 & `disben' == .
            }

            if (`wave'>1) {
                qui replace `disben' = .a if (`w'_ivfio == 2) & `disben' == .
                qui replace `disben' = .b if inlist(`w'_ivfio,1,3,-9) & _merge == 1 & `disben' == .
            }

            assert (`disben' != .)
            label define `disben' .a "Proxy respondent" .b "income data lost"
            label values `disben' `disben'
        }
        drop _merge

        label variable `disben' "Recieves a disability beneift"

    }

end




*NOT YET IN UNDERSTANDING SOCIETY
* wINDRESP savings information (only available in waves 5, 10 and 15)
*********************************************************************
/*
program define indresp_savings, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars savings(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' == 5) return local vars "`w'save `w'saved `w'savek `w'savekb1 `w'savekb2 `w'savekb3 `w'savekb4 `w'savej `w'bank `w'bankk `w'bankkb1 `w'bankkb2 `w'bankkb3 `w'bankkb4 `w'bankj `w'ivfio"
        else if (`wave' == 10) return local vars "`w'save `w'saved `w'nvestnn `w'nvesth `w'nvesti `w'nvestj `w'svack `w'svackb1 `w'svackb2 `w'svackb3 `w'svackb4 `w'svacsj `w'svacsk `w'svacsp `w'ivfio"
        else if (`wave' == 15) return local vars "`w'save `w'saved `w'nvestnn `w'nvesth `w'nvesti `w'nvestj `w'svack `w'svackb1 `w'svackb2 `w'svackb3 `w'svackb4 `w'svackb5 `w'svacsj `w'svacsk `w'svacsp `w'ivfio"
    }
    else {

        if "`savings'" == "" local savings "savings"

        if (`wave' == 5) {
            qui gen double `savings' = 0 if `w'bank == 2
            * First for people who say they save
            qui replace `savings' = `w'savek if (`w'savek >= 0 & `w'savek < .)
            qui replace `savings' = 250 if (`w'savekb1 == 2 & `w'savekb4 == 2) & `w'savek == -1
            qui replace `savings' = 750 if (`w'savekb1 == 2 & `w'savekb4 == 1) & `w'savek == -1
            qui replace `savings' = 3000 if (`w'savekb1 == 1 & `w'savekb2 == 2) & `w'savek == -1
            qui replace `savings' = 7500 if (`w'savekb1 == 1 & `w'savekb2 == 1 & `w'savekb3 == 2) & `w'savek == -1
            * Correction for joint and sole and joint
            qui replace `savings' = `savings'/2 if `savings' < . & inlist(`w'savej,2,3)

            * Now for people who say they don't save
            qui replace `savings' = `w'bankk if `w'bank == 1 & (`w'bankk >= 0 & `w'bankk < .)
            qui replace `savings' = 250 if `w'bank == 1 & `w'bankk == -1 & (`w'bankkb1 == 2 & `w'bankkb4 == 2)
            qui replace `savings' = 750 if `w'bank == 1 & `w'bankk == -1 & (`w'bankkb1 == 2 & `w'bankkb4 == 1)
            qui replace `savings' = 3000 if `w'bank == 1 & `w'bankk == -1 & (`w'bankkb1 == 1 & `w'bankkb2 == 2)
            qui replace `savings' = 7500 if `w'bank == 1 & `w'bankk == -1 & (`w'bankkb1 == 1 & `w'bankkb2 == 1 & `w'bankkb3 == 2)
            * Correction for joint and sole and joint
            qui replace `savings' = `savings'/2 if `savings' < . & `w'save == 2 & `w'bank == 1 & inlist(`w'bankj,2,3)
            label variable `savings' "Stock of savings (indiv)"
            qui gen byte `savings'i = 0 if (`w'bank == 2) | (`w'savek >= 0 & `w'savek < .) | (`w'bank == 1 & (`w'bankk >= 0 & `w'bankk < .))
            qui replace `savings'i = 1 if `savings' < . & `savings'i >= .
            label variable `savings'i "savings imputation flag"

            if ("`mindic'" == "mindic") {
                qui replace `savings' = .a if inlist(`w'ivfio,2,3) & `savings' == .
                qui replace `savings' = .b if inlist(`w'save,-2,-8,-9) & `savings' == .
                qui replace `savings' = .c if `w'save == 1 & inlist(`w'savek,-2,-8,-9) & `savings' == .
                qui replace `savings' = .d if `w'save == 1 & `w'savek == -1 & `w'savekb3 == 1 & `savings' == .
                qui replace `savings' = .e if `w'save == 1 & `w'savek == -1 & (inlist(`w'savekb1,-1,-2,-8,-9) | (`w'savekb1 == 1 & inlist(`w'savekb2,-1,-2,-8,-9)) | (`w'savekb1 == 1 & `w'savekb2 == 1 & inlist(`w'savekb3,-1,-2,-8,-9)) | (`w'savekb1 == 2 & inlist(`w'savekb4,-1,-2,-8,-9))) & `savings' == .
                qui replace `savings' = .f if `w'save == 2 & inlist(`w'bank,-1,-2,-8,-9) & `savings' == .
                qui replace `savings' = .g if `w'save == 2 & `w'bank == 1 & inlist(`w'bankk,-2,-8,-9) & `savings' == .
                qui replace `savings' = .h if `w'save == 2 & `w'bankk == -1 & `w'bankkb3 == 1 & `savings' == .
                qui replace `savings' = .i if `w'save == 2 & `w'bankk == -1 & (inlist(`w'bankkb1,-1,-2,-8,-9) | (`w'bankkb1 == 1 & inlist(`w'bankkb2,-1,-2,-8,-9)) | (`w'bankkb1 == 1 & `w'bankkb2 == 1 & inlist(`w'bankkb3,-1,-2,-8,-9)) | (`w'bankkb1 == 2 & inlist(`w'bankkb4,-1,-2,-8,-9))) & `savings' == .

                qui replace `savings'i = .a if inlist(`w'ivfio,2,3) & `savings'i == .
                qui replace `savings'i = .b if inlist(`w'save,-2,-8,-9) & `savings'i == .
                qui replace `savings'i = .c if `w'save == 1 & inlist(`w'savek,-2,-8,-9) & `savings'i == .
                qui replace `savings'i = .d if `w'save == 1 & `w'savek == -1 & `w'savekb3 == 1 & `savings'i == .
                qui replace `savings'i = .e if `w'save == 1 & `w'savek == -1 & (inlist(`w'savekb1,-1,-2,-8,-9) | (`w'savekb1 == 1 & inlist(`w'savekb2,-1,-2,-8,-9)) | (`w'savekb1 == 1 & `w'savekb2 == 1 & inlist(`w'savekb3,-1,-2,-8,-9)) | (`w'savekb1 == 2 & inlist(`w'savekb4,-1,-2,-8,-9))) & `savings'i == .
                qui replace `savings'i = .f if `w'save == 2 & inlist(`w'bank,-1,-2,-8,-9) & `savings'i == .
                qui replace `savings'i = .g if `w'save == 2 & `w'bank == 1 & inlist(`w'bankk,-2,-8,-9) & `savings'i == .
                qui replace `savings'i = .h if `w'save == 2 & `w'bankk == -1 & `w'bankkb3 == 1 & `savings'i == .
                qui replace `savings'i = .i if `w'save == 2 & `w'bankk == -1 & (inlist(`w'bankkb1,-1,-2,-8,-9) | (`w'bankkb1 == 1 & inlist(`w'bankkb2,-1,-2,-8,-9)) | (`w'bankkb1 == 1 & `w'bankkb2 == 1 & inlist(`w'bankkb3,-1,-2,-8,-9)) | (`w'bankkb1 == 2 & inlist(`w'bankkb4,-1,-2,-8,-9))) & `savings'i == .

            }

        }
        else if inlist(`wave',10,15) {
            qui gen double `savings' = 0 if `w'nvestnn == 0
            qui replace `savings' = 0 if (`w'nvesth == 0 & `w'nvesti == 0 & `w'nvestj == 0)
            * Exact response
            qui replace `savings' = `w'svack if (`w'svack >= 0 & `w'svack < .)
            * Banded response (top (open) band not coded)
            qui replace `savings' = 250 if (`w'svack == -1) & (`w'svackb1 == 2 & `w'svackb4 == 2)
            qui replace `savings' = 750 if (`w'svack == -1) & (`w'svackb1 == 2 & `w'svackb4 == 1)
            qui replace `savings' = 3000 if (`w'svack == -1) & (`w'svackb1 == 1 & `w'svackb2 == 2)
            qui replace `savings' = 7500 if (`w'svack == -1) & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 2)
            if (`wave' == 15) qui replace `savings' = 15000 if (`w'svack == -1) & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1 & `w'svackb5 == 2)
            * Correction for joint
            qui replace `savings' = `savings'/2 if `savings' < . & `w'svacsj == 2
            * Correction for joint and sole: estimate provided for AMOUNT held in SOLE NAME
            qui replace `savings' = `w'svacsk + (`savings' - `w'svacsk)/2 if `savings' < . & (`w'svacsk >= 0 & `w'svacsk < .) & (`savings' >= `w'svacsk) & `w'svacsj == 3
            * Correction for joint and sole: estimate provided for SHARE in TOTAL
            qui replace `savings' = `savings'*`w'svacsp/100 if `savings' < . & (`w'svacsp >= 0 & `w'svacsp <= 100) & `w'svacsk == -1 & `w'svacsj == 3
            label variable `savings' "Stock of savings (indiv)"
            qui gen byte `savings'i = 0 if (`w'nvestnn == 0) | (`w'nvesth == 0 & `w'nvesti == 0 & `w'nvestj == 0) | (`w'svack >= 0 & `w'svack < .)
            qui replace `savings'i = 1 if `savings' < . & `savings'i >= .
            label variable `savings'i "savings imputation flag"

            if ("`mindic'" == "mindic") {
                qui replace `savings' = .a if inlist(`w'ivfio,2,3) & `savings' == .
                qui replace `savings'i = .a if inlist(`w'ivfio,2,3) & `savings'i == .
                if (`wave' == 10) qui replace `savings' = .b if `w'save == -2 & `savings' == .
                qui replace `savings' = .j if (inlist(`w'nvestnn,-1,-2,-9) | (`w'nvestnn == -8 & `w'nvesth == -8 & `w'nvesti == -8 & `w'nvestj == -8)) & `savings' == .
                qui replace `savings' = .k if (`w'nvesth == 1 | `w'nvesti == 1 | `w'nvestj == 1) & inlist(`w'svack,-2,-8,-9) & `savings' == .

                qui replace `savings'i = .j if (inlist(`w'nvestnn,-1,-2,-9) | (`w'nvestnn == -8 & `w'nvesth == -8 & `w'nvesti == -8 & `w'nvestj == -8)) & `savings'i == .
                qui replace `savings'i = .k if (`w'nvesth == 1 | `w'nvesti == 1 | `w'nvestj == 1) & inlist(`w'svack,-2,-8,-9) & `savings'i == .

                if (`wave' == 10) {
                    qui replace `savings' = .l if `w'svack == -1 & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1) & `savings' == .
                    qui replace `savings' = .n if `w'svack == -1 & (inlist(`w'svackb1,-1,-2,-8,-9) | (`w'svackb1 == 1 & inlist(`w'svackb2,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & inlist(`w'svackb3,-1,-2,-8,-9)) | (`w'svackb1 == 2 & inlist(`w'svackb4,-1,-2,-8,-9))) & `savings' == .

                    qui replace `savings'i = .l if `w'svack == -1 & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1) & `savings'i == .
                    qui replace `savings'i = .n if `w'svack == -1 & (inlist(`w'svackb1,-1,-2,-8,-9) | (`w'svackb1 == 1 & inlist(`w'svackb2,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & inlist(`w'svackb3,-1,-2,-8,-9)) | (`w'svackb1 == 2 & inlist(`w'svackb4,-1,-2,-8,-9))) & `savings'i == .

                }
                else {
                    qui replace `savings' = .m if `w'svack == -1 & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1 & `w'svackb5 == 1) & `savings' == .
                    qui replace `savings' = .n if `w'svack == -1 & (inlist(`w'svackb1,-1,-2,-8,-9) | (`w'svackb1 == 1 & inlist(`w'svackb2,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & inlist(`w'svackb3,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1 & inlist(`w'svackb5,-1,-2,-8,-9)) | (`w'svackb1 == 2 & inlist(`w'svackb4,-1,-2,-8,-9))) & `savings' == .

                    qui replace `savings'i = .m if `w'svack == -1 & (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1 & `w'svackb5 == 1) & `savings'i == .
                    qui replace `savings'i = .n if `w'svack == -1 & (inlist(`w'svackb1,-1,-2,-8,-9) | (`w'svackb1 == 1 & inlist(`w'svackb2,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & inlist(`w'svackb3,-1,-2,-8,-9)) | (`w'svackb1 == 1 & `w'svackb2 == 1 & `w'svackb3 == 1 & inlist(`w'svackb5,-1,-2,-8,-9)) | (`w'svackb1 == 2 & inlist(`w'svackb4,-1,-2,-8,-9))) & `savings'i == .
                }
            }

        }

        else if !inlist(`wave',5,10,15) {
            gen double `savings' = .l
            gen byte `savings'i = .l
        }

        if ("`mindic'" == "mindic") {
            label define `savings' .a "Proxy/phone respondent" .b "save missing" .c "savek missing" .d "savekb3==1" .e "savekb* missing" .f "bank missing" .g "bankk missing" .h "bankkb3==1" .i "bankkb* missing" .j "nvestnn missing" .k "svack missing" .l "svackb3==1 (wave10)" .m "svackb5==1 (wave15)" .n "svackb* missing" .l "Not asked in this wave"
            label values `savings' `savings'
            label values `savings'i `savings'
            assert (`savings' != .)
            assert (`savings'i != .)
        }

    }

end






* wINDRESP investments information (only available in waves 5, 10 and 15)
*********************************************************************

program define indresp_invests, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars invests(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' == 5) return local vars "`w'nvest `w'nvestk `w'nvestc1 `w'nvestc2 `w'nvestc3 `w'nvestc4 `w'nvesta `w'nvestj `w'ivfio `w'save"
        else if (`wave' == 10) return local vars "`w'nvestnn `w'nvesta `w'nvestb `w'nvestc `w'nvestd `w'nveste `w'nvestf `w'nvestg `w'nvestk `w'nvestc1 `w'nvestc2 `w'nvestc3 `w'nvestc4 `w'nvestsj `w'nvestsk `w'nvestsp `w'ivfio `w'save"
        else if (`wave' == 15) return local vars "`w'nvestnn `w'nvesta `w'nvestb `w'nvestc `w'nvestd `w'nveste `w'nvestf `w'nvestg `w'nvestk `w'nvestc1 `w'nvestc2 `w'nvestc3 `w'nvestc4 `w'nvestc5 `w'nvestsj `w'nvestsk `w'nvestsp `w'ivfio `w'save"
    }
    else {

        if "`invests'" == "" local invests "invests"

        if (`wave' == 5) {
            qui gen double `invests' = 0 if `w'nvest == 2
            qui replace `invests' = `w'nvestk if (`w'nvestk >= 0 & `w'nvestk < .)
            qui replace `invests' = 500 if (`w'nvestc1 == 2 & `w'nvestc4 == 2) & `w'nvestk == -1
            qui replace `invests' = 3000 if (`w'nvestc1 == 2 & `w'nvestc4 == 1) & `w'nvestk == -1
            qui replace `invests' = 10000 if (`w'nvestc1 == 1 & `w'nvestc2 == 2) & `w'nvestk == -1
            qui replace `invests' = 32500 if (`w'nvestc1 == 1 & `w'nvestc2 == 1 & `w'nvestc3 == 2) & `w'nvestk == -1
            qui replace `invests' = `invests'/2 if `invests' < . & `w'nvestj == 1
            label variable `invests' "Stock of invests (indiv)"
            qui gen byte `invests'i = 0 if (`w'nvest == 2) | (`w'nvestk >= 0 & `w'nvestk < .)
            qui replace `invests'i = 1 if `invests' < . & `invests'i >= .
            label variable `invests'i "invests imputation flag"

            if ("`mindic'" == "mindic") {
                qui replace `invests' = .a if inlist(`w'ivfio,2,3) & `invests' == .
                qui replace `invests' = .b if inlist(`w'save,-2,-8,-9) & `invests' == .
                qui replace `invests' = .c if inlist(`w'nvest,-1,-2,-8,-9) & `invests' == .
                qui replace `invests' = .d if inlist(`w'nvesta,-1,-2,-8,-9) & `invests' == .
                qui replace `invests' = .e if inlist(`w'nvestk,-2,-8,-9) & `invests' == .
                qui replace `invests' = .f if `w'nvestc3 == 1 & `invests' == .
                qui replace `invests' = .g if (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests' == .

                qui replace `invests'i = .a if inlist(`w'ivfio,2,3) & `invests'i == .
                qui replace `invests'i = .b if inlist(`w'save,-2,-8,-9) & `invests'i == .
                qui replace `invests'i = .c if inlist(`w'nvest,-1,-2,-8,-9) & `invests'i == .
                qui replace `invests'i = .d if inlist(`w'nvesta,-1,-2,-8,-9) & `invests'i == .
                qui replace `invests'i = .e if inlist(`w'nvestk,-2,-8,-9) & `invests'i == .
                qui replace `invests'i = .f if `w'nvestc3 == 1 & `invests'i == .
                qui replace `invests'i = .g if (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests'i == .


            }


        }
        else if inlist(`wave',10,15) {
            qui gen double `invests' = 0 if `w'nvestnn == 0
            qui replace `invests' = 0 if (`w'nvesta == 0 & `w'nvestb == 0 & `w'nvestc == 0 & `w'nvestd == 0 & `w'nveste == 0 & `w'nvestf == 0 & `w'nvestg == 0)
            * Exact response
            qui replace `invests' = `w'nvestk if (`w'nvestk >= 0 & `w'nvestk < .)
            * Banded response (top (open) band not coded)
            qui replace `invests' = 500 if (`w'nvestk == -1) & (`w'nvestc1 == 2 & `w'nvestc4 == 2)
            qui replace `invests' = 3000 if (`w'nvestk == -1) & (`w'nvestc1 == 2 & `w'nvestc4 == 1)
            qui replace `invests' = 10000 if (`w'nvestk == -1) & (`w'nvestc1 == 1 & `w'nvestc2 == 2)
            qui replace `invests' = 32500 if (`w'nvestk == -1) & (`w'nvestc1 == 1 & `w'nvestc2 == 1 & `w'nvestc3 == 2)
            if (`wave' == 15) qui replace `invests' = 32500 if (`w'nvestk == -1) & (`w'nvestc1 == 1 & `w'nvestc2 == 1 & `w'nvestc3 == 1 & `w'nvestc5 == 2)
            * Correction for joint
            qui replace `invests' = `invests'/2 if `invests' < . & `w'nvestsj == 2
            * Correction for joint and sole: estimate provided for AMOUNT held in SOLE NAME
            qui replace `invests' = `w'nvestsk + (`invests' - `w'nvestsk)/2 if `invests' < . & (`w'nvestsk >= 0 & `w'nvestsk < .) & (`invests' >= `w'nvestsk) & `w'nvestsj == 3
            * Correction for joint and sole: estimate provided for SHARE in TOTAL
            qui replace `invests' = `invests'*`w'nvestsp/100 if `invests' < . & (`w'nvestsp >= 0 & `w'nvestsp <= 100) & `w'nvestsk == -1 & `w'nvestsj == 3
            label variable `invests' "Stock of invests (indiv)"
            qui gen byte `invests'i = 0 if (`w'nvestnn == 0) | (`w'nvesta == 0 & `w'nvestb == 0 & `w'nvestc == 0 & `w'nvestd == 0 & `w'nveste == 0 & `w'nvestf == 0 & `w'nvestg == 0) | (`w'nvestk >= 0 & `w'nvestk < .)
            qui replace `invests'i = 1 if `invests' < . & `invests'i >= .
            label variable `invests'i "invests imputation flag"

            if ("`mindic'" == "mindic") {
                qui replace `invests' = .a if inlist(`w'ivfio,2,3) & `invests' == .
                qui replace `invests'i = .a if inlist(`w'ivfio,2,3) & `invests'i == .

                if (`wave' == 10) qui replace `invests' = .b if `w'save == -2 & `invests' == .
                qui replace `invests' = .h if (inlist(`w'nvestnn,-1,-2,-9) | (`w'nvestnn == -8 & `w'nvesta == -8 & `w'nvestb == -8 & `w'nvestc == -8 & `w'nvestd == -8 & `w'nveste == -8 & `w'nvestf == -8 & `w'nvestg == -8)) & `invests' == .
                qui replace `invests' = .i if (`w'nvesta == 1 | `w'nvestb == 1 | `w'nvestc == 1 | `w'nvestd == 1 | `w'nveste == 1 | `w'nvestf == 1 | `w'nvestg == 1) & inlist(`w'nvestk,-2,-8,-9) & `invests' == .

                qui replace `invests'i = .h if (inlist(`w'nvestnn,-1,-2,-9) | (`w'nvestnn == -8 & `w'nvesta == -8 & `w'nvestb == -8 & `w'nvestc == -8 & `w'nvestd == -8 & `w'nveste == -8 & `w'nvestf == -8 & `w'nvestg == -8)) & `invests'i == .
                qui replace `invests'i = .i if (`w'nvesta == 1 | `w'nvestb == 1 | `w'nvestc == 1 | `w'nvestd == 1 | `w'nveste == 1 | `w'nvestf == 1 | `w'nvestg == 1) & inlist(`w'nvestk,-2,-8,-9) & `invests'i == .

                if (`wave' == 10) {
                    qui replace `invests' = .j if `w'nvestc3 == 1 & `invests' == .
                    qui replace `invests' = .l if `w'nvestk == -1 & (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests' == .

                    qui replace `invests'i = .j if `w'nvestc3 == 1 & `invests'i == .
                    qui replace `invests'i = .l if `w'nvestk == -1 & (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests'i == .

                }
                else {
                    qui replace `invests' = .k if `w'nvestc5 == 1 & `invests' == .
                    qui replace `invests' = .l if `w'nvestk == -1 & (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & `w'nvestc3 == 1 & inlist(`w'nvestc5,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests' == .

                    qui replace `invests'i = .k if `w'nvestc5 == 1 & `invests'i == .
                    qui replace `invests'i = .l if `w'nvestk == -1 & (inlist(`w'nvestc1,-1,-2,-8,-9) | (`w'nvestc1 == 1 & inlist(`w'nvestc2,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & inlist(`w'nvestc3,-1,-2,-8,-9)) | (`w'nvestc1 == 1 & `w'nvestc2 == 1 & `w'nvestc3 == 1 & inlist(`w'nvestc5,-1,-2,-8,-9)) | (`w'nvestc1 == 2 & inlist(`w'nvestc4,-1,-2,-8,-9))) & `invests'i == .

                }

            }

        }

        else if !inlist(`wave',5,10,15) {
            gen double `invests' = .o
            gen byte `invests'i = .o
        }

        if ("`mindic'" == "mindic") {
            label define `invests' .a "Proxy/phone respondent" .b "save missing" .c "nvest missing" .d "nvest* missing" .e "nvestk missing" .f "nvestc3==1" .g "nvestc* missing" .h "nvestnn missing" .i "nvestk missing" .j "nvestc3==1 (wave 10)" .k "nvest5==1 (wave 15)" .l "nvestc* missing" .o "Not asked in this wave"
            label values `invests' `invests'
            label values `invests'i `invests'
            assert (`invests' != .)
            assert (`invests'i !=.)
        }

    }

end
*/




/*
* wINDRESP debts information (only available in waves 5, 10 and 15)
*********************************************************************

program define indresp_debts, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars debts(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' == 5) return local vars "`w'debt `w'debty `w'debtc1 `w'debtc2 `w'debtc3 `w'debtc4 `w'debtj `w'ivfio `w'debta"
        else if (`wave' == 10) return local vars "`w'debt `w'debty `w'debtc1 `w'debtc2 `w'debtc3 `w'debtc4 `w'debtsj `w'debtsk `w'debtsp `w'ivfio `w'debta"
        else if (`wave' == 15) return local vars "`w'debt `w'debty `w'debtc1 `w'debtc2 `w'debtc3 `w'debtc4 `w'debtc5 `w'debtsj `w'debtsk `w'debtsp `w'ivfio `w'debta"
    }
    else {

        if "`debts'" == "" local debts "debts"

        if (`wave' == 5) {

            * Zero
            qui gen double `debts' = 0 if `w'debt == 2
            * Exact (positive) amount
            qui replace `debts' = `w'debty if (`w'debty >= 0 & `w'debty < .)
            * Bands
            qui replace `debts' = 50 if `w'debty == -1 & (`w'debtc1 == 2 & `w'debtc4 == 2)
            qui replace `debts' = 300 if `w'debty == -1 & (`w'debtc1 == 2 & `w'debtc4 == 1)
            qui replace `debts' = 1000 if `w'debty == -1 & (`w'debtc1 == 1 & `w'debtc2 == 2)
            qui replace `debts' = 3250 if `w'debty == -1 & (`w'debtc1 == 1 & `w'debtc2 == 1 & `w'debtc3 == 2)
            * Correction for joint
            qui replace `debts' = `debts'/2 if `debts' < . & `w'debtj == 1
            label variable `debts' "Stock of debts (indiv)"
            qui gen byte `debts'i = 0 if (`w'debt == 2) | (`w'debty >= 0 & `w'debty < .)
            qui replace `debts'i = 1 if `debts' < . & `debts'i >= .
            label variable `debts'i "debts imputation flag"

        }
        else if inlist(`wave',10,15) {

            * Zero
            qui gen double `debts' = 0 if `w'debt == 2
            * Exact (positive) amount
            qui replace `debts' = `w'debty if (`w'debty >= 0 & `w'debty < .)
            * Bands
            qui replace `debts' = 50 if `w'debty == -1 & (`w'debtc1 == 2 & `w'debtc4 == 2)
            qui replace `debts' = 300 if `w'debty == -1 & (`w'debtc1 == 2 & `w'debtc4 == 1)
            qui replace `debts' = 1000 if `w'debty == -1 & (`w'debtc1 == 1 & `w'debtc2 == 2)
            qui replace `debts' = 3250 if `w'debty == -1 & (`w'debtc1 == 1 & `w'debtc2 == 1 & `w'debtc3 == 2)
            if (`wave' == 15) qui replace `debts' = 7500 if `w'debty == -1 & (`w'debtc1 == 1 & `w'debtc2 == 1 & `w'debtc3 == 1 & `w'debtc5 == 2)
            * Correction for joint
            qui replace `debts' = `debts'/2 if `debts' < . & `w'debtsj == 1
            * Correction for joint and sole: estimate provided for AMOUNT held in SOLE NAME
            qui replace `debts' = `w'debtsk + (`debts' - `w'debtsk)/2 if `debts' < . & (`w'debtsk >= 0 & `w'debtsk < .) & (`debts' >= `w'debtsk) & `w'debtsj == 3
            * Correction for joint and sole: estimate provided for SHARE in TOTAL
            qui replace `debts' = `debts'*`w'debtsp/100 if `debts' < . & (`w'debtsp >= 0 & `w'debtsp <= 100) & `w'debtsk == -1 & `w'debtsj == 3
            label variable `debts' "Stock of debts (indiv)"
            qui gen byte `debts'i = 0 if (`w'debt == 2) | (`w'debty >= 0 & `w'debty < .)
            qui replace `debts'i = 1 if `debts' < . & `debts'i >= .
            label variable `debts'i "debts imputation flag"

        }

        if ("`mindic'" == "mindic") {
        if inlist(`wave',5,10,15) {
            qui replace `debts' = .a if inlist(`w'ivfio,2,3) & `debts' == .
            qui replace `debts' = .b if inlist(`w'debt,-1,-2,-8,-9) & `debts' == .
            qui replace `debts' = .c if inlist(`w'debta,-1,-2,-8,-9) & `debts' == .
            qui replace `debts' = .d if inlist(`w'debty,-2,-8,-9) & `debts' == .

            qui replace `debts'i = .a if inlist(`w'ivfio,2,3) & `debts'i == .
            qui replace `debts'i = .b if inlist(`w'debt,-1,-2,-8,-9) & `debts'i == .
            qui replace `debts'i = .c if inlist(`w'debta,-1,-2,-8,-9) & `debts'i == .
            qui replace `debts'i = .d if inlist(`w'debty,-2,-8,-9) & `debts'i == .

            if inlist(`wave',5,10) {
                qui replace `debts' = .e if `w'debtc3 == 1 & `debts' == .
                qui replace `debts' = .g if (inlist(`w'debtc1,-1,-2,-8,-9) | (`w'debtc1 == 1 & inlist(`w'debtc2,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & inlist(`w'debtc3,-1,-2,-8,-9)) | (`w'debtc1 == 2 & inlist(`w'debtc4,-1,-2,-8,-9))) & `debts' == .

                qui replace `debts'i = .e if `w'debtc3 == 1 & `debts'i == .
                qui replace `debts'i = .g if (inlist(`w'debtc1,-1,-2,-8,-9) | (`w'debtc1 == 1 & inlist(`w'debtc2,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & inlist(`w'debtc3,-1,-2,-8,-9)) | (`w'debtc1 == 2 & inlist(`w'debtc4,-1,-2,-8,-9))) & `debts'i == .
            }
            else if (`wave' == 15) {
                qui replace `debts' = .f if `w'debtc5 == 1 & `debts' == .
                qui replace `debts' = .g if (inlist(`w'debtc1,-1,-2,-8,-9) | (`w'debtc1 == 1 & inlist(`w'debtc2,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & inlist(`w'debtc3,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & `w'debtc3 == 1 & inlist(`w'debtc5,-1,-2,-8,-9)) | (`w'debtc1 == 2 & inlist(`w'debtc4,-1,-2,-8,-9))) & `debts' == .

                qui replace `debts'i = .f if `w'debtc5 == 1 & `debts'i == .
                qui replace `debts'i = .g if (inlist(`w'debtc1,-1,-2,-8,-9) | (`w'debtc1 == 1 & inlist(`w'debtc2,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & inlist(`w'debtc3,-1,-2,-8,-9)) | (`w'debtc1 == 1 & `w'debtc2 == 1 & `w'debtc3 == 1 & inlist(`w'debtc5,-1,-2,-8,-9)) | (`w'debtc1 == 2 & inlist(`w'debtc4,-1,-2,-8,-9))) & `debts'i == .

            }
        }

        if !inlist(`wave',5,10,15) {
            gen double debts = .h
            gen byte debtsi = .h
        }

            label define `debts' .a "Proxy/phone respondent" .b "debt missing" .c "debt* missing" .d "debty missing" .e "debtc3==1" .f "debtc5==1" .g "debtc* missing" .h "Not asked in this wave"
            label values `debts' `debts'
            label values `debts'i `debts'
            assert `debts' != .
            assert `debts'i != .
        }


    }

end
*/

* Average amount saved per month (flow)
**********************************

/*set to zero if the person says they don't save out of current income (wsave=2)*/

program define indresp_saved, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars saved(name) mindic]
    local w = char(96+`wave')
    if "`whatvars'" == "whatvars" {
        if inlist(`wave',2,4,6,8,10,13) return local vars "`w'_save `w'_saved"
    }
    else {
        if inlist(`wave',1,3,5,7,9,11,12,14,15) {
           qui gen `saved' = .
        }

        if inlist(`wave',2,4,6,8,10,13) {
            if "`saved'" == "" local saved "saved"

            qui gen long `saved' = `w'_saved if `w'_save==1  & `w'_saved>=0 & `w'_saved<.
            qui replace `saved' =  0 if `w'_save==2
            label variable `saved' "how much on average do you manage to save a month?"
        }

    if "`mindic'" == "mindic" {
             if inlist(`wave',1,3,5,7,9,11,12,14,15)  {
                qui replace `saved' = .d
            }

            if inlist(`wave',2,4,6,8,10,13)  {
                qui replace `saved' = .a if `w'_ivfio==2
                qui replace `saved' = .b if `w'_ivfio!=2 & inlist(`w'_saved,-1,-2,-9)
                qui replace `saved' = .c if `w'_ivfio!=2 & inlist(`w'_save,-1,-2,-8,-9) & inlist(`w'_saved,-8)
            }

            if inlist(`wave',6,8)  {
                qui replace `saved' = .d if `w'_ivfio!=2 & `w'_save==-10 & `w'_saved==-10
            }

            label define `saved' .a "Proxy respondent" .b "wsaved invalid" .c "wsave invalid" .d "Not asked in this wave" .e "Not asked for IEMB"
            label values `saved' `saved'
            assert (`saved' != .)
        }
    }

end



* wINDRESP description of current activity (doesn't force people with a job to be employed/self-employed)
*********************************************************************************************************

program define indresp_econstat, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars econstat(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbstat `w'_ivfio"
    }
    else {

        if "`econstat'" == "" local econstat "econstat"

        qui gen byte `econstat' = (3 - `w'_jbstat) if inrange(`w'_jbstat,1,2)
        qui replace `econstat' = `w'_jbstat if inrange(`w'_jbstat,3,10)
        qui replace `econstat' = 11 if `w'_jbstat==97
        qui replace `econstat' = 11 if `w'_jbstat==11

		*PL added 08/08/22 
		if `wave'>=11 {
			qui replace `econstat' = 12 if `w'_jbstat==12
			qui replace `econstat' = 13 if `w'_jbstat==13
		}
		
		if `wave'>=13 {
			qui replace `econstat' = 14 if `w'_jbstat==14
			qui replace `econstat' = 15 if `w'_jbstat==15
		}
	
        label variable `econstat' "Economic status"
        label define `econstat' 1 "Employment" 2 "Self-employment" 3 "Unemployment" 4 "Retirement" 5 "Maternity leave" 6 "Family care" 7 "Full-time education" 8 "Long-term sickness/disablement" 9 "Government training scheme" 10 "Unpaid work in family business" 11 "Other" 12 "Furloughed (wave 11+12)" 13 "Short-time working (wave 11+)" 14 "Shared parental leave (wave 13+)" 15 "Adoption leave (wave 14+)"
        label values `econstat' `econstat'

        if "`mindic'" == "mindic" {
            qui replace `econstat' = .a if inlist(`w'_jbstat,-1,-2,-3,-4,-8,-9) & `econstat' == .
            assert (`econstat' != .)
            label define `econstat' .a "jbstat invalid", add
        }

    }

end

* ILO definition of unemployment
************************************

/* did paid work last week wJBHAS =1 */
/* do not have a job they are away from wJBOFF*/
/* not a full time student and not in a government training scheme JBSTAT*/
/* between 16 and 74 (age range to align with BHPS version, based on EUROSTAT definition) */
/* have looked for work in the last 4 weeks wJULK4*/
/* definition taken from Burgess, Gardiner and Propper, 2001, but upper ages 74 (rather than 60/65 male/female)*/

program define indresp_ilo_unemp, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ilo_unemp(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_jbstat `w'_jbhas `w'_jboff `w'_dvage `w'_julk4wk  `w'_ivfio"
    }
    else {

        if "`ilo_unemp'" == "" local ilo_unemp "ilo_unemp"


        if (`wave'==1) {
            qui gen byte `ilo_unemp' = 0 if (`w'_jbhas==1 | `w'_jboff==1|`w'_jboff==3) & !inlist(`w'_jbstat,7,9) & inrange(`w'_dvage,16,74)
            qui replace  `ilo_unemp' = 1 if `w'_jbhas==2 & `w'_jboff==2 & !inlist(`w'_jbstat,7,9) & inrange(`w'_dvage,16,74) & `w'_julk4wk==1
            qui replace  `ilo_unemp' = 2 if (inlist(`w'_jbstat,7,9) | !inrange(`w'_dvage,16,74) | `w'_julk4wk==2)

        }

        if (`wave'>1) {
            qui gen byte `ilo_unemp' = 0 if (`w'_jbhas==1 | `w'_jboff==1|`w'_jboff==3) & !inlist(`w'_jbstat,7,9) & inrange(`w'_dvage,16,74) & `w'_ivfio!=2
            qui replace  `ilo_unemp' = 1 if `w'_jbhas==2 & `w'_jboff==2 & !inlist(`w'_jbstat,7,9) & inrange(`w'_dvage,16,74) & `w'_julk4wk==1 & `w'_ivfio!=2
            qui replace  `ilo_unemp' = 2 if (inlist(`w'_jbstat,7,9) | !inrange(`w'_dvage,16,74) | (`w'_jbhas==2 & `w'_jboff==2 & `w'_julk4wk==2)) & `w'_ivfio!=2
        }

        label define `ilo_unemp' 0 "Employed" 1 "Unemployed" 2 "Not in labour force"
        label values `ilo_unemp' `ilo_unemp'

        if "`mindic'" == "mindic" {
        if (`wave'>1) {
            qui replace `ilo_unemp' = .a if `w'_ivfio==2 & `ilo_unemp' == .
        }
        qui replace `ilo_unemp' = .b if inlist(`w'_jbhas,-1,-2,-3,-4,-7,-9)  & `ilo_unemp' == .
        qui replace `ilo_unemp' = .c if inlist(`w'_jboff,-1,-2,-3,-4,-7,-8,-9)  & `ilo_unemp' == .
        qui replace `ilo_unemp' = .d if inlist(`w'_jbstat,-1,-2,-3,-4,-7,-9) & `ilo_unemp' == .
        qui replace `ilo_unemp' = .e if inlist(`w'_julk4wk,-1,-2,-3,-4,-7,-8,-9)  & `ilo_unemp' == .
        qui replace `ilo_unemp' = .f if inlist(`w'_jbstat,1,2) & `w'_jbhas==2 & `w'_jboff==2 & `ilo_unemp' == .

        label define `ilo_unemp' .a "Proxy respondent (Wave 2+)" .b "jbhas invalid" .c "jboff invalid" .d "jbstat invalid" .e "julk4 invalid" .f "Responses inconsistent", add
        assert (`ilo_unemp' != .)
        }

    }

end




* wINDRESP description of current activity (employment, SE, unemployed, retired, maternity leave, etc)
******************************************************************************************************

    * I think this forces you to be employed/self-employed if you have a job, even if it is not the best description of your current activity

    * for spells in wjobhist, need wjhstat and wjhsemp to create spell type
    * for spells in aindresp, need ajbstat
    * for spells in windresp (apart from wave a), need wnemst and derived jb1status

    * Note: in wave 1, the job history questions do not rely on jb1status

program define indresp_spelltype, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars spelltype(name) jb1status(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
            return local vars "`w'_jbstat"
    }
    else {

        qui gen byte `spelltype' = `jb1status' if inlist(`jb1status',1,2)
        qui replace `spelltype' = 3 - `w'_jbstat if inlist(`w'_jbstat,1,2) & !inlist(`jb1status',1,2)
        qui replace `spelltype' = `w'_jbstat if inrange(`w'_jbstat,3,10) & !inlist(`jb1status',1,2)
        qui replace `spelltype' = 11 if inlist(`w'_jbstat,97,11) & !inlist(`jb1status',1,2)

        label variable `spelltype' "Type of spell"
        label define `spelltype' 1 "Employment" 2 "Self-employment" 3 "Unemployment" 4 "Retirement" 5 "Maternity leave" 6 "Family care" 7 "Full-time education" 8 "Long-term sickness/disablement" 9 "Government training scheme" 10 "Unpaid work in family business" 11 "Other"
        label values `spelltype' `spelltype'

        if "`mindic'" == "mindic" {

            qui replace `spelltype' = .a if inlist(`w'_jbstat,-1,-2,-3,-4,-9) & `spelltype' == .

            assert (`spelltype' != .)
            label define `spelltype'  .a "jbstat invalid", add
        }

    }

end


* current status for start dates.
 * ********************************************************************************************************************************************************
* Usoc doesn't record start and end dates of period of non-employment. It just asks when you last worked. This status is a simplified
 * employed, self employed, retired, other not work (n.b. we only know start date of retirement in wave 1)
 * taken out retired as they are also asked when their last job ended which is more relevant that self reported retirement date"

program define indresp_currstat, rclass
    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars currstat(name) mindic]
    local w = char(96+`wave')
    if "`whatvars'" == "whatvars" {
      return local vars                "`w'_jbhas `w'_jboff `w'_jbsemp `w'_jbstat"

    }

    else {
        qui gen byte `currstat' = 1 if  (`w'_jbhas==1|`w'_jboff==1) & `w'_jbsemp~=2
        qui replace `currstat'  = 2 if  (`w'_jbhas==1|`w'_jboff==1) & `w'_jbsemp==2
        qui replace `currstat'  = 0 if ~(`w'_jbhas==1|`w'_jboff==1) & `w'_jbhas>0
        *qui replace `currstat'  = 3 if   `w'_jbstat==4 & ~(`w'_jbhas==1|`w'_jboff==1)

        label variable `currstat' "Current spell (simple) corresponds to spell dates"
        label define `currstat' 0 "Not employed" 1 "Employed" 2 "Self-employed"
        label values `currstat' `currstat'


        if "`mindic'" == "mindic" {
        qui replace `currstat' = .a if inlist(`w'_jbhas,-1,-2,-3,-4,-9) & `currstat'==.

            assert (`currstat' != .)
            label define `currstat'  .a "jbstat invalid", add
            assert `currstat'~=.
            }

        }

end

* Identify individuals whose current status started before last year's interview
********************************************************************************

* Note: this is based only on interview and spell start dates - it does not require spell types to be the same across waves
* It should work regardless of whether the later wave has been merged into the earlier one, or vice versa

program define indresp_b4prevint, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars b4prevint(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {

    if `wave'~=1 return local vars  "`w'_notempchk `w'_empchk `w'_samejob `w'_ff_jbstat `w'_ff_ivlolw `w'_jbsamr"

    }


    else {

        if `wave'==1  {
        qui gen byte `b4prevint' = .a
        }
        else {
        qui gen byte `b4prevint' = 1 if `w'_notempchk==1|(`w'_empchk==1 & `w'_samejob==1)|(`w'_empchk==1 & `w'_ff_jbstat==1)
        qui replace  `b4prevint' = 0 if `w'_notempchk==2|`w'_empchk==2|(`w'_empchk==1 & (`w'_jbsamr==2|`w'_samejob==2))
        }

        if "`mindic'" == "mindic" {
            label define b4prevint 0 "changed status since prev int" 1 "status started b4 prev int"  .a "not applicable (wave 1)" .b "proxy interview (not asked)" .c "notempchk/empchk invalid" .d "samejob invalid" .e "ff_jbstat invalid" .f "not interviewed last wave"
            label values `b4prevint' `b4prevint'

            if `wave'>1 {
            replace `b4prevint' = .f if `w'_ff_ivlolw~=1 & `b4prevint'==.
            replace `b4prevint' = .b if `w'_notempchk==-7|`w'_empchk==-7
            replace `b4prevint' = .d if `w'_empchk==1 & `w'_ff_jbstat>1 & `w'_samejob<0 & `b4prevint'==.
            replace `b4prevint' = .e if `w'_ff_jbstat<0 & `w'_ff_ivlolw==1 & `b4prevint'>=.
            replace `b4prevint' = .c if (`w'_notempchk<0 | `w'_empchk<0) & `b4prevint'==.
            }

            assert `b4prevint' != .
        }
     label var `b4prevint' "current status (currstat) began before previous interview (i.e whether status has stayed the same)"
    }
end



* wINDRESP start date for current activity (current job if working)
*******************************************************************

/*don't have start date of spell if not in employment (except retirement). However, we do have end date of last job. We use this as the start date of non-employment spell.
 * If never worked, we use the date that they last left education as the start date of non-employment spell.
 * Retirement date only is month and year so assume it starts on the 1st of the month. This only recorded in wave 1;
 * date left last employment is only month and year so assume it starts on the 1st of the month*/

program define indresp_spellstart, rclass
/*needs currstat*/
    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars startday(name) startmonth(name) startyear(name) jb1status(varname) mindic]
    local w = char(96+`wave')
    if "`whatvars'" == "whatvars" {
        if inlist(`wave',1) return local vars "`w'_jbbgd `w'_jbbgm `w'_jbbgy `w'_retdatey `w'_retdatem `w'_jbhad `w'_jlendy `w'_jlendm `w'_school `w'_scend `w'_fenow `w'_feend `w'_ivfio `w'_dvage `w'_istrtdaty "
        if `wave'>1 & `wave'<6 {
        #delimit ;
        return local vars                "`w'_pripn `w'_sampst `w'_hhorig `w'_jbbgd `w'_jbbgm `w'_jbbgy `w'_jbhad `w'_jlendy `w'_jlendm `w'_school `w'_scend `w'_fenow `w'_feend `w'_ivfio `w'_dvage `w'_istrtdaty `w'_ff_everint
                                               `w'_ff_ivlolw `w'_notempchk `w'_empchk
                                               `w'_empstendy4 `w'_empstendm `w'_empstendd `w'_nxtst `w'_nxtstelse `w'_cstat `w'_nxtstendd `w'_nxtstendm `w'_nxtstendy4  `w'_jbsamr `w'_wkplsam
                                               `w'_samejob `w'_jbendd `w'_jbendm  `w'_jbendy4 `w'_cjob `w'_nxtjbhrs `w'_nxtjbes `w'_nxtjbendd  `w'_nxtjbendm `w'_nxtjbendy4 `w'_ff_jbstat  `w'_ff_jbsemp
                                               `w'_nextstat*
                                               `w'_nextelse*
                                               `w'_currstat*
                                               `w'_currjob*
                                               `w'_statendd*
                                               `w'_statendm*
                                               `w'_statendm*
                                               `w'_statendy4*
                                               ";
        #delimit cr
        }

        if `wave'>=6 {

        #delimit ;
        return local vars                "`w'_pripn `w'_sampst `w'_hhorig `w'_jbbgd `w'_jbbgm `w'_jbbgy `w'_jbhad `w'_jlendy `w'_jlendm `w'_school `w'_scend `w'_fenow `w'_feend `w'_ivfio `w'_dvage `w'_istrtdaty
                                               `w'_ff_ivlolw `w'_notempchk `w'_empchk
                                               `w'_empstendy4 `w'_empstendm `w'_empstendd `w'_nxtst `w'_nxtstelse `w'_cstat `w'_nxtstendd `w'_nxtstendm `w'_nxtstendy4  `w'_jbsamr `w'_wkplsam
                                               `w'_samejob `w'_jbendd `w'_jbendm  `w'_jbendy4 `w'_cjob `w'_nxtjbhrs `w'_nxtjbes `w'_nxtjbendd  `w'_nxtjbendm `w'_nxtjbendy4 `w'_ff_jbstat `w'_ff_jbsemp
                                               `w'_nextstat*
                                               `w'_nextelse*
                                               `w'_currstat*
                                               `w'_currjob*
                                               `w'_statendd*
                                               `w'_statendm*
                                               `w'_statendm*
                                               `w'_statendy4*
                                               ";
        #delimit cr
        }

    }


    else {
        tempvar agelefted yearlefted yearage16

        if "`startday'" == "" local startday "startday"
        if "`startmonth'" == "" local startmonth "startmonth"
        if "`startyear'" == "" local startyear "startyear"
        if "`currstat'" == "" local currstat "currstat"
        if "`b4prevint'"==""  local b4prevint "b4prevint"

        egen `agelefted' = rmax(`w'_scend `w'_feend)
        replace `agelefted' = 10 if `w'_school==2
        gen `yearlefted' = `w'_istrtdaty-`w'_dvage+`agelefted' if `agelefted'>0 & `w'_dvage>0 & `w'_istrtdaty>0
        gen `yearage16'  = `w'_istrtdaty-`w'_dvage+16 if `w'_dvage>0 & `w'_istrtdaty>0

        if `wave'==1 {

/*start year*/
/*working (employed or self employed)*/
gen     `startyear' = `w'_jbbgy if (`currstat'==1|`currstat'==2) & `w'_jbbgy>0
/*not working. These people have date left last job but not date started current status*/
replace `startyear' = `w'_jlendy if `currstat'==0 & `w'_jlendy>0
replace `startyear' = `yearlefted' if `w'_jbhad==2 & `currstat'==0 & `startyear'==.  /*use year last left ed if never worked*/
replace `startyear' = `yearage16' if `w'_jbhad==2 & `currstat'==0 & `yearlefted'==. & ((`w'_school~=3 & `w'_fenow~=3)|`w'_dvage>30) /*assume people still in FE but age over 30 have had a gap so if they've never worked, take their school leaving age as year they left education*/
/*retired people asked when retired. Use this is year left last job not reported*/
replace `startyear' = `w'_retdatey if `currstat'==0 & `w'_retdatey>0 & `w'_jlendy<0 & `w'_jbhad==1 & `startyear'==.

/*start month*/
/*working (employed or self employed)*/
gen     `startmonth' = `w'_jbbgm if (`currstat'==1|`currstat'==2) & `w'_jbbgm>0
/*not working. These people have date left last job but not date started current status*/
replace `startmonth' = `w'_jlendm if `currstat'==0 & `w'_jlendm>0
replace `startmonth' = 7 if `w'_jbhad==2 & `currstat'==0 & `startyear'<.  /*assume left school in July if never worked and had a valid startyear*/
/*retired. use month retired if year and month left last job not reported*/
replace `startmonth' = `w'_retdatem if `currstat'==0 & `w'_jlendy<0 & `w'_jlendm<0 & `w'_retdatem>0 & `w'_jbhad==1  & `startyear'~=.

/*start day*/
/*working (employed or self employed)*/
gen     `startday' = `w'_jbbgd if (`currstat'==1|`currstat'==2) & `w'_jbbgd>0
/*not working. no start day so assume 1st if we have a valid month or if working but day is missing*/
replace `startday' = 1 if `startday'==. & `startmonth'<.

    if "`mindic'" == "mindic" {
        label define `startyear' .h "jbbgy invalid" .i "jblendy invalid" .j "jbhad invalid" .k "invalid education leaving age" .l "unknown currstat" ///
                                 .v "still in education" .x "proxy interview"
        label values `startyear' `startyear'

        replace `startyear' = .h if (`currstat'==1|`currstat'==2) & `w'_jbbgy<0 & `startyear'==.
        replace `startyear' = .v if `currstat'==0 & (`w'_jbhad==2|`w'_jbhad<0) & (`w'_school==3|`w'_fenow==3) & `w'_dvage<=30 & `startyear'==.
        replace `startyear' = .i if `currstat'==0 & `w'_jbhad==1 & `w'_jlendy<0 & `startyear'==.
        replace `startyear' = .x if `currstat'==0 & `w'_jbhad==-7  & `startyear'==.
        replace `startyear' = .j if `currstat'==0 & `w'_jbhad<0  & `startyear'==.
        replace `startyear' = .k if `currstat'==0 & `w'_jbhad==2 & ~(`w'_school==3|`w'_fenow==3) & `startyear'==.
        replace `startyear' = .l if `currstat'>=.

        label define `startmonth' .h "jbbgm invalid" .i "jlendm invalid" .j "jbhad invalid" .k "invalid education leaving age" .l "unknown currstat" ///
                                  .v "still in education" .x "proxy interview"
        label values startmonth startmonth

        replace `startmonth' = .h if (`currstat'==1|`currstat'==2) & `w'_jbbgm<0 & `startmonth'==.
        replace `startmonth' = .v if `currstat'==0 & (`w'_jbhad==2|`w'_jbhad<0) & (`w'_school==3|`w'_fenow==3) & `w'_dvage<=30 & `startmonth'==.
        replace `startmonth' = .i if `currstat'==0 & `w'_jbhad==1 & `w'_jlendm<0  & `startmonth'==.
        replace `startmonth' = .x if `currstat'==0 & `w'_jbhad==-7 & `startmonth'==.
        replace `startmonth' = .j if `currstat'==0 & `w'_jbhad<0   & `startmonth'==.
        replace `startmonth' = .k if `currstat'==0 & `w'_jbhad==2 & ~(`w'_school==3|`w'_fenow==3) & `startmonth'==.
        replace `startmonth' = .l if `currstat'>=.

        label define `startday' .h "jbbgm invalid" .i "jlendm invalid" .j "jbhad invalid"  .k "invalid education leaving age" .l "unknown currstat" ///
                                .v "still in education" .x "proxy interview"
        label values `startday' `startday'
        replace `startday' = `startmonth' if `startmonth'>=. & `startday'==.

        assert `startday'~=.
        assert `startmonth'~=.
        assert `startyear'~=.

        }
} /*end wave = 1*/

    /*see AnnualEventHistoryFlowChart.pub for the routing for these questions**/
    else {  /*wave 2*/

    /*first generate additional loops so that all years have 10 loops*/
    if `wave'>=3 {
    forval i = 7/10 {
     capture gen `w'_statendm`i' = -8
     capture gen `w'_statendy4`i' = -8
     capture gen `w'_statendd`i' = -8
     capture gen `w'_currstat`i' = -8
     capture gen `w'_currjob`i' = -8
     }
    }

    **YEAR
     gen     `startyear' = .y if `b4prevint'==1  /*status not changed*/
     replace `startyear' = `w'_empstendy4 if `w'_cstat==2                     & `w'_empstendy4>0
     replace `startyear' = `w'_empstendy4 if `w'_cjob==1                      & `w'_empstendy4>0
     replace `startyear' = `w'_jbendy4    if `w'_cjob==1                      & `w'_jbendy4>0
     replace `startyear' = `w'_nxtstendy4 if `w'_cstat==1 & `w'_currjob1==1   & `w'_nxtstendy4>0
     replace `startyear' = `w'_nxtjbendy4 if `w'_cjob==2  & `w'_currjob1==1   & `w'_nxtjbendy4>0
     replace `startyear' = `w'_nxtstendy4 if `w'_cstat==1 & `w'_currstat1==2  & `w'_nxtstendy4>0
     replace `startyear' = `w'_nxtjbendy4 if `w'_cjob==2  & `w'_currstat1==2  & `w'_nxtjbendy4>0


         *2+ spell changes
         forval i = 2/10 {
         local j = `i'-1
         replace `startyear' = `w'_statendy4`j' if `w'_currstat`i'==2 & `w'_statendy4`j'>0
         replace `startyear' = `w'_statendy4`j' if `w'_currjob`i'==1  & `w'_statendy4`j'>0
         }

     **MONTH
     gen     `startmonth' = .y if `b4prevint'==1  /*status not changed*/
     replace `startmonth' = `w'_empstendm if `w'_cstat==2                     & `w'_empstendm>0
     replace `startmonth' = `w'_empstendm if `w'_cjob==1                      & `w'_empstendm>0
     replace `startmonth' = `w'_jbendm    if `w'_cjob==1                      & `w'_jbendm>0
     replace `startmonth' = `w'_nxtstendm if `w'_cstat==1 & `w'_currjob1==1   & `w'_nxtstendm>0
     replace `startmonth' = `w'_nxtjbendm if `w'_cjob==2  & `w'_currjob1==1   & `w'_nxtjbendm>0
     replace `startmonth' = `w'_nxtstendm if `w'_cstat==1 & `w'_currstat1==2  & `w'_nxtstendm>0
     replace `startmonth' = `w'_nxtjbendm if `w'_cjob==2  & `w'_currstat1==2  & `w'_nxtjbendm>0

         *2+ spell changes
         forval i = 2/10 {
         local j = `i'-1
         replace `startmonth' = `w'_statendm`j' if `w'_currstat`i'==2 & `w'_statendm`j'>0
         replace `startmonth' = `w'_statendm`j' if `w'_currjob`i'==1  & `w'_statendm`j'>0

         }

     **DAY
     gen     `startday' = .y if `b4prevint'==1  /*status not changed*/
     replace `startday' = `w'_empstendd if `w'_cstat==2                     & `w'_empstendd>0
     replace `startday' = `w'_empstendd if `w'_cjob==1                      & `w'_empstendd>0
     replace `startday' = `w'_jbendd    if `w'_cjob==1                      & `w'_jbendd>0
     replace `startday' = `w'_nxtstendd if `w'_cstat==1 & `w'_currjob1==1   & `w'_nxtstendd>0
     replace `startday' = `w'_nxtjbendd if `w'_cjob==2  & `w'_currjob1==1   & `w'_nxtjbendd>0
     replace `startday' = `w'_nxtstendd if `w'_cstat==1 & `w'_currstat1==2  & `w'_nxtstendd>0
     replace `startday' = `w'_nxtjbendd if `w'_cjob==2  & `w'_currstat1==2  & `w'_nxtjbendd>0

     *2+ spell changes
     forval i = 2/10 {
     local j = `i'-1
     replace `startday' = `w'_statendd`j' if `w'_currstat`i'==2 & `w'_statendd`j'>0
     replace `startday' = `w'_statendd`j' if `w'_currjob`i'==1  & `w'_statendd`j'>0

     }

     replace `startday' = 1 if `startday'==. & `startmonth'<. /*assume startday is 1st whenever we have a valid month*/

    ***************************************************************
    /**now do the people who haven't been interviewed before W2+**/
    ***************************************************************
     * *YEAR
    *working (employed or self employed)
    replace `startyear' = `w'_jbbgy if (`currstat'==1|`currstat'==2) & `w'_jbbgy>0
    *not working. These people have date left last job but not date started current status
    replace `startyear' = `w'_jlendy if `currstat'==0 & `w'_jlendy>0
    replace `startyear' = `yearlefted' if `w'_jbhad==2 & `currstat'==0 & `startyear'==.  /*use year last left ed if never worked*/
    replace `startyear' = `yearage16' if `w'_jbhad==2 & `currstat'==0 & `yearlefted'==. & ((`w'_school~=3 & `w'_fenow~=3)|`w'_dvage>30) /*assume people still in FE but age over 30 have had a gap so if they've never worked, take their school leaving age as year they left education*/

    *start month
    *working (employed or self employed)
    replace `startmonth' = `w'_jbbgm if (`currstat'==1|`currstat'==2) & `w'_jbbgm>0
    *not working. These people have date left last job but not date started current status
    replace `startmonth' = `w'_jlendm if `currstat'==0 & `w'_jlendm>0
    replace `startmonth' = 7 if `w'_jbhad==2 & `currstat'==0 & `startyear'<.  /*assume left school in July if never worked and had a valid startyear*/

    *start day
    *working (employed or self employed)
    replace `startday' = `w'_jbbgd if (`currstat'==1|`currstat'==2) & `w'_jbbgd>0
    *not working. no start day so assume 1st if we have a valid month or if working but day is missing
    replace `startday' = 1 if `startday'==. & `startmonth'<.
     if "`mindic'" == "mindic" {
         label define `startyear' .a "empstendy4 invalid" .b "jbendy4 invalid" .c "nxtstendy4 invalid" .d "nxtjbendy4 invalid" .e "statendy4 invalid" .f "ff_jbstat invalid" ///
                                  .g "empchk/notempchk invalid" ///
                                  .v "other routing variables invalid" .w "proxy interview" .x "never interviewed but not asked right questions" .y "started spell b4 previous interview"
         label values `startyear' `startyear'
         replace `startyear' = .w if `b4prevint'==.a /*proxies*/
         replace `startyear' = .x if `w'_ff_ivlolw~=1 & `startyear'==.
         replace `startyear' = .a if `w'_cstat==2 & `w'_empstendy4<0
         replace `startyear' = .a if `w'_cjob==1  &  (`w'_notempchk==2|`w'_empchk==2) &  `w'_empstendy4<0
         replace `startyear' = .b if `w'_cjob==1  & ~(`w'_notempchk==2|`w'_empchk==2) &  `w'_jbendy4<0
         replace `startyear' = .c if `w'_cstat==1 & `w'_currjob1==1 & `w'_nxtstendy4<0
         replace `startyear' = .d if `w'_cjob==2 & `w'_currjob1==1 & `w'_nxtjbendy4<0
         replace `startyear' = .c if `w'_cstat==1 & `w'_currstat1==2 & `w'_nxtstendy4<0
         replace `startyear' = .d if `w'_cjob==2 & `w'_currstat1==2 & `w'_nxtjbendy4<0
         replace `startyear' = .f if `w'_ff_jbstat<0 & `w'_ff_ivlolw==1 & `startyear'==.
         replace `startyear' = .g if inlist(`w'_empchk, -9,-2,-1) & `startyear'==.
         replace `startyear' = .g if inlist(`w'_notempchk, -9, -2, -1) & `startyear'==.
         replace `startyear' = .v if inlist(`w'_nxtst, -9, -2, -1) & `startyear'==.

             forval i = 2/10 {
             local j = `i'-1
             replace `startyear' = .e if `w'_currstat`i'==2 & `w'_statendy4`j'<0
             replace `startyear' = .e if `w'_currjob`i'==1 & `w'_statendy4`j'<0
             }
             replace `startyear' = .v if `startyear'==.


         label define `startmonth' .a "empstendm invalid" .b "jbendm invalid" .c "nxtstendm invalid" .d "nxtjbendm invalid" .e "statendm invalid" .f "ff_jbstat invalid" ///
                                   .g "empchk/notempchk invalid" ///
                                   .v "other routing variables invalid" .w "proxy interview" .x "never interviewed but not asked right questions" .y "started spell b4 previous interview"
         label values `startmonth' `startmonth'
         replace `startmonth' = .w if `b4prevint'==.a /*proxies*/
         replace `startmonth' = .y if `w'_ff_ivlolw~=1 & `startmonth'==.
         replace `startmonth' = .a if `w'_cstat==2 & `w'_empstendm<0
         replace `startmonth' = .a if `w'_cjob==1  &  (`w'_notempchk==2|`w'_empchk==2) &  `w'_empstendm<0
         replace `startmonth' = .b if `w'_cjob==1  & ~(`w'_notempchk==2|`w'_empchk==2) &  `w'_jbendm<0
         replace `startmonth' = .c if `w'_cstat==1 & `w'_currjob1==1 & `w'_nxtstendm<0
         replace `startmonth' = .d if `w'_cjob==2 & `w'_currjob1==1 & `w'_nxtjbendm<0
         replace `startmonth' = .c if `w'_cstat==1 & `w'_currstat1==2 & `w'_nxtstendm<0
         replace `startmonth' = .d if `w'_cjob==2 & `w'_currstat1==2 & `w'_nxtjbendm<0
         replace `startmonth' = .f if `w'_ff_jbstat<0 & `w'_ff_ivlolw==1 & `startmonth'==.
         replace `startmonth' = .g if inlist(`w'_empchk, -9,-2,-1) & `startmonth'==.
         replace `startmonth' = .g if inlist(`w'_notempchk, -9, -2, -1) & `startmonth'==.
         replace `startmonth' = .v if inlist(`w'_nxtst, -9, -2, -1) & `startmonth'==.

             forval i = 2/10 {
             local j = `i'-1
             replace `startmonth' = .e if `w'_currstat`i'==2 & `w'_statendm`j'<0
             replace `startmonth' = .e if `w'_currjob`i'==1 & `w'_statendm`j'<0

                }
                replace `startmonth' = .v if `startmonth'==.

         label define `startday' .a "empstendd invalid" .b "jbendd invalid" .c "nxtstendd invalid" .d "nxtjbendd invalid" .e "statendd invalid" .f "ff_jbstat invalid" ///
                                  .g "empchk/notempchk invalid" ///
                                  .v "other routing variables invalid" .w "proxy interview" .x "never interviewed but not asked right questions" .y "started spell b4 previous interview"
         label values `startday' `startday'
         replace `startday' = .w if `b4prevint'==.a /*proxies*/
         replace `startday' = .x if `w'_ff_ivlolw~=1 & `startday'==.
         replace `startday' = .a if `w'_cstat==2 & `w'_empstendd<0 & `startday'==.
         replace `startday' = .a if `w'_cjob==1  &  (`w'_notempchk==2|`w'_empchk==2) &  `w'_empstendd<0  & `startday'==.
         replace `startday' = .b if `w'_cjob==1  & ~(`w'_notempchk==2|`w'_empchk==2) &  `w'_jbendd<0  & `startday'==.
         replace `startday' = .c if `w'_cstat==1 & `w'_currjob1==1 & `w'_nxtstendd<0  & `startday'==.
         replace `startday' = .d if `w'_cjob==2 & `w'_currjob1==1 & `w'_nxtjbendd<0 & `startday'==.
         replace `startday' = .c if `w'_cstat==1 & `w'_currstat1==2 & `w'_nxtstendd<0  & `startday'==.
         replace `startday' = .d if `w'_cjob==2 & `w'_currstat1==2 & `w'_nxtjbendd<0  & `startday'==.
         replace `startday' = .f if `w'_ff_jbstat<0 & `w'_ff_ivlolw==1 & `startday'==.  & `startday'==.
         replace `startday' = .g if inlist(`w'_empchk, -9,-2,-1) & `startday'==.  & `startday'==.
         replace `startday' = .g if inlist(`w'_notempchk, -9, -2, -1) & `startday'==.  & `startday'==.
         replace `startday' = .v if inlist(`w'_nxtst, -9, -2, -1) & `startday'==.  & `startday'==.

             forval i = 2/10 {
             local j = `i'-1
             replace `startday' = .e if `w'_currstat`i'==2 & `w'_statendm`j'<0  & `startday'==.
             replace `startday' = .e if `w'_currjob`i'==1 & `w'_statendm`j'<0  & `startday'==.

                }
                replace `startday' = .u if `startday'==.

                /*for people never interviewed*/
                label define `startyear' .h "jbbgy invalid" .i "jblendy invalid" .j "jbhad invalid" .k "invalid education leaving age" .l "unknown currstat" ///
                                         .u "still in education", add
                label values `startyear' `startyear'

                replace `startyear' = .h if (`currstat'==1|`currstat'==2) & `w'_jbbgy<0 & `startyear'==.x
                replace `startyear' = .u if `currstat'==0 & (`w'_jbhad==2|`w'_jbhad<0) & (`w'_school==3|`w'_fenow==3) & `w'_dvage<=30 & `startyear'==.x
                replace `startyear' = .i if `currstat'==0 & `w'_jbhad==1 & `w'_jlendy<0 & `startyear'==.x
                replace `startyear' = .w if `currstat'==0 & `w'_jbhad==-7  & `startyear'==.x
                replace `startyear' = .j if `currstat'==0 & `w'_jbhad<0  & `startyear'==.x
                replace `startyear' = .k if `currstat'==0 & `w'_jbhad==2 & ~(`w'_school==3|`w'_fenow==3) & `startyear'==.x
                replace `startyear' = .l if `currstat'>=. & `startyear'==.x

                label define `startmonth' .h "jbbgm invalid" .i "jlendm invalid" .j "jbhad invalid" .k "invalid education leaving age" .l "unknown currstat" ///
                                          .u "still in education", add
                label values startmonth startmonth

                replace `startmonth' = .h if (`currstat'==1|`currstat'==2) & `w'_jbbgm<0 & `startmonth'==.x
                replace `startmonth' = .u if `currstat'==0 & (`w'_jbhad==2|`w'_jbhad<0) & (`w'_school==3|`w'_fenow==3) & `w'_dvage<=30 & `startmonth'==.x
                replace `startmonth' = .i if `currstat'==0 & `w'_jbhad==1 & `w'_jlendm<0  & `startmonth'==.x
                replace `startmonth' = .w if `currstat'==0 & `w'_jbhad==-7 & `startmonth'==.x
                replace `startmonth' = .j if `currstat'==0 & `w'_jbhad<0   & `startmonth'==.x
                replace `startmonth' = .k if `currstat'==0 & `w'_jbhad==2 & ~(`w'_school==3|`w'_fenow==3) & `startmonth'==.x
                replace `startmonth' = .l if `currstat'>=. & `startyear'==.x

                label define `startday' .h "jbbgm invalid" .i "jlendm invalid" .j "jbhad invalid"  .k "invalid education leaving age" .l "unknown currstat" ///
                                        .u "still in education", add
                label values `startday' `startday'
                replace `startday' = `startmonth' if `startmonth'>=. & (`startday'==.|`startday'==.x)


        } /*if mindic*/
    }

    }
end



* spelltype 1 year ago

**********************
/*
program define indresp_currstatly, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars currstatly(name) intdate(varname) currstat(varname) startday(varname) startmonth(varname) startyear(varname) b4prevint(varname) ivfio(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
    }
    else {

        if "`currstatly'" == "" local currstatly "currstatly"
        if "`intdate'" == "" local intdate "intdate"
        if "`currstat'" == "" local currstat "currstat"
        if "`startday'" == "" local startday "startday"
        if "`startmonth'" == "" local startmonth "startmonth"
        if "`startyear'" == "" local startyear "startyear"
        if "`b4prevint'" == "" local b4prevint "b4prevint"
        if "`ivfio'" == "" local ivfio "ivfio"

*        tempvar b4ly

        qui gen byte b4ly = 1 if `intdate' < . & ((`startyear' < year(`intdate') - 1) | (`startyear' == year(`intdate') - 1 & `startmonth' < month(`intdate')) | (`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startday' <= day(`intdate')) | `b4prevint' == 1)
        qui replace b4ly  = 0 if `startyear' < . & ((`startyear' > year(`intdate') - 1) | (`startyear' == year(`intdate') - 1 & `startmonth' > month(`intdate') & `startmonth' < .) | (`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startmonth' < . & `startday' > day(`intdate') & `startday' < .))

        * First, do the easy cases: those whose status goes back more than a year, or doesn't and there's no way of finding out about it

        preserve
        qui keep if (b4ly == 1 | `ivfio' == 2 | (`ivfio' == 3 & `wave' <= 14))

        * I asssume that people whose startday is missing were doing the activity relevant for the month in question
        qui gen byte `spelltypely' = `spelltype' if b4ly == 1 | (b4ly >= . & intdate < . & `startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startday' >= .)

        if "`mindic'" == "mindic" {
            qui replace `spelltypely' = .a if `spelltype' >= . & `spelltypely' == .
            qui replace `spelltypely' = .b if `spelltype' < . & b4ly == 0 & inlist(`ivfio',2,3) & `spelltypely' == .
            qui replace `spelltypely' = .c if `spelltype' < . & b4ly >= . & intdate < . & !(`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startday' >= .) & inlist(`ivfio',2,3) & `spelltypely' == .
            assert (`spelltypely' != .)
            label define `spelltypely' .a "spelltype missing/unknown" .b "Proxy/phone response" .c "startdate missing"  .d "Wave 17+ (still needs coding)"
            label values `spelltypely' `spelltypely'
        }

        tempfile easydata
        qui save `easydata'

        restore

        qui keep if (b4ly != 1 & (`ivfio' == 1 | (`ivfio' == 3 & `wave' >= 15)))

        tempfile harddata
        sort pid
        qui save `harddata'
        keep pid `spelltype' `intdate' `startday' `startmonth' `startyear' `b4septly' b4ly
        tempfile harddatafew
        qui save `harddatafew'


        * merge in jobhist data

        local rawvars "`w'hid `w'pno `w'jspno pid `w'jha9ly"
        foreach drvdvar in spelltype spellstart b4septly {
            jobhist_`drvdvar', wave(`wave') whatvars
            local rawvars "`rawvars' `r(vars)'"
        }

        local rawvars : list uniq rawvars
        qui use `rawvars' using "$data\\`w'jobhist.dta", clear

        jobhist_spelltype,     wave(`wave') spelltype(`spelltype')
        jobhist_spellstart,    wave(`wave') startday(`startday') startmonth(`startmonth') startyear(`startyear')

        * delete any spells with the same start date
        qui bysort pid `startyear' `startmonth' `startday' (`w'jspno): gen byte todrop = _n > 1 & `startday' < . & `startmonth' < . & `startyear' < .
        qui drop if todrop
        drop todrop
        qui bysort pid (`w'jspno): replace `w'jspno = _n

        * there's a problem with two spells - same start dates, both b4septly
        jobhist_b4septly,      wave(`wave')  b4septly(`b4septly') startd(`startday') startm(`startmonth') starty(`startyear')
        *keep pid `w'jspno `spelltype' `startday' `startmonth' `startyear' `b4septly'
        keep pid `w'jspno `spelltype' `startday' `startmonth' `startyear' `b4septly'

        * sort cases where there is more than one spell before septly
        qui bysort pid (`w'jspno): gen byte numb4septly = sum(`b4septly')
        qui drop if (numb4septly > 1) | (`b4septly' == 0 & numb4septly == 1)
        drop numb4septly

        * At this point: some individuals may have no b4septly spell. No one should have more than one.


        qui append using `harddatafew'
        qui replace `w'jspno = 0 if `w'jspno >= .
        egen byte minspellno = min(`w'jspno), by(pid)
        qui drop if minspellno > 0
        drop minspellno
        qui bysort pid (`w'jspno): replace `intdate' = `intdate'[1] if _n > 1
        qui replace b4ly = 1 if `w'jspno > 0 & `intdate' < . & ((`startyear' < year(`intdate') - 1) | (`startyear' == year(`intdate') - 1 & `startmonth' < month(`intdate')) | (`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startday' <= day(`intdate')) | `b4septly' == 1)
        qui replace b4ly = 0 if `w'jspno > 0 & `startyear' < . & ((`startyear' > year(`intdate') - 1) | (`startyear' == year(`intdate') - 1 & `startmonth' > month(`intdate') & `startmonth' < .) | (`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startmonth' < . & `startday' > day(`intdate') & `startday' < .))


        * Need to deal with cases where appending has created duplicated spells (again)
        qui bysort pid `startyear' `startmonth' `startday' (`w'jspno): gen byte todrop = _n > 1 & `startday' < . & `startmonth' < . & `startyear' < .
        qui drop if todrop
        drop todrop
        qui bysort pid (`w'jspno): replace `w'jspno = _n

        * Drop spells where dates are out of order
        local exit = 0
        local i = 1
        while !`exit' {
            qui bysort pid (`w'jspno): gen byte todrop = ((`startyear' > `startyear'[_n-1] & `startyear' < .) | ((`startyear' == `startyear'[_n-1] & `startyear' < .) & (`startmonth' > `startmonth'[_n-1] & `startmonth' < .)) | ((`startyear' == `startyear'[_n-1] & `startyear' < .) & (`startmonth' == `startmonth'[_n-1] & `startmonth' < .) & (`startday' > `startday'[_n-1] & `startday' < .))) & _n > 1
            su todrop, meanonly
            if r(max) == 1 qui drop if todrop
            else local exit = 1
            drop todrop
            local ++i
            if `i' > 6 {
                di as error "More than 6 loops required - check this"
                crash
            }
        }

        * Create an indicator for active spell one year before interview
        qui bysort pid (`w'jspno): gen byte active = sum(b4ly == 1)
        qui replace active = 0 if active > 1
        qui replace active = 1 if b4ly >= .
        egen byte problem = total(active == 1), by(pid)
        qui replace problem = (problem != 1)

        * When there is uncertainty over which is the active spell, is the spelltype the same?
        qui egen byte minspelltype = min(`spelltype') if active & problem, by(pid active)
        qui egen byte maxspelltype = max(`spelltype') if active & problem, by(pid active)

        * If minspelltype and maxspelltype are the same, then we have no problem - choose the earlier one
        qui by pid (`w'jspno): gen byte activesum = sum(active)
        qui replace active = 0 if activesum > 1 & minspelltype == maxspelltype & active & problem
        drop activesum problem minspelltype maxspelltype
        egen byte problem = total(active == 1), by(pid)
        qui replace problem = (problem != 1)

        * Identify cases where the problem is uncertainty over the day of the month the spell started
        gen byte dayunclear = b4ly >= . & `intdate' < . & (`startyear' == year(`intdate') - 1 & `startmonth' == month(`intdate') & `startday' >= .) & problem
        qui by pid (`w'jspno): gen byte dayunclearsum = sum(dayunclear)
        qui replace dayunclear = 0 if dayunclearsum > 1 & problem
        egen byte fixed = max(dayunclear), by(pid)
        qui replace active = 0 if active == 1 & dayunclear == 0 & fixed
        qui replace problem = 0 if fixed
        qui replace active = 0 if problem == 1
        drop problem dayunclear dayunclearsum fixed

        qui gen byte temp = `spelltype' if active
        qui egen byte `spelltypely' = min(temp), by(pid)
        drop temp

        if "`mindic'" == "mindic" qui replace `spelltypely' = .c if `spelltypely' >= .
        keep pid `spelltypely'

        qui by pid: keep if _n == 1
        sort pid
        qui save `harddatafew', replace

        qui use `harddata'
        merge pid using `harddatafew', unique
        assert _merge == 3
        drop _merge
        qui save `harddata', replace
        use `easydata', clear
        qui append using `harddata'
        sort pid


        if "`mindic'" == "mindic" {
            assert (`spelltypely' != .)
        }
        label define `spelltypely' 1 "Employment" 2 "Self-employment" 3 "Unemployment" 4 "Retirement" 5 "Maternity leave" 6 "Family care" 7 "Full-time education" 8 "Long-term sickness/disablement" 9 "Government training scheme" 10 "Other", add
        label variable `spelltypely' "spelltype 1 year ago"
        label values `spelltypely' `spelltypely'

    }

end
**/



* Cross-sectional weights
*************************

* I'm not sure whether you are supposed to use cross-sectional weights when data is pooled across years...but this is exactly what I am doing!

program define indresp_rxwgt, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars rxwgt(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if `wave'==1  return local vars "`w'_indinus_xw"
        if inrange(`wave',2,5)  return local vars "`w'_indinub_xw"
        if `wave'>=6 & `wave'<14 return local vars "`w'_indinui_xw"
		if `wave'>=14 return local vars "`w'_inding2_xw"
    }
    else {

        if "`rxwgt'" == "" local rxwgt "rxwgt"

        if `wave'==1  qui gen double `rxwgt' = `w'_indinus_xw
        if inrange(`wave',2,5)  qui gen double `rxwgt' = `w'_indinub_xw
        if `wave'>=6 & `wave'<14  qui gen double `rxwgt' = `w'_indinui_xw
		if `wave'>=14  qui gen double `rxwgt' = `w'_inding2_xw
        *need to select weight for wave 6 when IEMBS sample is included (see US User Guide)

        assert (`rxwgt' >= 0 & `rxwgt' < .)
        label variable `rxwgt' "Cross-sectional respondent weight"

    }

end


/*
* Program to deal with variables merged in from previous waves (some observations won't have been interviewed)
**************************************************************************************************************

program define fixfornoint

    syntax varname, mergevar(varname) [drop]
    local varname "`varlist'_m"

    qui count if `mergevar' == 1
    if r(N) > 0 {
        capture confirm variable `varname'
        if _rc {
            gen byte `varname' = (`mergevar' == 1)
            label define `varname' 0 "Non-missing" 1 "Not interviewed in both waves"
            label values `varname' `varname'
        }
        else {
            qui su `varname'
            qui replace `varname' = r(max) + 1 if `mergevar' == 1
            label define `varname' `=r(max)+1' "Not interviewed in both waves", modify
        }
        assert (`varlist' < .) + (`varname' > 0 & `varname' < .) == 1
        if "`drop'" == "drop" drop `mergevar'
    }
    else {
        capture confirm variable `varname'
        if _rc {
            assert (`varlist' < .)
        }
        else {
            assert (`varlist' < .) + (`varname' > 0 & `varname' < .) == 1
        }
    }

end
*/



* Identify individuals who are working in the same job as last year
*******************************************************************

* Depends on labour market status, intdate13 and startdate (and whether they were interviewed last year)
/*
program define indresp_samejob, rclass

    syntax [, samejob(name) spelltype(varname) spelltypeoth(varname) jb1status(varname) jb1statusoth(varname) startday(varname) startmonth(varname) startyear(varname) b4septly(varname) previntdate(varname) mergevar(varname) mindic]

    if "`samejob'" == "" local samejob "samejob"
    if "`spelltype'" == "" local spelltype "spelltype"
    if "`spelltypeoth'" == "" local spelltypeoth "spelltypeoth"
    if "`jb1status'" == "" local jb1status "jb1status"
    if "`jb1statusoth'" == "" local jb1statusoth "jb1statusoth"
    if "`startday'" == "" local startday "startday"
    if "`startmonth'" == "" local startmonth "startmonth"
    if "`startyear'" == "" local startyear "startyear"
    if "`b4septly'" == "" local b4septly "b4septly"
    if "`previntdate'" == "" local previntdate "previntdate"
    if "`mergevar'" == "" local mergevar "mergevar"

    qui gen byte `samejob' = 1 if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & ((`startyear' < year(`previntdate')) | (`startyear' == year(`previntdate') & `startmonth' < month(`previntdate')) | (`startyear' == year(`previntdate') & `startmonth' == month(`previntdate') & `startday' < day(`previntdate'))) & `previntdate' < .
    qui replace `samejob' = 1 if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & `b4septly' == 1
    qui replace `samejob' = 0 if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & ((`startyear' > year(`previntdate') & `startyear' < .) | (`startyear' == year(`previntdate') & `startmonth' > month(`previntdate') & `startmonth' < .) | (`startyear' == year(`previntdate') & `startmonth' == month(`previntdate') & `startday' >= day(`previntdate') & `startday' < .))
    label variable `samejob' "Same job held in both waves"

    if "`mindic'" == "mindic" {
        qui replace `samejob' = .a if `mergevar' == 1 & `samejob' == .
        qui replace `samejob' = .b if inrange(`spelltype',3,10) & `mergevar' == 3 & `samejob' == .
        qui replace `samejob' = .c if `spelltype' >= . & `mergevar' == 3 & `samejob' == .
        qui replace `samejob' = .d if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & `mergevar' == 3 & `previntdate' >= . & `b4septly' != 1 & `samejob' == .
        qui replace `samejob' = .e if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & `mergevar' == 3 & `previntdate' < . & `startyear' >= . & `b4septly' != 1 & `samejob' == .
        qui replace `samejob' = .f if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & `mergevar' == 3 & `previntdate' < . & `startyear' == year(`previntdate') & `startmonth' >= . & `b4septly' != 1 & `samejob' == .
        qui replace `samejob' = .g if inlist(`spelltype',1,2) & (`spelltype' == `spelltypeoth' & `spelltype' == `jb1status' & `spelltype' == `jb1statusoth') & `mergevar' == 3 & `previntdate' < . & `startyear' == year(`previntdate') & `startmonth' == month(`previntdate') & `startday' >= . & `b4septly' != 1 & `samejob' == .
        qui replace `samejob' = .h if inlist(`spelltype',1,2) & (`spelltype' != `spelltypeoth' | `spelltype' != `jb1status' | `spelltype' != `jb1statusoth') & `mergevar' == 3 & `samejob' == .

        assert (`samejob' != .)
        label define `samejob' .a "Not interviewed in both years" .b "Not working" .c "spelltype missing" .d "previntdate missing" .e "startmonth missing" .f "startmonth missing" .g "startday missing" .h "spelltype, spelltypeoth, jb1status and jb1statusoth inconsistent"
        label values `samejob' `samejob'
    }

end
*/





* Days between interviews
*************************
/*
program define indresp_daysbetwint, rclass

    syntax [, daysbetwint(name) previntdate(varname) intdate(varname) mergevar(varname) mindic]
    if "`daysbetwint'" == "" local daysbetwint "daysbetwint"
    if "`previntdate'" == "" local previntdate "previntdate"
    if "`intdate'" == "" local intdate "intdate"
    if "`mergevar'" == "" local mergevar "mergevar"

    assert `intdate' > `previntdate' if `previntdate' < .
    qui gen int `daysbetwint' = `intdate' - `previntdate'
    label variable `daysbetwint' "Number of days between interviews"

    if "`mindic'" == "mindic" {
        qui replace `daysbetwint' = .a if `mergevar' == 1 & `daysbetwint' == .
        qui replace `daysbetwint' = .b if `mergevar' == 3 & `previntdate' >= . & `daysbetwint' == .
        qui replace `daysbetwint' = .c if `mergevar' == 3 & `previntdate' < . & `intdate' >= . & `daysbetwint' == .
        assert (`daysbetwint' != .)
        label define `daysbetwint' .a "Not interviewed in both years" .b "previntdate missing" .c "intdate missing"
        label values `daysbetwint' `daysbetwint'
    }

end
*/



* Days worked between interviews
********************************

* Note: the wave() option relates to the LATER wave (not the earlier one)
/*
program define indresp_daysworked, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars daysworked(name) daysunemp(name) previntdate(varname) intdate(varname) spelltype(varname) startday(varname) startmonth(varname) startyear(varname) b4septly(varname) b4prevint(varname) daysbetwint(varname) ivfio(varname) mergevar(varname) work unemp mindic]
    local w = char(96+`wave')

    foreach var in daysworked daysunemp previntdate intdate spelltype startday startmonth startyear b4septly b4prevint daysbetwint ivfio mergevar {
        if "``var''" == "" local `var' "`var'"
    }
    if "`work'" == "" & "`unemp'" == "" {
        local work "work"
        local unemp "unemp"
    }

    * Deal first with observations where current activity goes back before previous interview, or we have no information
    preserve
*    qui keep if (`b4prevint' == 1 | `mergevar' != 3 | inlist(`ivfio',2,3))
    qui keep if (`b4prevint' == 1 | `mergevar' != 3 | `ivfio' == 2 | (`ivfio' == 3 & `wave' <= 14))

    if "`work'" == "work" {
        * If activity goes back before last interview, do 0/daysbetwint on basis of current activity
        qui gen int `daysworked' = `daysbetwint' if `b4prevint' == 1 & inlist(`spelltype',1,2)
        qui replace `daysworked' = 0 if `b4prevint' == 1 & inrange(`spelltype',3,10)
        if "`mindic'" == "mindic" {
            qui replace `daysworked' = .a if `b4prevint' == 1 & (`spelltype'==11 | `spelltype' >=.)
            qui replace `daysworked' = .b if `b4prevint' == 1 & inlist(`spelltype',1,2) & `daysbetwint' >= .
            qui replace `daysworked' = .c if `b4prevint' != 1 & `mergevar' != 3
            qui replace `daysworked' = .d if `b4prevint' != 1 & `mergevar' == 3 & inlist(`ivfio',2,3)
            label define `daysworked' .a "spelltype missing/unknown " .b "daysbetwint missing" .c "Not interviewed in both waves" .d "Proxy/phone response" .h "Wave 17+ (not yet coded)"
            label values `daysworked' `daysworked'
        }
    }
    if "`unemp'" == "unemp" {
        qui gen int `daysunemp' = `daysbetwint' if `b4prevint' == 1 & inlist(`spelltype',3,4,6,8)
        qui replace `daysunemp' = 0 if `b4prevint' == 1 & inlist(`spelltype',1,2,5,7,9,10)
        if "`mindic'" == "mindic" {
            qui replace `daysunemp' = .a if `b4prevint' == 1 & (`spelltype'==11 | `spelltype' >=.)
            qui replace `daysunemp' = .b if `b4prevint' == 1 & inlist(`spelltype',3,4,6,8) & `daysbetwint' >= .
            qui replace `daysunemp' = .c if `b4prevint' != 1 & `mergevar' != 3
            qui replace `daysunemp' = .d if `b4prevint' != 1 & `mergevar' == 3 & inlist(`ivfio',2,3)
            label define `daysunemp' .a "spelltype missing/unknown" .b "daysbetwint missing" .c "Not interviewed in both waves" .d "Proxy/phone response" .h "Wave 17+ (not yet coded)"
            label values `daysunemp' `daysunemp'
        }
    }

    tempfile b4previntdata
    qui save `b4previntdata', replace


    * Now deal with the observations where the current activity (probably) doesn't go back before previous interview, but we know about earlier activities (i.e. they were full interviewed in later wave)
    restore
*   qui keep if (`b4prevint' != 1 & `mergevar' == 3 & `ivfio' == 1)
    qui keep if (`b4prevint' != 1 & `mergevar' == 3 & (`ivfio' == 1 | (`ivfio' == 3 & `wave' >= 15)))
    tempfile notb4previntdata
    sort pid
    qui save `notb4previntdata', replace
    keep pid `spelltype' `previntdate' `intdate' `startday' `startmonth' `startyear' `b4septly'
    tempfile notb4previntdatafew
    qui save `notb4previntdatafew', replace


    * merge in jobhist data

    local rawvars "`w'hid `w'pno `w'jspno pid `w'jha9ly"
    foreach drvdvar in spelltype spellstart b4septly {
        jobhist_`drvdvar', wave(`wave') whatvars
        local rawvars "`rawvars' `r(vars)'"
    }

    local rawvars : list uniq rawvars
    qui use `rawvars' using "$data\\`w'jobhist.dta", clear

    jobhist_spelltype,     wave(`wave') spelltype(`spelltype')
    jobhist_spellstart,    wave(`wave') startday(`startday') startmonth(`startmonth') startyear(`startyear')

    * delete any spells with the same start date
    qui bysort pid `startyear' `startmonth' `startday' (`w'jspno): gen byte todrop = _n > 1 & `startday' < . & `startmonth' < . & `startyear' < .
    qui drop if todrop
    drop todrop
    qui bysort pid (`w'jspno): replace `w'jspno = _n

    * there's a problem with two spells - same start dates, both b4septly
    jobhist_b4septly,      wave(`wave')  b4septly(`b4septly') startd(`startday') startm(`startmonth') starty(`startyear')
    keep pid `w'jspno `spelltype' `startday' `startmonth' `startyear' `b4septly'

    * sort cases where there is more than one spell before septly
    qui bysort pid (`w'jspno): gen byte numb4septly = sum(`b4septly')
    qui drop if (numb4septly > 1) | (`b4septly' == 0 & numb4septly == 1)
    drop numb4septly

    * At this point: some individuals may have no b4septly spell. No one should have more than one.


    qui append using `notb4previntdatafew'
    qui replace `w'jspno = 0 if `w'jspno >= .
    egen byte minspellno = min(`w'jspno), by(pid)
    qui drop if minspellno > 0
    drop minspellno
    qui bysort pid (`w'jspno): replace `previntdate' = `previntdate'[1] if _n > 1
    qui bysort pid (`w'jspno): replace `intdate' = `intdate'[1] if _n > 1

    * Need to deal with cases where appending has created duplicated spells (again)
    qui bysort pid `startyear' `startmonth' `startday' (`w'jspno): gen byte todrop = _n > 1 & `startday' < . & `startmonth' < . & `startyear' < .
    qui drop if todrop
    drop todrop
    qui bysort pid (`w'jspno): replace `w'jspno = _n

    * Drop spells where dates are out of order
    local exit = 0
    local i = 1
    while !`exit' {
        qui bysort pid (`w'jspno): gen byte todrop = ((`startyear' > `startyear'[_n-1] & `startyear' < .) | ((`startyear' == `startyear'[_n-1] & `startyear' < .) & (`startmonth' > `startmonth'[_n-1] & `startmonth' < .)) | ((`startyear' == `startyear'[_n-1] & `startyear' < .) & (`startmonth' == `startmonth'[_n-1] & `startmonth' < .) & (`startday' > `startday'[_n-1] & `startday' < .))) & _n > 1
        su todrop, meanonly
        if r(max) == 1 qui drop if todrop
        else local exit = 1
        drop todrop
        local ++i
        if `i' > 6 {
            di as error "More than 6 loops required - check this"
            crash
        }
    }

    * One dodgy case in wave 8 (spells out of order, confused by missing day for spell in between)
    if (`wave' == 8) {
        qui drop if pid == 11772417 & inlist(`w'jspno,4,5)
        qui replace `w'jspno = `w'jspno - 2 if pid == 11772417 & inlist(`w'jspno,6,7)
    }

    * create min and max start dates
    indresp_minandmaxdate, mindate(minstartdate2) maxdate(maxstartdate2) day(`startday') month(`startmonth') year(`startyear')

    * deal with cases where maxstartdate2 is after the interview date
    qui replace maxstartdate2 = `intdate' if maxstartdate2 > `intdate' & maxstartdate2 < .
    * for b4septly cases, even the maxstartdate2 must be before this date
    qui replace maxstartdate2 = mdy(9,1,`wave'+1989) if maxstartdate2 > mdy(9,1,`wave'+1989) & `b4septly' == 1 & maxstartdate2 < .
    qui gen long newmax = .
    qui bysort pid (`w'jspno): replace newmax = cond(maxstartdate2[_n-1]<.,maxstartdate2[_n-1],newmax[_n-1])
    format %td newmax
    qui by pid (`w'jspno): replace maxstartdate2 = newmax if maxstartdate2 > newmax & maxstartdate2 < . & _n > 1
    drop newmax
    qui replace minstartdate2 = maxstartdate2 if minstartdate2 > maxstartdate2 & minstartdate < .

    * deal with cases where minstartdate2 is before september last year and it is not the b4septly spell
    qui replace minstartdate2 = mdy(9,2,`wave'+1989) if minstartdate2 < mdy(9,2,`wave'+1989) & `b4septly' == 0
    * now make sure dates are in descending order
    qui by pid (`w'jspno): gen byte `w'jspnoback = _N - `w'jspno - 1
    qui gen long newmin = .
    qui bysort pid (`w'jspnoback): replace newmin = cond(minstartdate2[_n-1]<.,minstartdate2[_n-1],newmin[_n-1])
    format %td newmin
    qui by pid (`w'jspnoback): replace minstartdate2 = newmin if minstartdate2 < newmin & newmin < . & _n > 1
    drop newmin `w'jspnoback
    sort pid `w'jspno
    assert minstartdate2 <= maxstartdate2

    * get midpoint of uncertain range
    qui gen long startdate2 = int((minstartdate2 + maxstartdate2)/2)
    format %td startdate2
    drop minstartdate2 maxstartdate2

    * end date
    qui by pid (`w'jspno): gen long enddate2 = startdate[_n-1]
    qui by pid (`w'jspno): replace enddate2 = `intdate' if _n == 1
    format %td enddate2

    * There are a very small number of cases where b4septly is missing. These come from windresp.



    * identify individuals whose history doesn't go back before the previous interview date
    egen byte noneb4lastint = min(startdate2 > `previntdate' | `previntdate' >= .), by(pid)
    egen byte missingtemp = max(startdate2 >= . & (enddate2 > `previntdate' | `previntdate' >= .)), by(pid)
    * Missing startdate2 does not matter if end date is before previntdate
    * It also does not matter if it is part of a string of the same type of spell (e.g. two employment spells, the later of which is missing a start date) - I haven't resolved this one yet


    if "`work'" == "work" {
        * now calculate number of days working for each spell
        qui gen int `daysworked' = 0 if inrange(`spelltype',3,10)
        qui replace `daysworked' = max(enddate2 - max(startdate2,`previntdate'), 0) if enddate2 < . & startdate2 < . & `previntdate' < . & inlist(`spelltype',1,2)
        egen byte missing = max(`daysworked' >= . | (`spelltype'==11 | `spelltype' >=.)), by(pid)
        qui egen int totdaysworked = total(`daysworked'), by(pid)
        qui replace totdaysworked = . if missing
        drop missing `daysworked'
        rename totdaysworked `daysworked'

        if "`mindic'" == "mindic" {
            qui replace `daysworked' = .e if (`spelltype' == 11 | `spelltype' >= .) & `daysworked' == .
            qui egen byte min`daysworked' = min(`daysworked') if (`daysworked' > .), by(pid)
            qui bys pid (min`daysworked'): replace `daysworked' = min`daysworked'[_N] if min`daysworked'[_N] > .
            drop min`daysworked'
            qui replace `daysworked' = .f if (startdate2 >= . | enddate2 >= .) & inlist(`spelltype',1,2) & `daysworked' == .
            qui egen byte min`daysworked' = min(`daysworked') if (`daysworked' > .), by(pid)
            qui bys pid (min`daysworked'): replace `daysworked' = min`daysworked'[_N] if min`daysworked'[_N] > .
            drop min`daysworked'
            qui replace `daysworked' = .f if missingtemp /*& `daysworked' == .*/
            qui replace `daysworked' = .g if noneb4lastint /*& `daysworked' == .*/

            assert (`daysworked' != .)
        }
    }
    if "`unemp'" == "unemp" {

        * now calculate number of days unemployed for each spell
        qui gen int `daysunemp' = 0 if inlist(`spelltype',1,2,5,7,9,10)
        qui replace `daysunemp' = max(enddate2 - max(startdate2,`previntdate'), 0) if enddate2 < . & startdate2 < . & `previntdate' < . & inlist(`spelltype',3,4,6,8)
        egen byte missing = max(`daysunemp' >= . | (`spelltype'==11 | `spelltype' >=.)), by(pid)
        qui egen int totdaysunemp = total(`daysunemp'), by(pid)
        qui replace totdaysunemp = . if missing
        drop missing `daysunemp'
        rename totdaysunemp `daysunemp'

        if "`mindic'" == "mindic" {
            qui replace `daysunemp' = .e if (`spelltype'==11 | `spelltype' >=.) & `daysunemp' == .
            qui egen byte min`daysunemp' = min(`daysunemp') if (`daysunemp' > .), by(pid)
            qui bys pid (min`daysunemp'): replace `daysunemp' = min`daysunemp'[_N] if min`daysunemp'[_N] > .
            drop min`daysunemp'
            qui replace `daysunemp' = .f if (startdate2 >= . | enddate2 >= .) & inlist(`spelltype',3,4,6,8) & `daysunemp' == .
            qui egen byte min`daysunemp' = min(`daysunemp') if (`daysunemp' > .), by(pid)
            qui bys pid (min`daysunemp'): replace `daysunemp' = min`daysunemp'[_N] if min`daysunemp'[_N] > .
            drop min`daysunemp'
            qui replace `daysunemp' = .f if missingtemp /*& `daysunemp' == .*/
            qui replace `daysunemp' = .g if noneb4lastint /*& `daysunemp' == .*/

            assert (`daysunemp' != .)
        }
    }
    if "`work'" == "work" {
        if "`unemp'" == "unemp" keep pid `daysworked' `daysunemp'
        else keep pid `daysworked'
    }
    else keep pid `daysunemp'

    qui by pid: keep if _n == 1
    qui merge pid using `notb4previntdata', unique
    assert _merge == 3
    drop _merge
    qui save `notb4previntdata', replace
    use `b4previntdata', clear
    qui append using `notb4previntdata'
    sort pid


    if "`work'" == "work" {
        label variable `daysworked' "No. of days worked since previous interview"
        if "`mindic'" == "mindic" {
            assert (`daysworked' != .)
            label define `daysworked' .e "spelltype missing" .f "startyear missing" .g "No spell before previous interview", add
            label values `daysworked' `daysworked'
        }
    }
    if "`unemp'" == "unemp" {
        label variable `daysunemp' "No. of days unemployed (not training) since previous interview"
        if "`mindic'" == "mindic" {
            assert (`daysunemp' != .)
            label define `daysunemp' .e "spelltype missing" .f "startyear missing" .g "No spell before previous interview", add
            label values `daysunemp' `daysunemp'
        }
    }

end
*/


* Hours worked between interviews
*********************************
/*
program define indresp_jb1annualhrsot, rclass

    syntax [, jb1annualhrsot(name) jb1status(varname) jb1hrsot1(varname) jb1hrsot2(varname) previntdate(varname) intdate(varname) samejob(varname) mergevar(varname) mindic]
    if "`jb1annualhrsot'" == "" local jb1annualhrsot "jb1annualhrsot"
    if "`jb1status'" == "" local jb1status "jb1status"
    if "`jb1hrsot1'" == "" local jb1hrsot1 "jb1hrsot1"
    if "`jb1hrsot2'" == "" local jb1hrsot2 "jb1hrsot2"
    if "`previntdate'" == "" local previntdate "previntdate"
    if "`intdate'" == "" local intdate "intdate"
    if "`samejob'" == "" local samejob "samejob"

    assert `intdate' > `previntdate' if `previntdate' < .
    qui gen double `jb1annualhrsot' = (0.9*(`intdate'-`previntdate')/7)*(`jb1hrsot1' + `jb1hrsot2')/2 if (`jb1hrsot1' < . & `jb1hrsot2' < .) &  `mergevar' == 3 & `samejob' == 1
    qui replace `jb1annualhrsot' = (0.9*(`intdate'-`previntdate')/7)*(`jb1hrsot1') if (`jb1hrsot1' < . & `jb1hrsot2' >= .) &  `mergevar' == 3 & `samejob' == 1
    qui replace `jb1annualhrsot' = (0.9*(`intdate'-`previntdate')/7)*(`jb1hrsot2') if (`jb1hrsot1' >= . & `jb1hrsot2' < .) &  `mergevar' == 3 & `samejob' == 1
    label variable `jb1annualhrsot' "Number of hours worked between interviews"

    if "`mindic'" == "mindic" {
        qui replace `jb1annualhrsot' = .a if `mergevar' == 1 & `jb1annualhrsot' == .
        qui replace `jb1annualhrsot' = .b if `mergevar' == 3 & `samejob' != 1 & `jb1annualhrsot' == .
        qui replace `jb1annualhrsot' = .c if `mergevar' == 3 & `samejob' == 1 & (`jb1hrsot1' >= . & `jb1hrsot2' >= .) & `jb1annualhrsot' == .
        qui replace `jb1annualhrsot' = .d if `mergevar' == 3 & `samejob' == 1 & (`jb1hrsot1' < . | `jb1hrsot2' < .) & `previntdate' >= . & `jb1annualhrsot' == .
        qui replace `jb1annualhrsot' = .e if `mergevar' == 3 & `samejob' == 1 & (`jb1hrsot1' < . | `jb1hrsot2' < .) & `previntdate' < . & `intdate' >= . & `jb1annualhrsot' == .
        assert (`jb1annualhrsot' != .)
        label define `jb1annualhrsot' .a "Not interviewed in both waves" .b "Not in same job in both waves" .c "Missing hours in both waves" .d "previntdate missing" .e "intdate missing"
        label values `jb1annualhrsot' `jb1annualhrsot'
    }

end
*/

program define indresp_evermarried, rclass

syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars evermarried(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_mlstat"
        if (`wave'>1 & `wave'<6)  return local vars "`w'_mlstat `w'_ff_ivlolw `w'_ff_everint `w'_mlstatchk"
        if (`wave'>=6)  return local vars "`w'_mlstat `w'_ff_ivlolw `w'_mlstatchk"
    }
    else {

        if "`evermarried'" == "" local evermarried "evermarried"


        if (`wave'==1) {
            qui gen byte `evermarried' = 1 if inlist(`w'_mlstat,2,3,4,5,6,7,8,9)
            qui replace `evermarried' = 0 if inlist(`w'_mlstat,1)
        }

        if (`wave'>1) {
            *only asked if correct in grid
            qui gen byte `evermarried' = 1 if inlist(`w'_mlstat,2,3,4,5,6,7,8,9)
            qui replace  `evermarried' = 0 if inlist(`w'_mlstat,1)
        }

        label variable `evermarried' "Ever married (now or before)"

        if "`mindic'" == "mindic" {
            if (`wave'>1) {
                qui replace `evermarried' = .a if `w'_ivfio==2 & `evermarried'==.
                qui replace `evermarried' = .b if ((`w'_ff_everint==1| `w'_ff_ivlolw==1) & `w'_mlstatchk!=2) & `evermarried'==.

            }
            qui replace `evermarried' = .c if inlist(`w'_mlstat,-1,-2,-4,-7,-8,-9) & `evermarried'==.
            label define `evermarried' .a "Proxy respondent (Wave 2+)" .b "Interviewed in previous wave/correct in grid (Wave 2+)" .c "mlstat invalid"
            label values `evermarried' `evermarried'
            assert `evermarried'!=.
        }

    }

end

program define indresp_finexpect, rclass

syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars finexpect(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_finfut"
    }

    else {

        if "`finexpect'" == "" local finexpect "finexpect"

        qui gen byte `finexpect' = 0 if inlist(`w'_finfut,-1)
        qui replace  `finexpect' = 1 if inlist(`w'_finfut,1)
        qui replace  `finexpect' = 2 if inlist(`w'_finfut,2)
        qui replace  `finexpect' = 3 if inlist(`w'_finfut,3)

        label variable `finexpect' "Financial expectations for next year"

        label define `finexpect' 0 "Don't know" 1 "Better than now" 2 "Worse than now" 3 "About the same"


        if "`mindic'" == "mindic" {
				qui replace `finexpect' = .a if inlist(`w'_finfut,-2,-9)
				qui replace `finexpect' = .b if inlist(`w'_finfut,-7)

            label define `finexpect' .a "Missing" .b "Proxy respondent", add
            label values `finexpect' `finexpect'
            assert `finexpect'!=.
        }

    }

end







exit