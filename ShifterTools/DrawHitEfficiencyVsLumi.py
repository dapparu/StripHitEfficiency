import sys
import os
import subprocess
import math
from ROOT import TCanvas, TGraph, TGraphAsymmErrors, TFile, TEfficiency

import ROOT
ROOT.gROOT.SetBatch(True)
ROOT.gStyle.SetOptTitle(1)


def get_layer_name(layer):
  if layer<5: return 'TIB L'+str(layer)
  if layer>=5 and layer<11: return 'TOB L'+str(layer-4)
  if layer>=11 and layer<14: return 'TID- D'+str(layer-10)
  if layer>=14 and layer<17: return 'TID+ D'+str(layer-13)
  if layer>=17 and layer<26: return 'TEC- W'+str(layer-16)
  if layer>=26 and layer<35: return 'TEC+ W'+str(layer-25)
  return ''


def add_points(graph, directory, layer):

  ipt=graph.GetN()

  # List runs
  for root, directories, files in os.walk(directory):
    for rundir in directories:
      if "run_" in rundir:
        # start to process run
        run = rundir[4:]
        #print "processing run ", run
		
        lumi=0
        lumi_err=0

        # Get informations for a given run
        frun = TFile(directory+"/"+rundir+"/withMasking/rootfile/SiStripHitEffHistos_run"+run+".root")
        fdir = frun.GetDirectory("SiStripHitEff")        
 
        # for efficiency
        hfound = fdir.Get("found")
        htotal = fdir.Get("all")

        if htotal == None:
          print '  Missing histogram in file '+frun.GetName()
          continue

        # lumi
        hlumi = fdir.Get("instLumi")
        if hlumi == None:
          print '  Missing lumi histogram in file '+frun.GetName()
          continue
        lumi = hlumi.GetMean()
        lumi_err = hlumi.GetRMS()
        #print "lumi (avg+/-rms): ", lumi, "+/-", lumi_err

        # efficiency for a given layer
        found = hfound.GetBinContent(layer)
        total = htotal.GetBinContent(layer)
        eff = found/total
        #print run, eff, lumi, lumi_err

        # remove run without lumi informations
        if lumi>1 :
          eff_vs_lumi.SetPoint(ipt, lumi, eff)
          low = TEfficiency.Bayesian(total, found, .683, 1, 1, False)
          up = TEfficiency.Bayesian(total, found, .683, 1, 1, True);
          eff_vs_lumi.SetPointError(ipt, lumi_err, lumi_err, eff-low, up-eff)
          ipt+=1
        frun.Close()


#------------------------------------------------------------------
hiteffdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency"

if len(sys.argv)<2:
  print "Syntax is:  DrawHitEfficiencyVsLumi.py  ERA  "
  print "  example:  DrawHitEfficiencyVsLumi.py GR17 "
  exit() 

era=str(sys.argv[1])


#---------------------


# Produce trend plots for each layer

graphs=[]
c1 = TCanvas()

for layer in range(1,35):

  print 'producing trend plot for layer '+str(layer)

  graphs.append( TGraphAsymmErrors() )
  eff_vs_lumi = graphs[-1]
  xlabels = add_points(eff_vs_lumi, hiteffdir+"/"+era, layer)

  eff_vs_lumi.SetTitle(get_layer_name(layer))
  eff_vs_lumi.GetXaxis().SetTitle("inst. lumi [x10^{30}]")
  eff_vs_lumi.GetYaxis().SetTitle("hit efficiency")

  eff_vs_lumi.SetMarkerStyle(20)
  eff_vs_lumi.SetMarkerSize(.8)
  eff_vs_lumi.Draw("AP")

  eff_vs_lumi_lastpt = TGraphAsymmErrors()
  npt = eff_vs_lumi.GetN()
  x, y = ROOT.Double(0), ROOT.Double(0)
  eff_vs_lumi.GetPoint(npt-1, x, y)
  eff_vs_lumi_lastpt.SetPoint(0, x, y)
  eff_vs_lumi_lastpt.SetMarkerStyle(24)
  eff_vs_lumi_lastpt.SetMarkerColor(2)
  eff_vs_lumi_lastpt.Draw("P")

  c1.Print("SiStripHitEffTrendPlotVsLumi_layer"+str(layer)+".png")


