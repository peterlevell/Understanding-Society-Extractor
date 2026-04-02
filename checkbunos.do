capture program drop varsforhgra
program define varsforhgra

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [indall]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    if "`indall'" == "indall" c_local varsforhgra "`w'hidp `w'pno `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof `w'depchl_dv `w'mastat_dv `w'ppno"
    else c_local varsforhgra "`w'hidp `w'pno `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof"

end

capture program drop fixhgra
program define fixhgra

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [indall]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "hgra" " {c |} "

    gen byte hgrai = 0
    label variable hgrai "Responsible adult number changed"

    qui count if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    qui replace hgrai = 1 if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    qui replace `w'adresp15_dv = `w'hgbiom if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & inrange(`w'hgbiom,1,50)
    di as text %30s "missing --> mother" " {c |} " as res %5.0g r(N)

    qui count if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    qui replace hgrai = 1 if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    qui replace `w'adresp15_dv = `w'hgbiom if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & inrange(`w'hgbiom,1,50) & (`w'adresp15_dv != `w'hgbiom)
    di as text %30s "non-missing --> mother" " {c |} " as res %5.0g r(N)

    qui count if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    qui replace hgrai = 1 if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    qui replace `w'adresp15_dv = `w'hgbiof if inrange(`w'dvage,0,15) & `w'adresp15_dv == 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50)
    di as text %30s "missing --> father" " {c |} " as res %5.0g r(N)

    qui count if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    qui replace hgrai = 1 if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    qui replace `w'adresp15_dv = `w'hgbiof if inrange(`w'dvage,0,15) & `w'adresp15_dv > 0 & `w'hgbiom == 0 & inrange(`w'hgbiof,1,50) & (`w'adresp15_dv != `w'hgbiof)
    di as text %30s "non-missing --> father" " {c |} " as res %5.0g r(N)

    qui count if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    qui replace hgrai = 1 if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    qui replace `w'adresp15_dv = 0 if `w'adresp15_dv > 0 & `w'dvage >= 16 & `w'dvage < .
    di as text %30s "non-missing --> 0 (>=16)" " {c |} " as res %5.0g r(N)

    * Correct for a value of mhgra where the corresponding pno doesn't exist
    if `wi' == 13 {
        qui replace hgrai = 1 if (mhid ==  13200844 & mpno == 1)
        qui replace mhgra = 3 if (mhid ==  13200844 & mpno == 1)
    }

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


capture program drop varsforage
program define varsforage

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsforage "`w'hidp `w'pno `w'dvage"

end

capture program drop fixage
program define fixage

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "age" " {c |} "

    gen byte agei = 0
    label variable agei "Age changed"

end

capture program drop varsfordepchl
program define varsfordepchl

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsfordepchl "`w'hidp `w'pno `w'dvage `w'depchl_dv `w'mastat_dv `w'hgbiom `w'hgbiof `w'_ivfio_dv"

end

