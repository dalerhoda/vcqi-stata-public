*! vcqi_to_double_iwplot version 1.16 - Biostat Global Consulting - 2017-05-26
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2015-12-21	1.01	MK Trimner		vcqi_log_comment missing "Error" added to the below lines:
*										vcqi_log_comment $VCP 1 Error "The VCQI database passed in to this program does not seem to exist."
*										vcqi_log_comment $VCP 1 Error "The database named was `database'."			
*
* 2016-01-12	1.02	D. Rhoda		Updated to go with iwplot_vcqi v. 1.10
*
* 2016-08-07 	1.04	D. Rhoda		Updated with default iwplot NL value
* 2016-09-08	1.05	D. Rhoda		Added Plots_IW_UW folder
* 2016-09-20	1.06	D. Rhoda		Fixed sort when showing levels 1 and 3
*										but not 2
* 2017-01-26	1.07	D. Rhoda		Do not include horizontal line at top
* 2017-01-27	1.08	D. Rhoda		Check to see that the files associated with
*										database database2 datafile and datafile2
*										all exist before proceeding. Else fail.
* 2017-01-31	1.09	D. Rhoda		Cleaned up code
* 2017-02-15	1.10	Dale Rhoda		Allow plotting with LEVEL4_SET_VARLIST
*										and use lighter shade for level4 rows
* 2017-03-18	1.11	Dale Rhoda		Only shade level 1 results if also
*										showing results from levels 2 or 3
* 2017-05-16	1.12	Dale Rhoda		Restructured to also make level2 plots
*										if the user requests them 
* 2017-05-18	1.13	Dale Rhoda		Change to default blue colors
* 2017-05-19	1.14	Dale Rhoda		Fix a problem with quotation marks
* 2017-05-25	1.15	Dale Rhoda		Fix a problem with ylines
* 2017-05-26	1.16	Dale Rhoda		Handle vertical lines when national 
*										results are at the top or bottom row
*******************************************************************************

