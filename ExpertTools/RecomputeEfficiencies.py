#from ROOT import ROOT, gROOT, TFile, TH1F, TEfficiency, TGraph, TObject, TKey
from ROOT import *
import sys


if len(sys.argv)<2:
  print "Syntax is: RecomputeEfficiencies.py INPUTFILE"
  exit()

inputfilename=str(sys.argv[1])


f = TFile(inputfilename)
source = f.GetDirectory('SiStripHitEff')

fout = TFile('SiStripHitEffHistos_fill_merged.root', 'recreate')
output = fout.mkdir('SiStripHitEff')

source.cd()
for key in source.GetListOfKeys():
  classname = key.GetClassName()
  cl = gROOT.GetClass(classname)
  if (not cl):
    continue
  if (cl.InheritsFrom(TH1.Class())):
	source.cd()
	obj = key.ReadObj()
	output.cd()
	obj.Write()
	name = obj.GetName()
	print 'saving ', name
	# compute efficiency with the corresponding histos
	if 'found' in name:
	  if len(name) > 6:
	    hfound = obj
	    htot = source.Get(name.replace('found', 'total'))
	    output.cd()
	    graph = TGraphAsymmErrors()
	    graph.BayesDivide(hfound, htot)
	    graph.SetName(name.replace('layerfound_', 'eff').replace('found', 'eff').replace('layer_', 'layer').replace('vs','Vs'))
	    graph.SetMarkerStyle(20)
	    print 'saving ', graph.GetName()
	    graph.Write()
	  else:
	    hfound = obj
	    htot = source.Get(name.replace('found', 'all'))
	    output.cd()
	    graph = TGraphAsymmErrors()
	    graph.BayesDivide(hfound, htot)
	    for ibin in range( graph.GetN() ):
		  graph.SetPointEXlow(ibin, 0)
		  graph.SetPointEXhigh(ibin, 0)
	    if '2' in name:
	      graph.SetName('eff_all')
	    else:
	      graph.SetName('eff_good')
	    graph.SetMarkerStyle(20)
	    print 'saving ', graph.GetName()
	    graph.Write()
	  
	
	
fout.Close()
f.Close()
