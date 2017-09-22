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



if [ $# != 1 ]; then
  echo "Usage: $0 runnumber"
  echo "Runs the Hit Efficiency Study"
  exit 0;
fi

  #####################
  # Run period to be updated manually
  ERA="GR17"
  echo "era: $ERA"
  #####################

runnumber=$1
echo "The run number is $runnumber"

EOSpath="/store/group/dpg_tracker_strip/comm_tracker/Strip/Calibration/calibrationtree"
echo "The full directory path is $EOSpath/$ERA"

# get the first 2 files of that run
filelist=`eos ls $EOSpath/$ERA | grep $runnumber | sort -t '_' -k 3n | head -2`
filelistfull=`eos ls $EOSpath/$ERA | grep $runnumber`


fullpathfilelist=""
for file in `echo $filelist`
do
 fullpathfilelist+="'root://eoscms//eos/cms$EOSpath/$ERA/$file',"
done
fullpathfilelist=`echo $fullpathfilelist | sed 's/.$//'`
echo $fullpathfilelist

if [ "$fullpathfilelist" = "" ]
then
 echo "No file found in $EOSpath/$ERA for run $runnumber"
 exit
fi

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

StoreOutputs withMasking

rm BadModules.log


# produce and store trend plots

./TrendPlots.sh $ERA

echo "Done."
