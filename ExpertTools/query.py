# Check the runs infos from RunRegistry for Collisions in ExpressStream
# Output list saved in runlist.txt

import sys
from rrapi import RRApi, RRApiError

URL  = "http://runregistry.web.cern.ch/runregistry/"
api = RRApi(URL, debug = True)

#out= api.columns('TRACKER', 'datasets')
#for line in out:
#  print line

def get_runs_in_fill(fill):
  runs={}
  mycolumns = ['number', 'runClassName', 'lhcFill', 'triggers', 'startTime', 'stopTime']
  output = api.data(workspace='TRACKER', table='runsummary', template = 'json', columns = mycolumns, filter = {'runClassName':'like %Collisions%'}, query="{lhcFill}="+str(fill), order=['number asc'])
  for run in output:
    runs[ int(run['number']) ] = {'CLASSNAME':run['runClassName'], 'FILL':run['lhcFill'], 'TRIGGERS':run['triggers'], 'STARTTIME':run['startTime'], 'STOPTIME':run['stopTime']}
  return runs

def get_run_certif(run):
  runs={}
  mycolumns = ['runNumber', 'runClassName', 'datasetName', 'pix', 'strip', 'track']
  output = api.data(workspace='TRACKER', table='datasets', template = 'json', columns = mycolumns, filter = {'runNumber':'= '+str(run), 'datasetState' : '= COMPLETED'})
  ## keep only Express
  for run in output:
    if 'Express' in run['datasetName']:
      runs[ int(run['runNumber']) ] = {'DATASET':run['datasetName'], 'PIX':run['pix']['status'], 'STRIP':run['strip']['status'], 'TRACK':run['track']['status']}
  return runs

#-----------------------------
if len(sys.argv)<2:
  print "Syntax is: python2.6 query.py FILLNUMBER"
  exit()

fillnumber=str(sys.argv[1])

outfile = open('runlist.txt', 'w')
runsInFill = get_runs_in_fill(fillnumber)
for run in runsInFill:
  run_certif = get_run_certif(run)
  if run in run_certif:
    outfile.write(str(run)+' '+runsInFill[run]['CLASSNAME']+' '+run_certif[run]['DATASET']+' '+str(runsInFill[run]['FILL'])+' '+run_certif[run]['PIX']+' '+run_certif[run]['STRIP']+' '+run_certif[run]['TRACK']+' '+str(runsInFill[run]['TRIGGERS'])+'\n')
outfile.close()
