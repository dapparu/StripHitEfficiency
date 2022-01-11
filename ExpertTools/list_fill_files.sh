#!/bin/bash -f


if [ $# != 1 ]; then
  echo "Usage: $0 fillnumber"
  exit 0;
fi

FILLNUMBER=$1

# Get list of runs and fill runlist.txt
python3 getRunsInFill.py $FILLNUMBER | grep -v ">>" > runlist.txt


while read RUN DATASET_TYPE DATASET FILL PIX STRIP TRACK TRIGGERS
do
  if [ "$FILL" == "$FILLNUMBER" -a "$TRACK" == "GOOD" ]
#  if [ "$FILL" == "$FILLNUMBER" ]
  then
#    echo $RUN $FILL $TRACK
    ./list_run_files.sh $RUN
    echo ","
  fi
done < runlist.txt

