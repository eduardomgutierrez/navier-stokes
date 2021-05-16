#!/bin/bash

# sbatch ./slurm.sh T_O2ULFM_OPT3
# sbatch ./slurm.sh T_ISPC_GCC
# sbatch ./slurm.sh T_ISPC_GCC9
# sbatch ./slurm.sh T_ISPC_C11
# sbatch ./slurm.sh T_ISPC_C9

srun icc solver.c solver.h -O2 -DVECT_LINSOLVE -DINV_M -DRB -DREUSE -DN=66 --ffast-math lin_solve_ispc lin_solve_ispc.h headless.c -o headless && ./headless > icc_66.out
srun icc solver.c solver.h -O2 -DVECT_LINSOLVE -DINV_M -DRB -DREUSE -DN=258 --ffast-math lin_solve_ispc lin_solve_ispc.h headless.c -o headless && ./headless > icc_258.out
srun icc solver.c solver.h -O2 -DVECT_LINSOLVE -DINV_M -DRB -DREUSE -DN=514 --ffast-math lin_solve_ispc lin_solve_ispc.h headless.c -o headless && ./headless > icc_514.out
srun icc solver.c solver.h -O2 -DVECT_LINSOLVE -DINV_M -DRB -DREUSE -DN=1026 --ffast-math lin_solve_ispc lin_solve_ispc.h headless.c -o headless && ./headless > icc_1026.out