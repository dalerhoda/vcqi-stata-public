*! RI_QUAL_05_06PO version 1.04 - Biostat Global Consulting - 2017-08-26
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
*               1.00	Dale Rhoda		Original
* 2016-02-11	1.01	Dale Rhoda		
* 2016-09-08	1.02	Dale Rhoda		Add VCQI_MAKE_XX_PLOTS macros
* 2017-05-19	1.03	Dale Rhoda		Add threshold to database filename
* 2017-08-26	1.04	Mary Prier		Added version 14.1 line
*******************************************************************************

program define RI_QUAL_05_06PO
	version 14.1
	
	local oldvcp $VCP
	global VCP RI_QUAL_05_06PO
	vcqi_log_comment $VCP 5 Flow "Starting"

	quietly {
		if "$VCQI_MAKE_UW_PLOTS" == "1" {
		
			noi di as text _col(5) "Unweighted proportion plot"
			
			capture mkdir Plots_IW_UW
		
			local d `=lower("$RI_QUAL_05_DOSE_NAME")' 
			local t `=int($RI_QUAL_05_INTERVAL_THRESHOLD)'

			vcqi_to_uwplot , database(${VCQI_OUTPUT_FOLDER}/RI_QUAL_05_${ANALYSIS_COUNTER}_`d'_`t'_database) ///
				filetag(RI_QUAL_05) ///
				title("RI - Proportion of later `=upper("`d'")'" "Doses Received Before `t' Days Passed") ///
				name(RI_QUAL_05_${ANALYSIS_COUNTER}_uwplot)
				
			vcqi_log_comment $VCP 3 Comment "Unweighted proportion plot was created and exported."
			
			graph drop _all
		}
	}
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end
