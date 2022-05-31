import scipy
from pimc import singleComponentCanonical,inputFileTools
import pandas as pd
import numpy as np
import os
from pathlib import Path
import tqdm

minC=-11
maxC=-4
nOpt=10

data=pd.read_csv(snakemake.input[0],delim_whitespace=True).reset_index(drop=True)
data=data.drop("CA",axis=1)
labels=singleComponentCanonical.generateLabels(data)

print("Creating optimization folders...")
for i,row in tqdm.tqdm(data.iterrows(),total=len(data)):
    data_opt = pd.DataFrame(  [row.values] , columns=row.index )
    CAS=np.logspace( minC, maxC,nOpt)
    for CA in CAS:
        data_opt["CA"]=CA
        #js=singleComponentCanonical.generateInputFiles(data_opt)
        opt_labels=["CA{:2.3e}".format(CA)]
        opt_folder=os.path.join(snakemake.output[0],labels[i],opt_labels[0])
        Path(opt_folder).mkdir(parents=True, exist_ok=True)
        data_opt.to_csv(os.path.join(opt_folder,"parameters.dat"),sep=" ")

    #run_folder=os.path.join(folder_run,labels[i])    
    #Path(run_folder).mkdir(parents=True, exist_ok=True)

