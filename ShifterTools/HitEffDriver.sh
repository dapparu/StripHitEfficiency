#!/bin/bash -f

#CreateIndex ()
#{
#    COUNTER=0
#    LASTUPDATE=`date`
#
#    for Plot in `ls *.png`; do
#        if [[ $COUNTER%2 -eq 0 ]]; then
#            cat >> index_new.html  << EOF
#<TR> <TD align=center> <a href="$Plot"><img src="$Plot"hspace=5 vspace=5 border=0 style="width: 90%" ALT="$Plot"></a> 
#  <br> $Plot </TD>
#EOF
#        else
#            cat >> index_new.html  << EOF
#  <TD align=center> <a href="$Plot"><img src="$Plot"hspace=5 vspace=5 border=0 style="width: 90%" ALT="$Plot"></a> 
#  <br> $Plot </TD> </TR> 
#EOF
#        fi
#
#        let COUNTER++
#    done
#
#    cat /afs/cern.ch/cms/tracker/sistrvalidation/WWW/template_index_foot.html | sed -e "s@insertDate@$LASTUPDATE@g" >> index_new.html
#
#    mv -f index_new.html index.html
#}

# Creating html index
CreateIndex ()
{  
    LASTUPDATE=`date`
    
            cat >> index_new.html  << EOF
<TR> <TD align=center> <a href="SiStripHitEffTKMapBad.png"><img src="SiStripHitEffTKMapBad.png"hspace=5 vspace=5 border=0 style="width: 90%" ALT="SiStripHitEffTKMapBad.png"></a> 
  <br> SiStripHitEffTKMapBad.png </TD>
EOF

            cat >> index_new.html  << EOF
  <TD align=center> <a href="SiStripHitEffTKMap.png"><img src="SiStripHitEffTKMap.png"hspace=5 vspace=5 border=0 style="width: 90%" ALT="SiStripHitEffTKMap.png"></a> 
  <br> SiStripHitEffTKMap.png </TD> </TR> 
EOF

            cat >> index_new.html  << EOF
<TR> <TD align=center> <a href="SiStripHitEffTKMapEff.png"><img src="SiStripHitEffTKMapEff.png"hspace=5 vspace=5 border=0 style="width: 90%" ALT="SiStripHitEffTKMapEff.png"></a> 
  <br> SiStripHitEffTKMapEff.png </TD>
EOF

            cat >> index_new.html  << EOF
  <TD align=center> <a href="Summary.png"><img src="Summary.png"hspace=5 vspace=5 border=0 style="width: 90%" ALT="Summary.png"></a> 
  <br> Summary.png </TD> </TR> 
EOF

    cat /afs/cern.ch/cms/tracker/sistrvalidation/WWW/template_index_foot.html | sed -e "s@insertDate@$LASTUPDATE@g" >> index_new.html

    mv -f index_new.html index.html
}


# Storing outputs into www directory
StoreOutputs ()
{

  analysistype=$1
  
  wwwdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency"

  #Now publish all of the relevant files
  #Create the relevant directories on a per run basis
  echo "Creating directories ..."

  #mkdir "/afs/cern.ch/cms/CAF/CMSALCA/ALCA_TRACKERCALIB/SiStrip/CalibrationValidation/HitEfficiency/run_$runnumber"
  mkdir -p "$wwwdir/$ERA/run_$runnumber"
  echo "Creating run_$runnumber/$analysistype"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype/cfg"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype/sqlite"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype/QualityLog"
  mkdir "$wwwdir/$ERA/run_$runnumber/$analysistype/rootfile"

  echo "Moving output to the proper directory ..."

  #Move the config file
  mv "SiStripHitEff_run$runnumber.py" "$wwwdir/$ERA/run_$runnumber/$analysistype/cfg"

  #Move the log files
  mv "InefficientModules_$runnumber.txt" "$wwwdir/$ERA/run_$runnumber/$analysistype/QualityLog"
  mv "EfficiencyResults_$runnumber.txt" "$wwwdir/$ERA/run_$runnumber/$analysistype/QualityLog"
  if [ -f BadModules_input.txt ]
  then
    mv BadModules_input.txt "$wwwdir/$ERA/run_$runnumber/$analysistype/QualityLog"
  fi

  #Move the root file containing hot cold maps
  mv "SiStripHitEffHistos_run$runnumber.root" "$wwwdir/$ERA/run_$runnumber/$analysistype/rootfile"

  #Generate an index.html file to hold the TKMaps
  cat /afs/cern.ch/cms/tracker/sistrvalidation/WWW/template_index_header.html | sed -e "s@insertPageName@Validation Plots --- Hit Efficiency Study --- Tracker Maps@g" > index_new.html
  CreateIndex

  mv index.html "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "SiStripHitEffTKMapBad.png" "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "SiStripHitEffTKMap.png"    "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "SiStripHitEffTKMapEff.png" "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "SiStripHitEffTKMapDen.png" "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "SiStripHitEffTKMapNum.png" "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots"
  mv "Summary.png" "$wwwdir/$ERA/run_$runnumber/$analysistype/Plots/Summary.png"

  # Create the sqlite- and metadata-files
  echo "Preparing the sqlite and metadata files ..."

  if [ -f dbfile.db ]
  then
	ID1=`uuidgen -t`
	#cp dbfile.db SiStripHitEffBadModules@${ID1}.db # before payload whas appended to the file
	mv dbfile.db SiStripHitEffBadModules@${ID1}.db
	cat template_SiStripHitEffBadModules.txt | sed -e "s@insertFirstRun@$runnumber@g" -e "s@insertIOV@$runnumber@" > SiStripHitEffBadModules@${ID1}.txt

	mv "SiStripHitEffBadModules@${ID1}.db" "$wwwdir/$ERA/run_$runnumber/$analysistype/sqlite"
	mv "SiStripHitEffBadModules@${ID1}.txt" "$wwwdir/$ERA/run_$runnumber/$analysistype/sqlite"
  fi
  
}


