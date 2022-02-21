import sys
import os
import subprocess
import math
import ROOT as R

R.gROOT.SetBatch(True)
R.gStyle.SetOptTitle(1)


def get_layer_name(layer):
  if layer<5: return 'TIB L'+str(layer)
  if layer>=5 and layer<11: return 'TOB L'+str(layer-4)
  if layer>=11 and layer<14: return 'TID- D'+str(layer-10)
  if layer>=14 and layer<17: return 'TID+ D'+str(layer-13)
  if layer>=17 and layer<26: return 'TEC- W'+str(layer-16)
  if layer>=26 and layer<35: return 'TEC+ W'+str(layer-25)
  return ''

def get_short_layer_name(layer):
  if layer<5: return 'L'+str(layer)
  if layer>=5 and layer<11: return 'L'+str(layer-4)
  if layer>=11 and layer<14: return 'D'+str(layer-10)
  if layer>=14 and layer<17: return 'D'+str(layer-13)
  if layer>=17 and layer<26: return 'W'+str(layer-16)
  if layer>=26 and layer<35: return 'W'+str(layer-25)
  return ''



def add_points(graph, directory, subdir, layer, filter=False):

  ipt=graph.GetN()
  labels = []
  offsets = [0.999, 0.9995, 0.9995, 0.9995, 0.9995, 0.9995, 0.9995, 0.9995, 0.9995, 0.]
  coeffs = [0.005/40, 0.004/40, 0.004/40, 0.0035/40, 0.009/40, 0.007/40, 0.004/40, 0.003/40, 0.0005/40, 0]
 
  # List runs
  for root, directories, files in os.walk(directory):
    for rundir in sorted(directories):
      if "run_" in rundir:
        # start to process run
        run = rundir[4:]
        #print ("processing run ", run)
		
        # for efficiency
        frun = R.TFile(directory+"/"+rundir+"/"+subdir+"/rootfile/SiStripHitEffHistos_run"+run+".root")
        fdir = frun.GetDirectory("SiStripHitEff")
        hfound = fdir.Get("found")
        htotal = fdir.Get("all")

        if htotal == None: 
          print('  Missing histogram in file '+frun.GetName())
          continue

        # measured efficiency for a given layer
        found = hfound.GetBinContent(int(layer))
        if found < 1 : found = 0
        total = htotal.GetBinContent(int(layer))
        if total>0: eff = found/total
        else: eff = 0
        #print (run, eff)
        labels.append(run)
        low = R.TEfficiency.Bayesian(total, found, .683, 1, 1, False)
        up = R.TEfficiency.Bayesian(total, found, .683, 1, 1, True)


        # PU info
        hpu = fdir.Get("PU")
        if hpu == None:
          print('  Missing pu histogram in file '+frun.GetName())
          continue
        pu = hpu.GetMean()
        pu_err = hpu.GetRMS()
        #print( 'PU (avg+/-rms): ', pu, '+/-', pu_err )


        # compute expected efficiency
        
        ##########  TO REPLACE

        expected = eff
        if eff == 0 : expected = 1.

        expected=offsets[layer-1]-pu*coeffs[layer-1]

        ##########


        # compute ratio and fill graph

        ratio = eff/expected
        if filter and (ratio>0.998 and ratio<1.0015): ratio=0
        graph.SetPoint(ipt, ipt+1, ratio)
        graph.SetPointError(ipt, 0, 0, (eff-low)/expected, (up-eff)/expected)
        if not filter and (ratio <0.998 or ratio >1.0015):
            print(run, found, total, '\t{:.4f}'.format(eff), '{:.4f}'.format(expected), '{:.4f}'.format((eff-low)/expected), '\t{:.2f}'.format(pu), '{:.2f}'.format(pu_err))
        #print('ODD', found, total, eff, expected, up)
        ipt+=1
        frun.Close()

  axis = graph.GetXaxis()
  for i in range(graph.GetN()) : 
    axis.SetBinLabel(axis.FindBin(i+1), labels[i])
    #print (i, axis.FindBin(i+1), labels[i])
  return labels



