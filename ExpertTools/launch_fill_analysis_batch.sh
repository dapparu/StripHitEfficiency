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
while read RUN DATASET_TYPE DATASET FILL PIX STRIP TRACKING TRIGGERS
do
  if [ "$FILL" == "$1" -a "$TRACKING" == "GOOD" ]
#  if [ "$FILL" == "$1" ]
  then
     echo " $RUN"
     echo $RUN >> runshortlist.txt
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
fi


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
NJOBS=$(( $NFILES/$NFILESPERJOB ))
NENDFILES=$(( $NFILES%$NFILESPERJOB ))

#echo $NFILES = $NJOBS * $NFILESPERJOB + $NENDFILES

for (( I=1; I<=$NJOBS; I++ ))
do
  NLINES=$(( $I*$NFILESPERJOB ))
  FIRSTLINE=$(( ($I-1)*$NFILESPERJOB+1 ))
  LASTLINE=$(( $I*$NFILESPERJOB ))
  echo files $FIRSTLINE - $LASTLINE
  LISTTEMP=""
  for FILE in `echo -e $FILELISTEXPANDED | sed -n -e ''$FIRSTLINE','$LASTLINE'p' | sed -e '$s/,$//'`
  do
    LISTTEMP+=$FILE
  done
  #echo $LISTTEMP
  echo 'launching job' $I
  cp $CODEDIR/SiStripHitEff_fill_template.py SiStripHitEff_fill${FILLNUMBER}_$I.py
  sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_fill${FILLNUMBER}_$I.py
  sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_fill${FILLNUMBER}_$I.py
  sed -i "s/FILLNUMBER/$FILLNUMBER\_$I/g" SiStripHitEff_fill${FILLNUMBER}_$I.py
  sed -i "s|FILELIST|$LISTTEMP|g" SiStripHitEff_fill${FILLNUMBER}_$I.py
  bsub -q1nh $CODEDIR/cmsRun_batch_eos $CODEDIR $WORKDIR/SiStripHitEff_fill${FILLNUMBER}_$I.py $WORKDIR/BadModules_input.txt $WORKDIR
done

# sending last job for remaining files
if [ $NENDFILES -gt 0 ]
then
  FIRSTLINE=$(( $NJOBS*$NFILESPERJOB+1 ))
  LASTLINE=$NFILES
  echo files $FIRSTLINE - $LASTLINE
  LISTTEMP=""
  for FILE in `echo -e $FILELISTEXPANDED | sed -n -e ''$FIRSTLINE','$LASTLINE'p' | sed -e '$s/,$//'`
  do
    LISTTEMP+=$FILE
  done
  LASTJOB=$(( $NJOBS+1 ))
  #echo $LISTTEMP
  echo 'launching job' $LASTJOB
  cp $CODEDIR/SiStripHitEff_fill_template.py SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py
  sed -i "s/FIRSTRUN/$FIRSTRUN/g" SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py
  sed -i "s/LASTRUN/$LASTRUN/g" SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py
  sed -i "s/FILLNUMBER/$FILLNUMBER\_$LASTJOB/g" SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py
  sed -i "s|FILELIST|$LISTTEMP|g" SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py
  bsub -q1nh $CODEDIR/cmsRun_batch_eos $CODEDIR $WORKDIR/SiStripHitEff_fill${FILLNUMBER}_$LASTJOB.py $WORKDIR/BadModules_input.txt $WORKDIR
fi

echo $LASTJOB > njobs.txt

echo "Results in $WORKDIR"
