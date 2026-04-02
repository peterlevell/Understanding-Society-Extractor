/*

**************DESCRIPTION***********************************************************************************************

FILE:       	us_hhresp_vars.ado
PURPOSE:    	Lots of individual programs, each one setting up a particular variable from Understanding Society hhdresp dataset
AUTHOR:     	Peter Levell (based on BHPS version by Jonathan Shaw)
THIS VERSION:   06/12/2014

DETAILS:			You're most likely to want to use "variable programs - driver.do", which calls programs from this file.

TYPICAL USE:  Too many individual programs to list here, but important common program options:
							- whatvars = lists which raw BHPS variables are used to create the derived variable (rather than actually creating it)
							- mindic   = use extended missing values (.a, .b, etc) to explain why variable is missing

**************LOG*******************************************************************************************************

18/03/2013	Moved from GE Tax Credits and tidied up
11/04/2013      Added in ivfho variable -PL
11/04/2013      Added in household gross income variable
12/04/2013      Fixed hvaluei, renti, inrent so that none of these would have missing values - PL
29/06/2020	Added hh monthly gross and net labour income 
13/06/2023 	Fixed rentf variable which is not available for wave 12

**************NOTES*****************************************************************************************************

[Date]				[Note]

************************************************************************************************************************

DONE
ivfho
hhintdate
rooms
hown
tenure
hvalue
ctband
llord
furnished
rent
inrent
cars

NOT IN US
hhtype (this is in the hhsamp file)
hhgrsslabinc (but there is monthly rather than annual version)

*/


