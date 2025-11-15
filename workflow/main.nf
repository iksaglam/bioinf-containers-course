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
