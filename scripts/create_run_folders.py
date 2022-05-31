import scipy
from pimc import singleComponentCanonical,inputFileTools
import pandas as pd
import numpy as np
import os
from pathlib import Path

for folder in os.listdir(snakemake.input[0]):
    for seed in range(snakemake.params.nChains):
        Path( os.path.join(snakemake.output[0],folder,"run{:d}".format(seed) )).mkdir(parents=True, exist_ok=True)