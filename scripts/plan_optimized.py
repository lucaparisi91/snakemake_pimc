import pandas as pd
import numpy as np

r_close = 0.6 
r_ab_a = 100
r_b_a = 1

Z=pd.read_csv( snakemake.input[0] , delim_whitespace=True)
sims=pd.read_csv( snakemake.input[1] , delim_whitespace=True)

if snakemake.config["ensamble"]=="semiCanonical":
    CA=(1/r_close - 1)/( np.exp(Z["ZA"])*( 1 + r_b_a + r_ab_a ) )
    CB=r_b_a*CA*np.exp(Z["ZA"] - Z["ZB"])
    CAB=r_ab_a*CA*np.exp(Z["ZA"] - Z["ZAB"])
    
    sims["CA"]=CA
    sims["CB"]=CB
    sims["CAB"]=CAB
    
else:
    CA=(1/r_close - 1)/np.exp(Z["ZA"])
    sims["CA"]=CA
sims=sims.loc[:,sims.columns != "folders"].drop_duplicates().dropna()

sims.to_csv(snakemake.output[0],sep="\t")
