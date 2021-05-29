#!/bin/bash

for tn in 1 2 4 8 16 28
do
export OMP_NUM_THREADS=$tn
echo Encolando T_OMP y T_OMP_C con $OMP_NUM_THREADS hilos.

sbatch ./util/slurm.sh T_OMP
sbatch ./util/slurm.sh T_OMP 2050
sbatch ./util/slurm.sh T_OMP 4098

sbatch ./util/slurm.sh T_OMP_C
sbatch ./util/slurm.sh T_OMP_C 2050
sbatch ./util/slurm.sh T_OMP_C 4098
done