def draw_subdet(graphs, subdet):

  l_min=0
  l_max=0
  subdet_str=''
  
  if subdet==1:
    l_min=1
    l_max=4
    subdet_str='TIB'

  if subdet==2:
    l_min=5
    l_max=9
    subdet_str='TOB'

  if subdet==3:
    l_min=11
    l_max=13
    subdet_str='TIDm'

  if subdet==4:
    l_min=14
    l_max=16
    subdet_str='TIDp'

  if subdet==5:
    l_min=17
    l_max=24
    subdet_str='TECm'

  if subdet==6:
    l_min=26
    l_max=33
    subdet_str='TECp'

  leg = R.TLegend(.92, .3, .99, .7)
  leg.SetHeader('')
  leg.SetBorderSize(0)

  min_y=1.
  for layer in range(l_min,l_max+1):
    if layer==l_min: graphs[layer-1].Draw('AP')
    else: graphs[layer-1].Draw('P')
    graphs[layer-1].SetMarkerColor(1+layer-l_min)
    min_y = graphs[layer-1].GetMinimum() if graphs[layer-1].GetMinimum()<min_y else min_y
    leg.AddEntry(graphs[layer-1], ' '+get_short_layer_name(layer), 'p')
  
  graphs[l_min-1].SetTitle(subdet_str)
  haxis = graphs[l_min-1].GetHistogram()
  haxis.GetYaxis().SetRangeUser(min_y, 1.)
  leg.Draw()
  
  c1.Print('SiStripHitEffTrendPlot_Subdet'+str(subdet)+'.png')



#------------------------------------------------------------------



hiteffdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency"

if len(sys.argv)<3:
  print("Syntax is:  DrawHitEfficiencyVsRun.py  ERA  SUBDIRECTORY")
  print("  example:  DrawHitEfficiencyVsRun.py GR17 standard")
  exit() 

era=str(sys.argv[1])
subdir=str(sys.argv[2])


#---------



# Produce trend plots for each layer

graphs=[]

for layer in range(1,10):#35

  print('producing trend plot for layer '+str(layer))

  graphs.append( R.TGraphAsymmErrors() )
  eff_vs_run = graphs[-1]
  eff_vs_run_filtered = R.TGraphAsymmErrors()

  xlabels = add_points(eff_vs_run, hiteffdir+"/"+era, subdir, layer)
  add_points(eff_vs_run_filtered, hiteffdir+"/"+era, subdir, layer, True)

  eff_vs_run.SetTitle(get_layer_name(layer))
  #eff_vs_run.GetXaxis().SetTitle("run number")
  eff_vs_run.GetYaxis().SetTitle("Ratio of measured over expected hit efficiency")

  c1 = R.TCanvas()
  eff_vs_run.SetMarkerStyle(20)
  eff_vs_run.SetMarkerSize(.8)

  # if many runs, clean xlabels
  xaxis = eff_vs_run.GetXaxis()
  nbins = len(xlabels)
  nless = int(nbins/40+1)
  #print(nless)
  if nbins > 40 :
    for i in range(eff_vs_run.GetN()) :
      if i%(nless)==0 or i == nbins-1 :
        xaxis.SetBinLabel(xaxis.FindBin(i+1), xlabels[i])
        #print(i, xaxis.FindBin(i+1), xlabels[i])
      else :
        xaxis.SetBinLabel(xaxis.FindBin(i+1), '')
  
  # adapt y range in case efficiency is 0 for some runs
  #yaxis = eff_vs_run.GetYaxis()
  #if yaxis.GetXmin()==0 and yaxis.GetXmax()>0.5 : 
  #  yaxis.SetRangeUser(0.5, yaxis.GetXmax())

  eff_vs_run.Draw("AP")
  l = R.TLine(0, 1, xaxis.GetXmax(), 1)
  l.Draw()

  eff_vs_run_filtered.SetMarkerStyle(20)
  eff_vs_run_filtered.SetMarkerSize(.8)
  eff_vs_run_filtered.SetMarkerColor(2)
  eff_vs_run_filtered.Draw('P')
  c1.Print("SiStripHitEffTrendPlotVsRun_layer"+str(layer)+".png")



