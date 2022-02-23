import json
import ctypes
import sys
import os
import subprocess
import math
import numpy as np
import ROOT
from ROOT import TCanvas, TGraph, TGraphErrors, TGraphAsymmErrors, TFile, TEfficiency, TLine
sys.path.append(".")

from EfficiencyCalculator import EfficiencyCalculator

def fillNumberFromRun(run):
    f = open("/afs/cern.ch/user/d/dapparu/EPR/CMSSW_11_3_2/src/StripHitEfficiency/ShifterTools/GR18/runlist_all.txt","r")
    fill=-1
    for x in f:
        if x.split(' ')[0]==run:
            fill=x.split(' ')[1]
            return int(fill)
    return int(fill)

def get_layer_name(layer):
  if layer<5: return 'TIB L'+str(layer)
  if layer>=5 and layer<11: return 'TOB L'+str(layer-4)
  if layer>=11 and layer<14: return 'TID R'+str(layer-10)
  if layer>=14 and layer<17: return 'TID R'+str(layer-13)
  if layer>=17 and layer<24: return 'TEC R'+str(layer-16)
  if layer>=24 and layer<31: return 'TEC R'+str(layer-23)
  return ''
  
#wwwdir = '/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency/GR18/'
wwwdir = '/afs/cern.ch/user/d/dapparu/www/GR18/'
run = '320674'
fill = '-1'

run = sys.argv[1] 
fill = fillNumberFromRun(run)

print(run,fill)

# Get informations for a given run
frun = TFile(wwwdir+'run_'+run+'/withMasking/rootfile/SiStripHitEffHistos_run'+run+'.root')
#frun = TFile("/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency/GR18/run_316766/withMasking/rootfile/SiStripHitEffHistos_run316766.root")
fdir = frun.GetDirectory('SiStripHitEff')

# efficiency
gmeas = fdir.Get('eff_good').Clone()

if gmeas == None:
    print('  Missing graph in file '+frun.GetName())
    exit()

# PU
hpu = fdir.Get('PU')
if hpu == None:
    print('  Missing lumi/pu histogram in file '+frun.GetName())
    exit()
pu = hpu.GetMean()
pu_err = hpu.GetRMS()
print('           pu :', pu, '+/-', pu_err)

#frun.Close()



### Compute Predictions

os.system("cp GR18/fill_"+str(fill)+".txt .")

command_str1 = "python MakeJson.py fill_"+str(fill)+".txt"
command_str2 = "mv good_fill_"+str(fill)+".txt fill"+str(fill)+".json"

os.system(command_str1)
os.system(command_str2)

os.system("rm fill_"+str(fill)+".txt")

fillJson_str = "fill"+str(fill)+".json"

pred = EfficiencyCalculator()
pred.set_pileup(pu)
#pred.set_fillscheme("/afs/cern.ch/user/d/dapparu/EPR/jsonFiles/good_fill6714.json")
pred.set_fillscheme(fillJson_str)
pred.read_inputs("parameters_files/HIPProbPerPU.root","parameters_files/LowPUOffset.root")

gpred = TGraphErrors()
#######################################
for ilay in range(1, gmeas.GetN()):
    layer = get_layer_name(ilay)
    pred.read_deadtime("parameters_files/Ndeadtime.txt",layer)
    expected = pred.compute_avg_eff_layer(layer)
    error = np.sqrt(pred.compute_error_avg_eff_layer(layer))
    print(expected,error)
    gpred.SetPoint(ilay-1, ilay-0.5, expected) 
    gpred.SetPointError(ilay-1, 0, error) 

#######################################


# Draw graphs

c = TCanvas()
c.Divide(1,2)
c.cd(1)
gmeas.Draw('AP')
gmeas.SetMinimum(0.99)

list_label=["TIB L1","TIB L2","TIB L3","TIB L4","TOB L1","TOB L2","TOB L3","TOB L4","TOB L5","","TID- R1","TID- R2","TID- R3","TID+ R1","TID+ R2","TID+ R3","TEC- R1","TEC- R2","TEC- R3","TEC- R4","TEC- R5","TEC- R6","TEC- R7","TEC- R8","","TEC+ R1","TEC+ R2","TEC+ R3","TEC+ R4","TEC+ R5","TEC+ R6","TEC+ R7","TEC+ R8",""]

# Draw vertical lines
nLayers = gmeas.GetN()
print(nLayers, 'layers')
ymin = gmeas.GetMinimum()
ymax = gmeas.GetMaximum()
lTIB = TLine(4, ymin, 4, ymax)
lTIB.SetLineStyle(3)
lTIB.Draw()
lTOB = TLine(10, ymin, 10, ymax)
lTOB.SetLineStyle(3)
lTOB.Draw()
lTID = TLine(16, ymin, 16, ymax)
lTID.SetLineStyle(3)
lTID.Draw()

gpred.SetMarkerStyle(20)
gpred.SetMarkerColor(4)
gpred.Draw('P')

#c.Print('graph'+str(run)+'.png')
c.cd(2)
gmeas2 = gmeas.Clone()
gmeas2.GetYaxis().SetTitle("data/prediction")
for i in range (1,nLayers+1):
    b1 = gmeas.GetPointY(i-1)
    b2 = gpred.GetPointY(i-1)
    e1 = gmeas.GetErrorY(i-1)
    e2 = gpred.GetErrorY(i-1)
    b1sq = b1*b1
    b2sq = b2*b2
    e1sq = e1*e1
    e2sq = e2*e2
    errsq = (e1sq*b2sq+e2sq*b1sq)
    if b1==0:
        break
    if b2>0:
        gmeas2.SetPoint(i-1,i-0.5,b1/b2)
        gmeas2.SetPointError(i-1,0,0,np.sqrt(errsq),np.sqrt(errsq))
    else:
        gmeas2.SetPoint(i-1,i-0.5,0)
        gmeas2.SetPointError(i-1,0,0,0,0)
    gmeas2.GetXaxis().SetBinLabel(i,list_label[i])

gmeas2.SetTitle("")
gmeas2.GetXaxis().SetRangeUser(0,30)
gmeas2.GetXaxis().SetLabelSize(0.01)
gmeas2.GetXaxis().LabelsOption("v")
ymin=0.995
ymax=1.005
gmeas2.Draw("AP")
gmeas2.SetMarkerColor(1)
gmeas2.SetLineColor(1)
gmeas2.SetMinimum(ymin)
gmeas2.SetMaximum(ymax)
l1 = TLine(0,1,30,1)
l1.Draw()
l3=TLine()
l3.SetLineStyle(4)
l3.DrawLine(0,0.998,30,0.998)
l3.DrawLine(0,1.002,30,1.002)
l2 = TLine()
l2.SetLineStyle(3)
l2.DrawLine(4, ymin, 4, ymax)
l2.DrawLine(10, ymin, 10, ymax)
l2.DrawLine(16, ymin, 16, ymax)
c.Print('eff_graph'+str(run)+'.png')
c.Print('eff_graph'+str(run)+'.pdf')

