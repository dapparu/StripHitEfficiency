#!/bin/sh

# $1 : work directory for the fill
if [ "$1" = "" ]
then
    echo " Syntax : ./check_jobs_results.sh Fill_XXXX_temp"
    exit
fi

if [ ! -d "$1" ]; then
  echo "The directory $1 does not exist"
  exit
fi


# getting number of sent jobs
if [ -f "$1/njobs.txt" ]; then
  NTOTJOB=$(( `cat $1/njobs.txt` ))
else
  echo "File $1/njobs.txt not found"
  NTOTJOB=0
fi

echo "A total of $NTOTJOB jobs were sent."


# checking status of the ended jobs
NJOB=0
NGOOD=0
echo "New bad modules found:"
for LOG in `ls $1/LSFJOB_*/STDOUT`
do
 NJOB=$(( $NJOB + 1 ))
 STATUS=`cat $LOG | grep "New IOV" | wc -l`
 if [ "$STATUS" == "1" ] ; then
   NGOOD=$(( $NGOOD + 1 ))
 else
   echo "$LOG job looks to have crashed"
 fi
 cat $LOG | grep Tracker
done

echo "$NGOOD / $NJOB jobs are successful" 

ls -l $1/SiStripHitEffHistos_*.root

# if all jobs ended correctly, merge the output root files
if [ $NGOOD -eq $NJOB -a $NJOB -eq $NTOTJOB ]; then
  FILES=""
  for FILE in `ls $1/SiStripHitEffHistos_*_*.root`
  do
    FILES+="$FILE "
  done
  echo "Merging the outputs"
  hadd $1/SiStripHitEffHistos_merged.root $FILES
fi


