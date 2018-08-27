#include <TSystem.h>
#include <TFile.h>
#include <TCanvas.h>
#include <TLegend.h>
#include <TH1F.h>
#include <TStyle.h>
#include <TGraphAsymmErrors.h>
#include <iostream>
#include <TLatex.h>

set<uint32_t> read_bad_modules(TString filename);
void SiStripHitEff_CompareIneffMod(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2);

void bookGraph (TGraphAsymmErrors *g, int nL);
void SiStripHitEff_CompareRuns(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2, TString type="standard");

void SiStripHitEff_CompareRuns(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2, TString type="standard"){

  int nLayers = 34;

  TString wwwdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency/";
  
  TString dir1=wwwdir+"/"+ERA1+"/run_"+runnumber1+"/";
  TString dir2=wwwdir+"/"+ERA2+"/run_"+runnumber2+"/";
  
  if( type!="standard" && type!="withMasking" ){
    std::cerr << endl << "Only types 'standard' and 'withMasking' exist." << endl << endl;
	return;
  }  
  
  TFile *f1= new TFile(dir1+type+"/rootfile/SiStripHitEffHistos_run"+runnumber1+".root");
  TFile *f2= new TFile(dir2+type+"/rootfile/SiStripHitEffHistos_run"+runnumber2+".root");

  TH1F *found_r1, *found2_r1;
  TH1F *all_r1, *all2_r1;
  TH1F *found_r2, *found2_r2;
  TH1F *all_r2, *all2_r2;

  if (f1->IsZombie() || f2->IsZombie()){
    std::cerr << endl << "---> You should first execute the command: './HitEffDriver_woRoot.sh  /store/group/dpg_tracker_strip/comm_tracker/Strip/Calibration/calibrationtree/ERA/YOURCALIBRATIONTREE' for the run(s) you want to analyze" << endl;
    return;
  }  
  
  // Get histos and lumi info
  f1->cd("SiStripHitEff");
  found_r1=(TH1F*)gDirectory->Get("found");
  found2_r1=(TH1F*)gDirectory->Get("found2");
  all_r1=(TH1F*)gDirectory->Get("all");
  all2_r1=(TH1F*)gDirectory->Get("all2");
  TH1F *lumi1=(TH1F*)gDirectory->Get("instLumi");
  TH1F *pu1=(TH1F*)gDirectory->Get("PU");

  double lum1=lumi1->GetMean();
  int puissance1=30;
  while(lum1>=10.)
    {
      lum1/=10.;
      puissance1++;
    }
  TString meanlumi1=Form("%.2f",lum1);
  TString meanpu1=Form("%.2f",pu1->GetMean());
  
  f2->cd("SiStripHitEff");
  found_r2=(TH1F*)gDirectory->Get("found");
  found2_r2=(TH1F*)gDirectory->Get("found2");
  all_r2=(TH1F*)gDirectory->Get("all");
  all2_r2=(TH1F*)gDirectory->Get("all2");
  TH1F *lumi2=(TH1F*)gDirectory->Get("instLumi");
  TH1F *pu2=(TH1F*)gDirectory->Get("PU");

  double lum2=lumi2->GetMean();
  int puissance2=30;
  while(lum2>=10.)
    {
      lum2/=10.;
      puissance2++;
    }
  TString meanlumi2=Form("%.2f",lum2);
  TString meanpu2=Form("%.2f",pu2->GetMean());

  
  // Compute efficiencies, fill graphs
  TGraphAsymmErrors *gr_r1 = new TGraphAsymmErrors(nLayers+1);
  gr_r1->BayesDivide(found_r1,all_r1); 
  bookGraph(gr_r1, nLayers);
  gr_r1->SetMarkerColor(2);
  gr_r1->SetLineColor(2);
  gr_r1->SetMarkerStyle(20);
  TGraphAsymmErrors *gr2_r1 = new TGraphAsymmErrors(nLayers+1);
  gr2_r1->BayesDivide(found2_r1,all2_r1);
  bookGraph(gr2_r1, nLayers);
  gr2_r1->SetMarkerColor(1);
  gr2_r1->SetLineColor(1);
  gr2_r1->SetMarkerStyle(21);

  TGraphAsymmErrors *gr_r2 = new TGraphAsymmErrors(nLayers+1);
  gr_r2->BayesDivide(found_r2,all_r2); 
  bookGraph(gr_r2, nLayers);
  gr_r2->SetMarkerColor(2);
  gr_r2->SetLineColor(2);
  gr_r2->SetMarkerStyle(24);
  TGraphAsymmErrors *gr2_r2 = new TGraphAsymmErrors(nLayers+1);
  gr2_r2->BayesDivide(found2_r2,all2_r2);
  bookGraph(gr2_r2, nLayers);
  gr2_r2->SetMarkerColor(1);
  gr2_r2->SetLineColor(1);
  gr2_r2->SetMarkerStyle(25);
  
  
  // Draw plots
  TCanvas *c = new TCanvas();
  c->SetGridy();
  c->SetGridx();
  gr_r1->Draw("AP");
  gr_r2->Draw("Psame");
  TLegend *leg1 = new TLegend(0.4,0.205,0.89,0.355);
  leg1->SetFillStyle(0);
  //leg1->SetBorderSize(50);
  leg1->AddEntry(gr_r1,Form("#splitline{Good Modules, RUN %s}{<PU>: %s, <inst. lumi.>: %s x 10^{%i} cm^{-2} s^{-1}}",runnumber1.Data(),meanpu1.Data(),meanlumi1.Data(),puissance1),"p");
  leg1->AddEntry(gr_r2,Form("#splitline{Good Modules, RUN %s}{<PU>: %s, <inst. lumi.>: %s x 10^{%i} cm^{-2} s^{-1}}",runnumber2.Data(),meanpu2.Data(),meanlumi2.Data(),puissance2),"p");
  leg1->SetTextSize(0.027);
  leg1->SetFillStyle(1001);
  leg1->Draw("same");
  c->SaveAs("SiStripHitEff_CompareRuns_GoodModules.png","png");

  gr2_r1->Draw("AP");
  gr2_r2->Draw("Psame");
  TLegend *leg2 = new TLegend(0.4,0.205,0.89,0.355);
  leg2->SetFillStyle(0);
  //leg2->SetBorderSize(0);
  leg2->AddEntry(gr2_r1,Form("#splitline{All Modules, RUN %s}{<PU>: %s, <inst. lumi.>: %s x 10^{%i} cm^{-2} s^{-1}}",runnumber1.Data(),meanpu1.Data(),meanlumi1.Data(),puissance1),"p");
  leg2->AddEntry(gr2_r2,Form("#splitline{All Modules, RUN %s}{<PU>: %s, <inst. lumi.>: %s x 10^{%i} cm^{-2} s^{-1}}",runnumber2.Data(),meanpu2.Data(),meanlumi2.Data(),puissance2),"p");
  leg2->SetTextSize(0.027);
  leg2->SetFillStyle(1001);
  leg2->Draw("same"); 
  c->SaveAs("SiStripHitEff_CompareRuns_AllModules.png","png");

  // Compare list of inefficient modules
  SiStripHitEff_CompareIneffMod(ERA1, runnumber1, ERA2, runnumber2);
  
  return;
}

