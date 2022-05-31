print("create")

import scipy
from pimc import singleComponentCanonical,inputFileTools
import pandas as pd
import numpy as np
import os

data=pd.read_csv(snakemake.input[0],delim_whitespace=True).reset_index(drop=True)

if (data.shape[0] != 1) :
    raise RuntimeError("Should only be one row in the dataframe")


j=singleComponentCanonical.generateInputFiles(data)[0]
label=singleComponentCanonical.generateLabels(data)[0]

settings=[ {"folder" : snakemake.wildcards.folder , "jSon" : [ ["input.json", j  ] ] } ]    
folders=[ os.path.abspath(setting["folder"]) for setting in settings  ]

inputFileTools.createSimFolders(settings)