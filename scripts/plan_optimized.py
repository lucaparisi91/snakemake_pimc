import pandas as pd
import numpy as np
r_close = 0.6 # target fraction of the time in the closed sector

Z=pd.read_csv( snakemake.input[0] , delim_whitespace=True)
sims=pd.read_csv( snakemake.input[1] , delim_whitespace=True)
CA=(1/r_close - 1)/np.exp(Z["ZA"])
sims["CA"]=CA
sims=sims.loc[:,sims.columns != "folders"].drop_duplicates().dropna()

sims.to_csv(snakemake.output[0],sep="\t")