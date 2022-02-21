import sys
import os
import subprocess
import ROOT as R


#####################################
# Function definition

def analyse_PU(filename):

    good_quality = True

    print('Analysing PU conditions of file', filename, ':')
    frun = R.TFile(filename)
    if frun == None:
        print('  File not found.')
        return False
    fdir = frun.GetDirectory('SiStripHitEff')


    # PU info
    hpu = fdir.Get('PU')
    if hpu == None:
        print('  Missing pu histogram in file '+frun.GetName())
        return False
    pu = hpu.GetMean()
    pu_err = hpu.GetRMS()
    print( ' PU (avg+/-rms): ', '{:.2f}'.format(pu), '+/-', '{:.2f}'.format(pu_err) )
    if pu_err > 5 :
        print(' >> WARNING: large dispersion of PU conditions')
        good_quality = False


    # hits vs PU
    hhits = fdir.Get('layertotal_vsPU_layer_1')
    if hhits == None:
        print('  Missing layertotal_vsPU_layer_1 histogram in file '+frun.GetName())
        return False

    ibin_low = hhits.FindBin(pu-2*pu_err)
    ibin_up = hhits.FindBin(pu+2*pu_err)
    integral_tot = hhits.Integral(0, hhits.GetNbinsX()+1)
    integral_in = hhits.Integral(ibin_low, ibin_up)
    fraction = (integral_tot-integral_in)/integral_tot
    print(' {:.1f}'.format(fraction*100), '% of hits from events outside the PU range(', hhits.GetBinLowEdge(ibin_low), '-', hhits.GetBinLowEdge(ibin_up+1), ') (2 sigma)')
    if fraction > 0.25:
        print(' >> WARNING: large fraction of hits from events with anormal PU conditions')
        good_quality = False

    frun.Close()
    return good_quality


#####################################
# Start of main part

if len(sys.argv)<2:
    print("Missing argument : analyse_files_PU.py filelist.txt")
    exit()
  
filelist = str(sys.argv[1])

# Listing files
fileslist = filelist.split(',')
if '' in fileslist :
    fileslist.remove('')
#print(fileslist)

# Checking files
good_files_list = []
for file in sorted(fileslist):
    good_file = analyse_PU(file)
    
    if good_file:
        good_files_list.append(file)
    else:
        print(' >> Excluding file '+file+' from further treatment')
    print('')

# Saving good list
print('Keeping ', len(good_files_list), 'files over the ', len(fileslist))
fout = open('goodPU_filelist.txt', 'w')
for file in good_files_list:
    fout.write(file+'\n')
fout.close()