void bookGraph (TGraphAsymmErrors *g, int nL){
  
  for(int j = 0; j<nL+1; j++)
    g->SetPointError(j, 0., 0., g->GetErrorYlow(j),g->GetErrorYhigh(j) );

  g->GetXaxis()->SetLimits(0,nL);
  g->GetYaxis()->SetLimits(0.88,1.0);
  g->SetMarkerSize(1.2);
  g->SetLineWidth(4);
  g->SetMinimum(0.90);
  g->SetMaximum(1.001);
  g->GetYaxis()->SetTitle("Efficiency");
  gStyle->SetTitleFillColor(0);
  gStyle->SetTitleBorderSize(0);
  g->SetTitle(" Hit Efficiency ");

  TString label[34]={"TIB L1", "TIB L2", "TIB L3", "TIB L4", 
		     "TOB L1", "TOB L2", "TOB L3", "TOB L4", "TOB L5", "TOB L6",
		     "TID- D1", "TID- D2", "TID- D3",
		     "TID+ D1", "TID+ D2", "TID+ D3",
		     "TEC- D1", "TEC- D2", "TEC- D3", "TEC- D4", "TEC- D5", "TEC- D6", "TEC- D7", "TEC- D8", "TEC- D9",
		     "TEC+ D1", "TEC+ D2", "TEC+ D3", "TEC+ D4", "TEC+ D5", "TEC+ D6", "TEC+ D7", "TEC+ D8", "TEC+ D9"};
  
  for ( Long_t k=1; k<nL+1; k++) 
    g->GetXaxis()->SetBinLabel(((k+1)*100+2)/(nL)-4,label[k-1]);
  
  return;
}

