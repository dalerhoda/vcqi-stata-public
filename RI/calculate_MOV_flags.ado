*! calculate_MOV_flags version 1.08 - Biostat Global Consulting - 2017-02-09
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2015-12-21	1.01	MK Trimner		added globals VCP and VCP  and starting comment
*
* 2016-04-01	1.02	Mary Prier		Added a block of code that uses local 
*										macros to build a global macro that will 
*										list which doses with dates to loop 
*										through, if this global macro is not
* 										already defined in the control program.
* 										
* 2016-04-06	1.03	Mary Prier		For crude doses, replace eligible with 0 
*                                       if child got an early dose (single or
*                                       multi-dose). Also, updated code at the
* 										bottom that flags mov_for_anydose_`t' to
* 										use flag_had_mov_`d'_`t' variable.
*
* 2016-06-12	1.04	Dale Rhoda		Fixed logic for total_elig_`d'_`t' &
*                                       finished audit for Issue 106: audit
*                                       MOV flags for single dose & 3-dose
*                                       vaccines
*
* 2016-09-19	1.05	Dale Rhoda		Only run if VCQI_CHECK_INSTEAD_OF_RUN
*										is not 1
*
* 2017-01-09	1.06	Dale Rhoda		Only run if 1+ respondents has a
*										dob_for_valid_dose_calculations
*
* 2017-01-30	1.07	Dale Rhoda		Use sleight of hand to calculate MOV
*										flags for 2-dose vaccines.  At the top
*										of this program, add them to the list
*										of 3-dose vaccines and generate dose
*										3 scalars and variables...then calculate
*										MOV flags for all single-dose and 3-dose
*										vaccines...and at the bottom of the 
*										program, strip off the dose 3 variables
*										for the 2-dose vaccines.  The net 
*										result is that MOV flags for dose 2
* 										are calculated in the same manner for
*										2-dose and 3-dose vaccines.
*
* 2017-02-09	1.08	Dale Rhoda		Set tick back to 0 if register sets
*										it to missing
*******************************************************************************

