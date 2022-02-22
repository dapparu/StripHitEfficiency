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
python3 getRunsInFill.py $FILLNUMBER | grep -v ">>" > runlist.txt


SHORTFILELIST=""
FILELIST=""
FILELISTEXPANDED=""
FIRST=true

echo "List of good runs in fill:"
rm -f runshortlist.txt
rm -f filelist.txt
while read RUN DATASET_TYPE DATASET FILL PIX STRIP TRACKING TRIGGERS
do
  if [ "$FILL" == "$1" -a "$TRACKING" == "GOOD" ]
  then
     echo " $RUN"
     echo $RUN >> runshortlist.txt
     $CODEDIR/list_run_files.sh $RUN | sed -e 's/,/\n/g' -e "s/'//g" >> filelist.txt
	 FILELISTTEMP=`$CODEDIR/list_run_files.sh $RUN`
     SHORTFILELISTTEMP=`$CODEDIR/list_run_files.sh $RUN 2`
     FILELISTTEMPEXP=`echo $FILELISTTEMP | sed -e 's/,/,\\\n/g'`
	 if [ "$FILELISTTEMP" != "" ]
	 then
	   if [ $FIRST = true ]
	   then
		 FILELIST="$FILELISTTEMP"
		 SHORTFILELIST="$SHORTFILELISTTEMP"
		 FILELISTEXPANDED="$FILELISTTEMPEXP"
	   else
		 FILELIST="$FILELIST\n,\n$FILELISTTEMP"
		 SHORTFILELIST="$SHORTFILELIST\n,\n$SHORTFILELISTTEMP"
		 FILELISTEXPANDED="$FILELISTEXPANDED,\n$FILELISTTEMPEXP"
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
WORKDIR=Fill_${FILLNUMBER}_temp
if [ -d $WORKDIR ]
  then
    echo "Directory exists already for this fill. Exiting."
	exit
  else
    mkdir ${WORKDIR}
	cd ${WORKDIR}
    mkdir jobs_output 
fi


# Copy run list and file list in workdir 
cp $CODEDIR/runlist.txt .
cp $CODEDIR/filelist.txt .

# First pass with only two files per run
echo "Bad channels identification"

rm -f BadModules_input.txt
cp $CODEDIR/SiStripHitEff_fill_template.py SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s/FILLNUMBER/$FILLNUMBER/g" SiStripHitEff_fill$FILLNUMBER.py
sed -i "s|FILELIST|$SHORTFILELIST|g" SiStripHitEff_fill$FILLNUMBER.py

cmsRun SiStripHitEff_fill$FILLNUMBER.py >& fill_$FILLNUMBER.log
mv BadModules.log BadModules_input.txt


# Second pass with all the files
echo "Full analysis using batch"

NFILES=`echo -e $FILELISTEXPANDED | wc -l`
NFILESPERJOB=10
NJOBS=$(( $NFILES/$NFILESPERJOB +1))
NENDFILES=$(( $NFILES%$NFILESPERJOB ))

$NJOBS > njobs.txt
cp njobs.txt $WORKDIR

cp $CODEDIR/SiStripHitEff_HTCondor_fill_template.py SiStripHitEff_HTCondor_fill.py
#echo $NFILES = $NJOBS * $NFILESPERJOB + $NENDFILES
sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_HTCondor_fill.py
sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_HTCondor_fill.py
sed -i "s/FILLNUMBER/$FILLNUMBER/g" SiStripHitEff_HTCondor_fill.py

condor_submit $CODEDIR/job.sub workdir=$CODEDIR/$WORKDIR codedir=$CODEDIR njobs=$NJOBS nfilesperjob=$NFILESPERJOB 

echo "Results in $WORKDIR"
