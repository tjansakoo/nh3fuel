echo Cdo process begun

#---- Cdo settings
DailyAveragedData=Y                                             # If Y, daily averaged data(Note:data is relatively large) will be added. [Y/N]
prefix=Re		                                                    # Set the output filename's prefix
remap_sp=remapcon	                                              # specify the remap policy to use. There are other remap policies. See "https://code.mpimet.mpg.de/projects/cdo/embedded/index.html#x1-1500002.3.1".
Removetmpdep/tmp=N 	                                                 	# Remove tmpdep/tmp File [Y/N].
TargetResolutionAveragedData=Y                                  # If Y, yearly, monthly and daily(optional) averaged ncs in target resolution(specified in $ResSim) will be created.[Y/N]
csvoutput=N                                                     # CSV file output

#---- Directory settings
GeosHOME=/LARGE0/gr10502/individual/tjansakoo/Geos/Code
LocalDataDir=/LARGE0/gr10502/laboshare
ShellDir=/LARGE0/gr10502/individual/tjansakoo/Geos/Code/NIESGeosRunShell
StorageOutDir=/LARGE0/gr10502/individual/tjansakoo/Geos/Output
CODEDir=$GeosHOME/UT
GEOSCODEDirOrig=GCClassic.13.4.0 
GEOSCODEDir=$GeosHOME/CodeCopy/$$
RUNDir=/LARGE0/gr10502/individual/tjansakoo/Geos/rundirs
DataDirName=ExtData