##############################################



if [ $# -lt 1 ]; then
  echo "Usage: $0 [-n #files] [-e era] runnumber"
  echo "Runs the Hit Efficiency Study"
  exit 0;
fi


# Default values for options
# Run period
ERA="GR18"
# nb of files to be processed for the run
NFILES="4"

# Setting options
while getopts ":n:e:" OPT
do
  #echo $OPT $OPTARG
  case $OPT in
    n)  NFILES="$OPTARG";;
    e)  ERA="$OPTARG";;
    \?) echo "Invalid option -$OPTARG"
  esac
done
shift $((OPTIND-1))

echo "era: $ERA"

# Setting argument
# run number
runnumber=$1
echo "run number: $runnumber"

echo "$NFILES files to be processed,"

EOSpath="/store/group/dpg_tracker_strip/comm_tracker/Strip/Calibration/calibrationtree"
echo "from directory: $EOSpath/$ERA"

# get the first files of that run
filelist=`eos ls $EOSpath/$ERA | grep $runnumber | sort -t '_' -k 3n | head -$NFILES`
filelistfull=`eos ls $EOSpath/$ERA | grep $runnumber`

NTOT=`echo $filelistfull | wc -w`
if [ $NFILES -gt $NTOT ]
then
  NFILES=$NTOT
fi
echo "Will run on $NFILES files over the $NTOT available"

if [ $NTOT -eq 0 ]
then
 echo "No file found in $EOSpath/$ERA for run $runnumber"
 exit
fi

echo $filelist > filelist.txt

echo "--------------------------"



######################
# Checking PU in files

IFILE=1
PUfilelist=""
rm -f SiStripHitEffHistos_run${runnumber}_*.root
for file in `echo $filelist`
do

  FILEID=`echo $file | awk -F'_' '{print $3} '| sed -e 's/.root//'`
  if [[ "$FILEID" == "" ]]
  then
    FILEID="0"
  fi
  echo "RUNNING ON FILE $FILEID: $file"
  fullpathfile="'root://eoscms//eos/cms$EOSpath/$ERA/$file'"

  cp SiStripHitEff_template.py "SiStripHitEff_run$runnumber.py"
  sed -i "s/newrun/$runnumber/g" "SiStripHitEff_run$runnumber.py"
  sed -i "s|'root://eoscms//eos/cms/newfilelocation'|$fullpathfile|g" "SiStripHitEff_run$runnumber.py"

  rm -f BadModules_input.txt

  cmsRun "SiStripHitEff_run$runnumber.py" >& "run_${runnumber}_$FILEID.log"
  mv "SiStripHitEffHistos_run$runnumber.root" "SiStripHitEffHistos_run${runnumber}_$FILEID.root"
  PUfilelist+="SiStripHitEffHistos_run${runnumber}_$FILEID.root,"

  IFILE=$((IFILE+1))
done


# Analyzing the PU info in the output files
#echo $PUfilelist
echo "Analysing PU conditions ..."
echo ""
rm -f goodPU_filelist.txt
python3 analyse_files_PU.py $PUfilelist >& "run_${runnumber}_PU.log"
cat run_${runnumber}_PU.log

