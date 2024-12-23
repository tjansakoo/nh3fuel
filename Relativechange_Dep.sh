

#to execute %diffecrent between 2 nc file

### --------------------- User Input -----------------------###
execute=Y
csv=Y
Baseline_sce=1p5c_w_nh3
stat=mean

echo "Execute or not? (${execute})"
echo "Export .csv file or not? (${csv})"
echo "Let's go!!!"

### --------------------- User Input -----------------------###
for Scenario in 1p5c_w_nh3_LoAQC 
do
	for yr in 2030 2050 2100
	do

		cd "/Users/tjansakoo/Library/CloudStorage/OneDrive-KyotoUniversity/KUAtmos_2024/Analysis/NH3base/data/deposition/"
		echo "Current Scenario is ${Scenario} ${yr}"
				
        #rm -rf Diff
		#rm -rf Rechange
		#rm -rf csv

        mkdir Diff && chmod 777 Diff
		mkdir Rechange && chmod 777 Rechange
		mkdir csv && chmod 777 csv

		for Sp in Wet_Dry_Dep_N
		do

			infile_Initial=${Sp}_${Baseline_sce}_${yr}_year${stat}.nc
			infile_Final=${Sp}_${Scenario}_${yr}_year${stat}.nc

			ncdiff nc/$infile_Final nc/$infile_Initial Diff/${Sp}_${Baseline_sce}_${Scenario}_${yr}_diff_year${stat}.nc 					#Final - Initial
			cdo div Diff/${Sp}_${Baseline_sce}_${Scenario}_${yr}_diff_year${stat}.nc nc/$infile_Initial tmp1.nc 									#%change
			cdo mulc,100 tmp1.nc Rechange/${Sp}_${Baseline_sce}_${Scenario}_${yr}_rechange_year${stat}.nc
		done

		if [ ${csv} == "Y" ]; then
			#cdo outputtab
		  for i in Diff Rechange
			do
				cd "/Users/tjansakoo/Library/CloudStorage/OneDrive-KyotoUniversity/KUAtmos_2024/Analysis/NH3base/data/deposition/${i}"
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

echo " - - - - - - - - - - - - - DONE!!! - - - - - - - - - - - - - - "