* I want to take indrespoptions and parse it like syntax does, putting the results into locals with the corresponding names


* In calling program, need to add a check that wave has been specified (because here all options are treated as being optional)

*********************************************************************************
* PROGRAM: check_option_syntax                                                 	*
*********************************************************************************
*                                                                              	*
* DESCRIPTION: parse options and check they're correctly specified             	*
*                                                                              	*
* LONG DESCRIPTION: the Stata syntax command will accept a maximum of 70 		*
*		options (this is the maximum you can pass to the syntax command and the	*
*		maximum you can specify in the syntax command). I need to be able to deal *
*		with more than 70 options. This program parses options (note it's only the *
*		options and not the whole Stata syntax), checks they're correctly 		*
*		specified and returns the options specified in locals just like the syntax *
*		command does. It can deal with as many options as you like				*
*                                                                              	*
* NOTE:                                                                        	*
* - All options are treated as optional (so need to check existence of         	*
*   compulsory options outside this program)                                   	*
*                                                                              	*
* PARAMETERS                                                                  	*
* - optionspec(): option specification, e.g. wave(integer) ivfio(name) 			*
*			intdate(string) region(name)										*
* - optionlist(): list of options specified by user, e.g. wave(5) ivfio(ivfio) 	*
*			intdate(intdate(intdate) intyear(intyear) intmonth(intmonth)) 		*
*			region(region)														*
* - ignore: ignore options that are in optionlist but not in optionspec 		*
*                                                                              	*
*********************************************************************************

capture program drop check_option_syntax
program define check_option_syntax

	syntax, optionspec(string asis) optionlist(string asis) [ignore]

	* Remove any quotes surrounding the whole local strings
	local optionspec `optionspec'
	local optionlist `optionlist'

	* Break optionspec up into individual option specs
	* suffix() adds specified suffix to the local name of each option
	break_up_options, optionlist(`optionspec') suffix("_spec")

	* Break optionlist up into individual options
	* suffix() adds specified suffix to the local name of each option
	* listname is the name of a local that will list all the locals that were created
		* (i.e. options that were listed plus any specified prefix and suffix) but not their arguments)
	break_up_options, optionlist(`optionlist') suffix("_listed") listname(optionslisted)

	* optionslisted will contain e.g. "wave_listed ivfio_listed intdate_listed region_listed"
	foreach option of local optionslisted {

		* Remove "_listed" suffix
		local option : subinstr local option "_listed" ""

		* Check corresponding option spec exists (unless ignore is specified)
		if `"``option'_spec'"' == "" {
			if  ("`ignore'" == "") {
				di as error "Unknown option `option'"
				exit 198
			}
		}
		else {
			* Construct option to check
			local 0 `", ``option'_listed'"'

			* Check syntax of option
			syntax, ``option'_spec'

			* Copy option into calling environment
			c_local `option' ``option''
		}
	}



end


********************************************************************************
* PROGRAM: break_up_options                                                    *
********************************************************************************
*                                                                              *
* DESCRIPTION: split a list of options into separate option components         *
*    and return in locals in calling environment                               *
*                                                                              *
* PARAMETERS                                                                   *
* - optionlist(): list of options to break up, e.g. wave(5) ivfio(ivfio)			 *
*   	intdate(intdate(intdate) intyear(intyear) intmonth(intmonth))						 *
* 		region(region)																													 *
*	- prefix(): string to prefix each option name	with (needed so repeated calls *
*			don't overwrite each other)																							 *
*	- suffix(): string to suffix each option name with (needed so repeated calls *
*			don't overwrite each other)																							 *
*	- listname(): name of local containing list of options specified (but not 	 *
*			their contents																													 *
*                                                                              *
********************************************************************************

capture program drop break_up_options
program define break_up_options

	syntax, optionlist(string asis) [prefix(name) suffix(name) listname(name)]

	* Loop through options, copying them into locals named after the option
	while `"`optionlist'"' != "" {
		gettoken tok optionlist : optionlist, bind
		if regexm(`"`tok'"',"^([a-zA-Z0-9_]+)\((.+)\)$") {
			c_local `prefix'`=regexs(1)'`suffix' `"`=regexs(1)'(`=regexs(2)')"'
		}
		else if regexm(`"`tok'"',"^([a-zA-Z0-9_]+)$") {
			c_local `prefix'`=regexs(1)'`suffix' `"`=regexs(1)'"'
		}
    	local list `"`list' `prefix'`=regexs(1)'`suffix'"'
	}

	* Copy list of options specified into listname if requested
	if "`listname'" != "" c_local `listname' `"`list'"'


end


exit


