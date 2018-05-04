# Check the runs infos from RunRegistry for Collisions in ExpressStream
# Output list saved in runlist.txt

GetRunsInFill ()
{
  
  QUERY="select g.RUN_NUMBER, g.RUN_CLASS_NAME, g.RDA_NAME, r.LHCFILL, g.RDA_CMP_PIXEL, g.RDA_CMP_STRIP, g.RDA_CMP_TRACKING, r.TRIGGERS from runreg_tracker.datasets g, runreg_tracker.runs r where g.RUN_NUMBER=r.RUNNUMBER and r.LHCFILL="$1" and g.RUN_CLASS_NAME like '%Collisions%' and g.RDA_NAME like '%Express%' ORDER BY g.RUN_NUMBER"

  #python2.6 rhapi.py "$QUERY" | sed -e 's/,/ /g' > runlist.txt
  python2.6 query.py $1
}
