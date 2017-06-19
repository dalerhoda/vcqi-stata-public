*! RI_CONT_01_04GO version 1.00 - Biostat Global Consulting - 2015-10-22
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
*******************************************************************************

program define RI_CONT_01_04GO

	local oldvcp $VCP
	global VCP RI_CONT_01_04GO
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	quietly {
		local j 1
		while `j' <= `=wordcount("$RI_CONT_01_DROPOUT_LIST")' {
			local d1 `=word(lower("$RI_CONT_01_DROPOUT_LIST"),`j')'
			local ++j
			local d2 `=word(lower("$RI_CONT_01_DROPOUT_LIST"),`j')'
			local ++j
			noi di _continue _col(5) "`d1' to `d2' "
		
			make_unwtd_output_database, measureid(RI_CONT_01) vid(`d1'_`d2') var(dropout_`d1'_`d2') estlabel(`=upper("`d1'")'-`=upper("`d2'")' Dropout (%))

		}
		noi di ""
	}
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end
