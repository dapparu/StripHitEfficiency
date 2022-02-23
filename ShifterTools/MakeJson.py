import json
import sys


def ReadJSONFile(name):
    tab=[]
    with open(name) as json_file:
        data = json.load(json_file)
        for d in data["data"]:
            if d["attributes"]["luminosity_detected"] == True :
                tab.append(d["attributes"]["bunch_number"])
    return tab

def PairMakerFromTab(tab):
    train=[]
    NewTrain=True
    AtLeastTwoTrains=False
    for i in range(0,len(tab)):
        if NewTrain==False:
            if tab[i]==current+1:
                current=tab[i]
            else:
                end=current
                NewTrain=True
                if AtLeastTwoTrains:
                    train.append([begin,end+1])
                else:
                    train.append([begin+1,end+1])
                AtLeastTwoTrains=True
        else:
            begin=tab[i]
            current=begin
            NewTrain=False
        if i==len(tab)-1:
            end=tab[i]
            if AtLeastTwoTrains:
                train.append([begin,end+1])
            else:
                train.append([begin+1,end+1])

    return train
    
        
#tab=ReadJSONFile("../Fill6714/data.txt")
tab=ReadJSONFile(str(sys.argv[1]))
#print tab
train = PairMakerFromTab(tab)
#print train
train_string=str(train)
#print train_string
fout=open("good_"+str(sys.argv[1]),"w+")
fout.write(train_string)
fout.close
