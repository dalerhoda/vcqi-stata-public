*! COVG_DIFF_02 version 1.00 - Biostat Global Consulting - 2015-10-28

program define COVG_DIFF_02

	local oldvcp $VCP
	global VCP COVG_DIFF_02
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	noi di "Calculating $VCP ..."

	noi di _col(3) "Checking global macros"
	COVG_DIFF_02_00GC
	if "$VCQI_PREPROCESS_DATA" 		== "1" noi di _col(3) "Pre-processing dataset"
	if "$VCQI_PREPROCESS_DATA" 		== "1" COVG_DIFF_02_01PP
	*COVG_DIFF_02_02DQ 
	*COVG_DIFF_02_03DV
	if "$VCQI_GENERATE_DATABASES" 	== "1" noi di _col(3) "Generating output databases"
	if "$VCQI_GENERATE_DATABASES" 	== "1" COVG_DIFF_02_04GO
	
	* The program to export to excel is called 
	* by vcqi_halt_immediately...not by this program.
	
	*if "$EXPORT_TO_EXCEL" == "1" COVG_DIFF_02_05TO
	*if "$MAKE_PLOTS"      == "1" COVG_DIFF_02_06PO

	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end