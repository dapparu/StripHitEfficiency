#!/bin/bash -f


if [ $# != 1 ]; then
  echo "Usage: $0 fillnumber"
  exit 0;
fi

FILLNUMBER=$1
echo Analyzing fill $FILLNUMBER

# the script guesses that all needed codes are in the current directory
CODEDIR=`pwd`


# Get list of good runs and corresponding files

# Get list of runs and fill runlist.txt
source query.sh
GetRunsInFill $FILLNUMBER


SHORTFILELIST=""
FILELIST=""
FIRST=true
rm -f runshortlist.txt
while read RUN DATASET_TYPE DATASET FILL PIX STRIP TRACKING TRIGGERS
do
  if [ "$FILL" == "$1" -a "$TRACKING" == "GOOD" ]
  then
    #echo $RUN $TRACKING
     echo $RUN >> runshortlist.txt
     FILELISTTEMP=`$CODEDIR/list_run_files.sh $RUN`
     SHORTFILELISTTEMP=`$CODEDIR/list_run_files.sh $RUN 2`
	 if [ "$FILELISTTEMP" != "" ]
	 then
	   if [ $FIRST = true ]
	   then
		 FILELIST="$FILELISTTEMP"
		 SHORTFILELIST="$SHORTFILELISTTEMP"
	   else
		 FILELIST="$FILELIST\n,\n$FILELISTTEMP"
		 SHORTFILELIST="$SHORTFILELIST\n,\n$SHORTFILELISTTEMP"
	   fi
	   FIRST=false
	 fi
  fi
done < runlist.txt


if [ -f runshortlist.txt ]
  then
    sort runshortlist.txt > runshortlist_ordered.txt
  else
    echo "No corresponding good run found in Collisions ExpressStream"
	exit
fi

FIRSTRUN=`cat runshortlist_ordered.txt | head -1`
NRUN=`wc -l runshortlist_ordered.txt | awk '{print $1}'`
LASTRUN=`cat runshortlist_ordered.txt | tail -1`


# Create a directory for outputs and for work
WORKDIR=Fill_${FILLNUMBER}
if [ -d $WORKDIR -o -d ${WORKDIR}_temp ]
  then
    echo "Directory exists already for this fill. Exiting."
	exit
  else
    mkdir ${WORKDIR}_temp
	cd ${WORKDIR}_temp
fi


# First pass with only two files per run
echo "Bad channels identification"

rm -f BadModules_input.txt
cp $CODEDIR/SiStripHitEff_fill_template.py SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FILLNUMBER/$FILLNUMBER/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s|FILELIST|$SHORTFILELIST|g" SiStripHitEff_fill$FILLNUMBER.py

cmsRun "SiStripHitEff_fill$FILLNUMBER.py" >& "fill_$FILLNUMBER.log"
mv BadModules.log BadModules_input.txt


# Second pass with all the files
echo "Full analysis"

cp $CODEDIR/SiStripHitEff_fill_template.py SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FILLNUMBER/$FILLNUMBER/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s|FILELIST|$FILELIST|g" SiStripHitEff_fill$FILLNUMBER.py

cmsRun "SiStripHitEff_fill$FILLNUMBER.py" >& "fill_$FILLNUMBER.log"
mv BadModules_input.txt BadModules_input_fill$FILLNUMBER.txt
mv BadModules.log BadModules_fill$FILLNUMBER.log

cd ..
mv ${WORKDIR}_temp ${WORKDIR}
