# Bioinformatics Containerization Tutorial  
## Session 5: Nextflow Mini-Pipeline

## Table of Contents
- [Overview](#overview)
- [Design of the mini-pipeline](#design-of-the-mini-pipeline)
- [main.nf: minimal pipeline](#mainnf-minimal-pipeline)
- [nextflow.config: local Docker use](#nextflowconfig-local-docker-use)
- [Running Nextflow locally with Docker](#running-nextflow-locally-with-docker)
- [Running Nextflow on KUACC with Apptainer + SLURM](#running-nextflow-on-kuacc-with-apptainer--slurm)
- [Summary](#summary)

---

## Overview

In this session you will:

- Wrap the ANGSD and PCAngsd pipelines into a minimal Nextflow workflow.
- Use your existing Docker image locally.
- See how to lift the same pipeline to KUACC with Apptainer + SLURM.

We assume you already have:

- `isophya-course:0.1` built.
- `scripts/01_call_genotypes.sh`, `scripts/02_pcangsd_pipeline.sh`.
- A working `compose.yaml` from Session 2.

---

## Design of the mini-pipeline

We build two processes:

- **call_genotypes**: runs `01_call_genotypes.sh`.
- **pcangsd_pipeline**: runs `02_pcangsd_pipeline.sh`.

The workflow is:

1. `call_genotypes` runs first.
2. `pcangsd_pipeline` depends on its completion.

We do not pass many files explicitly; instead we rely on the same directory layout and environment variables as in Docker/Apptainer.

---

## main.nf: minimal pipeline

Create `workflow/main.nf`:

```groovy
#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

params.pop      = params.pop ?: 'isophya71'
params.threads  = params.threads ?: 8
params.workdir  = params.workdir ?: '/workspace'
params.scriptdir = "${params.workdir}/scripts"

process call_genotypes {

    tag { params.pop }

    publishDir '/results', mode: 'copy', overwrite: true

    input:
    val pop from Channel.value(params.pop)

    output:
    val pop into geno_done

    script:
    """
    cd ${params.workdir}
    export POP=${pop}
    export THREADS=${params.threads}

    ./scripts/01_call_genotypes.sh

    echo "${pop}" > /results/.geno_done_${pop}
    """
}

process pcangsd_pipeline {

    tag { params.pop }

    publishDir '/results', mode: 'copy', overwrite: true

    input:
    val pop from geno_done

    script:
    """
    cd ${params.workdir}
    export POP=${pop}
    export THREADS=${params.threads}

    ./scripts/02_pcangsd_pipeline.sh

    echo "${pop}" > /results/.pcangsd_done_${pop}
    """
}

workflow {

    call_genotypes()
    pcangsd_pipeline()
}
```

---

## nextflow.config: local Docker use

Create `workflow/nextflow.config`:

```groovy
profiles {

  docker_local {

    process.executor = 'local'
    process.container = 'isophya-course:0.1'
    docker.enabled = true

    workDir = 'work'

    process {
      withName: 'call_genotypes' {
        cpus = 8
        memory = '32 GB'
      }
      withName: 'pcangsd_pipeline' {
        cpus = 8
        memory = '32 GB'
      }
    }

    docker.runOptions = """
      -v ${baseDir}/../data:/data:ro
      -v ${baseDir}/../scripts:/workspace/scripts:ro
      -v ${baseDir}/../results:/results:rw
      -w /workspace
    """
  }

  kuacc_apptainer {

    process.executor = 'slurm'
    workDir = '/scratch/$USER/nextflow-work'

    process.container = '/home/iksaglam/oulu/isophya-course_0.1.sif'

    singularity.enabled = true
    singularity.autoMounts = false

    process {
      withName: 'call_genotypes' {
        cpus = 8
        memory = '32 GB'
        time = '8h'
        clusterOptions = '--partition=short'
      }
      withName: 'pcangsd_pipeline' {
        cpus = 8
        memory = '32 GB'
        time = '8h'
        clusterOptions = '--partition=short'
      }
    }

    singularity.runOptions = """
      --bind /home/iksaglam/oulu/data:/data:ro
      --bind /userfiles/utopalan22/isophya/new_bams:/data/bams:ro
      --bind /userfiles/utopalan22/isophya/references:/data/ref:ro
      --bind /home/iksaglam/oulu/results:/results
      --bind /home/iksaglam/oulu/scripts:/workspace/scripts:ro
      --pwd /workspace
    """
  }

}
```

---

## Running Nextflow locally with Docker

From `bioinf-containers-course/workflow`:

```bash
cd ~/bioinf-containers-course/workflow

nextflow run main.nf -profile docker_local \
  --pop isophya71 \
  --threads 8
```

Nextflow will:

- Pull `isophya-course:0.1` if needed.
- Run `call_genotypes` inside the container.
- Then run `pcangsd_pipeline`.

Check results:

```bash
ls ../results
```

---

## Running Nextflow on KUACC with Apptainer + SLURM

Once KUACC’s Apptainer and SLURM integration is working, you can run:

```bash
cd ~/oulu/workflow

nextflow run main.nf -profile kuacc_apptainer \
  --pop isophya71 \
  --threads 8
```

Nextflow will:

- Submit `call_genotypes` as a SLURM job using the `isophya-course_0.1.sif`.
- After completion, submit `pcangsd_pipeline`.
- Use the same bindings as in Session 4.

---

## Summary

After Session 5 you can:

- Express your ANGSD and PCAngsd workflows as a Nextflow pipeline.
- Run the entire analysis locally with Docker from one command.
- Reuse the same container and bindings on KUACC with Apptainer + SLURM.

