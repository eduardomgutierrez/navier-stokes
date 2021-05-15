#!/bin/bash

#SBATCH --job-name=gutierrez-stizza-navier-stokes
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28

srun python3 ./automatization/run.py