# Cleaned list of files
if [ -f goodPU_filelist.txt ]
then
  goodfilelist=`cat goodPU_filelist.txt`
else
  echo "Missing file 'goodPU_filelist.txt'"
  exit
fi

NGOOD=`echo $goodfilelist | wc -w`
if [ $NGOOD -eq 0 ]
then
 echo "No calibTree file with stable PU conditions for run $runnumber"
 exit
fi

echo "files that will be used:"
fullpathfilelist=""
for file in `echo $goodfilelist`
do
  FILEID=`echo $file | awk -F'_' '{print $3} '| sed -e 's/.root//'`
  if [[ "$FILEID" == "0" ]]
  then
    fullpathfilelist+="'root://eoscms//eos/cms$EOSpath/$ERA/calibTree_$runnumber.root',"
  else
    fullpathfilelist+="'root://eoscms//eos/cms$EOSpath/$ERA/calibTree_${runnumber}_$FILEID.root',"
  fi
done
fullpathfilelist=`echo $fullpathfilelist | sed 's/.$//'`
echo $fullpathfilelist

echo "--------------------------"




######################
# Lauching production

#cp dbfile_31X_IdealConditions.db dbfile.db

cp SiStripHitEff_template.py "SiStripHitEff_run$runnumber.py"
sed -i "s/newrun/$runnumber/g" "SiStripHitEff_run$runnumber.py"
sed -i "s|'root://eoscms//eos/cms/newfilelocation'|$fullpathfilelist|g" "SiStripHitEff_run$runnumber.py"

echo "Launching cmsRun ..."

cmsRun "SiStripHitEff_run$runnumber.py" >& "run_$runnumber.log" 

cat run_$runnumber.log | awk 'BEGIN{doprint=0}{if(match($0,"New IOV")!=0) doprint=1;if(match($0,"%MSG")!=0) {doprint=0;} if(match($0,"Message")!=0) {doprint=0;} if(doprint==1) print $0}' > InefficientModules_$runnumber.txt
cat run_$runnumber.log | awk 'BEGIN{doprint=0}{if(match($0,"occupancy")!=0) doprint=1;if(match($0,"efficiency")!=0) doprint=1; if(match($0,"%MSG")!=0) {doprint=0;} if(match($0,"tempfilename")!=0) {doprint=0;} if(match($0,"New IOV")!=0) {doprint=0;} if(match($0,"generation")!=0) {doprint=0;} if(doprint==1) print $0}' > EfficiencyResults_$runnumber.txt

mv run_$runnumber.log run_${runnumber}_standard.log

# Storing outputs in www directory
StoreOutputs standard



# Running the analysis a second time in masking some inefficient modules
mv BadModules.log BadModules_input.txt

cp SiStripHitEff_template.py "SiStripHitEff_run$runnumber.py"
sed -i "s/newrun/$runnumber/g" "SiStripHitEff_run$runnumber.py"
sed -i "s|'root://eoscms//eos/cms/newfilelocation'|$fullpathfilelist|g" "SiStripHitEff_run$runnumber.py"

echo "Launching cmsRun for second job ..."

cmsRun "SiStripHitEff_run$runnumber.py" >& "run_$runnumber.log" 

# don't want to save this one where the inefficient modules have been masked and can not be identified
rm dbfile.db

cat run_$runnumber.log | awk 'BEGIN{doprint=0}{if(match($0,"New IOV")!=0) doprint=1;if(match($0,"%MSG")!=0) {doprint=0;} if(match($0,"Message")!=0) {doprint=0;} if(doprint==1) print $0}' > InefficientModules_$runnumber.txt
cat run_$runnumber.log | awk 'BEGIN{doprint=0}{if(match($0,"occupancy")!=0) doprint=1;if(match($0,"efficiency")!=0) doprint=1; if(match($0,"%MSG")!=0) {doprint=0;} if(match($0,"tempfilename")!=0) {doprint=0;} if(match($0,"New IOV")!=0) {doprint=0;} if(match($0,"generation")!=0) {doprint=0;} if(doprint==1) print $0}' > EfficiencyResults_$runnumber.txt

mv run_$runnumber.log run_${runnumber}_withMasking.log
cp  

StoreOutputs withMasking

rm BadModules.log
#rm -f SiStripHitEffHistos_run${runnumber}_*.root


# produce and store trend plots

./TrendPlots.sh $ERA


echo "Done."
