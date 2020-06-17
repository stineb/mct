#!/bin/bash

bsub -n 2 -W 12:00 -u bestocke -J get_data_watch_prec -R "rusage[mem=5000]" "R --vanilla --slave < ~/mct/rscript_get_data_watch_prec.R > ~/hpc_log/rscript_get_data_watch_prec.Rout"