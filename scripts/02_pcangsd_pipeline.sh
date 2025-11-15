#!/usr/bin/env bash
set -euo pipefail

for f in "$BEAGLE" "/data/$CLST" "/data/$INFO" "$RSCRIPT"; do
  [[ -s "$f" ]] || { echo "ERROR: missing required file: $f" >&2; exit 1; }
done

# required inputs via env
POP="${POP:?set POP}"
THREADS="${THREADS:-8}"


# fixed locations inside the container (compose mounts)
BEAGLE="/results/results_genotypes/${POP}.beagle.gz"
STRUCT_OUT="/results/structure/${POP}"
SEL_OUT="/results/selection/${POP}"
INFO="/data/${POP}.info"
CLST="/data/${POP}.clst"
PLOT_PCA_R="/scripts/plotPCA.R"
PLOT_ADMIX_R="/scripts/plotAdmix.R"
CONVERT_ZSCORES="/scripts/pcadapt.R"

mkdir -p /results/structure /results/selection

echo "[1/2] pcangsd: structure + inbreeding + plotting"
pcangsd \
  --beagle "${BEAGLE}" \
  --admix \
  --inbreed_samples \
  --inbreed_sites \
  --threads "${THREADS}" \
  --out "${STRUCT_OUT}"

Rscript "${PLOT_PCA_R}" \
  -i "${STRUCT_OUT}.cov" \
  -c "1-2" \
  -a "${CLST}" \
  -o "${STRUCT_OUT}.pca.pdf"

Rscript "${PLOT_ADMIX_R}" \
  "${STRUCT_OUT}.admix.2.Q" \
  "${INFO}"

echo "[2/2] pcangsd: pcadapt selection + R postprocess"
pcangsd \
  -b "${BEAGLE}" \
  --hwe "${STRUCT_OUT}.lrt.sites" \
  --pcadapt \
  --sites_save \
  -o "${SEL_OUT}"

Rscript "${CONVERT_ZSCORES}" \
  "${SEL_OUT}.pcadapt.zscores" \
  "${SEL_OUT}"

echo "done:"
echo "  structure: ${STRUCT_OUT}.*"
echo "  selection: ${SEL_OUT}.pcadapt.*  (+ .test/.pval from R)"

