{smcl}
{title:Title}

{p2colset 5 20 20 2}{...}
{p2col:{cmd:usextract} {hline 2}}Extract Understanding Society data across multiple waves{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:usextract} {cmd:using} {it:filename}{cmd:,}
    {cmd:waves(}{it:numlist}{cmd:)}
    [{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt waves(numlist)}}waves to extract (integers 1{hline 1}15){p_end}

{syntab:Dataset options}
{synopt:{opt hhrespoptions(string)}}options for household response file; see {help usextract##hhrespoptions:hhrespoptions}{p_end}
{synopt:{opt hhsampoptions(string)}}options for household sample file; see {help usextract##hhsampoptions:hhsampoptions}{p_end}
{synopt:{opt indalloptions(string)}}options for individual (all) file; see {help usextract##indalloptions:indalloptions}{p_end}
{synopt:{opt indrespoptions(string)}}options for individual response file; see {help usextract##indrespoptions:indrespoptions}{p_end}
{synopt:{opt xwaveoptions(string)}}options for cross-wave file; see {help usextract##xwaveoptions:xwaveoptions}{p_end}

{syntab:Sample options}
{synopt:{opt keepdepkid}}keep dependent children (dropped by default){p_end}
{synopt:{opt keepindwoiv}}keep individuals without an interview in indresp{p_end}
{synopt:{opt dropnohhiv}} drop households where no individual is interviewed {p_end}

{syntab:Other options}
{synopt:{opt uprate(string)}}uprate monetary variables to a common price level; see {help usextract##uprate:uprate}{p_end}
{synopt:{opt neednotexist}}do not error if source data files do not exist for a wave{p_end}
{synopt:{opt mindic}}use extended missing values (.a, .b, ...) to indicate reasons for missingness{p_end}
{synopt:{opt replace}}replace output file if it already exists{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:usextract} builds a longitudinal individual-level dataset from the Understanding Society
raw data files, combining the household response (hhresp), household sample (hhsamp),
individual-all (indall) and individual response (indresp) files across one or more waves.
It optionally merges variables from the cross-wave file (xwavedat).

{pstd}
Beyond simply merging files, the program applies a series of corrections and consistency
checks to the data:

{pstd}
{bf:Family structure.} Benefit unit numbers ({cmd:buno_dv}) are cleaned to ensure that
partners are in the same benefit unit; children aged 0{hline 1}15 are placed in the same
benefit unit as their responsible adult; and dependents aged 16{hline 1}18 are placed in
the same benefit unit as their mother (or father if the mother is absent). Benefit units
with no non-dependent adults are handled, and units with two adults are checked to confirm
they are couples. Minor corrections are also made to the responsible adult number
({cmd:adresp15_dv}).

{pstd}
{bf:Coding frame consistency.} Variables such as marital status ({cmd:mastat_dv}), age
({cmd:dvage}) and dependent child status ({cmd:depchl_dv}) are corrected for
inconsistencies in how they are coded across waves.

{pstd}
{bf:Earnings harmonisation.} The {cmd:jb1earn()} option constructs a single consistent
weekly gross earnings variable by drawing on different source variables depending on
employment status and interview mode. For employees it uses the continuous gross usual pay
variable ({cmd:paygu_dv}); for the self-employed it uses usual pay ({cmd:jspayu}) or
annual profit ({cmd:jsprf}). For proxy and telephone interviews, where only banded earnings
are collected, band midpoints are substituted using wave-specific band definitions.

{pstd}
{bf:Cross-sectional weights.} The {cmd:rxwgt()} option constructs a single
consistently-named weight variable by selecting the appropriate underlying weight for each
wave: {cmd:indinus_xw} (wave 1), {cmd:indinub_xw} (waves 2{hline 1}5),
{cmd:indinui_xw} (waves 6{hline 1}13) and {cmd:inding2_xw} (wave 14 onwards).

{pstd}
{bf:Cross-wave information.} Variables from the official UKHLS cross-wave file
({it:xwavedat.dta}) {hline 1} which have no wave dimension {hline 1} can be merged in
via {cmd:xwaveoptions()}.

{pstd}
After running {cmd:usextract}, users can be confident that {cmd:hidp}, {cmd:pno} and
{cmd:buno_dv} are non-missing; partners share a benefit unit and consistent marital status;
and dependent child indicators are never missing.

{pstd}
The raw data directory must be set in the global macro {cmd:$data} before calling this command.


{marker hhrespoptions}{...}
{title:Options for hhrespoptions()}

{pstd}
Variables available from the household response file ({it:w_hhresp.dta}).
All options take a {it:name} argument specifying what to call the variable in the output dataset.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ivfho(name)}}household interview outcome{p_end}
{synopt:{opt hhintdate(name)}}household interview date{p_end}
{synopt:{opt rooms(name)}}number of rooms{p_end}
{synopt:{opt hown(name)}}whether household owns their home{p_end}
{synopt:{opt tenure(name)}}housing tenure{p_end}
{synopt:{opt hvalue(name)}}house value{p_end}
{synopt:{opt llord(name)}}type of landlord{p_end}
{synopt:{opt furnished(name)}}whether property is furnished{p_end}
{synopt:{opt ctband(name)}}council tax band{p_end}
{synopt:{opt cars(name)}}number of cars{p_end}
{synopt:{opt rent(name)}}monthly rent{p_end}
{synopt:{opt inrent(string)}}components of income included in rent ({cmd:inrent1(}{it:name}{cmd:)} {cmd:inrent2(}{it:name}{cmd:)} {cmd:inrent3(}{it:name}{cmd:)}){p_end}
{synopt:{opt monthlymortgage(name)}}monthly mortgage payment{p_end}
{synopt:{opt hhrxwgt(name)}}household cross-sectional weight{p_end}
{synopt:{opt rawvars(namelist)}}additional raw variables to carry through{p_end}
{synopt:{opt neednotexist}}suppress error if variable missing for a wave{p_end}
{synopt:{opt mindic}}use extended missing values{p_end}
{synoptline}


{marker hhsampoptions}{...}
{title:Options for hhsampoptions()}

{pstd}
Variables available from the household sample file ({it:w_hhsamp.dta}).

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt htype(name)}}household type{p_end}
{synopt:{opt rawvars(namelist)}}additional raw variables to carry through{p_end}
{synopt:{opt neednotexist}}suppress error if variable missing for a wave{p_end}
{synopt:{opt mindic}}use extended missing values{p_end}
{synoptline}


{marker indalloptions}{...}
{title:Options for indalloptions()}

{pstd}
Variables available from the individual (all) file ({it:w_indall.dta}).

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt depkid(name)}}dependent child indicator{p_end}
{synopt:{opt female(name)}}sex (female = 1){p_end}
{synopt:{opt couple(name)}}in a couple{p_end}
{synopt:{opt married(name)}}married{p_end}
{synopt:{opt numkids(name)}}number of own dependent children in household{p_end}
{synopt:{opt age(name)}}age{p_end}
{synopt:{opt ageband(name)}}age band{p_end}
{synopt:{opt ageyng(name)}}age of youngest child{p_end}
{synopt:{opt kidage(name)}}age of children{p_end}
{synopt:{opt numleq12resp(name)}}number of children aged 12 or under with a responsible adult{p_end}
{synopt:{opt parentinhh(name)}}parent present in household{p_end}
{synopt:{opt parentsinhh(name)}}both parents present in household{p_end}
{synopt:{opt numothads18(name)}}number of other adults aged 18+ in household{p_end}
{synopt:{opt hbrooms(name)}}number of bedrooms{p_end}
{synopt:{opt ownkids(name)}}own children indicator{p_end}
{synopt:{opt eqscale(name)}}equivalence scale{p_end}
{synopt:{opt rawvars(namelist)}}additional raw variables to carry through{p_end}
{synopt:{opt neednotexist}}suppress error if variable missing for a wave{p_end}
{synopt:{opt mindic}}use extended missing values{p_end}
{synoptline}