capture program drop fixdepchl
program define fixdepchl

    syntax, wave(numlist integer max=1 >=1 <=$numwaves) [fixage]
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "depchl" " {c |} "

    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 204277443 & a_pno == 4
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 273212443 & a_pno == 3
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 274404483 & a_pno == 3
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 341708163 & a_pno == 4
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 409206323 & a_pno == 3
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 476072763 & a_pno == 4
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 613254603 & a_pno == 2
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 680990083 & a_pno == 4
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 885250523 & a_pno == 3
    if `wi' == 1 qui replace a_depchl = 1 if a_hidp == 1226702323 & a_pno == 3


    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 209521602 & b_pno == 2
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 409047202 & b_pno == 3
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 447113602 & b_pno == 3
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 619085602 & b_pno == 3
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 620683602 & b_pno == 5
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 851890402 & b_pno == 3
    if `wi' == 2 qui replace b_depchl = 1 if b_hidp == 820637602 & b_pno == 3

    if "`fixage'" == "fixage" {
        qui fixage, wave(`wave')
    }

    * Check dependent indicator
    assert inrange(`w'dvage,0,18) | `w'dvage < 0 if `w'depchl_dv == 1

    if (`wi'>1) {
        assert `w'dvage >= 16 & `w'dvage <. if `w'depchl_dv == 2
    }

    if (`wi'==1) {
        assert `w'dvage >= 16 & `w'dvage <. if `w'depchl_dv == 2 & a_hidp ~= 1090558163
        *three individuals in the household have missing ages but other variables indicate that they are probably over 16 and so not dependent children.
    }


    gen byte depchli = 0
    label variable depchli "Dependent child indicator changed"

    qui count if inrange(`w'dvage,0,15) & `w'depchl_dv < 0
    qui replace depchli = 1 if inrange(`w'dvage,0,15) & `w'depchl_dv < 0
    qui replace `w'depchl_dv = 1 if inrange(`w'dvage,0,15) & `w'depchl_dv < 0
    di as text %30s "Set to 1 (because <=15)" " {c |} " as res %5.0g r(N)

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

capture program drop varsformastat
program define varsformastat

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsformastat "`w'hidp `w'pno `w'mastat_dv"

end

capture program drop fixmastat
program define fixmastat

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    di as text %30s "mastat" " {c |} "

    gen byte mastati = 0
    label variable mastati "Marital status changed"

    gen byte ppnoi = 0
    label variable ppnoi "Partner changed"

    if (`wi'==1) {
        qui replace a_mastat_dv = 2 if a_hidp==69311723 & a_pno ==1
        qui replace mastati = 1 if a_hidp==69311723 & a_pno ==1

        qui replace a_mastat_dv = 10 if a_hidp==136864283 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==136864283 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==205051283 & inlist(a_pno,1,2)
        qui replace mastati = 1  if a_hidp==205051283 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==205579643 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==205579643 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==273141043 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==273141043 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==273768683 & a_pno==6
        qui replace mastati = 1 if a_hidp==273768683 & a_pno==6

        qui replace a_mastat_dv = 2 if a_hidp==408062563 & a_pno==2
        qui replace mastati = 1 if a_hidp==408062563 & a_pno==2

        qui replace a_ppno = 1 if a_hidp==545305603 & a_pno==3
        qui replace a_ppno = 0 if a_hidp==545305603 & a_pno==2
        qui replace a_ppno = 3 if a_hidp==545305603 & a_pno==1

        qui replace ppnoi = 1 if a_hidp==545305603 & a_pno==3
        qui replace ppnoi = 1 if a_hidp==545305603 & a_pno==2
        qui replace ppnoi = 1 if a_hidp==545305603 & a_pno==1

        qui replace a_mastat_dv = 3 if a_hidp == 884498443 & a_pno==1
        qui replace mastati = 1 if a_hidp == 884498443 & a_pno==1

        qui replace a_mastat_dv = 10 if a_hidp==952716043 & inlist(a_pno,1,3)
        qui replace mastati = 1 if a_hidp==952716043 & inlist(a_pno,1,3)

        qui replace a_mastat_dv = 2 if a_hidp==1020610643 & a_pno==2
        qui replace mastati = 1 if a_hidp==1020610643 & a_pno==2

        qui replace a_mastat_dv = 10 if a_hidp==1156690203 & inlist(a_pno,1,3)
        qui replace mastati = 1 if a_hidp==1156690203 & inlist(a_pno,1,3)

        qui replace a_mastat_dv = 2 if a_hidp==1225928483 & a_pno==1
        qui replace mastati = 1 if a_hidp==1225928483 & a_pno==1

        qui replace a_mastat_dv = 10 if a_hidp==1566375923 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1566375923 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1633004363 & inlist(a_pno,1,3)
        qui replace mastati = 1 if a_hidp==1633004363 & inlist(a_pno,1,3)

        qui replace a_ppno = 0 if a_hidp==1362001923 & inlist(a_pno,2,10)
        qui replace ppnoi = 1  if a_hidp==1362001923 & inlist(a_pno,2,10)

        qui replace a_mastat_dv = 10 if a_hidp==70272563 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==70272563 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==137093443 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==137093443 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 2 if a_hidp==137907403 & a_pno==2
        qui replace mastati = 1 if a_hidp==137907403 & a_pno==2

        qui replace a_mastat_dv = 10 if a_hidp==204806483 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==204806483 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==408427043 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==408427043 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==408886723 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==408886723 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==613264803 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==613264803 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==680812603 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==680812603 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==682342603 & inlist(a_pno,1,3)
        qui replace mastati = 1 if a_hidp==682342603 & inlist(a_pno,1,3)

        qui replace a_mastat_dv = 10 if a_hidp==816745283 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==816745283 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==954189603 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==954189603 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1021005723 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1021005723 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1157768139 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1157768139 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1224336603 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1224336603 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1498303163 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1498303163 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1564116963 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1564116963 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1632163883 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1632163883 & inlist(a_pno,1,2)

        qui replace a_mastat_dv = 10 if a_hidp==1224833683 & inlist(a_pno,1,2)
        qui replace mastati = 1 if a_hidp==1224833683 & inlist(a_pno,1,2)

        qui replace a_ppno = 10 if a_hidp==1362001923 & a_pno==2
        qui replace a_ppno = 2 if a_hidp==1362001923 & a_pno==10

        qui replace ppnoi = 1  if a_hidp==1362001923 & a_pno==2
        qui replace ppnoi = 1  if a_hidp==1362001923 & a_pno==10

        qui replace a_mastat_dv = 2 if a_hidp==1362001923 & a_pno==10
        qui replace mastati = 1 if a_hidp==1362001923  & a_pno==10

    }

    if (`wi'==2) {

        qui replace b_mastat_dv = 10 if b_hidp==137754402 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==137754402 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==412433602 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==412433602 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==545686402 & inlist(b_pno,1,3)
        qui replace mastati = 1 if b_hidp==545686402 & inlist(b_pno,1,3)

        qui replace b_mastat_dv = 10 if b_hidp==580611202 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==580611202 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==616991202 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==616991202 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==646646002 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==646646002 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==647944802 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==647944802 & inlist(b_pno,1,2)

        qui replace b_mastat_dv = 10 if b_hidp==650637602 & inlist(b_pno,1,2)
        qui replace mastati = 1 if b_hidp==650637602 & inlist(b_pno,1,2)


    }

end


capture program drop varsforbuno
program define varsforbuno

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    c_local varsforbuno "`w'hidp `w'pno `w'buno_dv `w'mastat_dv `w'ppno `w'depchl_dv `w'dvage `w'adresp15_dv `w'hgbiom `w'hgbiof `w'ivfio_dv"

end

capture program drop fixbuno
program define fixbuno

    syntax, wave(numlist integer max=1 >=1 <=$numwaves)
    local wi = `wave'
    local w = char(96+`wi') + "_"

    assert `w'hidp > 0 & `w'pno > 0

    di as text %30s "buno" " {c |} "

    * 1. Clean marital status, age, responsible adult number and dependent child indicator
    **************************************************************************************

    * In wave 1, some marital status responses are not consistent within couples
    qui fixmastat, wave(`wi')

    * Check age variable
    qui fixage, wave(`wi')

    * Check dependent indicator
    qui fixdepchl, wave(`wi')

    * Correct responsible adult number using mother and father number (note: this doesn't sort out all cases where there are problems)
    qui fixhgra, wave(`wi')


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
*    di as text `numnewbuno' " buno(s) changed to avoid partners being split across bunos"
    di as text %30s "Spouse --> partner" " {c |} " as res %5.0g `numnewbuno'

    * Re-create buno of partner, etc
    createvars ptrmastat ptrptrpno ptrbuno, wave(`wi')

    * Check spouses both say same status (married or living as couple)
    egen byte look1 = max(ptrmastat != `w'mastat_dv & `w'ppno > 0), by(`w'hidp)
    assert look1 == 0
    drop look1

    * Check spouse numbers are consistent between partners
    egen byte look2 = max(ptrptrpno != `w'pno & `w'ppno > 0), by(`w'hidp)
    assert look2 == 0
    drop look2

    * Check spouses are in the same buno
    egen byte look3 = max(ptrbuno != `w'buno_dv & `w'ppno > 0), by(`w'hidp)
    assert look3 == 0
    drop look3


    * 4. Put children in the same buno as their parent(s)
    *****************************************************

    * Copy buno of responsible adult, natural mother and natural father onto dependent child line
    createvars rabuno mabuno fabuno, wave(`wi')

    * Children 0-15 should be in the same buno as their responsible adult (= mother if present, if not then father if present, if not then someone else)
    * Fix this if it isn't the case
    * Note: those few children without a responsible adult may still appear in their own benefit unit
    qui count if (`w'buno_dv != rabuno & rabuno < .) & inrange(`w'dvage,0,15)
    qui replace bunoi = 1 if (`w'buno_dv != rabuno & rabuno < .) & inrange(`w'dvage,0,15)
    qui replace `w'buno_dv = rabuno if (`w'buno_dv != rabuno & rabuno < .) & inrange(`w'dvage,0,15)
    assert (`w'buno_dv == rabuno) if inrange(`w'dvage,0,15) & rabuno < .
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
    * Note: this is not very general. It only works for cases where there is only one other benefit unit in the household
    qui bys `w'hidp (`w'buno_dv `w'pno): gen byte bunocounter = 1 if _n == 1
    qui by `w'hidp (`w'buno_dv `w'pno): replace bunocounter = bunocounter[_n-1] + (`w'buno_dv != `w'buno_dv[_n-1]) if _n > 1
    egen byte numbunos = max(bunocounter), by(`w'hidp)
    label variable numbunos "Number of bunos in hh"
    drop bunocounter
    egen byte noadshh = min(`w'depchl_dv == 1), by(`w'hidp)
    label variable noadshh "Hh has no adults"
*    assert noadshh == 0
    egen byte noadsbuno = min(`w'depchl_dv == 1), by(`w'hidp `w'buno_dv)
    label variable noadsbuno "Buno has no adults"
*    qui assert numbunos == 2 if noadsbuno
*    qui bys `w'hidp (noadsbuno): replace bunoi = 1 if noadsbuno & numbunos == 2
*    qui bys `w'hidp (noadsbuno): replace `w'buno_dv = `w'buno_dv[1] if noadsbuno & numbunos == 2
*    drop noadsbuno
*    egen byte noadsbuno = min(`w'depchl_dv == 1), by(`w'hidp `w'buno_dv)
*    assert noadsbuno == 0


    * 5. Check adults in buno
    *************************

    * Check no more than 2 adults in buno
    egen byte numadsbuno = total(`w'depchl_dv == 2), by(`w'hidp `w'buno_dv)
    assert numadsbuno <= 2
    * When there are 2 adults, check they are partners
    assert `w'ppno > 0 & `w'ppno < . if (numadsbuno == 2 & `w'depchl_dv == 2)

end

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
            local rhs "`w'buno_dv[\`i'] if (inrange(`w'dvage,0,15) & (`w'adresp15_dv == `w'pno[\`i'])) & (\`i' <= _N)"
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

global numwaves = 2

varsforbuno, wave(2)

*use `varsforbuno' a_sppno using "M:\UnderstandingSociety\data\\a_indall.dta", `clear'
use `varsforbuno' b_sppno using "M:\UnderstandingSociety\data\\b_indall.dta", `clear'

*clist a_hidp if a_depchl_dv ==2 & a_dvage==.
*clist a_hidp if a_depchl_dv ==2 & a_dvage<16

*drop if a_depchl_dv ==2 & a_dvage==.
*drop if a_depchl_dv ==2 & a_dvage<16
