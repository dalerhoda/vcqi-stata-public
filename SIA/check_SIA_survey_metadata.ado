*! check_SIA_survey_metadata version 1.02 - Biostat Global Consulting - 2017-08-26
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2016-03-10	1.01	Dale Rhoda		Put error in log and set VCQI_ERROR	
* 2017-08-26	1.02	Mary Prier		Added version 14.1 line							
*******************************************************************************

program define check_SIA_survey_metadata
	version 14.1
	
	local oldvcp $VCP
	global VCP check_SIA_survey_metadata
	vcqi_log_comment $VCP 5 Flow "Starting"
		
	if "$SIA_FINGERMARKS_SOUGHT" != "0" & "$SIA_FINGERMARKS_SOUGHT" != "1" {
		di as error "Please set SIA_FINGERMARKS_SOUGHT to 0 or 1."
		vcqi_global VCQI_ERROR 1
		vcqi_log_comment $VCP 1 Error "Please set SIA_FINGERMARKS_SOUGHT to 0 or 1."

		vcqi_halt_immediately
		
	}
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end

		
