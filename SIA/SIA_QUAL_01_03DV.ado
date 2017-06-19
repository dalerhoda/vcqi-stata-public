*! SIA_QUAL_01_03DV version 1.01 - Biostat Global Consulting - 2016-03-07
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2016-03-07	1.01	Dale Rhoda		Added _seen and _unseen variables
*******************************************************************************

program define SIA_QUAL_01_03DV

	local oldvcp $VCP
	global VCP SIA_QUAL_01_03DV
	vcqi_log_comment $VCP 5 Flow "Starting"

	quietly {
		use "${VCQI_OUTPUT_FOLDER}/SIA_QUAL_01_${ANALYSIS_COUNTER}", clear

		gen     campaign_card_seen = 	.
		replace campaign_card_seen = 	inlist(SIA21,1) if inlist(SIA20,1,2) 
		label variable campaign_card_seen "Vaccinated Respondent Received SIA Card - Seen"

		gen     campaign_card_unseen = 	.
		replace campaign_card_unseen = 	inlist(SIA21,2) if inlist(SIA20,1,2) 
		label variable campaign_card_unseen "Vaccinated Respondent Received SIA Card - Unseen"

		gen     got_campaign_card = .
		replace got_campaign_card = (campaign_card_seen == 1 | campaign_card_unseen == 1) if inlist(SIA20,1,2) 
		label variable got_campaign_card "Vaccinated Respondent Received SIA Card"

		save, replace
	}
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end