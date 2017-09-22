# Tools and recipe to produce results for a fill:

## Use WBM to list the fills

`https://cmswbm.cern.ch`

## Check the quality of data in a fill

`./check_fill_runregistry.sh FILLNUMBER`

It queries the Run Registry and list the runs from the fill with their certification for the ExpressStream and their statistics.
It prints a summary of the fraction of the fill flagged as good.
It uses `query.sh` and `rhapy.py` to send the query to the Run Registry.

## Check the number of calibTree files available for the fill (optional)

`./list_fill_files.sh FILLNUMBER`

It prints the list of the files of the good runs for the fill in a format that can be included in the cfg file.
It uses `list_run_files.sh`.


## Produce the results (in interactive mode) when there are few files

`./launch_fill_analysis.sh FILLNUMBER`

It launches a first cmsRun job on 2 calibTree files per run to produce a list of inefficient modules.
Then it launches intereactively a second cmsRun job on all the files to produce the results. The results are stored localy in a directory *Fill_FILLNUMBER*.
It uses the `SiStripHitEff_fill_template.py` configuration file.

## Produce the results using batch (when more than 10 files to run on)

`./launch_fill_analysis_batch.sh FILLNUMBER`

It launches a first cmsRun job on 2 calibTree files per run to produce a list of inefficient modules.
The second pass job is splitted in jobs sent to the lxplus batch (each job runs on 10 files, by default).
It uses the `cmsRun_batch_eos` script for the jobs on the batch and results are stored in the directory *Fill_FILLNUMBER_temp*.
 
## Check the status of the job sent to the batch

`./check_jobs_results.sh RESULTS_DIRECTORY`

It checks the logs of the jobs.
If all jobs have correctly finished, the output files are merged in a file named *SiStripHitEffHistos_merged.root* .
Otherwise you need to send again the failed jobs from the work directory.
It prints also the remaining inefficient modules. It is good to check that no more are remaining. It can happen because not all the files are used to identify them in the first pass.

## Clean the merged file and recompute the efficiencies

`python2.6 RecomputeEfficiencies.py INPUTFILE`

Only the histograms are correctly merged in the previous step using the ROOT hadd command. This script recomputes correctly the efficiencies from the histograms and save the TGraphs. The output file is named *SiStripHitEffHistos_fill_merged.root* .


