*! DESC_02_04GO version 1.01 - Biostat Global Consulting - 2017-08-26
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2017-08-26	1.01	Mary Prier		Added version 14.1 line
*******************************************************************************

program define DESC_02_04GO
	version 14.1
	
	local oldvcp $VCP
	global VCP DESC_02_04GO
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	quietly {
		local vid 1
		foreach d in $DESC_02_VARIABLES {
			use "${VCQI_OUTPUT_FOLDER}/DESC_02_${ANALYSIS_COUNTER}_${DESC_02_COUNTER}", clear
			make_DESC_0203_output_database, measureid(DESC_02) vid(`vid')  var(desc02_`vid') label(`: variable label `d'')
			local ++vid
		}
	
	}
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end

