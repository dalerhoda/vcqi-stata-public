*! DESC_03 version 1.00 - Biostat Global Consulting - 2015-10-28

program define DESC_03

	local oldvcp $VCP
	global VCP DESC_03
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	noi di "Calculating $VCP ..."

	noi di _col(3) "Checking global macros"
	DESC_03_00GC
	if "$VCQI_PREPROCESS_DATA" 		== "1" noi di _col(3) "Pre-processing dataset"
	if "$VCQI_PREPROCESS_DATA" 		== "1" DESC_03_01PP
	*if "$VCQI_PREPROCESS_DATA"	 	== "1" noi di _col(3) "Checking data quality"
	*DESC_03_02DQ 
	if "$VCQI_GENERATE_DVS" 		== "1" noi di _col(3) "Calculating derived variables"
	if "$VCQI_GENERATE_DVS" 		== "1" DESC_03_03DV
	if "$VCQI_GENERATE_DATABASES" 	== "1" noi di _col(3) "Generating output databases"
	if "$VCQI_GENERATE_DATABASES" 	== "1" DESC_03_04GO
	if "$EXPORT_TO_EXCEL" 			== "1" noi di _col(3) "Exporting to Excel"
	if "$EXPORT_TO_EXCEL" 			== "1" DESC_03_05TO
	*if "$MAKE_PLOTS"      			== "1" RI_COVG_03_06PO
	*if "$MAKE_PLOTS"      			== "1" DESC_03_06PO

	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end