program define us_hhresp_vars

    # delimit;
    syntax,                     wave(numlist integer max=1 >=1 <=$numwaves)
                                [
                                ivfho(name)
                                hhintdate(name)
                                htype(name)
                                rooms(name)
                                hown(name)
                                tenure(name)
                                hvalue(name)
                                totmortgage(name)
                                monthlymortgage(name)
                                llord(name)
                                furnished(name)
                                ctband(name)
                                rent(name)
                                inrent(string)
                                cars(name)
                                hhgrsmthlabinc(string)
								hhnetmthlabinc(string)
                                hhrxwgt(name)
                                rawvars(namelist)
								neednotexist
                                mindic
                                ];

    local inrent_syntax         "inrent1(name)
                                inrent2(name)
                                inrent3(name)";


    # delimit cr

    local hhrespvars "ivfho hhintdate htype rooms hown tenure hvalue totmortgage monthlymortgage llord furnished ctband rent inrent cars hhgrsmthlabinc hhnetmthlabinc hhrxwgt"

    local wi = `wave'
    local w = char(96+`wi') + "_"

    * Find out what raw variables are required
    ******************************************


    local idvars "`w'hidp"

    local rawvars : list idvars | rawvars

    local othvars ""
    foreach hhrespvar of local hhrespvars {
        if "``hhrespvar''" != "" {
            hhresp_`hhrespvar', wave(`wi') whatvars
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
        useundersoc `rawvars' `othvars' using "$data\\`w'hhresp.dta", clear `neednotexist'


        * Create finished variables
        if "`ivfho'" != "" {
            hhresp_ivfho, wave(`wi') ivfho(`ivfho') `mindic'
        }
        if "`hhintdate'" != "" {
            hhresp_hhintdate, wave(`wi') hhintdate(`hhintdate') `mindic'
        }
        if "`htype'" != "" {
            hhresp_htype, wave(`wi') htype(`htype') `mindic'
        }
        if "`rooms'" != "" {
            hhresp_rooms, wave(`wi') rooms(`rooms') `mindic'
        }
        if "`hown'" != "" {
            hhresp_hown, wave(`wi') hown(`hown') `mindic'
        }
        if "`tenure'" != "" {
            hhresp_tenure, wave(`wi') tenure(`tenure') `mindic'
        }
        if "`hvalue'" != "" {
            hhresp_hvalue, wave(`wi') hvalue(`hvalue') `mindic'
        }
        if "`totmortgage'" != "" {
            hhresp_totmortgage, wave(`wi') totmortgage(`totmortgage') tenure(`tenure') `mindic'
        }
        if "`monthlymortgage'" != "" {
            hhresp_monthlymortgage, wave(`wi') monthlymortgage(`monthlymortgage') tenure(`tenure') `mindic'
        }

        if "`llord'" != "" {
            hhresp_llord, wave(`wi') llord(`llord') hown(`hown') `mindic'
        }
        if "`furnished'" != "" {
            hhresp_furnished, wave(`wi') furnished(`furnished') hown(`hown') `mindic'
        }
        if "`ctband'" != "" {
            hhresp_ctband, wave(`wi') ctband(`ctband') `mindic'
        }
        if "`rent'" != "" {
            hhresp_rent, wave(`wi') rent(`rent') hown(`hown') `mindic'
        }
        if "`inrent'" != "" {
            local 0 ", `inrent'"
            syntax [, `inrent_syntax']
            hhresp_inrent, wave(`wi') inrent1(`inrent1') inrent2(`inrent2') inrent3(`inrent3') hown(`hown') `mindic'
        }
        if "`cars'" != "" {
            hhresp_cars, wave(`wi') cars(`cars') `mindic'
        }

        if "`hhgrsmthlabinc'" != "" {
            local 0 ", `hhgrsmthlabinc'"
            hhresp_hhgrsmthlabinc, wave(`wi') hhgrsmthlabinc(`hhgrsslabinc') `mindic'
        }

        if "`hhnetmthlabinc'" != "" {
            local 0 ", `hhnetmthlabinc'"
            hhresp_hhnetmthlabinc, wave(`wi') hhnetmthlabinc(`hhnetslabinc') `mindic'
        }
		
        if "`hhrxwgt'" != "" {
            hhresp_hhrxwgt, wave(`wi') hhrxwgt(`hhrxwgt')
        }

        if "`othvars'" != "" {
            drop `othvars'
        }
        sort `w'hidp
    }

end

* Interview outcome
*******************

program define hhresp_ivfho, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ivfho(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'>1) return local vars "`w'_ivfho"
    }
    else {

        if "`ivfho'" == "" local ivfho "ivfho"

        if (`wave'>1) {
        gen byte `ivfho' = `w'_ivfho

        label variable `ivfho' "Final household interview outcome"
        label define `ivfho' 10 "All eligible HH intv" 11 "Interviews + proxies " 12 "Interviews + refusal" 13 "HH comp + ques only" 20 "Phone - all eligible HH intv" 22 "Phone - interviews + refusal"
        label values `ivfho' `ivfho'
        }

        if "`mindic'" == "mindic" {
        if (`wave'==1) {
        gen byte `ivfho' = .a
        label define `ivfho' .a "Not included in wave 1"
        assert `ivfho'!= .
        }
        if (`wave'>1) {
        assert `ivfho' < .
        }
        }
    }

end

* Interview date
****************

program define hhresp_hhintdate, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hhintdate(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_startdatd  `w'_startdatm  `w'_startdaty"
    }
    else {

        if (`wave'==1) {
            if "`hhintdate'" == "" local hhintdate "hhintdate"
            qui gen long `hhintdate' = mdy(`w'_startdatm,`w'_startdatd,`w'_startdaty)

            * Allow a few days leeway at start of interview window
            format %td `hhintdate'
        }

        if (`wave'>1) {
            qui gen `hhintdate' = .
        }

        label variable `hhintdate' "Date of interview"

        if "`mindic'" == "mindic" {
            if (`wave'==1) {
                qui replace `hhintdate' = .a if inlist(`w'_startdatd,-1,-2,-3,-4,-9) & `hhintdate' == .
                qui replace `hhintdate' = .b if inlist(`w'_startdatm,-1,-2,-3,-4,-9) & `hhintdate' == .
                qui replace `hhintdate' = .c if inlist(`w'_startdaty,-1,-2,-3,-4,-9) & `hhintdate' == .
            }
            if (`wave'>1) {
                qui replace `hhintdate' = .d
            }

            assert (`hhintdate' != .)
            label define `hhintdate' .a "startdatd invalid" .b "startdatm invalid" .c "startdaty invalid" .d "Wave 2+ (interview day not asked)"
            label values `hhintdate' `hhintdate'
        }

    }

end

program define hhresp_hhrxwgt, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hhrxwgt(name)]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_hhdenus_xw"
        *includes BHPS sample
        if (inrange(`wave', 2, 5))  return local vars "`w'_hhdenub_xw"
        if (`wave'>5 & `wave'<=14)  return local vars "`w'_hhdenui_xw"
		if (`wave'>=15)  return local vars "`w'_hhdeng2_xw"
    }
    else {

        if `wave'==1 qui gen double `hhrxwgt' = `w'_hhdenus_xw
        if inrange(`wave', 2, 5)  qui gen double `hhrxwgt' = `w'_hhdenub_xw
        if (`wave'>5 & `wave'<=14) qui gen double `hhrxwgt' = `w'_hhdenui_xw
		if (`wave'>=15) qui gen double `hhrxwgt' = `w'_hhdeng2_xw
        assert (`hhrxwgt' >= 0 & `hhrxwgt' < .)
        label variable `hhrxwgt' "Cross-sectional household weight"
    }

end


* Number of rooms
*****************

program define hhresp_rooms, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars rooms(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_hsrooms `w'_hsbeds"
        else return local vars "`w'_hsrooms `w'_hsbeds `w'_ff_hsrooms `w'_ff_hsbeds `w'_hsroomchk `w'_origadd"

    }
    else {

        if "`rooms'" == "" local rooms "rooms"

        if (`wave'==1) qui gen byte `rooms' = `w'_hsrooms + `w'_hsbeds if inrange(`w'_hsrooms,0,200) & inrange(`w'_hsbeds,0,200)

        if (`wave'>=2) {
            qui gen byte `rooms' = `w'_hsrooms   + `w'_hsbeds if inrange(`w'_hsrooms,0,200) & inrange(`w'_hsbeds,0,200) & (`w'_hsroomchk==2|`w'_hsroomchk==-8|`w'_hsroomchk==-10)
            qui replace `rooms'  = `w'_ff_hsrooms + `w'_ff_hsbeds if inrange(`w'_ff_hsrooms,0,200) & inrange(`w'_ff_hsbeds,0,200) & `w'_hsroomchk==1
        }

        assert rooms!=0
        label variable `rooms' "No. rooms incl bed excl kitch, bath, let"

        if "`mindic'" == "mindic" {

            if (`wave'==1) {
                qui replace `rooms' = .a if inlist(`w'_hsrooms,-1,-2,-9) & `w'_hsbeds>=0 & `rooms' == .
                qui replace `rooms' = .b if inlist(`w'_hsbeds,-1,-2,-9) & `w'_hsrooms>=0 & `rooms' == .
                qui replace `rooms' = .c if inlist(`w'_hsbeds,-1,-2,-9) & inlist(`w'_hsrooms,-1,-2,-9) & `rooms' == .
            }

            if (`wave'>=2) {
                qui replace `rooms' = .a if inlist(`w'_hsrooms,-1,-2,-9) & `w'_hsbeds>=0 & (`w'_hsroomchk==2|`w'_hsroomchk==-8|`w'_hsroomchk==-10) & `rooms' == .
                qui replace `rooms' = .b if inlist(`w'_hsbeds,-1,-2,-9) & `w'_hsrooms>=0 & (`w'_hsroomchk==2|`w'_hsroomchk==-8|`w'_hsroomchk==-10) & `rooms' == .
                qui replace `rooms' = .c if inlist(`w'_hsbeds,-1,-2,-9) & inlist(`w'_hsrooms,-1,-2,-9) & (`w'_hsroomchk==2|`w'_hsroomchk==-8|`w'_hsroomchk==-10) & `rooms' == .
                qui replace `rooms' = .d if inlist(`w'_hsroomchk, -1,-2,-9) & `rooms' == .
                qui replace `rooms' = .e if `w'_hsroomchk==-8 & inlist(`w'_origadd,-9) & `rooms' == .
                qui replace `rooms' = .f if `w'_hsroomchk==-8 & inlist(`w'_origadd,2) & `rooms' == .
                qui replace `rooms' = .g if `w'_hsroomchk==-8 & `w'_origadd==1 & inrange(`w'_ff_hsrooms,0,200) & inrange(`w'_ff_hsbeds,0,200) & `rooms' == .
            }
            assert (`rooms' != .)
            label define `rooms' .a "hsrooms invalid" .b "hsbeds invalid" .c "both hsbeds and hsrooms invalid" .d "hsroomchk invalid" .e "worigadd missing" .h "Changed address but not asked again" .g "Can't be sure number of rooms is same as last time"
            label values `rooms' `rooms'
        }

    }

end


* Owner or renter?
******************

*information on who owns with mortgages is in US but made variable consistent with the old BHPS one

program define hhresp_hown, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hown(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'==1) return local vars "`w'_hsownd"
        if (`wave'>=2) return local vars "`w'_hsownd `w'_ff_hsownd `w'_hsowndchk `w'_ff_hsownd"
    }
    else {

        if "`hown'" == "" local hown "hown"

        if (`wave'==1) {
            qui gen byte `hown' = 1 if inrange(`w'_hsownd,1,2)
            qui replace  `hown' = `w'_hsownd-1 if inrange(`w'_hsownd,3,5)
            qui replace  `hown' = 5 if `w'_hsownd==97
        }

        if (`wave'>=2) {
            qui gen byte `hown' = 1 if inrange(`w'_hsownd,1,2) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace  `hown' = `w'_hsownd-1 if inrange(`w'_hsownd,3,5) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace  `hown' = 5 if `w'_hsownd==97 & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)

            qui replace  `hown' = 1 if inrange(`w'_ff_hsownd,1,2) & `w'_hsowndchk==1
            qui replace  `hown' = `w'_ff_hsownd-1 if inrange(`w'_ff_hsownd,3,5) & `w'_hsowndchk==1
            qui replace  `hown' = 5 if `w'_ff_hsownd==97 & `w'_hsowndchk==1

        }

        label variable `hown' "Own or rent accommodation"
        label define `hown' 1 "Owned" 2 "Shared ownership" 3 "Rented" 4 "Rent-free" 5 "Other"
        label values `hown' `hown'

        if "`mindic'" == "mindic" {

            if (`wave'==1) {
                qui replace `hown' = .a if inlist(`w'_hsownd,-1,-2,-9) & `hown' == .
            }

            if (`wave'>=2) {
                qui replace `hown' = .a if inlist(`w'_hsownd,-1,-2,-8,-9) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10|(`w'_hsowndchk>0 & `w'_origadd==2)) & `hown' == .
                qui replace `hown' = .b if inlist(`w'_ff_hsownd,-1,-2,-9) & (`w'_hsowndchk==1) & `hown' == .
                qui replace `hown' = .c if inlist(`w'_hsowndchk,-1,-2,-9) & `hown' == .
                qui replace `hown' = .d if inlist(`w'_origadd,-1,-8,-9) & `hown' == .
                qui replace `hown' = .e if `w'_origadd ==2 & `w'_hsowndchk==-8 & `hown' == .
                qui replace `hown' = .f if `w'_origadd ==1 & `w'_hsowndchk==-8 & `hown' == .
		qui replace `hown' = .g if `w'_origadd ==1 & `w'_hsowndchk==1 &  `w'_ff_hsownd ==-8 & `hown' == .
            }

            assert (`hown' != .)
            label define `hown' .a "hsownd invalid" .b "ff_hsownd invalid" .c "hsowndchk invalid" .d "origadd missing" .e "Changed address but not asked again" .f "Can't be sure same tenure status as last period" .g "ff_hsownd not valid", add
        }

    }

end


* Tenure variable for FORTRAN
*****************************

program define hhresp_tenure, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars tenure(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' == 1) return local vars "`w'_hsownd `w'_rentll"
        else return local vars "`w'_hsownd `w'_rentll `w'_ff_hsownd `w'_hsowndchk `w'_origadd"

    }
    else {

        if "`tenure'" == "" local tenure "tenure"

        if (`wave'==1) {
            qui gen byte `tenure' = 1 if `w'_hsownd == 1
            qui replace `tenure'  = 2 if `w'_hsownd == 2
            qui replace `tenure'  = 3 if `w'_hsownd == 3
            qui replace `tenure'  = 4 if `w'_hsownd == 4 & inlist(`w'_rentll,1,2,4,5)
            qui replace `tenure'  = 5 if `w'_hsownd == 4 & inlist(`w'_rentll,3,6,7,8,9,10)
            qui replace `tenure'  = 6 if `w'_hsownd == 5
            qui replace `tenure'  = 7 if `w'_hsownd == 97
        }

        if (`wave'>=2) {
            qui gen byte `tenure' = 1 if `w'_ff_hsownd == 1 & `w'_hsowndchk==1
            qui replace `tenure'  = 2 if `w'_ff_hsownd == 2 & `w'_hsowndchk==1
            qui replace `tenure'  = 3 if `w'_ff_hsownd == 3 & `w'_hsowndchk==1
            qui replace `tenure'  = 4 if `w'_ff_hsownd == 4 & inlist(`w'_rentll,1,2,4,5)  & `w'_hsowndchk==1
            qui replace `tenure'  = 5 if `w'_ff_hsownd == 4 & inlist(`w'_rentll,3,6,7,8,9,10) & `w'_hsowndchk==1
            qui replace `tenure'  = 6 if `w'_ff_hsownd == 5  & `w'_hsowndchk==1
            qui replace `tenure'  = 7 if `w'_ff_hsownd == 97 & `w'_hsowndchk==1


            qui replace `tenure' = 1 if `w'_hsownd == 1  & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 2 if `w'_hsownd == 2  & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 3 if `w'_hsownd == 3  & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 4 if `w'_hsownd == 4 & inlist(`w'_rentll,1,2,4,5)     & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 5 if `w'_hsownd == 4 & inlist(`w'_rentll,3,6,7,8,9,10) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 6 if `w'_hsownd == 5   & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `tenure'  = 7 if `w'_hsownd == 97  & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
        }


        label variable `tenure' "Housing tenure for FORTRAN"
        label define `tenure' 1 "Own outright" 2 "Mortgage" 3 "Part own, part rent" 4 "Social renter" 5 "Private renter" 6 "Rent free" 7 "Other"
        label values `tenure' `tenure'

        if "`mindic'" == "mindic" {
            if (`wave'==1) {
                qui replace `tenure' = .a if inlist(`w'_hsownd,-1,-2,-9) & tenure==.
                qui replace `tenure' = .b if `w'_hsownd==4 & inlist(`w'_rentll,-1,-2,-9) & tenure==.
            }

            if (`wave'>=2) {
                qui replace `tenure' = .a if inlist(`w'_hsownd,-1,-2,-9) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10) & `tenure' ==.
                qui replace `tenure' = .b if (`w'_hsownd==4 & inlist(`w'_rentll,-1,-2,-8,-9) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10))|(`w'_ff_hsownd==4 & inlist(`w'_rentll,-1,-2,-8,-9) & `w'_hsowndchk==1) & `tenure' ==.
                qui replace `tenure' = .c if inlist(`w'_hsowndchk,-1,-2,-9) & `tenure' ==.
                qui replace `tenure' = .d if inlist(`w'_origadd,-1,-9) & `tenure' ==.
                qui replace `tenure' = .e if inlist(`w'_origadd,2) & `w'_hsowndchk==-8 & `tenure' ==.
                qui replace `tenure' = .f if `w'_origadd ==1 & `w'_hsowndchk==-8 & `tenure'  == .
                qui replace `tenure' = .a if `w'_hsownd<0 & `tenure'==.
            }

            assert (`tenure' != .)
            label define `tenure' .a "hsownd invalid" .b "rentll invalid" .c "hsowndchk invalid" .d "origadd missing" .e "Changed address but not asked again" .f "Can't be sure tenure status the same as last period", add

        }

    }

end


* Estimated house value
***********************

program define hhresp_hvalue, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hvalue(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave' == 1) return local vars "`w'_hsownd `w'_hsval"
        else return local vars             "`w'_hsownd `w'_hsval `w'_hsowndchk `w'_ff_hsownd"
    }
    else {

        if "`hvalue'" == "" local hvalue "hvalue"

        if (`wave'==1) {
            qui gen double `hvalue' = `w'_hsval if (`w'_hsval >= 0 & `w'_hsval < .) & inlist(`w'_hsownd,1,2,3)
        }

        if (`wave'>=2) {
            qui gen double `hvalue' = `w'_hsval if (`w'_hsval >= 0 & `w'_hsval < .) & inlist(`w'_hsownd,1,2,3) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)
            qui replace `hvalue'    = `w'_hsval if (`w'_hsval >= 0 & `w'_hsval < .) & inlist(`w'_ff_hsownd,1,2,3) & `w'_hsowndchk==1
        }

        label variable `hvalue' "Expected sale price of house"

        if "`mindic'" == "mindic" {

            if (`wave'==1) {
                qui replace `hvalue' = .a if !inlist(`w'_hsownd,1,2,3) & `hvalue' == .
                qui replace `hvalue' = .b if inlist(`w'_hsownd,1,2,3) & inlist(`w'_hsval,-1,-2,-9) & `hvalue' == .
            }

            if (`wave'>=2) {
                qui replace `hvalue' = .a if !inlist(`w'_hsownd,1,2,3) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)  & `hvalue' == .
                qui replace `hvalue' = .b if inlist(`w'_hsownd,1,2,3) & inlist(`w'_hsval,-1,-2,-9) & (`w'_hsowndchk==2|`w'_hsowndchk==-8|`w'_hsowndchk==-10)  & `hvalue' == .


                qui replace `hvalue' = .a if !inlist(`w'_ff_hsownd,1,2,3) & `w'_hsowndchk==1  & `hvalue' == .
                qui replace `hvalue' = .b if inlist(`w'_ff_hsownd,1,2,3) & inlist(`w'_hsval,-1,-2,-9) & `w'_hsowndchk==1 & `hvalue' == .
                qui replace `hvalue' = .c if inlist(`w'_hsowndchk,-1,-2,-9) & `hvalue' ==.
            }

            assert (`hvalue' != .)
            label define `hvalue' .a "Not owned" .b "hsval invalid"  .c "hsowndchk invalid"
            label values `hvalue' `hvalue'
        }

    }

