*! RI_QUAL_01_06PO version 1.06 - Biostat Global Consulting - 2017-05-16
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
* 2016-02-12	1.01	Dale Rhoda		Check user global to see whether to
*										save .gph file
* 2016-02-17	1.02	MK Trimner		Move export option in opplot (Issue61)
* 2016-04-04	1.03	Dale Rhoda		Add leading 0 to stratum ID for export
* 2016-07-06	1.04	Dale Rhoda		Add weightvar to organ pipe plot
* 2016-09-08	1.05	Dale Rhoda		Add VCQI_MAKE_XX_PLOTS macros
* 2016-05-16	1.06	Dale Rhoda		Tell user how many inchworm plots
*										will be made
*******************************************************************************

program define RI_QUAL_01_06PO

	version 14
	local oldvcp $VCP
	global VCP RI_QUAL_01_06PO
	vcqi_log_comment $VCP 5 Flow "Starting"
	
	quietly {
	
		********************************
		* Make organ pipe plots
		
		if "$VCQI_MAKE_OP_PLOTS" == "1" {
		
			noi di _col(5) "Organ pipe plots"
				
			capture mkdir Plots_OP
			
			* Make a list of strata and their names
			
			use "${VCQI_OUTPUT_FOLDER}/RI_QUAL_01_${ANALYSIS_COUNTER}", clear

			keep stratumid HH02
			duplicates drop
			sort stratumid 
			local opp_nstrata = _N
			forvalues i = 1/`=_N' {
				if stratumid[`i'] < 10 local opp_stratum_id_`i' 0`=stratumid[`i']'
				else local opp_stratum_id_`i' = stratumid[`i']
				local opp_stratum_name_`i' = HH02[`i']
			}
			
			use "${VCQI_OUTPUT_FOLDER}/RI_QUAL_01_${ANALYSIS_COUNTER}", clear

			* Now make the plots themselves - one for each stratum
				
			local subtitle RI_QUAL_01: RI Card Availability

			forvalues i = 1/`opp_nstrata' {

				graph drop _all
				
				local savegph
				if $SAVE_VCQI_GPH_FILES ///
					local savegph   saving("Plots_OP/RI_QUAL_01_${ANALYSIS_COUNTER}_opplot_`opp_stratum_id_`i''_`opp_stratum_name_`i''", replace)

				local savedata
				if $VCQI_SAVE_OP_PLOT_DATA ///
					local savedata savedata(Plots_OP/RI_QUAL_01_${ANALYSIS_COUNTER}_opplot_`opp_stratum_id_`i''_`opp_stratum_name_`i'')			

				opplot showed_card_with_dates , clustvar(clusterid) weightvar(psweight) ///
					   stratvar(stratumid) stratum(`=int(`opp_stratum_id_`i'')') ///
					   title("`opp_stratum_id_`i'' - `opp_stratum_name_`i''") ///
					   subtitle(`quote'"`subtitle'"`quote') ///
					   barcolor1(ltblue) `savegph' `savedata' ///
					   export (Plots_OP/RI_QUAL_01_${ANALYSIS_COUNTER}_opplot_`opp_stratum_id_`i''_`opp_stratum_name_`i''.png)
				
				vcqi_log_comment $VCP 3 Comment "Graphic file: RI_QUAL_01_${ANALYSIS_COUNTER}_`opp_stratum_id_`i''_`opp_stratum_name_`i''.png was created and saved."

			}
		}
		
		********************************
		* Make the inchworm plot
		if "$VCQI_MAKE_IW_PLOTS" == "1" {
		
			* The number of plots (ppd) depends on whether
			* we are making level2 iwplots; calculate ppd and send
			* the number to the screen to calibrate the user's expectations
			
			local ppd 1
			
			local show2 = $SHOW_LEVEL_2_ALONE         + ///
						  $SHOW_LEVELS_2_3_TOGETHER   + ///
						  $SHOW_LEVELS_2_4_TOGETHER   + ///
						  $SHOW_LEVELS_2_3_4_TOGETHER > 0 
			
			if `show2' == 1 & "$VCQI_MAKE_LEVEL2_IWPLOTS" == "1" {
				use "$VCQI_DATA_FOLDER/level2names", clear
				count
				local ppd = `ppd' + `ppd'*r(N)
				clear
			}		
			
			noi di _col(5) "Inchworm plots (`ppd' plots)"		
			
			capture mkdir Plots_IW_UW

			graph drop _all

			vcqi_to_iwplot , database(${VCQI_OUTPUT_FOLDER}/RI_QUAL_01_${ANALYSIS_COUNTER}_ca_database) ///
				filetag(RI_QUAL_01_${ANALYSIS_COUNTER}) ///
				datafile(${VCQI_OUTPUT_FOLDER}/RI_QUAL_01_${ANALYSIS_COUNTER}) ///
				title(RI - Card Availability) name(RI_QUAL_01_${ANALYSIS_COUNTER}_iwplot)
				
			vcqi_log_comment $VCP 3 Comment "Inchworm plot was created and exported."
		}
	}
	vcqi_log_comment $VCP 5 Flow "Exiting"
	global VCP `oldvcp'

end