set<uint32_t>  read_bad_modules(TString filename){  // read bad modules to mask

  ifstream badModules_file;
  set<uint32_t> badModules_list;
  
  if(!filename.IsNull()) {
	badModules_file.open(filename.Data());
	uint32_t badmodule_detid;
	int mods, fiber1, fiber2, fiber3;
	if(badModules_file.is_open()) {
      string line;
	  while ( getline (badModules_file,line) ) {
		if(badModules_file.eof()) continue;
		stringstream ss(line);
		ss >> badmodule_detid >> mods >> fiber1 >> fiber2 >> fiber3;
		if(badmodule_detid!=0 && mods==1 && (fiber1==1 || fiber2==1 || fiber3==1) )
	      badModules_list.insert(badmodule_detid);
	  }
      badModules_file.close();
	}
  }
  
  return badModules_list;
}


// Compare lists of inefficient modules and print a tracker map
void SiStripHitEff_CompareIneffMod(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2){

  int nLayers = 34;

  TString wwwdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency/";
  
  TString dir1=wwwdir+"/"+ERA1+"/run_"+runnumber1+"/";
  TString dir2=wwwdir+"/"+ERA2+"/run_"+runnumber2+"/";
  
  TString filename1 = dir1+"withMasking/QualityLog/BadModules_input.txt";
  TString filename2 = dir2+"withMasking/QualityLog/BadModules_input.txt";

  set<uint32_t> badModules_list1 = read_bad_modules(filename1.Data());
  set<uint32_t> badModules_list2 = read_bad_modules(filename2.Data());
  
  set<uint32_t>::iterator itBadMod1;
  set<uint32_t>::iterator itBadMod2;
  bool inBothFile=false;
  
  ofstream badModules_file_diff;
  badModules_file_diff.open("bad_modules_diff.txt");
  ofstream badModules_file_diff_formap;
  badModules_file_diff_formap.open("bad_modules_diff_formap.txt");
  
  for (itBadMod1=badModules_list1.begin(); itBadMod1!=badModules_list1.end(); ++itBadMod1){ 
    inBothFile=false;
  	for (itBadMod2=badModules_list2.begin(); itBadMod2!=badModules_list2.end(); ++itBadMod2)
	  if (*itBadMod1==*itBadMod2) inBothFile=true;
	if(inBothFile){ 
	  badModules_file_diff<<"| "<<*itBadMod1<<endl;
	  badModules_file_diff_formap<<*itBadMod1<<" 2"<<endl;
    }
	else{ 
	  badModules_file_diff<<"- "<<*itBadMod1<<endl;
	  badModules_file_diff_formap<<*itBadMod1<<" 1"<<endl;
    }
  }
  
  for (itBadMod2=badModules_list2.begin(); itBadMod2!=badModules_list2.end(); ++itBadMod2){
    inBothFile=false;
  	for (itBadMod1=badModules_list1.begin(); itBadMod1!=badModules_list1.end(); ++itBadMod1)
	  if (*itBadMod2==*itBadMod1) { inBothFile=true;}
	if(!inBothFile) { 
	  badModules_file_diff<<"+ "<<*itBadMod1<<endl;
	  badModules_file_diff_formap<<*itBadMod2<<" 3"<<endl;
    }
  }	  
  
  badModules_file_diff_formap.close();
  badModules_file_diff.close();
  gSystem->Exec("sort -k 2 -n bad_modules_diff.txt > bad_modules_diff_sorted.txt");
  gSystem->Exec("mv -f bad_modules_diff_sorted.txt bad_modules_diff.txt");
  
  TString title="Inefficient modules (only in run "+runnumber1+" in blue, common to both runs in green, only in run "+runnumber2+" in red)";
  TString command="print_TrackerMap bad_modules_diff.txt '"+title+"' SiStripHitEff_CompareIneffMod_map.pdf 2400 False False 1 3";
  gSystem->Exec(command.Data());
}