{marker indrespoptions}{...}
{title:Options for indrespoptions()}

{pstd}
Variables available from the individual response file ({it:w_indresp.dta}).
Compound options (marked with *) take a sub-option string rather than a single name.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt ivfio(name)}}individual interview outcome{p_end}
{synopt:{opt hoh(name)}}head of household indicator{p_end}
{synopt:{opt intdate(string)}}* interview date: {cmd:intdate(}{it:name}{cmd:)} {cmd:intyear(}{it:name}{cmd:)} {cmd:intmonth(}{it:name}{cmd:)}{p_end}
{synopt:{opt gor(name)}}government office region{p_end}
{synopt:{opt mover(name)}}mover indicator{p_end}
{synopt:{opt edgrp(name)}}education group{p_end}
{synopt:{opt edgrpnew(name)}}education group (new classification){p_end}
{synopt:{opt edtype(name)}}education type{p_end}
{synopt:{opt labmktmths(name)}}months in each labour market state{p_end}
{synopt:{opt jb1status(name)}}main job status{p_end}
{synopt:{opt jb1soc(name)}}main job SOC occupation code{p_end}
{synopt:{opt jb1start(string)}}* main job start date: {cmd:jb1startd(}{it:name}{cmd:)} {cmd:jb1startm(}{it:name}{cmd:)} {cmd:jb1starty(}{it:name}{cmd:)}{p_end}
{synopt:{opt jb1tenure(name)}}main job tenure{p_end}
{synopt:{opt jb1hrs(name)}}usual hours in main job{p_end}
{synopt:{opt jb1hrsot(name)}}usual overtime hours in main job{p_end}
{synopt:{opt earndate(string)}}* earnings reference date: {cmd:earndate(}{it:name}{cmd:)} {cmd:earnmth(}{it:name}{cmd:)} {cmd:earnyear(}{it:name}{cmd:)}{p_end}
{synopt:{opt jb1earn(string)}}* main job earnings: {cmd:jb1earn(}{it:name}{cmd:)} {cmd:jb1earni(}{it:name}{cmd:)}{p_end}
{synopt:{opt jb1wage(string)}}* main job hourly wage: {cmd:jb1wage(}{it:name}{cmd:)} {cmd:hrscap(}{it:#}{cmd:)}{p_end}
{synopt:{opt benefits(string)}}* benefit receipt: {cmd:cb(}{it:name}{cmd:)} {cmd:iwb(}{it:name}{cmd:)} {cmd:is(}{it:name}{cmd:)} {cmd:ctbccb(}{it:name}{cmd:)} {cmd:jsa(}{it:name}{cmd:)} {cmd:hb(}{it:name}{cmd:)} {cmd:ctc(}{it:name}{cmd:)}{p_end}
{synopt:{opt disben(name)}}disability benefits{p_end}
{synopt:{opt nonlabinc(name)}}non-labour income{p_end}
{synopt:{opt maintinc(name)}}maintenance income{p_end}
{synopt:{opt invinc(name)}}investment income{p_end}
{synopt:{opt saved(name)}}savings amount{p_end}
{synopt:{opt econstat(name)}}economic status{p_end}
{synopt:{opt ilo_unemp(name)}}ILO unemployment indicator{p_end}
{synopt:{opt evermarried(name)}}ever married indicator{p_end}
{synopt:{opt finexpect(name)}}financial expectations{p_end}
{synopt:{opt rxwgt(name)}}individual cross-sectional weight{p_end}
{synopt:{opt rawvars(namelist)}}additional raw variables to carry through{p_end}
{synopt:{opt neednotexist}}suppress error if variable missing for a wave{p_end}
{synopt:{opt mindic}}use extended missing values{p_end}
{synoptline}


{marker xwaveoptions}{...}
{title:Options for xwaveoptions()}

{pstd}
Variables available from the cross-wave file ({it:xwavedat.dta}).
This file has no wave dimension; variables are merged 1:1 on {cmd:pidp}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt rawvars(namelist)}} raw variables to carry through from xwavedat{p_end}
{synopt:{opt neednotexist}}suppress error if variable missing{p_end}
{synopt:{opt mindic}}use extended missing values{p_end}
{synoptline}


{marker uprate}{...}
{title:Options for uprate()}

{pstd}
Uprates monetary variables (marked with the {cmd:touprate} characteristic) to a common price level.
Requires {cmd:intdate()} to be specified within {cmd:indrespoptions()}.

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt year(#)}}target year for uprating{p_end}
{synopt:{opt month(#)}}target month for uprating{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}Set data path and extract waves 1 to 3 with basic individual variables:{p_end}

{phang2}
{cmd:global data "C:\data\ukhls"}{p_end}

{phang2}
{cmd:usextract using "mydata.dta", waves(1/3)} ///
{cmd:indalloptions(age(age) female(female) depkid(depkid))} ///
{cmd:mindic replace}


{title:Authors}

{pstd}Peter Levell (Institute for Fiscal Studies){p_end}
{pstd}David Sturrock (Institute for Fiscal Studies){p_end}
