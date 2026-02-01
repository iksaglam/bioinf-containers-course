# Bioinformatics Containerization Tutorial
## Session 1: Project Setup and Base Container

<br/><br/>

#### Topics to be covered:

- [Overview](#overview)  
- [Project directory layout](#project-directory-layout)  
- [Create the repository directory](#create-the-repository-directory)  
- [Define the Conda environment](#define-the-conda-environment)  
- [Write the Dockerfile](#write-the-dockerfile)  
- [Build the container](#build-the-container)  
- [Test the container](#test-the-container)  
- [Run with mounted data/results](#run-with-mounted-dataresults)  
- [Initialize Git and push to GitHub](#initialize-git-and-push-to-github)  
- [Using prebuilt BioContainers for QC](#using-prebuilt-biocontainers-for-qc)  
- [Summary](#summary)  

---

## Overview

In this session you will:

- Create a clean project directory for the course.
- Define a Conda environment for basic population-genomics tools.
- Build a Docker image using `micromamba`.
- Test the container and mount data/results directories.
- Initialize a Git repository.
- Use prebuilt BioContainers (`samtools`, `fastqc`) for basic QC.

---

## Project directory layout

Target layout:

```text
bioinf-containers-course/
├─ data/                 # BAMs, metadata files, lists etc.
├─ containers/
│  ├─ Dockerfile
│  └─ environment.yml
├─ workflow/
│  ├─ compose.yaml
│  ├─ nextflow.config
│  └─ main.nf
├─ scripts/              # Shell scripts, R scripts etc.
├─ hpc/
│  ├─ run_apptainer.sbatch
│  └─ Apptainer.def
└─ results/              # All outputs from analysis will go here
```

---

## Create the repository directory

```bash
mkdir -p bioinf-containers-course/{data,results,containers,workflow,scripts,hpc}
cd bioinf-containers-course
```

---

## Define the Conda environment

Create `containers/environment.yml`:

```yaml
name: base
channels:
  - bioconda
  - conda-forge

dependencies:
  - python=3.11
  - r-base=4.3

  # bioinformatics
  - samtools=1.20
  - bcftools=1.20
  - angsd=0.940
  - pcaone

  # R ecosystem
  - r-ggplot2
  - r-data.table
  - r-ggrepel
  - r-bigutilsr
  - r-cowplot
  - r-adegenet
  - r-ade4
  - r-vcfr
  - r-optparse

  # optional but convenient
  - pip
```

---

## Write the Dockerfile

Create `containers/Dockerfile`:

```dockerfile
FROM mambaorg/micromamba:1.5.10

COPY containers/environment.yml /tmp/environment.yml

RUN micromamba install -y -n base -f /tmp/environment.yml \
    && micromamba clean -a -y

USER root

ENV MAMBA_ROOT_PREFIX=/opt/conda
ENV PATH=/opt/conda/envs/base/bin:/opt/conda/bin:$PATH

RUN echo 'eval "$(micromamba shell hook --shell bash)"' > /etc/profile.d/micromamba.sh \
 && echo 'micromamba activate base' >> /etc/profile.d/micromamba.sh \
 && chmod +x /etc/profile.d/micromamba.sh

USER mambauser
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
CMD ["bash"
```

---

## Build the container

```bash
cd ~/bioinf-containers-course
docker build --no-cache --network=host -t isophya-course:0.2 -f containers/Dockerfile .
```

---

## Test the container

Interactive shell:

```bash
docker run --rm -it isophya-course:0.2 bash
```

Test with a login shell (important for SLURM/Apptainer later):
```bash
docker run --rm isophya-course:0.4 bash -lc "which angsd; which samtools; which R; echo \$CONDA_DEFAULT_ENV"
```

Expected paths (approx.):

```bash
/opt/conda/bin/angsd
/opt/conda/bin/samtools
/opt/conda/bin/R
base
```

---

## Run with mounted data/results

```bash
docker run --rm -it \
  -v "$(pwd)/data:/workspace/data:ro" \
  -v "$(pwd)/results:/workspace/results" \
  isophya-course:0.2 \
  bash -lc "samtools --version"
```

---

## Initialize Git and push to GitHub

Initialize repository:

```bash
cd bioinf-containers-course
git init
git add .
git commit -m "Initial container course project"
```

Add the GitHub remote:

```bash
git branch -M main
git remote add origin \
  https://github.com/iksaglam/bioinf-containers-course.git
git push -u origin main
```

---

## Using prebuilt BioContainers


Run prebuilt samtools:
```bash
docker run --rm staphb/samtools:1.20 samtools --version
```

**samtools flagstat**:

Assume you have:
```bash
bioinf-containers-course/data/U_KAV_D04_sorted_flt.bam
```

Run:

```bash
docker run --rm \
  -v "$(pwd)/data:/data:ro" \
  staphb/samtools:1.20 \
  samtools flagstat /data/U_KAV_D04_sorted_flt.bam
```



**FastQC**:

Run fastqc on a BAM:

Display help:
```bash
docker run --rm biocontainers/fastqc:v0.11.9_cv8 fastqc --help
```

Run FastQC:

```bash
docker run --rm \
  -v "$(pwd)/data:/data:ro" \
  -v "$(pwd)/results:/results" \
  biocontainers/fastqc:v0.11.9_cv8 \
  fastqc /data/U_KAV_D04_sorted_flt.bam --outdir /results
```

Outputs:
```bash
results/U_KAV_D04_sorted_flt_fastqc.html
results/U_KAV_D04_sorted_flt_fastqc.zip
```

---

## Summary

In this session, you:

- Created a reproducible directory structure  
- Wrote a Conda environment  
- Built a Docker container using micromamba  
- Tested the environment  
- Mounted data/results for real work  
- Initialized Git and learned how to push  
- Used prebuilt BioContainers for QC tasks  

---
