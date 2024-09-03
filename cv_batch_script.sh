#!/bin/bash
#SBATCH --job-name=MDG_cross_validation
#SBATCH --array=1-25%5     # Job array with 25 tasks i.e. 5 reps x 5 groups
#SBATCH --time=01:00:00    # Time limit for each job (adjust as needed)
#SBATCH --mem=16G          # Memory required per job (adjust as needed)
#SBATCH --cpus-per-task=1  # Number of CPUs per job (adjust as needed)
#SBATCH --export=NONE

# Load the R module 
module load R/4.3.1

# Run the R script with the appropriate SLURM_ARRAY_TASK_ID
Rscript cv_batch.R
