#!/bin/bash -f


if [ $# != 1 ]; then
  echo "Usage: $0 fillnumber"
  exit 0;
fi

FILLNUMBER=$1
echo analyzing fill $FILLNUMBER


# Get list of runs and fill runlist.txt
source query.sh
GetRunsInFill $FILLNUMBER


# Print infos and select good runs
rm -f runshortlist.txt
echo -e "RUN\t TRACKING\t TRIGGERS"
while read RUN DATASET_TYPE DATASET FILL PIX STRIP TRACKING TRIGGERS 
do
  if [ "$FILL" == "$1" ]
  then  
    echo -e "$RUN\t $TRACKING\t $TRIGGERS"
    if [ "$TRACKING" == "GOOD" ]
    then
      echo $RUN >> runshortlist.txt
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

FIRST_RUN=`cat runshortlist_ordered.txt | head -1`
NRUN=`wc -l runshortlist_ordered.txt | awk '{print $1}'`
LAST_RUN=`cat runshortlist_ordered.txt | tail -1`
NTRIGGERS=`awk '{if($4=='$FILLNUMBER' && $7=="GOOD") s+=$NF}END{print s}' runlist.txt`
NTOT=`awk '{if($4=='$FILLNUMBER') s+=$NF}END{print s}' runlist.txt`
FRAC=`echo "$NTRIGGERS/$NTOT*100" | bc -l | sed "s/\(.*\...\).*/\1/"`

echo "TOTAL GOOD: $FIRST_RUN-$LAST_RUN / $NRUN run(s) / $NTRIGGERS trigger(s) ($FRAC%)"