for Scenario in SSP2_BaU_NoCC_globalnh3_global2 SSP2_600C_CACN_DAC_NoCC SSP2_600C_CACN_DAC_amm_NoCC SSP2_600C_CACN_DAC_amm_LoAQC_NoCC
do
    for year in 2015 2030 2050 2100
    do
        cd "${RUNDir}/${Scenario}-${year}/MERRA2_4x5_Fullchem_Standard_global/OutputDir"
        
        #-------- making directories
        dirlist="tmpdep SurfaceConc SurfaceConc/csv SurfaceConc/nc4"
            for fl in ${dirlist}
            do
                if [ -e ${fl} ]; then
                rm -rf ${fl}
                fi
                mkdir -pm 777 ${fl}
            done
        
        cdo mergetime GEOSChem.WetLossLS.2016* MGT1.nc #kg/s*gridarea
        cdo yearmean MGT1.nc tmpdep/YM1.nc
        cdo mulc,31536000000000 tmpdep/YM1.nc tmpdep/tmp2.nc #mg/year*gridarea
        cdo select,name=WetLossLS_NITs tmpdep/tmp2.nc tmpdep/tmp4.nc
        cdo select,name=WetLossLS_NIT tmpdep/tmp2.nc tmpdep/tmp5.nc
        cdo select,name=WetLossLS_HNO3 tmpdep/tmp2.nc tmpdep/tmp6.nc
        cdo select,name=WetLossLS_PAN tmpdep/tmp2.nc tmpdep/tmp7.nc
        cdo chname,WetLossLS_NITs,NOx tmpdep/tmp4.nc tmpdep/tmp8.nc
        cdo chname,WetLossLS_NIT,NOx tmpdep/tmp5.nc tmpdep/tmp9.nc
        cdo chname,WetLossLS_HNO3,NOx tmpdep/tmp6.nc tmpdep/tmp10.nc
        cdo chname,WetLossLS_PAN,NOx tmpdep/tmp7.nc tmpdep/tmp11.nc
        
        cdo add tmpdep/tmp8.nc tmpdep/tmp9.nc tmpdep/tmp12.nc 
        cdo add tmpdep/tmp10.nc tmpdep/tmp11.nc tmpdep/tmp13.nc
        cdo add tmpdep/tmp12.nc tmpdep/tmp13.nc tmpdep/tmp14.nc
        cdo mulc,0.222 tmpdep/tmp14.nc tmpdep/tmp15.nc #N換算 mg(N)/year*gridarea
        cdo vertsum tmpdep/tmp15.nc tmpdep/NOYWET.nc 
        cdo fldsum tmpdep/NOYWET.nc tmpdep/tmp16.nc #mg(N)/year
        #NOyの乾性沈着量、化学種の選択と単位変換
        
        cdo mergetime GEOSChem.DryDep.2016* MGT16.nc #分子数/cm2*s
        cdo yearmean MGT16.nc tmpdep/YM17.nc
        cdo mulc,0.00000000733135 tmpdep/YM17.nc tmpdep/tmp18.nc #mg(N)/m2/year
        cdo select,name=DryDep_NITs tmpdep/tmp18.nc tmpdep/tmp19.nc
        cdo select,name=DryDep_NIT tmpdep/tmp18.nc tmpdep/tmp20.nc
        cdo select,name=DryDep_HNO3 tmpdep/tmp18.nc tmpdep/tmp21.nc
        cdo select,name=DryDep_NO2 tmpdep/tmp18.nc tmpdep/tmp22.nc
        cdo select,name=DryDep_PAN tmpdep/tmp18.nc tmpdep/tmp23.nc
        cdo chname,DryDep_NITs,NOx tmpdep/tmp19.nc tmpdep/tmp24.nc
        cdo chname,DryDep_NIT,NOx tmpdep/tmp20.nc tmpdep/tmp25.nc
        cdo chname,DryDep_HNO3,NOx tmpdep/tmp21.nc tmpdep/tmp26.nc
        cdo chname,DryDep_NO2,NOx tmpdep/tmp22.nc tmpdep/tmp27.nc
        cdo chname,DryDep_PAN,NOx tmpdep/tmp23.nc tmpdep/tmp28.nc
        cdo add tmpdep/tmp24.nc tmpdep/tmp25.nc tmpdep/tmp29.nc
        cdo add tmpdep/tmp26.nc tmpdep/tmp27.nc tmpdep/tmp30.nc
        cdo add tmpdep/tmp30.nc tmpdep/tmp28.nc tmpdep/tmp31.nc
        cdo add tmpdep/tmp29.nc tmpdep/tmp31.nc tmpdep/NOYDRY.nc
        cdo fldint tmpdep/NOYDRY.nc tmpdep/tmp33.nc #mg(N)/year
        
        #Wet+Dry(NOy)
        cdo add tmpdep/tmp33.nc tmpdep/tmp16.nc SurfaceConc/nc4/NOYDEP_${Scenario}_${year}.nc #トータルのNOy沈着量　#mg(N)/year

        #NHxの湿性沈着量、化学種の選択と単位変換
        cdo select,name=WetLossLS_NH3 tmpdep/tmp2.nc tmpdep/tmp34.nc #mg/year*gridarea
        cdo select,name=WetLossLS_NH4 tmpdep/tmp2.nc tmpdep/tmp35.nc
        cdo chname,WetLossLS_NH3,NHx tmpdep/tmp34.nc tmpdep/tmp36.nc
        cdo chname,WetLossLS_NH4,NHx tmpdep/tmp35.nc tmpdep/tmp37.nc
        cdo add tmpdep/tmp36.nc tmpdep/tmp37.nc tmpdep/tmp38.nc
        cdo mulc,0.823 tmpdep/tmp38.nc tmpdep/tmp39.nc  #mg(N)/year*gridarea
        cdo vertsum tmpdep/tmp39.nc tmpdep/NHXWET.nc
        cdo fldsum tmpdep/NHXWET.nc tmpdep/tmp40.nc #mg(N)/year
        #NHxの乾性沈着量、化学種の選択
        cdo select,name=DryDep_NH3 tmpdep/tmp18.nc tmpdep/tmp41.nc #mg(N)/m2/year
        cdo select,name=DryDep_NH4 tmpdep/tmp18.nc tmpdep/tmp42.nc
        cdo chname,DryDep_NH3,NHx tmpdep/tmp41.nc tmpdep/tmp43.nc
        cdo chname,DryDep_NH4,NHx tmpdep/tmp42.nc tmpdep/tmp44.nc
        cdo add tmpdep/tmp43.nc tmpdep/tmp44.nc tmpdep/NHXDRY.nc
        cdo fldint tmpdep/NHXDRY.nc tmpdep/tmp46.nc #mg(N)/year
        
        #Wet+Dry(NHx)
        cdo add tmpdep/tmp46.nc tmpdep/tmp40.nc SurfaceConc/nc4/NHXDEP_${Scenario}_${year}.nc #トータルのNHx沈着量　#mg
        rm tmpdep/tmp*.nc

        cp SurfaceConc/nc4/NOYDEP_${Scenario}_${year}.nc ${StorageOutDir}/Deposition/nc4
        cp SurfaceConc/nc4/NHXDEP_${Scenario}_${year}.nc ${StorageOutDir}/Deposition/nc4
    
    done
done





