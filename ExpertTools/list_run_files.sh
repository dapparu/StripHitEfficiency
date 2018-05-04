#!/bin/bash -f


if [ $# -lt 1 -o $# -gt 2 ]; then
  echo "Usage: $0 runnumber (nfiles)"
  exit 0;
fi


  #####################
  # Run period to be updated manually
  ERA="GR18"
  #echo "era: $ERA"
  #####################

runnumber=$1
nfiles=$2
EOSpath="/store/group/dpg_tracker_strip/comm_tracker/Strip/Calibration/calibrationtree"
#echo "The full directory path is $EOSpath/$ERA"

if [ "$nfiles" != "" ]
then
  #echo "Keeping only first $nfiles files for the run"
  filelist=`eos ls $EOSpath/$ERA | grep $runnumber | sort -t '_' -k 3n | head -$nfiles`
else
  filelist=`eos ls $EOSpath/$ERA | grep $runnumber | sort -t '_' -k 3n`
fi

fullpathfilelist=""
for file in `echo $filelist`
do
# fullpathfilelist+="'root://cms-xrd-global.cern.ch//$EOSpath/$ERA/$file',"
 fullpathfilelist+="'root://eoscms//eos/cms$EOSpath/$ERA/$file',"
done
fullpathfilelist=`echo $fullpathfilelist | sed 's/.$//'`

if [ "$fullpathfilelist" = "" ]
then
 #echo "No file found in $EOSpath/$ERA for run $runnumber"
 exit
fi

echo $fullpathfilelist
