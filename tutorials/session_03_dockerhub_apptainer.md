# Bioinformatics Containerization Tutorial  
## Session 3: DockerHub and Apptainer (KUACC)

## Table of Contents
- [Overview](#overview)
- [Tag, log in, and push to Docker Hub](#tag-log-in-and-push-to-docker-hub)
- [Build the Apptainer image locally](#build-the-apptainer-image-locally)
- [Transfer the .sif file to KUACC](#transfer-the-sif-file-to-kuacc)
- [Create runtime directories on KUACC](#create-runtime-directories-on-kuacc)
- [Binding layout inside the container](#binding-layout-inside-the-container)
- [Inspect and run Apptainer on KUACC](#inspect-and-run-apptainer-on-kuacc)
- [Run full pipelines interactively](#run-full-pipelines-interactively)
- [Summary](#summary)

---

## Overview

In this session you will:

- Tag, log in, and push your image to Docker Hub.
- Convert the Docker image into an Apptainer `.sif` file.
- Transfer the `.sif` file to KUACC.
- Bind KUACC directories into the container.
- Run ANGSD / PCAngsd inside Apptainer interactively.

---

## Tag, log in, and push to Docker Hub

Assume you have a local image:

```bash
docker images
```

Example:

```text
REPOSITORY          TAG       IMAGE ID       CREATED        SIZE
isophya-course      0.1       8c0a92d3f0a2   12 hours ago   6.3GB
```

### Log in to Docker Hub

```bash
docker login -u iksaglam
```

When prompted, use a Personal Access Token (PAT) with read/write scope.

Verify:

```bash
docker info | grep Username
```

### Tag the image

```bash
docker tag isophya-course:0.1 iksaglam/isophya-course:0.1
```

### Push the image

```bash
docker push iksaglam/isophya-course:0.1
```

Anyone can later run:

```bash
docker pull iksaglam/isophya-course:0.1
```

---

## Build the Apptainer image locally

On your laptop (with Apptainer installed):

```bash
apptainer build isophya-course_0.1.sif \
  docker://iksaglam/isophya-course:0.1
```

This produces:

```bash
ls -lh isophya-course_0.1.sif
```

---

## Transfer the `.sif` file to KUACC

```bash
scp isophya-course_0.1.sif \
  iksaglam@login.kuacc.ku.edu.tr:~/oulu/
```

On KUACC:

```bash
ssh iksaglam@login.kuacc.ku.edu.tr
cd ~/oulu
ls -lh isophya-course_0.1.sif
```

---

## Create runtime directories on KUACC

Inside `~/oulu`:

```bash
mkdir -p ~/oulu/data
mkdir -p ~/oulu/results
mkdir -p ~/oulu/scripts
```

Place into:

- `~/oulu/data`: `.bamlist`, `.sites`, `.chr`, `.info`, `.clst`, etc.
- `~/oulu/results`: empty directory for outputs.
- `~/oulu/scripts`: copies of `01_call_genotypes.sh`, `02_pcangsd_pipeline.sh`, `pcadapt.R`, `plotPCA.R`, `plotAdmix.R`.

Large data remain where they already live:

```bash
/userfiles/utopalan22/isophya/new_bams
/userfiles/utopalan22/isophya/references
```

---

## Binding layout inside the container

| Host path                       | Container path             | Use                     |
|---------------------------------|----------------------------|-------------------------|
| `~/oulu/data`                    | `/data`                   | metadata, lists, filters |
| `/userfiles/.../new_bams`        | `/data/bams`              | BAMs (large)           |
| `/userfiles/.../references`      | `/data/ref`               | reference genome       |
| `~/oulu/results`                 | `/results`                | outputs                |
| `~/oulu/scripts`                 | `/workspace/scripts`      | scripts                |

This matches the defaults in your scripts, for example:

```bash
REF="${REF:-/data/ref/isophya_contigs_CAYMY.fasta}"
```

---

## Inspect and run Apptainer on KUACC

### Inspect the image

```bash
cd ~/oulu
module load apptainer/1.4.1

apptainer inspect isophya-course_0.1.sif
```

### Test bindings interactively

```bash
apptainer exec \
  --bind ~/oulu/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/oulu/results:/results \
  --bind ~/oulu/scripts:/workspace/scripts:ro \
  isophya-course_0.1.sif \
  bash -lc 'ls /data; ls /data/bams | head; ls /data/ref; ls /workspace/scripts'
```

If this lists the expected files, your bindings are correct.

### Interactive shell

```bash
apptainer shell \
  --bind ~/oulu/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/oulu/results:/results \
  --bind ~/oulu/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.1.sif
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
cd ~/oulu

apptainer exec \
  --bind ~/oulu/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/oulu/results:/results \
  --bind ~/oulu/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.1.sif \
  bash -lc './scripts/01_call_genotypes.sh'
```

### PCAngsd + selection pipeline

```bash
cd ~/oulu

apptainer exec \
  --bind ~/oulu/data:/data:ro \
  --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro \
  --bind /userfiles/utopalan22/isophya/references:/data/ref:ro \
  --bind ~/oulu/results:/results \
  --bind ~/oulu/scripts:/workspace/scripts:ro \
  --pwd /workspace \
  isophya-course_0.1.sif \
  bash -lc './scripts/02_pcangsd_pipeline.sh'
```

---

## Summary

After Session 3 you can:

- Publish your image on Docker Hub.
- Build a portable Apptainer `.sif` file.
- Bind KUACC directories into the container.
- Run your ANGSD and PCAngsd workflows interactively on the cluster.

