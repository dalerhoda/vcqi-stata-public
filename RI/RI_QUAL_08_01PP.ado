*! RI_QUAL_08_01PP version 1.04 - Biostat Global Consulting - 2019-11-09
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2016-02-12	1.01	Dale Rhoda		Make list of temp datasets 
* 2017-01-31	1.02	Dale Rhoda		Added VCQI_LEVEL4_SET_VARLIST
* 2017-08-26	1.03	Mary Prier		Added version 14.1 line
* 2019-11-09	1.04 	Dale Rhoda		Introduced MOV_OUTPUT_DOSE_LIST
*******************************************************************************

program define RI_QUAL_08_01PP
	version 14.1
	
	local oldvcp $VCP
	global VCP RI_QUAL_08_01PP
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	quietly {
	
		local vc  `=lower("$RI_QUAL_08_VALID_OR_CRUDE")'

		use "${VCQI_OUTPUT_FOLDER}/RI_with_ids", clear
		merge 1:1 respid using RI_MOV_flags_to_merge
		keep if _merge == 1 | _merge == 3
		drop _merge

		local dlist	
		foreach d in $MOV_OUTPUT_DOSE_LIST {
			local dlist `dlist' total_mov_`d'_`vc' total_elig_`d'_`vc'
		}

		keep level1id level2id level3id stratumid clusterid respid RI01 RI03 RI11 RI12  ///
			 HH02 HH04 psweight $VCQI_LEVEL4_STRATIFIER $VCQI_LEVEL4_SET_VARLIST ///
			`dlist' total_mov_visits_`vc' total_elig_visits_`vc' total_movs_`vc'
			
		save "${VCQI_OUTPUT_FOLDER}/RI_QUAL_08_${ANALYSIS_COUNTER}", replace

		vcqi_global RI_QUAL_08_TEMP_DATASETS $RI_QUAL_08_TEMP_DATASETS RI_QUAL_08_${ANALYSIS_COUNTER}
	}
	
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end
