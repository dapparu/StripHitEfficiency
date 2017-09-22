#include <TSystem.h>
#include <TFile.h>
#include <TCanvas.h>
#include <TLegend.h>
#include <TH1F.h>
#include <TStyle.h>
#include <TGraphAsymmErrors.h>
#include <iostream>

void bookGraph (TGraphAsymmErrors *g, int nL);
void SiStripHitEff_CompareRuns(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2);

void SiStripHitEff_CompareRuns(TString ERA1, TString runnumber1, TString ERA2, TString runnumber2){

  int nLayers = 34;

  TString wwwdir="/afs/cern.ch/cms/tracker/sistrvalidation/WWW/CalibrationValidation/HitEfficiency/";
  
  TString dir1=wwwdir+"/"+ERA1+"/run_"+runnumber1+"/";
  TString dir2=wwwdir+"/"+ERA1+"/run_"+runnumber2+"/";
  
  TFile *f1= new TFile(dir1+"standard/rootfile/SiStripHitEffHistos_run"+runnumber1+".root");
  TFile *f2= new TFile(dir2+"standard/rootfile/SiStripHitEffHistos_run"+runnumber2+".root");

  TH1F *found_r1, *found2_r1;
  TH1F *all_r1, *all2_r1;
  TH1F *found_r2, *found2_r2;
  TH1F *all_r2, *all2_r2;

  if (f1->IsZombie() || f2->IsZombie()){
    std::cout << endl << "---> You should first execute the command: './HitEffDriver_woRoot.sh  /store/group/dpg_tracker_strip/comm_tracker/Strip/Calibration/calibrationtree/GR16/YOURCALIBRATIONTREE' for the run(s) you want to analyze" << endl;
    return;
  }  
  
  f1->cd("SiStripHitEff");
  found_r1=(TH1F*)gDirectory->Get("found");
  found2_r1=(TH1F*)gDirectory->Get("found2");
  all_r1=(TH1F*)gDirectory->Get("all");
  all2_r1=(TH1F*)gDirectory->Get("all2");
  
  f2->cd("SiStripHitEff");
  found_r2=(TH1F*)gDirectory->Get("found");
  found2_r2=(TH1F*)gDirectory->Get("found2");
  all_r2=(TH1F*)gDirectory->Get("all");
  all2_r2=(TH1F*)gDirectory->Get("all2");


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
  
  TCanvas *c = new TCanvas();
  c->SetGridy();
  c->SetGridx();
  gr_r1->Draw("AP");
  gr_r2->Draw("Psame");
  TLegend *leg1 = new TLegend(0.40,0.15,0.88,0.40);
  leg1->SetFillStyle(0);
  leg1->SetBorderSize(0);
  leg1->AddEntry(gr_r1,"Good Modules, RUN" + runnumber1,"p");
  leg1->AddEntry(gr_r2,"Good Modules, RUN" + runnumber2,"p");
  leg1->SetTextSize(0.030);
  leg1->SetFillColor(0);
  leg1->Draw("same");
  c->SaveAs("SiStripHitEff_CompareRuns_GoodModules.png","png");
  gr2_r1->Draw("AP");
  gr2_r2->Draw("Psame");
  TLegend *leg2 = new TLegend(0.40,0.15,0.88,0.40);
  leg2->SetFillStyle(0);
  leg2->SetBorderSize(0);
  leg2->SetTextSize(1.);
  leg2->AddEntry(gr2_r1,"All Modules, RUN" + runnumber1,"p");
  leg2->AddEntry(gr2_r2,"All Modules, RUN" + runnumber2,"p");
  leg2->SetTextSize(0.030);
  leg2->SetFillColor(0);
  leg2->Draw("same"); 
  c->SaveAs("SiStripHitEff_CompareRuns_AllModules.png","png");

  
  return;
}

void bookGraph (TGraphAsymmErrors *g, int nL){
  
  for(int j = 0; j<nL+1; j++)
    g->SetPointError(j, 0., 0., g->GetErrorYlow(j),g->GetErrorYhigh(j) );

  g->GetXaxis()->SetLimits(0,nL);
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
