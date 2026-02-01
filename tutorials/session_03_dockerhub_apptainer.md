# Bioinformatics Containerization Tutorial  
## Session 3: DockerHub and Apptainer (KUACC)

## Table of Contents
- [Overview](#overview)
- [Build SIF from your local Docker image](#build-sif-from-your-local-docker-image)
- [Build from Docker Hub](#build-from-docker-hub)
- [Transfer the .sif file to KUACC](#transfer-the-sif-file-to-kuacc)
- [Create runtime directories on KUACC](#create-runtime-directories-on-kuacc)
- [Binding layout inside the container](#binding-layout-inside-the-container)
- [Inspect and run Apptainer on KUACC](#inspect-and-run-apptainer-on-kuacc)
- [Run full pipelines interactively](#run-full-pipelines-interactively)
- [Summary](#summary)

---

## Overview

In this session you will:
- Convert the Docker image into an Apptainer `.sif`
- Tag, log in, and push your image to Docker Hub.
- Transfer the `.sif` file to KUACC.
- Bind KUACC directories into the container.
- Run ANGSD / PCA inside Apptainer interactively.
---


## Build SIF from your local Docker image

View your local images:

```bash
docker images
```

Assume you have a local image:

```bash
docker images
```

Example:

```text
IMAGE                              ID             DISK USAGE   CONTENT SIZE
biocontainers/fastqc:v0.11.9_cv8   7b8f85bb68da        839MB             0B        
hello-world:latest                 1b44b5a3e06a       10.1kB             0B  
iksaglam/isophya-course:0.1        fae152e8a545       2.76GB             0B        
isophya-course:0.1                 fae152e8a545       2.76GB             0B        
isophya-course:0.2                 4d3d86432c49       3.16GB             0B        
isophya-course:0.3                 98011ccca28e       3.16GB             0B        
staphb/samtools:1.20               c94ad914cd42        472MB             0B       


```

Build SIF

```bash
apptainer build isophya-course_0.2.sif docker-daemon://isophya-course:0.2
```

This produces:

```bash
ls -lh isophya-course_0.2.sif
```
---

## Build from Docker Hub

Log in to Docker Hub

```bash
docker login -u iksaglam
```

When prompted, use a Personal Access Token (PAT) with read/write scope.

Verify:

```bash
docker info | grep Username
```

Tag the image

```bash
docker tag isophya-course:0.2 iksaglam/isophya-course:0.2
```

Push the image

```bash
docker push iksaglam/isophya-course:0.2
```

Anyone can later run:

```bash
docker pull iksaglam/isophya-course:0.12
```


Build the Apptainer image locally

```bash
apptainer build isophya-course_0.2.sif docker://iksaglam/isophya-course:0.2
```

This again produces:

```bash
ls -lh isophya-course_0.2.sif
```

---

## Transfer the `.sif` file to KUACC

```bash
scp isophya-course_0.2.sif \
  iksaglam@login.kuacc.ku.edu.tr:~/KU/
```

On KUACC:

```bash
ssh iksaglam@login.kuacc.ku.edu.tr
cd ~/KU
ls -lh isophya-course_0.2.sif
```

---

## Create runtime directories on KUACC

Inside `~/KU`:

```bash
mkdir -p ~/KU/data
mkdir -p ~/KU/results
mkdir -p ~/KU/scripts
```

Place into:

- `~/KU/data`: `.bamlist`, `.sites`, `.chr`, `.info`, `.clst`, etc.
- `~/KU/results`: empty directory for outputs.
- `~/KU/scripts`: copies of `01_call_genotypes.sh`, `02_pcangsd_pipeline.sh`, `pcadapt.R`, `plotPCA.R`, `plotAdmix.R`.

Large data remain where they already live:

```bash
/userfiles/utopalan22/isophya/new_bams
/userfiles/utopalan22/isophya/references
```

---

## Binding layout inside the container

| Host path                       | Container path             | Use                     |
|---------------------------------|----------------------------|-------------------------|
| `~/KU/data`                    | `/data`                   | metadata, lists, filters |
| `/userfiles/.../new_bams`        | `/data/bams`              | BAMs (large)           |
| `/userfiles/.../references`      | `/data/ref`               | reference genome       |
| `~/KU/results`                 | `/results`                | outputs                |
| `~/KU/scripts`                 | `/workspace/scripts`      | scripts                |

This matches the defaults in your scripts, for example:

```bash
REF="${REF:-/data/ref/isophya_contigs_CAYMY.fasta}"
```

---

## Inspect and run Apptainer on KUACC

### Inspect the image

```bash
cd ~/KU
module load apptainer/1.4.1

apptainer inspect isophya-course_0.2.sif
```

### Test bindings interactively

```bash
apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  isophya-course_0.2.sif \
  bash -lc 'ls /data; ls /data/bams | head; ls /data/ref; ls /workspace/scripts'
```

If this lists the expected files, your bindings are correct.

### Interactive shell

```bash
apptainer shell \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.2.sif
```

Inside:

```bash
angsd -h
python -m pcangsd -h
ls /data
ls /results
```

---

## Run full pipelines interactively

### ANGSD genotype calling

```bash
cd ~/KU

apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.2.sif \
  bash -lc './scripts/01_call_genotypes.sh'
```

### PCA pipeline

```bash
cd ~/KU

apptainer exec \
  --bind ~/KU/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/KU/results:/results \
  --bind ~/KU/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.2.sif \
  bash -lc './scripts/02_pca.sh'
```

---

## Summary

After Session 3 you can:

- Publish your image on Docker Hub.
- Build a portable Apptainer `.sif` file.
- Bind KUACC directories into the container.
- Run your ANGSD and PCAngsd workflows interactively on the cluster.