program define calculate_MOV_flags
	
	local oldvcp $VCP
	global VCP calculate_MOV_flags
	vcqi_log_comment $VCP 5 Flow "Starting"	
	
	quietly {

		if "$VCQI_CHECK_INSTEAD_OF_RUN" != "1" {

			use "RI_with_ids", clear
			
			* If none of the respondents have a dob_for_valid_dose_calculations
			* then do not set MOV flags
			
			if "$VCQI_NO_DOBS" == "1" {		
				vcqi_log_comment $VCP 2 Warning "User attempted to calculate Missed Opportunities for Vaccination (MOV) flags, but none of the respondents has a complete data of birth for valid dose calculations."
			}
			else {
			
				if "$VCQI_TESTING_CODE" == "" global VCQI_TESTING_CODE 0
				
				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step00, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step00
				}

				keep respid dob_for_valid_dose_calculations *card_date *card_tick ///
					 no_card *register_date *register_tick *_history 
								
				* If RI_RECORDS_NOT_SOUGHT, we just use data from the cards.
				
				* IF RI_RECORDS_SOUGHT_IF_NO_CARD then for MOV purposes we copy register 
				* dates to the card fields and calculate everything with the card variables.
				
				* IF RI_RECORDS_SOUGHT_FOR_ALL then when there is no card, copy the register
				* record to the card fields, and when there is both a card and an HC record,
				* then fill missing dates on the card from register for:
				*   a) any missing single-dose vaccine if the register has a date and card
				*      does not
				*   b) any series of doses if the register has more dates in the series
				*      than the card...if the register has fewer or the same number, 
				*      then just use the data from the card
				
				if $RI_RECORDS_NOT_SOUGHT == 1 {
					* No action required...
				}
				if $RI_RECORDS_SOUGHT_IF_NO_CARD == 1 {
					foreach d in `=lower("$RI_DOSE_LIST")' {
						replace `d'_card_date = `d'_register_date if no_card == 1
						replace `d'_card_tick = `d'_register_tick if no_card == 1
					}
				}
				if $RI_RECORDS_SOUGHT_FOR_ALL == 1 {
					foreach d in `=lower("$RI_SINGLE_DOSE_LIST")' {
						replace `d'_card_date = `d'_register_date if no_card == 1
						replace `d'_card_tick = `d'_register_tick if no_card == 1
						capture drop moveit
						* use register data if there's a date on register and not card or
						* if there are no dates, but there's a tick on register and not card
						gen moveit = (missing(`d'_card_date) & !missing(`d'_register_date)) | ///
									 (missing(`d'_card_date) & missing(`d'_register_date) & ///
									 !missing(`d'_register_tick) & `d'_card_tick != 1)
						replace `d'_card_date = `d'_register_date if moveit == 1
						replace `d'_card_tick = `d'_register_tick if moveit == 1
						drop moveit
					}
					
					foreach d in `=lower("$RI_MULTI_2_DOSE_LIST")' {
						* Use register data if there are more dates in the register for this 2-dose series than appear on the card
						capture drop moveit

						gen moveit = (!missing(`d'1_register_date)+!missing(`d'2_register_date) ) > ///
									 (!missing(`d'1_card_date)    +!missing(`d'2_card_date)     )	
									 
						forvalues i = 1/2 {
							replace `d'`i'_card_date = `d'`i'_register_date if moveit == 1
							replace `d'`i'_card_tick = `d'`i'_register_tick if moveit == 1
						}
					}
					
					foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
						* Use register data if there are more dates in the register for this 3-dose series than appear on the card
						capture drop moveit

						gen moveit = (!missing(`d'1_register_date)+!missing(`d'2_register_date) + !missing(`d'3_register_date)) > ///
									 (!missing(`d'1_card_date)    +!missing(`d'2_card_date)     + !missing(`d'3_card_date))	
									 
						forvalues i = 1/3 {
							replace `d'`i'_card_date = `d'`i'_register_date if moveit == 1
							replace `d'`i'_card_tick = `d'`i'_register_tick if moveit == 1
						}
					}
				}
				
				* Now set the card tick variable to yes if the card date is missing and 
				* the tick is not set, but the history is set...for MOV flags, we treat
				* a history report as the same as a card tick...we do not put a child 
				* with either a card tick or a history report in the denominator for MOVs
				foreach d in `=lower("$RI_DOSE_LIST")' {
					replace `d'_card_tick = 0 if missing(`d'_card_tick)
					replace `d'_card_tick = 1 if missing(`d'_card_date) & ///
												 `d'_card_tick == 0 & `d'_history == 1
				}	

				local s card
							
				keep respid dob_for_valid_dose_calculations *`s'_date *`s'_tick 
				drop dob_`s'_date
				
				* Now generate dose 3 variables for all 2-dose vaccines so this code
				* will calculate flags for the 2nd dose of a 2-dose series using the
				* same logit as for the 2nd dose of a 3-dose series.  At the bottom
				* of this program we will clean this up and remove all variables
				* associated with the 3rd dose of a 2-dose series.  This is simply
				* a convenience (and a fiction) for this program.
				
				vcqi_log_comment $VCP 3 Comment "Generating fictional variables associated with 3rd dose of 2-dose vaccines"
				vcqi_global RI_DOSE_LIST_SAVED $RI_DOSE_LIST
				vcqi_global RI_MULTI_3_DOSE_LIST_SAVED $RI_MULTI_3_DOSE_LIST
				foreach d in `=lower("$RI_MULTI_2_DOSE_LIST")' {
					gen `d'3_card_date = .
					gen `d'3_card_tick = 0
					vcqi_scalar `d'3_min_interval_days = `d'2_min_interval_days
					vcqi_scalar `d'3_min_age_days      = `d'2_min_age_days + `d'2_min_interval_days
					vcqi_global RI_MULTI_3_DOSE_LIST $RI_MULTI_3_DOSE_LIST `d'
					vcqi_global RI_DOSE_LIST $RI_DOSE_LIST `d'3
				}			

				* Generate a 3 char string D/T/M (date/tick/missing) for doses in a series
				* Note: This variable will be used at bottom of code when updating MOV flags

				forvalues i=1/3 {
					foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
						
						* Generate a string variable for each dose first, then concatenate them together
						gen `d'`i'_str1 = ""
						
						* Figure out if dose if D T or M
						replace `d'`i'_str1="M" if missing(`d'`i'_`s'_date) & `d'`i'_`s'_tick == 0
						replace `d'`i'_str1="T" if `d'`i'_`s'_tick == 1
						replace `d'`i'_str1="D" if !missing(`d'`i'_`s'_date)

					}
				}

				* Concatenate 3 doses into 1 string variable
				foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
					gen `d'_str3 = `d'1_str1 + `d'2_str1 + `d'3_str1
					tab `d'_str3, m
				}

				capture drop *_str1
				
				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step01, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step01
				}

				*******************************************************************************
				* This code uses local macros to build a global macro that will list
				* which doses with dates to loop through.  The global macro that lists which
				* doses are to be ANALYZED is a subset of this list, as this list may include
				* dates from doses that are not to be analyzed.  Usually, the two globals 
				* will be the same though, but flexibility is built in the code here.
				
				if "$RI_DOSES_WITH_DATES"=="" {
					
					local single $RI_SINGLE_DOSES_WITH_DATES
					if "`single'"=="" local single $RI_SINGLE_DOSE_LIST
					
					local multi3 $RI_MULTI_3_DOSES_WITH_DATES
					if "`multi3'"=="" local multi3 $RI_MULTI_3_DOSE_LIST
					
					* Construct the global RI_DOSES_WITH_DATES using the above locals
					* VCQI currently handles single-dose and three-dose vaccines. 

					* First, list single dose vaccines 
					global RI_DOSES_WITH_DATES `single'

					* Finally, list each dose for three-dose vaccines 
					foreach i in `multi3' {
						global RI_DOSES_WITH_DATES "$RI_DOSES_WITH_DATES `i'1 `i'2 `i'3"
					}

					* Put a copy of the dose list in the log
					vcqi_log_global RI_DOSES_WITH_DATES
				}
				
				vcqi_log_comment $VCP 5 Issue123 "RI_DOSES_WITH_DATES is: $RI_DOSES_WITH_DATES"

				*******************************************************************************
				* Now we're going to convert this from a wide dataset with one row per
				* respondent to a long dataset with one row per respondent/date...so if
				* the first respondent was vaccinated on 5 different dates, they'll have
				* five rows in the long dataset...each row indicates which vaccines the
				* person received on that date.  Each row also indicates whether they got
				* the dose according to tick instead of date, and we carry along the useful
				* 3-character strings for the 3-dose vaccines, as well.

				local vlist respid dob visitdate

				foreach d in `=lower("$RI_SINGLE_DOSE_LIST")' {
					local vlist `vlist' got_`d' got_`d'_tick
				}

				foreach d in  `=lower("$RI_MULTI_3_DOSE_LIST")' {
					local vlist `vlist' got_`d' got_`d'1_tick got_`d'2_tick got_`d'3_tick
				}

				foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
					local vlist `vlist' str3 `d'_str3
				}

				********************************************************************************

				capture postclose handle
				postfile handle `vlist' using movlong, replace
								
				forvalues i = 1/`=_N' {
					foreach d1 in `=lower("$RI_DOSES_WITH_DATES")'  {
						local plist		
						if `d1'_`s'_date[`i']==. continue
						foreach d2 in `=lower("$RI_SINGLE_DOSE_LIST")'  {
							if `d1'_`s'_date[`i']==`d2'_`s'_date[`i'] {
								local plist `plist' (1) (`=`d2'_`s'_tick[`i']')
							}
							else {
								local plist `plist' (0) (`=`d2'_`s'_tick[`i']')
							}
						}
						foreach d2 in `=lower("$RI_MULTI_3_DOSE_LIST")'  {
							if `d1'_`s'_date[`i']==`d2'1_`s'_date[`i'] | ///
							   `d1'_`s'_date[`i']==`d2'2_`s'_date[`i'] | ///
							   `d1'_`s'_date[`i']==`d2'3_`s'_date[`i'] {

								local plist `plist' (1) (`=`d2'1_`s'_tick[`i']') (`=`d2'2_`s'_tick[`i']') (`=`d2'3_`s'_tick[`i']')
							}
							else {
								local plist `plist' (0) (`=`d2'1_`s'_tick[`i']') (`=`d2'2_`s'_tick[`i']') (`=`d2'3_`s'_tick[`i']')
							}
						}

						foreach d2 in `=lower("$RI_MULTI_3_DOSE_LIST")'  {
							local plist `plist' (`d2'_str3[\`i\'])
						}

						post handle (respid[`i']) (dob_for_valid_dose_calculations[`i']) (`d1'_`s'_date[`i']) ///
									`plist' 
					}
				}


				capture postclose handle

				use movlong, clear

				qui compress
				format %td dob
				format %td visitdate
				duplicates drop
				drop if missing(dob)

				save, replace
				
				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step02, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step02
				}
				
				******************************************************************************
				* Right-o...now the dataset is long

				* Load up the scalars with the vaccination schedule
				
				* These scalars have already been defined in the control program so there
				* is no need to re-define them here.
				* do "${VCQI_PROGRAMS_ROOTPATH}/RI/RI_schedule.do"

				gen age = (visitdate - dob)
				order age, after(visitdate)
				sort respid age

				* make a unique id for each person
				gen person = respid
				order person age , last

				**********************************************
				* Set up variables for the multi-dose vaccines
				**********************************************
				foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
					foreach t in crude valid {  // t is for "type"

						**********
						* dose 1 *
						**********
						gen age_`d'1_`t' = age

						gen credit_`d'1_`t' = age >= `d'1_min_age_days
						gen elig_`d'1_`t'   = age >= `d'1_min_age_days
						
						* if early doses count, then s/he is always eligible
						if "`t'" == "crude" {
							replace credit_`d'1_`t' = 1
						}

						*** Update elig variables for "TDD" & "TDM" cases (See specifications 6.6a #10) ***
						replace credit_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDM")
						replace elig_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDM")
						
						gen got_`d'1_`t' = credit_`d'1_`t' == 1 & got_`d' == 1

						bysort person: gen cum_`d'1_`t' = sum(got_`d'1_`t')

						replace got_`d'1_`t' = got_`d'1_`t' == 1 & cum_`d'1_`t' == 1

						drop cum_`d'1_`t'

						gen dropthis1_`t' = got_`d'1_`t' * age

						bysort person: egen age_at_`d'1_`t' = max(dropthis1_`t') 

						bysort person: egen flag_got_`d'1_`t' = max(got_`d'1_`t')
						
						* For crude doses, replace eligible with 0 if child got an 
						* early dose
						replace elig_`d'1_`t' = 0 if flag_got_`d'1_`t'==1 & ///
							age>age_at_`d'1_`t' //& "`t'"=="crude"

						**********
						* dose 2 *
						**********
						gen age_`d'2_`t' = age
						
						gen credit_`d'2_`t' = flag_got_`d'1_`t' & ///
										  (age >= (age_at_`d'1_`t' + `d'2_min_interval_days))
						gen elig_`d'2_`t'   = flag_got_`d'1_`t' & ///
										  (age >= (age_at_`d'1_`t' + `d'2_min_interval_days))
						
						* if early doses count, then s/he is always eligible
						if "`t'" == "crude" {
							replace credit_`d'2_`t' = flag_got_`d'1_`t' & age > age_at_`d'1_`t'
							
							*** Update elig variables for "TDD" & "TDM" cases (See specifications 6.6a #10) ***
							replace credit_`d'2_`t' = 1 if inlist(`d'_str3,"TDD","TDM")
							replace elig_`d'2_`t' = age >= `d'1_min_age_days if inlist(`d'_str3,"TDD","TDM")
						}
						
						if "`t'" == "valid" {
							*** Update elig variables for "TDD" & "TDM" cases (See specifications 6.6a #10) ***
							replace credit_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDM")
							replace elig_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDM")
						}
						
						gen got_`d'2_`t' = credit_`d'2_`t' == 1 & got_`d' == 1

						bysort person: gen cum_`d'2_`t' = sum(got_`d'2_`t')

						replace got_`d'2_`t' = got_`d'2_`t' == 1 & cum_`d'2_`t' == 1

						drop cum_`d'2_`t'

						gen dropthis2_`t' = got_`d'2_`t' * age

						bysort person: egen age_at_`d'2_`t' = max(dropthis2_`t') 

						bysort person: egen flag_got_`d'2_`t' = max(got_`d'2_`t')

						* For crude doses, replace eligible with 0 if child got an 
						* early dose
						replace elig_`d'2_`t' = 0 if flag_got_`d'2_`t'==1 & ///
							age>age_at_`d'2_`t' //& "`t'"=="crude"
							
						**********
						* dose 3 *
						**********
						gen age_`d'3_`t' = age
						
						gen credit_`d'3_`t' = flag_got_`d'2_`t' & ///
										  (age >= (age_at_`d'2_`t' + `d'3_min_interval_days))
						gen elig_`d'3_`t'   = flag_got_`d'2_`t' & ///
										  (age >= (age_at_`d'2_`t' + `d'3_min_interval_days))

						gen cum_`d'_`t' = sum(got_`d')
						gen age_`d'_`t'2 = age * (cum_`d'_`t' == 1) * got_`d' if inlist(`d'_str3,"TDD","TDM")
						bysort person: egen age_max_`d'_`t' = max(age_`d'_`t'2)
						bysort person: replace age_`d'_`t'2 = age_max_`d'_`t' if inlist(`d'_str3,"TDD","TDM")
						drop age_max_`d'_`t'
						
						* if early doses count, then s/he is always eligible
						if "`t'" == "crude" {
							replace credit_`d'3_`t' = flag_got_`d'2_`t' & age > age_at_`d'2_`t'
							
							*** Update elig variables for "TDD" & "TDM" cases (See specifications 6.6a #10) ***
							replace credit_`d'3_`t' = 1 if inlist(`d'_str3,"TDD","TDM")
							replace elig_`d'3_`t' = age >= `d'1_min_age_days & (age>=age_`d'_crude2+`d'3_min_interval_days) if inlist(`d'_str3,"TDD","TDM")
						}
						
						if "`t'" == "valid" {
							*** Update elig variables for "TDD" & "TDM" cases (See specifications 6.6a #10) ***
							replace credit_`d'3_`t' = age_`d'_crude2 >= `d'1_min_age_days & (age>=age_`d'_crude2+`d'3_min_interval_days) if inlist(`d'_str3,"TDD","TDM")
							replace elig_`d'3_`t' = credit_`d'3_`t' if inlist(`d'_str3,"TDD","TDM")
						}	
						
						gen got_`d'3_`t' = credit_`d'3_`t' == 1 & got_`d' == 1

						bysort person: gen cum_`d'3_`t' = sum(got_`d'3_`t')

						replace got_`d'3_`t' = got_`d'3_`t' == 1 & cum_`d'3_`t' == 1

						drop cum_`d'3_`t'

						gen dropthis3_`t' = got_`d'3_`t' * age

						bysort person: egen age_at_`d'3_`t' = max(dropthis3_`t')

						bysort person: egen flag_got_`d'3_`t' = max(got_`d'3_`t')
						
						* For crude doses, replace eligible with 0 if child got an 
						* early dose
						replace elig_`d'3_`t' = 0 if flag_got_`d'3_`t'==1 & ///
							age>age_at_`d'3_`t' //& "`t'"=="crude"
							

						drop dropthis1_`t' dropthis2_`t' dropthis3_`t'

						*gen got_`d'1_`t' = got_`d'1_`t'
						*gen got_`d'2_`t' = got_`d'2_`t'
						*gen got_`d'3_`t' = got_`d'3_`t'
						
					}
				}

				********************************************************
				* Set up the same variables for the single-dose vaccines
				********************************************************
				foreach d in `=lower("$RI_SINGLE_DOSE_LIST")' {
					foreach t in crude valid {  // t is for "type"

						* this just makes a copy of the age variable for easy
						* reading in the data editor; drop later
						gen age_`d'_`t' = age
						
						* can we count the dose if it occurs in this visit?
						gen credit_`d'_`t' = age >= `d'_min_age_days

						* would it be an MOV if not given at this visit?
						gen elig_`d'_`t' = age >= `d'_min_age_days
						
						* if early doses count, then s/he is always eligible
						*if "`which_analysis'" == "crude" {
						if "`t'" == "crude" {
							replace credit_`d'_`t' = 1
						}
						if "`d'" == "opv0" {
							replace credit_opv0_`t' = age >= opv0_min_age_days & ///
													  age <= opv0_max_age_days 
							replace elig_opv0_`t' = age >= opv0_min_age_days & ///
													age <= opv0_max_age_days 
						}
						
						* did s/he get a valid dose at this visit?
						gen got_`d'_`t' = credit_`d'_`t' == 1 & got_`d' == 1
						
						* only track the first valid dose; ignore later doses
						bysort person: gen cum_`d'_`t' = sum(got_`d'_`t')
						replace got_`d'_`t' = got_`d'_`t' == 1 & cum_`d'_`t' == 1
						drop cum_`d'_`t'
						
						* calculate and remember the age at which they got this dose
						gen dropthis_`t' = got_`d'_`t' * age
						bysort person: egen age_at_`d'_`t' = max(dropthis_`t')
						drop dropthis_`t'
						
						* later we will drop all rows but one for this person, so
						* set a flag here in all rows indicating that they got a
						* valid dose
						bysort person: egen flag_got_`d'_`t' = max(got_`d'_`t')
						
						* DAR: changing this to be true for both crude & valid
						
						* For crude doses, replace eligible with 0 if child got an 
						* early dose
						replace elig_`d'_`t' = 0 if flag_got_`d'_`t'==1 & ///
							age>age_at_`d'_`t' // & "`t'"=="crude"
					}
				}

				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step03, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step03
				}
				
				*********************************************************
				* Calculate the variables for the mov measures
				*********************************************************

				foreach d in `=lower("$RI_DOSE_LIST")' {
					foreach t in crude valid {  // t is for "type"

						* how many rec'd up to and including this visit?
						bysort person: gen cum_`d'_`t' = sum(got_`d'_`t')
						
						* an mov is when s/he is eligible and doesn't receive it
						gen mov_`d'_`t' = elig_`d'_`t' == 1 & cum_`d'_`t' == 0
						
						* cumulative movs up to and including this visit
						bysort person: gen cum_mov_`d'_`t' = sum(mov_`d'_`t')
						
						* corrected mov is when they have had 1+ movs and then they get it
						gen cor_mov_`d'_`t' = cum_mov_`d'_`t' > 0 & got_`d'_`t' == 1
							
						* set a flag (in all visits) if the child had a 1+ corrected movs
						bysort person: egen flag_cor_mov_`d'_`t' = total(cor_mov_`d'_`t')
						replace flag_cor_mov_`d'_`t' = flag_cor_mov_`d'_`t' > 0 
						
						* record (in all visits) the child's total number of movs
						bysort person: egen total_mov_`d'_`t' = total(mov_`d'_`t')
						
						* set a flag (in all visits) if the child had 1+ movs
						gen flag_had_mov_`d'_`t' = total_mov_`d'_`t' > 0
						
						* set a flag (in all visits) if the child had only uncorrected movs for this dose
						gen flag_uncor_mov_`d'_`t' = (flag_had_mov_`d'_`t' == 1) & (flag_got_`d'_`t' == 0)
					
						* set a counter (in all visits) of the number of eligible opportunities
						*gen total_elig_`d'_`t' = flag_got_`d'_`t' + total_mov_`d'_`t'
						bysort person: egen total_elig_`d'_`t' = total(elig_`d'_`t')
						
						order *`d'_`t', last
					}
				}
				
				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step04, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step04
				}
				
				********************************************************************************
				* Update MOV flags 
				********************************************************************************
				* If dose was recorded by tick mark/history, do not include in MOV 
				*     Set the MOV-related flags to zero

				
				foreach d in `=lower("$RI_SINGLE_DOSE_LIST")' {
					foreach t in crude valid {  // t is for "type"
						replace mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace cum_mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace cor_mov_`d'_`t'  = 0 if got_`d'_tick==1 
						replace flag_cor_mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace total_mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace flag_had_mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace flag_uncor_mov_`d'_`t' = 0 if got_`d'_tick==1 
						replace total_elig_`d'_`t' = 0 if got_`d'_tick==1 
					}
				}
				
				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step05, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step05
				}
				
				* Multi-dose vaccines - Update MOV flags depending on 3 char string created at top of program
				* See file "MOV date tick missing updates - MP.xlsx" as well as specification doc for breakdown
				* Denominator only means: replace MOV flags with 0 and replace total_elig_<dose> with 1
				* Do not count means: replace MOV flags with 0
				* Note: The two cases are the same except "denominator only" also replaces total_elig_<dose> with 1

				foreach d in `=lower("$RI_MULTI_3_DOSE_LIST")' {
					foreach t in crude valid {
						
						*local d "dpt"
						*local t "valid"
						
						*** Dose 1 ***
						* Note: <inlist> can only handle a list of 10 strings, so have to use 2 replace statements for each MOV variable that needs updating
						replace mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cum_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cum_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_cor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_cor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace total_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace total_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_had_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_had_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_uncor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM") 
						replace flag_uncor_mov_`d'1_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")

						*** Dose 2 ***
						* Note: <inlist> can only handle a list of 10 strings, so have to use 3 replace statements for each MOV variable that needs updating
						replace mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cum_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace cum_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cum_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace flag_cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_cor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace total_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace total_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace total_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_had_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT")
						replace flag_had_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_had_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_uncor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"DTD","DTT","DTM","DMD","DMT") 
						replace flag_uncor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"TDD","TDT","TDM","TTD","TTT","TTM","TMD","TMT","TMM") 
						replace flag_uncor_mov_`d'2_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")

						* "TDD" & "TDT" & "TDM" are denominator only cases for dose2, so also update total_elig_<dose> var
						replace total_elig_`d'2_`t' = 1 if inlist(`d'_str3,"TDD","TDT","TDM")
						
						*** Dose 3 ***
						* Note: <inlist> can only handle a list of 10 strings, so have to use 3 replace statements for each MOV variable that needs updating
						replace mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cum_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace cum_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cum_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace flag_cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_cor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace total_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace total_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace total_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_had_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT")
						replace flag_had_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM")
						replace flag_had_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")
						
						replace flag_uncor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"DDT","DTD","DTT","DTM","DMD","DMT") 
						replace flag_uncor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"TDT","TTD","TTT","TTM","TMD","TMT","TMM") 
						replace flag_uncor_mov_`d'3_`t' = 0 if inlist(`d'_str3,"MDD","MDT","MDM","MTD","MTT","MTM","MMD","MMT")

						* "DTD" & "TTD" are denominator only cases for dose3, so also update total_elig_<dose> var
						replace total_elig_`d'3_`t' = 1 if inlist(`d'_str3,"DTD","TTD")
					
					}
				}

				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step06, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step06
				}
				
				********************************************************************************
				* Loop over all doses and calculate a final set of derived variables
				********************************************************************************

				gen elig_for_anydose_crude = 0
				gen elig_for_anydose_valid = 0

				gen mov_for_anydose_crude = 0
				gen mov_for_anydose_valid = 0

				gen total_visit_movs_crude = 0
				gen total_visit_movs_valid = 0

				foreach d in `=lower("$RI_DOSE_LIST")' {
					foreach t in crude valid {  // t is for "type"
					
						replace elig_for_anydose_`t' = 1 if elig_`d'_`t'==1
						*replace mov_for_anydose_`t' = 1 if flag_had_mov_`d'_`t'==1 
						replace mov_for_anydose_`t' = 1 if mov_`d'_`t'==1
						replace total_visit_movs_`t' = total_visit_movs_`t' + 1 if mov_`d'_`t'==1
						
					}
				}

				foreach t in crude valid {  // t is for "type"
					bysort person: egen total_elig_visits_`t' = total(elig_for_anydose_`t')
					bysort person: egen total_mov_visits_`t' = total(mov_for_anydose_`t')
					bysort person: egen total_movs_`t' = total(total_visit_movs_`t')
				}
				
				
				* Now drop the variables associated with the 3rd dose of any
				* 2-dose series...these were generated and calculated for 
				* convenience...to use the 3-dose code to calculate flags
				* for 2-dose vaccines...but now we need to clean this up
				*
				* Also remove the dose names in RI_MULTI_2_DOSE_LIST from
				* RI_MULTI_3_DOSE_LIST
				
				vcqi_log_comment $VCP 3 Comment "Dropping fictional variables associated with 3rd dose of 2-dose vaccines"
				foreach d in `=lower("$RI_MULTI_2_DOSE_LIST")' {
					drop *`d'3*
					scalar drop `d'3_min_interval_days 
					scalar drop `d'3_min_age_days
				}
				* Set RI_DOSE_LIST & RI_MULTI_3_DOSE_LIST back to their earlier values
				vcqi_global RI_DOSE_LIST $RI_DOSE_LIST_SAVED
				vcqi_global RI_MULTI_3_DOSE_LIST $RI_MULTI_3_DOSE_LIST_SAVED
				vcqi_global RI_DOSE_LIST_SAVED
				vcqi_global RI_MULTI_3_DOSE_LIST_SAVED
				
				
				order elig_for_anydose_crude mov_for_anydose_crude total_visit_movs_crude ///
					  total_elig_visits_crude total_mov_visits_crude total_movs_crude ///
					  elig_for_anydose_valid mov_for_anydose_valid total_visit_movs_valid ///
					  total_elig_visits_valid total_mov_visits_valid total_movs_valid, last

				drop age_*

				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step07, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step07
				}
				
				********************************************************************************

				* Only keep one row per person
				capture drop age
				capture drop got*
				capture drop *str3
				drop visitdate
				bysort person: keep if _n == 1
				capture drop person

				if $VCQI_TESTING_CODE == 1 {
					save RI_MOV_step08, replace
					vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_step08
				}
				
				save RI_MOV_flags_to_merge, replace
				vcqi_global RI_TEMP_DATASETS $RI_TEMP_DATASETS RI_MOV_flags_to_merge

				capture erase movlong.dta
			
			}
		}
	}
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end