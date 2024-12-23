

#to execute %diffecrent between 2 nc file

### --------------------- User Input -----------------------###

Resolution=05x05				#Input Resolution from GEOSchem simulation
execute=Y
Season_Ex=N
Year_Ex=Y
csv=N
Baseline_sce=SSP2_600C_CACN_DAC_amm_NoCC
#echo 'Please input Scenario :'
#read assum
#echo "Current Scenario is $assum"
#sleep 5
#echo "Let's get strat"
#Scenario=$assum           #Assumption Scenarios Name

echo "The resolution is ${Resolution}"
echo "Execute or not? (${execute})"
echo "Season or not? (${Season_Ex})"
echo "Year or not? (${Year_Ex})"
echo "Export .csv file or not? (${csv})"
echo "Let's go!!!"

### --------------------- User Input -----------------------###
for Scenario in SSP2_600C_CACN_DAC_amm_LoAQC_NoCC
do
	for yr in 2030 2050 2100
	do
		if [ ${execute} == "Y" ];
			then
				cd "/Users/tjansakoo/Library/CloudStorage/OneDrive-KyotoUniversity/KUAtmos_2024/Analysis/NH3base/data/nc/241018"
				echo "Current Scenario is ${Scenario} ${yr}"
				
                #rm -rf Diff
				#rm -rf Rechange
				#rm -rf Seasoning
				#rm -rf csv

                #mkdir Diff && chmod 777 Diff
				#mkdir Rechange && chmod 777 Rechange
				#mkdir Seasoning && chmod 777 Seasoning
				#mkdir csv && chmod 777 csv

				for Sp in pm25 o3
				do
					if [ ${Season_Ex} == "Y" ];
					then
						DateType=monavg
							infile_Final=${Resolution}_${Scenario}_${yr}_off_off_${Sp}_Surface_Re_${DateType}.nc4
							infile_Initial=${Resolution}_${Baseline_sce}_${yr}_off_off_${Sp}_Surface_Re_${DateType}.nc4	#Initial value

							ncdiff $infile_Final $infile_Initial Diff/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${DateType}.nc 					#Final - Initial
							cdo div Diff/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${DateType}.nc $infile_Initial tmp1.nc 									#%change
							cdo mulc,100 tmp1.nc Rechange/${Resolution}_${Sp}_${Scenario}_${yr}_rechange_${DateType}.nc

							for season in DJF MAM JJA SON
							do

								#surface concentration
								cdo selseas,${season} $infile_Final tmp1.nc
								cdo timselmean,3 tmp1.nc Seasoning/${Resolution}_${Sp}_${Scenario}_${yr}_surface_conc_${season}.nc

								#Diff
								cdo selseas,${season} Diff/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${DateType}.nc tmp1.nc
								cdo timselmean,3 tmp1.nc Seasoning/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${season}.nc

								#relative changing
								cdo selseas,${season} rechange/${Resolution}_${Sp}_${Scenario}_${yr}_rechange_${DateType}.nc tmp1.nc
								cdo timselmean,3 tmp1.nc Seasoning/${Resolution}_${Sp}_${Scenario}_${yr}_rechange_${season}.nc

								rm -f tmp1.nc
							done
					else
						echo Season Execution will be skip!!
					fi

					if [ ${Year_Ex} == "Y" ];
					then

						DateType=yearavg

						infile_Final=${Resolution}_${Scenario}_${yr}_off_off_${Sp}_Surface_Re_${DateType}.nc4
						infile_Initial=${Resolution}_${Baseline_sce}_${yr}_off_off_${Sp}_Surface_Re_${DateType}.nc4	#Initial value

						ncdiff $infile_Final $infile_Initial Diff/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${DateType}.nc 					#Final - Initial
						cdo div Diff/${Resolution}_${Sp}_${Scenario}_${yr}_diff_${DateType}.nc $infile_Initial tmp1.nc 									#%change
						cdo mulc,100 tmp1.nc Rechange/${Resolution}_${Sp}_${Scenario}_${yr}_rechange_${DateType}.nc
						rm -f tmp1.nc
					else
						echo Year Execution will be skip!!
					fi
				done
			else
				echo Execution Skip!!!
		fi

		if [ ${csv} == "Y" ]; then
			#cdo outputtab
		  for i in Diff Rechange Seasoning
			do
				cd "/Users/tjansakoo/Library/CloudStorage/OneDrive-KyotoUniversity/KUAtmos_2024/Analysis/NH3base/data/nc/${Scenario}/${yr}/${i}"
				for file in *.nc;
				do
					filename=`echo ${file} | sed "s/\.nc.*/.txt/"`
	        filenamecsv=`echo ${file} | sed "s/\.nc.*/.csv/"`
	        echo now : ${filename}
	        cdo -outputtab,year,name,month,date,lon,lat,value ${file} > ../csv/${filename}
					gsed -i '$d' ../csv/${filename}
					awk '{$1=""; print $0}' ../csv/${filename} > ../csv/tmp1.txt
          gsed -i 1d ../csv/tmp1.txt
          gsed -i "s/$/ ${Scenario}/" ../csv/tmp1.txt
          gsed -i "s/$/ ${yr}/" ../csv/tmp1.txt
	        gsed -i "1s/^/name month date lon lat value scenario yr\n/" ../csv/tmp1.txt
					cp ../csv/tmp1.txt ../csv/${filename}
	        #sed 's/ \+/,/g' ../csv/${filename} > ../csv/${filenamecsv}
	        rm -f ../csv/tmp1.txt
		  	done
		  done
		fi
	done
done
