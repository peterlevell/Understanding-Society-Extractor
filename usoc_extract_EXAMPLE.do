clear all
set more off

* ============================================================
* PATHS - edit these three lines for your machine before running
* ============================================================
* global data       = location of your Understanding Society raw data files
* global datadir_saved = location where you want to save the extracted dataset
* sysdir set PLUS   = location of this extractor (so Stata can find the ado files)
* ============================================================

global data "I:\UnderstandingSociety\data"

*location where you want to save the data (local drive)
global datadir_saved ""

sysdir set PLUS "I:\UnderstandingSociety\Extractor\v3_waves_1_15"
*check that this now in your adopath
sysdir
*Read the helpfile by typing help usextract

program define my_indiv_dataset_multiwave
	
    set more off
    clear	
    qui set mem 200m

    #delimit ;
	
   usextract 	using "$datadir_saved\usdataset_multiwave.dta",
																		waves(1(1)15)

																		/* hhresp */
																		hhrespoptions(
																			ivfho(ivfho)
																			hhintdate(hhintdate)
																			rooms(rooms)
																			hown(hown)
																			tenure(tenure)
																			hvalue(hvalue)
																			llord(llord)
																			furnished(furnished)
																			ctband(ctband)
																			cars(cars)
																			rent(rent)
																			inrent(inrent1(inrent1) inrent2(inrent2) inrent3(inrent3))
																			monthlymortgage(monthlymortgage)
																			hhrxwgt(hhrxwgt)
																			rawvars(hidp)
																			neednotexist
																			mindic					         /* Use extended missing values (.a, .b, etc) to explain why variable is missing */
																		)

																	 /* indall */
																		indalloptions(
																			depkid(depkid)
																			female(female)
																			couple(couple)
																			married(married)
																			numkids(numkids)
																			age(age)
																			ageband(ageband)
																			ageyng(yngkid)
																			kidage(kidage)
																			numleq12resp(resp12)
																			parentinhh(parentinhh)
																			parentsinhh(parentsinhh)
																			numothads18(nothads)
																			hbrooms(hbrooms)
																			ownkids(ownkids)
																			eqscale(eqscale)
																			rawvars(hidp buno_dv pno pidp single_dv ethn_dv)
																			neednotexist
																			mindic								/* Use extended missing values (.a, .b, etc) to explain why variable is missing */
																		)

																		/* indresp */
																		indrespoptions(
																			ivfio(ivfio)
																			hoh(hoh)
																			intdate(intdate(intdate) intyear(intyear) intmonth(intmonth))
																			gor(gor)
																			mover(mover)
																			edgrp(edgrp)
																			edgrpnew(edgrpnew)
																			edtype(edtype)
																			labmktmths(labmktmths)
																			jb1status(jb1status)
																			jb1soc(jb1soc)
																			jb1start(jb1startd(jb1startd) jb1startm(jb1startm) jb1starty(jb1starty))
																			jb1tenure(jb1tenure)
																			jb1hrs(jb1hrs)
																			jb1hrsot(jb1hrsot)
																			benefits(cb(cb) iwb(iwb) is(is) ctbccb(ctbccb) jsa(jsa) hb(hb) ctc(ctc))
																			disben(disben)
																			nonlabinc(nonlabinc)
																			maintinc(maintinc)
																			earndate(earndate(earndate) earnmth(earnmth) earnyear(earnyear))
																			jb1earn(jb1earn(jb1earn) jb1earni(jb1earni))
																			jb1wage(jb1wage(jb1wage) hrscap(50))
																			invinc(invinc)
																			saved(saved)
																			econstat(econstat) 
																			evermarried(evermarried)
																			ilo_unemp(ilo_unemp)
																			finexpect(finexpect)
																			rxwgt(rxwgt)
																			rawvars(hidp pno pidp mvyr mvever)
																			neednotexist
																			mindic								     /* Use extended missing values (.a, .b, etc) to explain why variable is missing */
																		)

																		/* hhsamp */
																		hhsampoptions(
																			htype(htype)
																			rawvars(hidp)
																			neednotexist
																			mindic									/* Use extended missing values (.a, .b, etc) to explain why variable is missing */
																		)
																		
																		xwaveoptions(
																			rawvars(pid ukborn ethn_dv)
																			neednotexist
																			mindic								    /* Use extended missing values (.a, .b, etc) to explain why variable is missing */
																		)

																		keepdepkid								    /* Keep dependent children */
																		keepindwoiv                                 /* Keep individuals without an interview in indresp */


																		replace								        /* Replace existing dataset if it exists */

																		;

    #delimit cr

end

my_indiv_dataset_multiwave


use "$datadir_saved\usdataset_multiwave.dta", clear

drop if hhrxwgt==.
drop if nohh==1 

save "$datadir_saved\usdataset_multiwave.dta", replace
