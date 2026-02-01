# Bioinformatics Containerization Tutorial  
## Session 2: Full Toolbox with Docker Compose

<br/><br/>

#### Topics to be covered

- [Overview](#overview)
- [Build or verify the toolbox image](#build-or-verify-the-toolbox-image)
- [Compose file layout](#compose-file-layout)
- [ANGSD genotype calling service](#angsd-genotype-calling-service)
- [PCAngsd + selection + plotting service](#pcangsd--selection--plotting-service)
- [Interactive use and overriding defaults](#interactive-use-and-overriding-defaults)
- [Summary](#summary)

---

## Overview

In this session you will:

- Extend the base container into a full population genomics toolbox.  
- Use `docker compose` to define reusable services.  
- Run:  
  - ANGSD genotype calling  
  - PCAngsd structure, inbreeding, and selection scan  
  - R-based plotting scripts (PCA + admixture)  
- Learn how to run commands interactively and override defaults.

We assume:

- `isophya-course:0.1` is already built (from Session 1).
- Your directory layout is:

```text
bioinf-containers-course/
 ├── containers/     # Dockerfile, environment.yml
 ├── data/           # BAMs, metadata (.clst, .info), filters (.sites, .chr)
 ├── results/        # outputs
 ├── scripts/        # 01_call_genotypes.sh, 02_pcangsd_pipeline.sh, R scripts
 ├── workflow/       # compose.yaml, main.nf, nextflow.config
 └── hpc/            # Apptainer.def, run_apptainer.sbatch
```

---

## Build or verify the toolbox image

If you have **not** built the image yet (or want to rebuild it):

```bash
cd ~/bioinf-containers-course

docker build -t isophya-course:0.1 -f containers/Dockerfile .
```

This image contains:

- `ANGSD`, `samtools`, `bcftools`  
- `R` and required R packages  
- `pcangsd` and dependencies  

---

## Compose file layout

Create `workflow/compose.yaml`:

```yaml
version: "3.9"

x-common: &common
  image: isophya-course:0.1
  user: "${UID}:${GID}"
  working_dir: /workspace
  volumes:
    - ../workflow:/workspace:rw
    - ../data:/data:ro
    - ../scripts:/workspace/scripts:ro
    - ../results:/results:rw
  tty: true

services:
  toolbox:
    <<: *common
    container_name: isophya-toolbox
    command: ["bash"]

  angsd-call:
    <<: *common
    container_name: isophya-angsd-call
    environment:
      POP: "isophya71"
      THREADS: "8"
      REF: "/data/isophya_contigs_CAYMY.fasta"
    command:
      - bash
      - -lc
      - |
        ./scripts/01_call_genotypes.sh

  pca-pipeline:
    <<: *common
    container_name: isophya-pcangsd-pipeline
    environment:
      POP: "isophya71"
      THREADS: "8"
      BEAGLE: "/results/genotypes/isophya71.beagle.gz"
    command:
      - bash
      - -lc
      - |
        ./scripts/02_pca.sh

  r:
    <<: *common
    container_name: isophya-r
    command: ["bash","-lc","R"]
```

---

## ANGSD genotype calling service

### Script layout

Your `scripts/01_call_genotypes.sh` runs ANGSD and writes output under `/results`.

Typical template:

```bash
#!/usr/bin/env bash
set -euo pipefail

POP="${POP:-isophya71}"
THREADS="${THREADS:-4}"
REF="${REF:-/data/isophya_contigs_CAYMY.fasta}"

BAMLIST="/data/${POP}.bamlist"
OUT_DIR="/results/genotypes"
mkdir -p "${OUT_DIR}"

angsd \
  -bam "${BAMLIST}" \
  -ref "${REF}" \
  -out "${OUT_DIR}/${POP}" \
  -GL 1 \
  -doMajorMinor 1 \
  -doMaf 1 \
  -doGlf 2 \
  -doGeno 5 \
  -doBcf 1 \
  -only_proper_pairs 1 \
  -doPost 1 \
  -postCutoff 0.80 \
  -minMapQ 10 \
  -minQ 20 \
  -SNP_pval 1e-12 \
  -minMaf 0.05 \
  -nThreads "${THREADS}"

# Convert BCF to BCF (re-index etc.)
bcftools convert \
  -O b \
  -o "${OUT_DIR}/${POP}.bcf" \
  "${OUT_DIR}/${POP}.bcf"
```

### Run the ANGSD step

```bash
cd ~/bioinf-containers-course
docker compose -f workflow/compose.yaml run --rm angsd-call
```

Check outputs:

```bash
ls results/genotypes
```

---

## PCAngsd + selection + plotting service

### Script layout

`scripts/02_pcangsd_pipeline.sh` performs:

- PCAngsd structure + inbreeding  
- PCAngsd pcadapt selection scan  
- R processing (`pcadapt.R`)  
- PCA + admixture plots  

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

POP="${POP:-isophya71}"
THREADS="${THREADS:-8}"
BEAGLE="${BEAGLE:-/results/genotypes/${POP}.beagle.gz}"

STRUCT_OUT="/results/structure/${POP}"
PLOT_DIR="/results/plots"

mkdir -p "$(dirname "${STRUCT_OUT}")" \
         "${PLOT_DIR}"

RSCRIPT_PCA="/workspace/scripts/plotPCA.R"

echo "[1/4] pcaone: structure"
PCAone \
  --beagle "${BEAGLE}" \
  --pc 10 \
  --threads "${THREADS}" \
  --out "${STRUCT_OUT}"


echo "[4/4] R: PCA plot"
Rscript "${RSCRIPT_PCA}" \
  -i "${STRUCT_OUT}.cov" \
  -c 1-2 \
  -a "/data/${POP}.clst" \
  -o "${PLOT_DIR}/${POP}.pca.pdf"
```

### Run the PCA pipeline

```bash
docker compose -f workflow/compose.yaml run --rm pca-pipeline
```

Check results:

```bash
ls results/structure
ls results/plots
```

---

## Interactive use and overriding defaults

### Start an interactive toolbox shell

```bash
docker compose -f workflow/compose.yaml run --rm toolbox
```

Inside:

```bash
angsd -h
PCAone -h
R --version

ls /data
ls /results
```

### Run a one-off ANGSD command via compose

```bash
docker compose -f workflow/compose.yaml run --rm angsd-call \
  -- angsd -h
```

### Run PCAone manually

```bash
docker compose -f workflow/compose.yaml run --rm toolbox

# inside container:
PCAone \
  --beagle /results/genotypes/isophya71.beagle.gz \
  --pc 10 \
  --threads 8 \
  --out /results/strucure/isophya71_demo
```

### Plotting only

#### PCA plot

```bash
docker compose -f workflow/compose.yaml run --rm toolbox

# inside:
Rscript /workspace/scripts/plotPCA.R \
  -i /results/structure/isophya71.cov \
  -c 1-2 \
  -a /data/isophya71.clst \
  -o /results/plots/isophya71.pca.pdf
```
---

## Summary

After Session 2 you can:

- Use `docker compose` to launch a reproducible interactive toolbox.  
- Run ANGSD and PCA workflows using predefined services.  
- Override service defaults and run arbitrary commands.  
- Generate PCA  using R script.  

---

