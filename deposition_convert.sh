#This shell script code using for extract N deposition from GEOSChem output
#and convert them to kgN km-2 yr-1

echo Cdo process begun

#---- Directory settings
GeosHOME=/LARGE0/gr10502/individual/tjansakoo/Geos/Code
LocalDataDir=/LARGE0/gr10502/laboshare
ShellDir=/LARGE0/gr10502/individual/tjansakoo/Geos/Code/NIESGeosRunShell
StorageOutDir=/LARGE0/gr10502/individual/tjansakoo/Geos/Output
CODEDir=$GeosHOME/UT
GEOSCODEDirOrig=GCClassic.13.4.0 
RUNDir=/LARGE0/gr10502/individual/tjansakoo/Geos/rundirs
DataDirName=ExtData

# Define constants
avogadro_number=6.02214076e23   # Avogadro's number in molecules/mol
grams_to_kg=1e-3                # Conversion factor from grams to kilograms
cm2_to_m2=1e-4                  # Conversion factor from cm^2 to m^2
seconds_per_year=31536000       # Number of seconds in a year
m2_to_km2=1e-6                    # Conversion factor from meters to kilometers
area_file="/LARGE2/gr10502/individual/tjansakoo/Geos"        # Grid Area

#molar_mass
molar_mass_nitrogen=14.01

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
        #cdo mergetime GEOSChem.DryDep.2016* GEOSChem.DryDep.2016.nc
        cdo yearsum MGT1.nc GEOSChem.DryDep.2016_yearsum.nc
        cdo yearmean MGT1.nc GEOSChem.DryDep.2016_yearmean.nc

        for VAR in NITs NIT NH4 NH3 HNO3;
        do
            cdo select,name=DryDep_${VAR} GEOSChem.DryDep.2016_yearsum.nc tmpdep/tmp1_yearsum.nc 
            cdo select,name=DryDep_${VAR} GEOSChem.DryDep.2016_yearmean.nc tmpdep/tmp1_yearmean.nc 

            # Convert to kgN km^-2 yr^-1
            cdo -expr,'Dep_N=DryDep_${VAR}*7.33919E-09' tmpdep/tmp1_yearsum.nc tmpdep/${VAR}_DD_tmp_yearsum.nc
            cdo -expr,'Dep_N=DryDep_${VAR}*7.33919E-09' tmpdep/tmp1_yearmean.nc tmpdep/${VAR}_DD_tmp_yearmean.nc
            # kgN km^-2 yr^-1 = molecule/cm2/sec * (mole/6.02e23 molecule) * (g/mol of N) * (kg/1000 g) * (1e10 cm2 / km2) * (31536000 sec / year)
        
        done
            cdo add tmpdep/NITs_DD_tmp_yearsum.nc tmpdep/NIT_DD_tmp_yearsum.nc tmpdep/tmp3_yearsum.nc
            cdo add tmpdep/tmp3_yearsum.nc tmpdep/NH4_DD_tmp_yearsum.nc tmpdep/tmp4_yearsum.nc
            cdo add tmpdep/tmp4_yearsum.nc tmpdep/NH3_DD_tmp_yearsum.nc tmpdep/tmp5_yearsum.nc
            cdo add tmpdep/tmp5_yearsum.nc tmpdep/HNO3_DD_tmp_yearsum.nc SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearsum.nc

            cdo add tmpdep/NITs_DD_tmp_yearmean.nc tmpdep/NIT_DD_tmp_yearmean.nc tmpdep/tmp3_yearmean.nc
            cdo add tmpdep/tmp3_yearmean.nc tmpdep/NH4_DD_tmp_yearmean.nc tmpdep/tmp4_yearmean.nc
            cdo add tmpdep/tmp4_yearmean.nc tmpdep/NH3_DD_tmp_yearmean.nc tmpdep/tmp5_yearmean.nc
            cdo add tmpdep/tmp5_yearmean.nc tmpdep/HNO3_DD_tmp_yearmean.nc SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearmean.nc

            #cdo mergetime GEOSChem.WetLossLS.2016* GEOSChem.WetLossLS.2016.nc
            cdo yearsum MGT16.nc GEOSChem.WetLossLS.2016_yearsum.nc
            cdo yearmean MGT16.nc GEOSChem.WetLossLS.2016_yearmean.nc

            #Fraction of N in each species 
            NITs_Frac=0.445
            NIT_Frac=0.225
            NH4_Frac=0.775
            NH3_Frac=0.823
            HNO3_Frac=0.221
            NO2_Frac=0.304
            N2O5_Frac=0.129
        
        List=("NITs" "NIT" "NH4" )

        for VAR2 in NITs NIT NH4 NH3 HNO3 NO2 N2O5;
        do
            cdo select,name=WetLossLS_${VAR} GEOSChem.WetLossLS.2016_yearsum.nc tmpdep/tmp11_yearsum.nc
            cdo select,name=WetLossLS_${VAR} GEOSChem.WetLossLS.2016_yearmean.nc tmpdep/tmp11_yearmean.nc

            # Convert to kg m^-2 sec^-1
            cdo div tmpdep/tmp11_yearsum.nc $area_file tmpdep/tmp22_yearsum.nc
            cdo div tmpdep/tmp11_yearmean.nc $area_file tmpdep/tmp22_yearmean.nc

            # Convert to kg km^-2 yr^-1
            cdo -expr,'Dep_N=WetLossLS_${VAR}*1000000' tmpdep/tmp22_yearsum.nc tmpdep/tmp33_yearsum.nc
            cdo -expr,'Dep_N=WetLossLS_${VAR}*1000000' tmpdep/tmp22_yearmean.nc tmpdep/tmp33_yearmean.nc

            #kg >> kgN km^-2 yr^-1
            cdo -expr,'Dep_N=Dep_N*${VAR2}_Frac' tmpdep/tmp33_yearsum.nc tmpdep/${VAR}_WD_tmp_yearsum.nc
            cdo -expr,'Dep_N=Dep_N*${VAR2}_Frac' tmpdep/tmp33_yearmean.nc tmpdep/${VAR}_WD_tmp_yearmean.nc
            
        done

        cdo add tmpdep/NITs_WD_tmp_yearsum.nc tmpdep/NIT_WD_tmp_yearsum.nc tmpdep/tmp33_yearsum.nc
        cdo add tmpdep/tmp33_yearsum.nc tmpdep/NH4_WD_tmp_yearsum.nc tmpdep/tmp44_yearsum.nc
        cdo add tmpdep/tmp44_yearsum.nc tmpdep/NH3_WD_tmp_yearsum.nc tmpdep/tmp55_yearsum.nc
        cdo add tmpdep/tmp55_yearsum.nc tmpdep/HNO3_WD_tmp_yearsum.nc tmpdep/tmp66_yearsum.nc
        cdo add tmpdep/tmp66_yearsum.nc tmpdep/NO2_WD_tmp_yearsum.nc tmpdep/tmp77_yearsum.nc
        cdo add tmpdep/tmp77_yearsum.nc tmpdep/N2O5_WD_tmp_yearsum.nc SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearsum.nc

        cdo add tmpdep/NITs_WD_tmp_yearmean.nc tmpdep/NIT_WD_tmp_yearmean.nc tmpdep/tmp33_yearmean.nc
        cdo add tmpdep/tmp33_yearmean.nc tmpdep/NH4_WD_tmp_yearmean.nc tmpdep/tmp44_yearmean.nc
        cdo add tmpdep/tmp44_yearmean.nc tmpdep/NH3_WD_tmp_yearmean.nc tmpdep/tmp55_yearmean.nc
        cdo add tmpdep/tmp55_yearmean.nc tmpdep/HNO3_WD_tmp_yearmean.nc tmpdep/tmp66_yearmean.nc
        cdo add tmpdep/tmp66_yearmean.nc tmpdep/NO2_WD_tmp_yearmean.nc tmpdep/tmp77_yearmean.nc
        cdo add tmpdep/tmp77_yearmean.nc tmpdep/N2O5_WD_tmp_yearmean.nc SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearmean.nc
    done
done

cdo add SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearsum.nc SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearsum.nc SurfaceConc/nc4/Wet_Dry_Dep_N_${Scenario}_${year}_yearsum.nc
cdo add SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearmean.nc SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearmean.nc SurfaceConc/nc4/Wet_Dry_Dep_N_${Scenario}_${year}_yearmean.nc

cp SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearsum.nc ${StorageOutDir}/Deposition/nc4
cp SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearsum.nc ${StorageOutDir}/Deposition/nc4
cp SurfaceConc/nc4/Wet_Dry_Dep_N_${Scenario}_${year}_yearsum.nc ${StorageOutDir}/Deposition/nc4

cp SurfaceConc/nc4/WetDep_N_${Scenario}_${year}_yearmean.nc ${StorageOutDir}/Deposition/nc4
cp SurfaceConc/nc4/DryDep_N_${Scenario}_${year}_yearmean.nc ${StorageOutDir}/Deposition/nc4
cp SurfaceConc/nc4/Wet_Dry_Dep_N_${Scenario}_${year}_yearmean.nc ${StorageOutDir}/Deposition/nc4