capture program drop vcqi_to_double_iwplot
program define vcqi_to_double_iwplot

	version 14
	
	syntax , DATABASE(string asis) FILETAG(string) DATAFILE(string asis) DATABASE2(string asis) DATAFILE2(string asis) ///
	[ TITLE(string asis) NAME(string) SUBTITLE(string asis) CAPTION(string asis) ]
	
	local oldvcp $VCP
	global VCP vcqi_to_iwplot
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	capture confirm file "`database'.dta"
	
	if _rc != 0 {
		di as error "vcqi_to_double_iwplot: The VCQI database passed in to this program does not seem to exist."
		di as error "vcqi_to_double_iwplot: The database named was `database'."

		vcqi_log_comment $VCP 1 Error "The VCQI database passed in to this program does not seem to exist."
		vcqi_log_comment $VCP 1 Error "The database named was `database'."
		
		vcqi_halt_immediately
	}
	
	capture confirm file "`database2'.dta"
	
	if _rc != 0 {
		di as error "vcqi_to_double_iwplot: The VCQI database2 passed in to this program does not seem to exist."
		di as error "vcqi_to_double_iwplot: The database2 named was `database2'."

		vcqi_log_comment $VCP 1 Error "The VCQI database2 passed in to this program does not seem to exist."
		vcqi_log_comment $VCP 1 Error "The database2 named was `database2'."
		
		vcqi_halt_immediately
	}

	capture confirm file "`datafile'.dta"
	
	if _rc != 0 {
		di as error "vcqi_to_double_iwplot: The VCQI datafile passed in to this program does not seem to exist."
		di as error "vcqi_to_double_iwplot: The database named was `datafile'."

		vcqi_log_comment $VCP 1 Error "The VCQI datafile passed in to this program does not seem to exist."
		vcqi_log_comment $VCP 1 Error "The database named was `datafile'."
		
		vcqi_halt_immediately
	}
	
	capture confirm file "`datafile2'.dta"
	
	if _rc != 0 {
		di as error "vcqi_to_double_iwplot: The VCQI datafile2 passed in to this program does not seem to exist."
		di as error "vcqi_to_double_iwplot: The database2 named was `datafile2'."

		vcqi_log_comment $VCP 1 Error "The VCQI datafile2 passed in to this program does not seem to exist."
		vcqi_log_comment $VCP 1 Error "The database2 named was `datafile2'."
		
		vcqi_halt_immediately
	}
	
	use "`database'", clear
	
	* Drop Level 4 labels if using the SET nomenclature
	if "$VCQI_LEVEL4_SET_VARLIST" != "" & "$LEVEL4_SET_CONDITION_1" == "" drop if level4id == 1

	local show4 = $SHOW_LEVELS_1_4_TOGETHER   + ///
				  $SHOW_LEVELS_2_4_TOGETHER   + ///
				  $SHOW_LEVELS_3_4_TOGETHER   + ///
				  $SHOW_LEVELS_2_3_4_TOGETHER > 0
				   
	local show3 = $SHOW_LEVEL_3_ALONE         + ///
				  $SHOW_LEVELS_2_3_TOGETHER   + ///
				  $SHOW_LEVELS_3_4_TOGETHER   + ///
				  $SHOW_LEVELS_2_3_4_TOGETHER > 0 

	local show2 = $SHOW_LEVEL_2_ALONE         + ///
				  $SHOW_LEVELS_2_3_TOGETHER   + ///
				  $SHOW_LEVELS_2_4_TOGETHER   + ///
				  $SHOW_LEVELS_2_3_4_TOGETHER > 0 
				   
	local show1 = $SHOW_LEVEL_1_ALONE + $SHOW_LEVELS_1_4_TOGETHER > 0			   

	if `show4' == 0 drop if level4id != .

	if `show3' == 0 drop if level == 3

	if `show2' == 0 drop if level == 2

	if `show1' == 0 drop if level == 1

	forvalues i = 1/4 {
		if `show`i'' == 1 local showmax `i'
	}
	forvalues i = 4(-1)1 {
		if `show`i'' == 1 local showmin `i'
	}

	local show2plus = (`show4' + `show3' + `show2' + `show1') > 1

	local l3est
	local l2est

	if `show3' == 1 & `show4' == 1 {
		gen level3_dropthis = estimate if level == 3 & level4id == .
		bysort level3id: egen level3_estimate = max(level3_dropthis)
		drop level3_dropthis
		replace level3_estimate = . if level3id == .
		local l3est level3_estimate level3id
	}
	if `show3' == 1 & `show4' == 0 gen level3_estimate = estimate
	capture order level3_estimate, after(outcome)

	if `show2' == 1 & (`show3' == 1 | `show4' == 1) {
		gen level2_dropthis = estimate if level == 2 & level4id == .
		bysort level2id: egen level2_estimate = max(level2_dropthis)
		drop level2_dropthis
		replace level2_estimate = . if level2id == .
		local l2est level2_estimate level2id
	}
	if `show2' == 1 & (`show3' + `show4' == 0 ) gen level2_estimate = estimate
	capture order level2_estimate, after(outcome)

	if `show1' == 1 & (`show2' == 1 | `show3' == 1 | `show4' == 1) {
		gen level1_dropthis = estimate if level == 1 & level4id == .
		bysort level1id: egen level1_estimate = max(level1_dropthis)
		drop level1_dropthis
		order level1_estimate, after(outcome)
	}

	if `show1' == 1 & `show2' == 1 replace level2_estimate = level1_estimate if level2_estimate == .
	if `show1' == 1 & `show2' == 0 & `show3' == 1 replace level3_estimate = level1_estimate if level3_estimate == .
	if `show2' == 1 & `show3' == 1 replace level3_estimate = level2_estimate if level3_estimate == .

	sort `l2est' `l3est' estimate

	if `show4' == 1 sort `l2est' `l3est' estimate level4id
		
	* Build rightsidetext to look like citext(1)
	
	* lower limit of traditional 95% CI
	gen p       = 100*estimate
	replace lcb = 100*lcb
	replace ucb = 100*ucb

	* 95% upper confidence bound (UCB)
	gen     ub_str2 = string(ucb, "%4.1f")
	replace ub_str2 = "100" if ub_str2=="100.0"
	
	* 95% lower confidence bound (LCB)
	gen     lb_str3 = string(lcb, "%4.1f")
	replace lb_str3 = "100" if lb_str3=="100.0"
	
	*   cistring1 contains lower 95% confidence bound (LCB), p, and 95% upper confidence bound
	gen rightsidetext =  strtrim(lb_str3) + " | " + strtrim(string(p, "%4.1f")) + " | " + ub_str2 
	
	keep name n deff estimate level level*id outcome rightsidetext
	
	* populate param4, 5, 6, and 7 in case the user decides to plot distributions from the data later
	gen rightid = .
	replace rightid = level3id if level == 3
	replace rightid = level2id if level == 2
	replace rightid = level1id if level == 1
	gen param7 = "if level" + string(level) + "id == " + string(rightid)
	if "$VCQI_LEVEL4_STRATIFIER"  != "" replace param7 = param7 + " & $VCQI_LEVEL4_STRATIFIER == " + string(level4id) if !missing(level4id) 
	if "$VCQI_LEVEL4_SET_VARLIST" != "" {
		forvalues i = 1/$LEVEL4_SET_NROWS {
			replace param7 = param7 + " & ${LEVEL4_SET_CONDITION_`i'} " if level4id == `i' & "${LEVEL4_SET_CONDITION_`i'}" != ""
		}
	}
	gen param6 = "svyset clusterid, weight(psweight) strata(stratumid)"
	gen param5 = outcome
	gen param4 = "`datafile'"

	gen source  = "DATASET"
	gen disttype = "SVYP"
	gen nparams  = 7
	gen param1 = round(n/deff,1) // effective sample size
	gen param2 = estimate
	gen param3 = "$VCQI_CI_METHOD" 
	
	gen outlinecolor = "vcqi_outline"

	* User specifies the colors for levels 1-4 in their adopath
	* 
	* There are files named color-vcqilevel1.style (and 2, 3, 4)
	* and color-vcqioutline.style
	* somewhere in the adopath...change the RGB values of those
	* files to get different colors in the plots.
	
	gen areacolor = ""
	forvalues i = 1/3 {
		replace areacolor = "vcqi_level`i'" if level == `i'
	}
	replace areacolor = "vcqi_level4" if !missing(level4id)

	gen markvalue = .
	gen clip = 95
	gen lcb  = 95
	gen ucb  = 95
	gen lcbcolor = "gs7"
	gen ucbcolor = "gs7"
	gen shadebehind = "gs15" if level == 1 & (`show2' + `show3' > 0)

	gen rowname = name
	
	save "Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'", replace
	
	* Now specify inputs for the second set of shapes
	*
	* These will be gray with no fill and they will not
	* show the LCB or UCB
	*
	* Each gray shape is plotted AFTER its corresponding colored
	* shape, so the gray shape will appear on top of the colored
	* one if there is any overlap.
	
	* Store the name of the second outcome
	use "`database2'", clear
	local outcome2 = outcome[1]
	
	use "Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'", clear
	gen rownumber = _n
	local nrows = _N
	expand 2
	bysort rownumber: gen nn = _n
	replace param4 = "`datafile2'" if nn == 2
	replace param5 = "`outcome2'"  if nn == 2
	replace outlinecolor = "gs3"   if nn == 2
	replace areacolor = "none"     if nn == 2
	replace lcb = .                if nn == 2
	replace ucb = .                if nn == 2
	replace rightsidetext = ""     if nn == 2
	
	save "Plots_IW_UW/iwplot_params_base", replace
	save "Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'", replace
	
	local pass_thru_options
	if `"`title'"'     != "" local pass_thru_options `pass_thru_options' title(`title')
	if `"`subtitle'"'  != "" local pass_thru_options `pass_thru_options' subtitle(`subtitle')
	if `"`note'"'      != "" local pass_thru_options `pass_thru_options' note(`note')
	if `"`caption'"'   != "" local pass_thru_options `pass_thru_options' caption(`caption')
		
	double_inchworm_plotit, filetag(`filetag') show1(`show1') show2(`show2') show3(`show3') ///
	        show4(`show4') `pass_thru_options' name(`name')
			
	* Make inchworm plot for every level 2 stratum, if requested

	if `show2' == 1 & "$VCQI_MAKE_LEVEL2_IWPLOTS" == "1" {
		use "$VCQI_DATA_FOLDER/level2names", clear
		forvalues i = 1/`=_N' {
			local l2name_`=level2id[`i']' = subinstr("`=level2name[`i']'"," ","_",.)
		}
		levelsof level2id, local(l2list)
		foreach l2l in `l2list' {

			use "Plots_IW_UW/iwplot_params_base", clear
			
			keep if level == 1 | level2id == `l2l'
			
			* shift all the rownumbers down so the first is 1, etc.
			gen rip_sortorder = _n
			sort rownumber
			rename rownumber rownumber_old
			gen rownumber = .
			replace rownumber = 1 in 1
			forvalues i = 2/`=_N' {
				if rownumber_old[`i'] == rownumber_old[`=`i'-1'] replace rownumber = rownumber[`=`i'-1'] in `i'
				else replace rownumber = rownumber[`=`i'-1'] + 1 in `i'
			}
			sort rip_sortorder
			drop rip_sortorder 
			*
			
			save "Plots_IW_UW/iwplot_params_`filetag'_l2_`l2l'_`show1'`show2'`show3'`show4'", replace
			
			double_inchworm_plotit, filetag(`filetag'_l2_`l2l') show1(`show1') show2(`show2') show3(`show3') ///
					show4(`show4') `pass_thru_options' name(`name'_l2_`l2l'_`l2name_`l2l'')
				
			vcqi_log_comment $VCP 3 Comment "Inchworm plot was created and exported."
		
			graph drop _all
		}
	}

	if $DELETE_TEMP_VCQI_DATASETS == 1 capture erase "Plots_IW_UW/iwplot_params_base"
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'
	
end
	
program define double_inchworm_plotit

	syntax ,  FILETAG(string) show1(integer) show2(integer) show3(integer) show4(integer) ///
	  [ TITLE(string asis) NAME(string) ///
	  SUBTITLE(string asis) NOTE(string asis) CAPTION(string asis) ]
	  
	use "Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'", clear
	
	* Decide where to plot lines across the plot
	* For now, we only add horizontal lines where we transition between level2
	* strata and we only do it if we are showing both level 2 and level 3 strata

	summarize rownumber
	local nrows = r(max)
	
	if `show2' == 1 & `show3' == 1 {
		tempvar sortorder
		gen `sortorder' = _n
		sort nn rownumber
		local ylist
		forvalues i = 1/`=`nrows'-1' {
			if level2id[`i'] != level2id[`=`i'+1'] local ylist `ylist' `=rownumber[`i']+0.5'
		}
		* Add a line above if the top row is showing national results
		if level[`nrows'] == 1 local ylist `ylist' `=`nrows'+0.5'
		* Add a line at the bottom if the first row shows national results
		if level[1]       == 1 local ylist 0.5 `ylist'
		
		sort `sortorder'
		drop `sortorder'
		drop nn
	}
	
	if "`ylist'" != "" {
		
		clear
		set obs `=wordcount("`ylist'")'
		gen ycoord 		= .
		gen xstart 		= 0
		gen xstop  		= 100
		gen color		= "gs12"
		gen thickness 	= "thin"
		gen style     	= "foreground"
		forvalues i = 1/`=_N' {
			replace ycoord = real(word("`ylist'",`i')) in `i'
		}
		
		tempfile horlines
		
		save `horlines', replace
	}
	
	* List key to right side text in a note
	local note Text at right: 1-sided 95% LCB | Point Estimate | 1-sided 95% UCB, size(vsmall) span
		
	local saving
	if $SAVE_VCQI_GPH_FILES ///
		local saving saving(Plots_IW_UW/`name'_`show1'`show2'`show3'`show4', replace)
		
	local export export(Plots_IW_UW/`name'_`show1'`show2'`show3'`show4'.png , width(2000) replace)	
	
	local clean 
	if $DELETE_TEMP_VCQI_DATASETS == 1 local clean cleanwork(YES)
	
	* If the user has not specified a value for NL, use a default of 30
	* (sometimes the user might specify a lower value to make fast, draft-quality plots
	*  but a value of 30 or 50 should be used for final product plots)
	
	if "$VCQI_IWPLOT_NL" == "" vcqi_global VCQI_IWPLOT_NL 30
		
	iwplot_svyp , ///
		inputdata("Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'") ///
		nl($VCQI_IWPLOT_NL) ///
		xtitle("Estimated Coverage %") ///
		horlinesdata("`horlines'") ///
		note(`note') ///
		caption(`caption') ///
		title(`title', span) ///
		subtitle(`subtitle', span) ///
		name(`=substr("`name'",1,min(32,length("`name'")))', replace) `saving' `clean' `export' 		
		
	if $DELETE_TEMP_VCQI_DATASETS == 1 capture erase "Plots_IW_UW/iwplot_params_`filetag'_`show1'`show2'`show3'`show4'.dta"

end