end

* Total outstanding mortgage on all property
*****************

program define hhresp_totmortgage, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars totmortgage(name) tenure(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if ((`wave'==1|`wave'>=5)) return local vars "`w'_hstotmg"
    }
    else {

        if "`totmortgage'" == "" local totmortgage "totmortgage"
        if "`tenure'" == "" local tenure "tenure"

        if (`wave'==1|`wave'>=5) {
            qui gen double `totmortgage' = `w'_hstotmg if `tenure' == 2 & `w'_hstotmg > 0
            char `totmortgage'[touprate] "touprate"

        }

        if inlist(`wave',2,3,4) {
            qui gen `totmortgage' = .
        }

        label variable `totmortgage' "Total outstanding mortgage on all property"


        if "`mindic'" == "mindic" {
            if inlist(`wave',2,3,4) {
                qui replace `totmortgage' = .a
            }
            if (`wave'==1|`wave'>=5) {
                qui replace `totmortgage' = .b if `w'_hstotmg == -7
                qui replace `totmortgage' = .c if `totmortgage' == . & `tenure' < . & `tenure' != 2
                qui replace `totmortgage' = .d if `totmortgage' == . & `tenure' >= .
                qui replace `totmortgage' = .e if `totmortgage' == . & inlist(`w'_hstotmg,-1,-2,-3,-8,-9)
                qui replace `totmortgage' = .f if `totmortgage' == . & `w'_hstotmg == 0
            }

            assert (`totmortgage' != .)
            label define `totmortgage' .a "Not asked in waves 2 to 4" .b "Phone interview" .c "Not a mortgager" .d "tenure missing" .e "hstotmg missing" .f "hstotmg is zero"
            label values `totmortgage' `totmortgage'


        }

    }


end

program define hhresp_monthlymortgage, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars monthlymortgage(name) tenure(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_xpmg"
    }
    else {

        if "`monthlymortgage'" == "" local monthlymortgage "monthlymortgage"
        if "`tenure'" == "" local tenure "tenure"

        qui gen double `monthlymortgage' = `w'_xpmg if `tenure' == 2 & `w'_xpmg > 0
        label variable `monthlymortgage' "Last total monthly mortgage payment (inc. capital and interest)"
		char `monthlymortgage'[touprate] "touprate"

        if "`mindic'" == "mindic" {
            qui replace `monthlymortgage' = .a if `monthlymortgage' == . & `tenure' < . & `tenure' != 2
            qui replace `monthlymortgage' = .b if `monthlymortgage' == . & `tenure' >= .
            qui replace `monthlymortgage' = .c if `monthlymortgage' == . & inlist(`w'_xpmg,-1,-2,-3,-8,-9)
            qui replace `monthlymortgage' = .d if `monthlymortgage' == . & `w'_xpmg == 0

            assert (`monthlymortgage' != .)
            label define `monthlymortgage' .a "Not a mortgager" .b "tenure missing" .c "wxpmg missing" .d "wxpmg is zero"
            label values `monthlymortgage' `monthlymortgage'

        }

    }


end



* Council tax band
******************

program define hhresp_ctband, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars ctband(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
         if (`wave'==1) return local vars "`w'_hsctax `w'_gor_dv"
         else return local vars "`w'_hsctax `w'_gor_dv `w'_origadd"
    }
    else {

        if "`ctband'" == "" local ctband "ctband"

        qui gen byte `ctband' = `w'_hsctax if inrange(`w'_hsctax,1,8)|`w'_hsctax==10

        label define `ctband' 1 "Band A" 2 "Band B" 3 "Band C" 4 "Band D" 5 "Band E" 6 "Band F" 7 "Band G" 8 "Band H" 9 "Band I (Wales only)"
        label values `ctband' `ctband'
        label variable `ctband' "Council tax band"

        if "`mindic'" == "mindic" {

            if (`wave'==1) {
                qui replace `ctband' = .a if `w'_gor_dv==12  & `ctband' == .
                qui replace `ctband' = .b if `w'_hsctax == 9 & `ctband' == .
                qui replace `ctband' = .c if `w'_gor_dv!=12 & inlist(`w'_hsctax,-1) & `ctband' == .
                qui replace `ctband' = .d if `w'_gor_dv!=12 & inlist(`w'_hsctax,-2,-9) & `ctband' == .
            }

            if (`wave'>=2) {
                qui replace `ctband' = .a if `w'_gor_dv==12  & `ctband' == .
                qui replace `ctband' = .b if `w'_hsctax == 9 & `ctband' == .
                qui replace `ctband' = .c if `w'_gor_dv!=12 &  inlist(`w'_hsctax,-1,-8) & `ctband' == .
                qui replace `ctband' = .d if `w'_gor_dv!=12 &  inlist(`w'_hsctax,-2,-9) & `ctband' == .
                qui replace `ctband' = .e if `w'_origadd==1 & `ctband' == .
                qui replace `ctband' = .f if `w'_gor_dv!=12 & inlist(`w'_origadd,-1,-2,-9) & inlist(`w'_hsctax,-8) & `ctband' == .
                qui replace `ctband' = .g if  inlist(`w'_gor_dv,-1,-2,-9) & inlist(`w'_hsctax,-8) & `ctband' == .
            }

            if (`wave'==5) qui replace `ctband' = 9 if `ctband'==10

            assert (`ctband' != .)
            label define `ctband' .a "Northern Ireland"  .b "Not valued separately" .c "hsctax unknown" .d "hsctax invalid" .e "Still living in original address" .f "origadd unknown" .g "gor unknown and hsctax inapplicable", add
        }

    }

end



* Type of landlord
******************

program define hhresp_llord, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars llord(name) hown(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_rentll"
    }
    else {

        if "`llord'" == "" local llord "llord"
        if "`hown'" == "" local hown "hown"

        qui gen byte `llord' = 1 if inlist(`hown',3,4,5) & inlist(`w'_rentll,1,2,4,5)
        qui replace `llord' = 2 if inlist(`hown',3,4,5) & inlist(`w'_rentll,3,6,7,8,9,10)
        label variable `llord' "Type of landlord"
        label define `llord' 1 "Social" 2 "Private"
        label values `llord' `llord'

        if "`mindic'" == "mindic" {

            qui replace `llord' = .a if inlist(`hown',1,2) & `llord' == .
            qui replace `llord' = .b if `hown' >= . & `llord' == .
            qui replace `llord' = .c if inlist(`hown',3,4,5) & inlist(`w'_rentll,-1,-2,-4,-8,-9) & `llord' == .

            assert (`llord' != .)
            label define `llord' .a "Not rented" .b "hown missing" .c "rentll invalid", add
        }

    }

end



* Whether rented accommodation is furnished
*******************************************

program define hhresp_furnished, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars furnished(name) hown(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        if (`wave'<12) return local vars "`w'_rentf"
    }
    else {

        if "`furnished'" == "" local furnished "furnished"
        if "`hown'" == "" local hown "hown"

	if `wave'<12 {
        	qui gen byte `furnished' = `w'_rentf if inlist(`w'_rentf,1,2,3)
      	  	label variable `furnished' "Whether furnished"
        	label define `furnished' 1 "Furnished" 2 "Part-furnished" 3 "Unfurnished"
        	label values `furnished' `furnished'
	}

	if (`wave'>=12) {
		qui gen byte `furnished' = .
	}

        if "`mindic'" == "mindic" {

            if `wave'<12 {
            	qui replace `furnished' = .a if inlist(`hown',1,5) & `furnished' == .
            	qui replace `furnished' = .b if `hown' >= . & `furnished' == .
            	qui replace `furnished' = .c if inlist(`hown',2,3,4) & inlist(`w'_rentf,-1,-2,-4,-8,-9) & `furnished' == .
	    }

	    if (`wave'>=12) {
		qui replace `furnished' = .d if `furnished' == .
	    }

            assert (`furnished' != .)
            label define `furnished' .a "Not rented" .b "hown missing" .c "rentf invalid" .d "rentf not asked this wave", add
        }

    }

