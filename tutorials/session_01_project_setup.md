# Bioinformatics Containerization Tutorial — Session 1: Project Setup and Base Container

In this session we will create a reproducible container-based project for basic population genomics tasks (building with micromamba, testing containers, using prebuilt BioContainers for QC, and initializing a git repo). The examples use `docker`, `micromamba`, `samtools`, `fastqc`, and a minimal Conda environment YAML.

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
  - samtools=1.20
  - bcftools=1.20
  - angsd=0.940
```

---

## Write the Dockerfile

Create `containers/Dockerfile`:

```dockerfile
FROM mambaorg/micromamba:1.5.8

USER root
WORKDIR /usr/local/env

COPY environment.yml /tmp/environment.yml

RUN micromamba create -y -f /tmp/environment.yml -n base && \
    micromamba clean --all --yes

ENV PATH="/opt/conda/envs/base/bin:${PATH}"

CMD ["/bin/bash"]
```

---

## Build the container

```bash
cd containers
docker build -t bioinf-base:latest .
```

---

## Test the container

Start a shell inside it:

```bash
docker run -it bioinf-base:latest bash
```

Test tools:

```bash
samtools --version
bcftools --version
python3 --version
R --version
```

---

## Run with mounted data/results

```bash
docker run \
  -v $(pwd)/data:/data \
  -v $(pwd)/results:/results \
  -it bioinf-base:latest bash
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
git remote add origin https://github.com/YOURUSERNAME/bioinf-containers-course.git
git push -u origin main
```

---

## Using prebuilt BioContainers for QC

**FastQC**:

```bash
docker run \
  -v $(pwd)/data:/data \
  -v $(pwd)/results:/results \
  biocontainers/fastqc:v0.12.1_cv8 \
  fastqc /data/*.fastq.gz -o /results
```

**samtools flagstat**:

```bash
docker run \
  -v $(pwd)/data:/data \
  biocontainers/samtools:v1.20_cv1 \
  samtools flagstat /data/sample.bam
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
