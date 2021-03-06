#!/bin/bash

module load netcdf
module load new r/3.6.0

njobs=100
for ((n=1;n<=${njobs};n++)); do
    echo "Submitting chunk number $n ..."
    bsub -W 72:00 -u bestocke -J "get_data_sif_pk $n" -R "rusage[mem=5000]" "Rscript --vanilla rscript_get_data_sif_pk.R $n $njobs"
done