end



* Gross last rent
*****************

program define hhresp_rent, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars rent(name) hown(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_rent `w'_rentwc `w'_renthb `w'_rentg"
    }
    else {

        if "`rent'" == "" local rent "rent"
        if "`hown'" == "" local hown "hown"

        * Rent-free
        qui gen double `rent' = 0 if `hown' == 4
        * Not rent-free
        * No HB
        qui replace `rent' = `w'_rent/`w'_rentwc if (`w'_rent >= 0 & `w'_rent < .) & inrange(`w'_rentwc,0.01,52) & `w'_renthb == 2 & inlist(`hown',3,5)
        * Some HB
        qui replace `rent' = `w'_rentg/`w'_rentwc if (`w'_rentg >= 0 & `w'_rentg < .) & inrange(`w'_rentwc,0.01,52) & `w'_renthb == 1 & inlist(`hown',3,5)
        * 100% rebate
        qui replace `rent' = `w'_rentg/`w'_rentwc if (`w'_rentg >= 0 & `w'_rentg < .) & inrange(`w'_rentwc,0.01,52) & `w'_rent == -3 & inlist(`hown',3,5)
        label variable `rent' "Gross weekly rent (not uprated)"

        * uprate? (also: what about house price above?)



        if "`mindic'" == "mindic" {
            qui replace `rent' = .a if inlist(`hown',1,2) & `rent' == .
            qui replace `rent' = .b if `hown' >= . & `rent' == .
            qui replace `rent' = .c if inlist(`hown',3,5) & inlist(`w'_rent,-1,-2,-4,-8,-9) & `w'_renthb != 1 & `rent' == .
            qui replace `rent' = .d if inlist(`hown',3,5) & inlist(`w'_renthb,-1,-2,-4,-8,-9) & `rent' == .
            qui replace `rent' = .e if inlist(`hown',3,5) & `w'_renthb == 1 & inlist(`w'_rentg,-1,-2,-4,-8,-9) & `rent' == .
            qui replace `rent' = .f if inlist(`hown',3,5) & ((`w'_renthb == 1 & (`w'_rentg >= 0 & `w'_rentg < .)) | (`w'_renthb == 2 & (`w'_rent >= 0 & `w'_rent < .))) & inlist(`w'_rentwc,-1,-2,-3,-4,-8,-9,95) & `rent' == .
            qui replace `rent' = .g if inlist(`hown',3,5) & ((`w'_renthb == 1 & (`w'_rentg >= 0 & `w'_rentg < .)) | (`w'_renthb == 2 & (`w'_rent >= 0 & `w'_rent < .))) & inlist(`w'_rentwc,90,96) & `rent' == .

            assert (`rent' != .)
            label define `rent' .a "Not rented" .b "hown missing" .c "rent invalid" .d "renthb invalid" .e "rentg invald" .f "rentwc invalid" .g "rentwc given as other or less than week"
            label values `rent' `rent'
        }

    }


