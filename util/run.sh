#!/bin/bash

echo Encolando T_CUDA.

sbatch ./util/slurm.sh T_CUDA_B128_RB_32
sbatch ./util/slurm.sh T_CUDA_B256_RB_32
sbatch ./util/slurm.sh T_CUDA_B512_RB_32
sbatch ./util/slurm.sh T_CUDA_B1024_RB_32
sbatch ./util/slurm.sh T_CUDA_B128_RB_16
sbatch ./util/slurm.sh T_CUDA_B256_RB_16
sbatch ./util/slurm.sh T_CUDA_B512_RB_16
sbatch ./util/slurm.sh T_CUDA_B1024_RB_16

sbatch ./util/slurm.sh T_CUDA_B128_RB_32 1024
sbatch ./util/slurm.sh T_CUDA_B256_RB_32 1024
sbatch ./util/slurm.sh T_CUDA_B512_RB_32 1024
sbatch ./util/slurm.sh T_CUDA_B1024_RB_32 1024
sbatch ./util/slurm.sh T_CUDA_B128_RB_16 1024
sbatch ./util/slurm.sh T_CUDA_B256_RB_16 1024
sbatch ./util/slurm.sh T_CUDA_B512_RB_16 1024
sbatch ./util/slurm.sh T_CUDA_B1024_RB_16 1024

sbatch ./util/slurm.sh T_CUDA_B128_RB_32 2048
sbatch ./util/slurm.sh T_CUDA_B256_RB_32 2048
sbatch ./util/slurm.sh T_CUDA_B512_RB_32 2048
sbatch ./util/slurm.sh T_CUDA_B1024_RB_32 2048
sbatch ./util/slurm.sh T_CUDA_B128_RB_16 2048
sbatch ./util/slurm.sh T_CUDA_B256_RB_16 2048
sbatch ./util/slurm.sh T_CUDA_B512_RB_16 2048
sbatch ./util/slurm.sh T_CUDA_B1024_RB_16 2048

sbatch ./util/slurm.sh T_CUDA_B128_RB_32 4096
sbatch ./util/slurm.sh T_CUDA_B256_RB_32 4096
sbatch ./util/slurm.sh T_CUDA_B512_RB_32 4096
sbatch ./util/slurm.sh T_CUDA_B1024_RB_32 4096
sbatch ./util/slurm.sh T_CUDA_B128_RB_16 4096
sbatch ./util/slurm.sh T_CUDA_B256_RB_16 4096
sbatch ./util/slurm.sh T_CUDA_B512_RB_16 4096
sbatch ./util/slurm.sh T_CUDA_B1024_RB_16 4096