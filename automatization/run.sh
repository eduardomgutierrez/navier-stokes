#!/bin/bash

sbatch ./slurm.sh T_O2ULFM_OPT3
sbatch ./slurm.sh T_ISPC_GCC
sbatch ./slurm.sh T_ISPC_GCC9
sbatch ./slurm.sh T_ISPC_C11
sbatch ./slurm.sh T_ISPC_C9
sbatch ./slurm.sh T_ISPC_ICC