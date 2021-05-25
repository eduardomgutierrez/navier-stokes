#!/bin/bash

#SBATCH --job-name=gutierrez-stizza-navier-stokes
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28

if [ -z "$2" ]
  then
    srun python3 ./automatization/run.py -t $1
  else
    srun python3 ./automatization/run.py -t $1 -S $2
fi