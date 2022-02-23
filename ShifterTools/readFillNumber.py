f = open("/afs/cern.ch/user/d/dapparu/EPR/CMSSW_11_3_2/src/StripHitEfficiency/ShifterTools/GR18/runlist_all.txt","r")
run=316766
fill=-1
for x in f:
    print(x.split(' ')[0])
    if x==run:
        fill=x+1
        print(fill)
