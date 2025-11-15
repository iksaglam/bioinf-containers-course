
cd ~/bioinf-containers-course

docker run --rm \
  -v "$(pwd)/data:/data:ro" \
  -v "$(pwd)/results:/results" \
  biocontainers/fastqc:v0.11.9_cv8 \
  fastqc /data/U_KAV_D04_sorted_flt.bam --outdir /results
