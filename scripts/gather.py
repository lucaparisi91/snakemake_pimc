import pandas as pd
import os
from pathlib import Path
import numpy as np
def gather(inputFiles,merge_parameters=True):
    '''
    collect data from inputFiles and merge with dataframe runs containing parameters and a folder colum. Gatherered data is merged with the row containing the parent directory of the inputfile
    '''
    datas=[]
    for filename in inputFiles:
        data=pd.read_csv( filename , delim_whitespace=True)
        folder=Path(filename).parent.absolute()

        if merge_parameters:
            parameters=pd.read_csv( os.path.join(folder,"parameters.dat") , delim_whitespace=True)
            data=pd.merge(data,parameters,how="cross").dropna()
        datas.append(data)

    data=pd.concat(datas)
    return (data)


merge_parameters=True
if snakemake.params:
    merge_parameters=snakemake.params.merge_parameters


data=gather(np.array(snakemake.input),merge_parameters=merge_parameters)
data.to_csv(snakemake.output[0],sep="\t")