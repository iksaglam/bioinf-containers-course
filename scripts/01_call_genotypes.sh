#!/usr/bin/env bash
# fail loudly on errors and undefined vars
set -euo pipefail

# ---------- configurable inputs ----------
# POP is the prefix of your bamlist, e.g. POP=isophya71 → /data/isophya71.bamlist
POP="${POP:-isophya71}"
REF="${REF:-/data/isophya_contigs_CAYMY.fasta}"
THREADS="${THREADS:-8}"

# input files (read-only)
BAMLIST="/data/${POP}.bamlist"
SITES="/data/6cov_nonparalog.sites"
REGIONS="/data/6cov_nonparalog.chr"

# outputs (writeable)
OUTDIR="/results/results_genotypes"
OUTPREFIX="${OUTDIR}/${POP}"

mkdir -p "${OUTDIR}"

# infer sample counts from bamlist
nInd="$(wc -l < "${BAMLIST}")"
mInd="$(( nInd / 2 ))"    # half the samples

echo "[info] POP=${POP} nInd=${nInd} mInd=${mInd} threads=${THREADS}"
echo "[info] bamlist=${BAMLIST}"
echo "[info] ref=${REF}"
echo "[info] sites=${SITES}"
echo "[info] regions=${REGIONS}"
echo "[info] outprefix=${OUTPREFIX}"

# --------- ANGSD: genotype likelihoods + BCF ----------
# -doBcf 1 → writes ${OUTPREFIX}.bcf
angsd \
  -bam "${BAMLIST}" \
  -ref "${REF}" \
  -out "${OUTPREFIX}" \
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
  -minInd "${mInd}" \
  -SNP_pval 1e-12 \
  -minMaf 0.05 \
  -sites "${SITES}" \
  -rf "${REGIONS}" \
  -nThreads "${THREADS}"

# --------- Convert BCF → VCF.gz (and index) ----------
# bcftools view is the standard way to convert .bcf → .vcf.gz
bcftools view -O z -o "${OUTPREFIX}.vcf.gz" "${OUTPREFIX}.bcf"
tabix -p vcf "${OUTPREFIX}.vcf.gz"

echo "[done] wrote:"
ls -lh "${OUTPREFIX}."*