end



* What service charges are included in rent
*******************************************

program define hhresp_inrent, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars inrent1(name) inrent2(name) inrent3(name) hown(varname) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_rentinc1 `w'_rentinc2 `w'_rentinc3 `w'_rent"
    }
    else {

        if "`hown'" == "" local hown "hown"

        forval i = 1/3 {
            qui gen byte `inrent`i'' = (`w'_rentinc`i' == 1) if inlist(`w'_rentinc`i',0,1)
            qui replace `inrent`i'' = 0 if `hown' == 4
        }
        label variable `inrent1' "Water and or sewerage charges in rent"
        label variable `inrent2' "Heating or lighting or hot water in rent"
        label variable `inrent3' "Council tax (rates) in rent"

        if "`mindic'" == "mindic" {
            forval i = 1/3 {
                qui replace `inrent`i'' = .a if inlist(`hown',1,2) & `inrent`i'' == .
                qui replace `inrent`i'' = .b if `hown' >= . & `inrent`i'' == .
                qui replace `inrent`i'' = .c if inlist(`hown',3,5) & inlist(`w'_rent,-1,-2,-4,-8,-9) & `inrent`i'' == .
                qui replace `inrent`i'' = .d if inlist(`hown',3,5) & (`w'_rent >= 0 & `w'_rent <.) & inlist(`w'_rentinc`i',-1,-2,-4,-8,-9) & `inrent`i'' == .
            }

            forval i = 1/3 {
                assert (`inrent`i'' != .)
                label define `inrent`i'' .a "Not rented" .b "hown missing" .c "rent invalid" .d "rentinc`i' invalid"
                label values `inrent`i'' `inrent`i''
            }

        }

    }

end





* Access to a car
*****************

program define hhresp_cars, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars cars(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_ncars"

    }
    else {

        if "`cars'" == "" local cars "cars"

        qui gen byte `cars' = `w'_ncars if `w'_ncars>=0
        label variable `cars' "Number of cars available to hh"
        label values `cars' `cars'

        if "`mindic'" == "mindic" {

            qui replace `cars' = .a if inlist(`w'_ncars,-1,-2,-3,-4,-8,-9) & `cars' == .
            qui replace `cars' = .b if inlist(`w'_ncars,-10) & `cars'==.

            assert (`cars' != .)
            label define `cars' .a "ncars invalid" .b "IEMB sample - not available", add

        }

    }

end


* Household gross earnings (monthly)
*****************
* Note: All income sources are imputed for all households but there appears to only be an imputation flag for total household income. So there is no imputation flag for this variable.

program define hhresp_hhgrsmthlabinc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hhgrsmthlabinc(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_fihhmnlabgrs_dv"
    }
    else {

        if "`hhgrsmthlabinc'"  == "" local hhgrsmthlabinc  "hhgrsmthlabinc"

        qui gen long `hhgrsmthlabinc' = `w'_fihhmnlabgrs_dv if `w'_fihhmnlabgrs_dv < .
        label variable `hhgrsmthlabinc' "Gross monthly household labour income"
		
       if "`mindic'" == "mindic" {
            assert (`hhgrsmthlabinc' != .)
        }

    }

end


* Household net earnings (monthly)
*****************
* Note: All income sources are imputed for all households but there appears to only be an imputation flag for total household income. So there is no imputation flag for this variable.

program define hhresp_hhnetmthlabinc, rclass

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [whatvars hhnetmthlabinc(name) mindic]
    local w = char(96+`wave')

    if "`whatvars'" == "whatvars" {
        return local vars "`w'_fihhmnlabnet_dv"
    }
    else {

        if "`hhnetmthlabinc'"  == "" local hhnetmthlabinc  "hhnetmthlabinc"

        qui gen long `hhnetmthlabinc' = `w'_fihhmnlabnet_dv if `w'_fihhmnlabnet_dv < .
        label variable `hhnetmthlabinc' "Net monthly household labour income"
	
       if "`mindic'" == "mindic" {
            assert (`hhnetmthlabinc' != .)
        }
		
	}

end



