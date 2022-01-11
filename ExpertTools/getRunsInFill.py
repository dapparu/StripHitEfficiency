import sys
import runregistry


def getLS(ls, subdet, flag):
    existing_flags = ['GOOD', 'BAD', 'STANDBY', 'NOTSET', 'EXCLUDED', 'EMPTY']
    ls_num = 0
    if subdet not in ls:
        print('Warning `'+str(subdet)+'` flag not found.')
        return 0
    #print( ls[subdet].keys() )
    if flag in ls[subdet].keys():
        ls_num = ls[subdet][flag]
    if flag == 'TOTAL':
        for f in ls[subdet]:
            if f in existing_flags:
                ls_num += ls[subdet][f]

    return ls_num    

def getFlag(ls, subdet):
    flag = 'BAD'
    ls_good = getLS(ls, subdet, 'GOOD')
    ls_tot = getLS(ls, subdet, 'TOTAL')
    frac = 0.
    if ls_tot > 0 : frac = float(ls_good) / ls_tot
    #print( ls_good, ls_tot, frac)
    if frac > 0.95 : 
        flag = 'GOOD'
    return flag 

#--------------------------------------------------------------

# Get arguments : fill_num, stream

fill_num = 0
stream = 'PromptReco' # Online, Express, PromptReco, ReReco
existing_streams = [ 'Online', 'Express', 'PromptReco', 'ReReco']

narg = len(sys.argv)
if narg < 2:
    print('Syntax: python3 getRunsInFill.py fill_number [stream]')
    exit()
else:
    if not sys.argv[1].isdigit():
        print('First argument should be a number')
        exit()
    else : 
        fill_num = int(sys.argv[1])

if narg >= 3:
    stream = sys.argv[2]
    if stream not in existing_streams:
        print('Second argument possible values are: ', existing_streams)
        exit()


# Get runs info in querying RunRegistry and filtering

runs = runregistry.get_runs( filter={ 'fill_number' : fill_num } )
sorted_runs = sorted(runs, key=lambda x: x['run_number'])

for run in sorted_runs:
    run_num = run['run_number']
    dataset_str = ''
    ntriggers = run['oms_attributes']['l1_triggers_counter']
    ls_good = 0
    ls_tot = 0
    pixel_flag = 'NOTSET'
    strip_flag = 'NOTSET'
    tracking_flag = 'NOTSET'

    datasets = runregistry.get_datasets( filter={ 
    'run_number' : run_num, 
    'class' : { 'like' : '%Collisions%' },
    'dataset_name' : { 'like' : '%'+stream+'%' }
    } )
    ndat = len(datasets)
    if ndat!=1:
        if ndat==0:
            print('>> No dataset found for the run '+str(run_num)+' !! Skipping it.')
        if ndat>1:
            print('>> Several datasets found for the run '+str(run_num)+' !! Skipping it.')
            print('>> The list is : ')
            for dataset in datasets:
                print('>>   ', dataset['name'])
        continue
    else :
        dataset = datasets[0]
        dataset_str = dataset['name']
        class_str = dataset['class']
        if 'lumisections' in dataset:
            lumisections = dataset['lumisections']
            pixel_flag = getFlag(lumisections, 'tracker-pixel')
            strip_flag = getFlag(lumisections, 'tracker-strip')
            tracking_flag = getFlag(lumisections, 'tracker-track')
    print(run_num, class_str, dataset_str, fill_num, pixel_flag, strip_flag, tracking_flag, ntriggers)



