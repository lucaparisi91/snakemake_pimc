import numpy as np
import pandas as pd
import os
from pathlib import Path


def gather(inputFiles,runs=None):
    '''
    collect data from inputFiles and merge with dataframe runs containing parameters and a folder colum. Gatherered data is merged with the row containing the parent directory of the inputfile
    '''
    datas=[]
    for filename in inputFiles:
        data=pd.read_csv( filename , delim_whitespace=True)
        folder=Path(filename).parent.absolute()
        if runs is not None:
            run= pd.merge( runs, pd.DataFrame( {"folders" : [folder]}   ))
            run=runs[  [ os.path.samefile( folderRun, folder) for folderRun in runs["folders"] ] ]
            run=run.loc[:, run.columns != "folders"]
            data=data.merge(run, how='cross')
        datas.append(data)

    data=pd.concat(datas)
    return (data)



runs=pd.read_csv( "{}/parameters.dat".format(snakemake.wildcards.folder) , delim_whitespace=True)
print(runs)
filenames= [ filename for filename in snakemake.input ]
data=gather(filenames,runs=runs)
data.to_csv(snakemake.output[0],sep="\t")

