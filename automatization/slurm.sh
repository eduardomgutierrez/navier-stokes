#!/bin/bash

#SBATCH --job-name=cremona-tinymc
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28

srun ./execute_it