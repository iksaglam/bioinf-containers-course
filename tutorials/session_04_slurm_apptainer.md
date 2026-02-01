# Bioinformatics Containerization Tutorial  
## Session 4: SLURM + Apptainer Workflow (KUACC)

## Table of Contents
- [Overview](#overview)
- [Minimal SLURM + Apptainer structure](#minimal-slurm--apptainer-structure)
- [SLURM job for ANGSD genotype calling](#slurm-job-for-angsd-genotype-calling)
- [SLURM job for PCAngsd + selection pipeline](#slurm-job-for-pcangsd--selection-pipeline)
- [Chaining jobs with dependencies](#chaining-jobs-with-dependencies)
- [Unified SLURM script with task selector (optional)](#unified-slurm-script-with-task-selector-optional)
- [Summary](#summary)

---

## Overview

In this session you will:

- Wrap Apptainer runs inside SLURM batch jobs on KUACC.
- Reuse the same bind layout as in Session 3.
- Run:
  - `01_call_genotypes.sh` (ANGSD) as a SLURM job.
  - `02_pca.sh` (PCAone) as a SLURM job.
- Optionally chain these jobs using `--dependency`.

Your scripts and `.sif` image remain unchanged; you only add SLURM wrappers.

---

## Minimal SLURM + Apptainer structure

Every batch script follows this pattern:

1. SLURM header: job name, partition, CPUs, memory, time.
2. `cd` into `~/KU`.
3. `module load apptainer/1.4.1`.
4. `apptainer exec` with consistent `--bind` layout:
   - `~/KU/data` → `/data`
   - `/userfiles/.../new_bams` → `/data/bams`
   - `/userfiles/.../references` → `/data/ref`
   - `~/KU/results` → `/results`
   - `~/KU/scripts` → `/workspace/scripts`
5. Execute the appropriate script inside the container.

---

## SLURM job for ANGSD genotype calling

Create `~/KU/hpc/run_angsd_genotypes.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=angsd_genotypes
#SBATCH --output=slurm-angsd-%j.out
#SBATCH --error=slurm-angsd-%j.err
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00

# 1) Go to working directory (where sif, data, results, scripts live)
cd ~/KU

# 2) Load Apptainer module
module load apptainer/1.4.1

# 3) Run the ANGSD genotypes script inside the container
apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  ~/KU/isophya-course_0.2.sif \
  bash -lc './scripts/01_call_genotypes.sh'
```

### Submit and monitor

From `~/KU`:

```bash
cd ~/KU
sbatch hpc/run_angsd_genotypes.sh
```

Example response:

```text
Submitted batch job 1234567
```

Monitor:

```bash
squeue -u iksaglam
tail -f slurm-angsd-1234567.out
tail -f slurm-angsd-1234567.err
```

Inspect results:

```bash
ls -R ~/KU/results
```

---

## SLURM job for PCAone pca pipeline

Create `~/KU/hpc/run_PCAone_pca.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=pca_pipeline
#SBATCH --output=slurm-pcangsd-%j.out
#SBATCH --error=slurm-pcangsd-%j.err
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00

cd ~/oulu
module load apptainer/1.4.1

apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KUresults:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  ~/oulu/isophya-course_0.2.sif \
  bash -lc './scripts/02_pca.sh'
```

Submit:

```bash
cd ~/KU
sbatch hpc/run_PCAone_pca.sh
```

Check queue and logs:

```bash
squeue -u iksaglam
tail -f slurm-pcangsd-<jobid>.out
ls -R ~/KU/results
```

---

## Chaining jobs with dependencies

Typical pattern:

1. Submit ANGSD job.
2. Submit PCAngsd job with `afterok` dependency.

Example:

```bash
cd ~/KU

# Step 1: submit ANGSD job
jid1=$(sbatch hpc/run_angsd_genotypes.sh | awk '{print $4}')
echo "ANGSD job id: $jid1"

# Step 2: submit PCAone job that waits for ANGSD to finish successfully
sbatch --dependency=afterok:$jid1 hpc/run_PCAone_pca.sh
```

---

## Unified SLURM script with task selector (optional)

Instead of two separate files, you can use one script with a variable:

Create `~/KU/hpc/run_isophya_task.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=isophya_task
#SBATCH --output=slurm-isophya-%x-%j.out
#SBATCH --error=slurm-isophya-%x-%j.err
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00

# TASK can be: angsd or PCAone
TASK="${TASK:-angsd}"

cd ~/KU
module load apptainer/1.4.1

case "$TASK" in
  angsd)
    SCRIPT="./scripts/01_call_genotypes.sh"
    ;;
  PCAone)
    SCRIPT="./scripts/02_pca.sh"
    ;;
  *)
    echo "Unknown TASK: $TASK" >&2
    exit 1
    ;;
esac

echo "Running TASK=${TASK} using ${SCRIPT}"

apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  ~/oulu/isophya-course_0.2.sif \
  bash -lc "${SCRIPT}"
```

Submit:

```bash
# ANGSD:
sbatch --export=TASK=angsd hpc/run_isophya_task.sh

# PCAngsd:
sbatch --export=TASK=PCAone hpc/run_isophya_task.sh
```

---

## Summary

After Session 4 you can:

- Submit containerized analyses as SLURM jobs.
- Use consistent bindings from laptop → Apptainer → SLURM.
- Chain jobs via dependencies to build simple two-step pipelines.

