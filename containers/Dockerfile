# syntax=docker/dockerfile:1
FROM mambaorg/micromamba:1.5.10

COPY containers/environment.yml /tmp/environment.yml
RUN micromamba install -y -n base -f /tmp/environment.yml \
 && micromamba clean -a -y

# build-time toolchain just to compile pcangsd; keep libgomp1 for OpenMP at runtime
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends g++ make libgomp1 \
 && /opt/conda/bin/python -m pip install --no-cache-dir pcangsd==1.36.4 \
 && /opt/conda/bin/python -c "import importlib.metadata as im; print('pcangsd', im.version('pcangsd'))" \
 && /opt/conda/bin/pcangsd -h >/dev/null \
 && apt-get purge -y g++ make \
 && apt-get autoremove -y --purge \
 && rm -rf /var/lib/apt/lists/*

# make sure login shells see conda
RUN printf 'export PATH=/opt/conda/bin:$PATH\n' > /etc/profile.d/00-conda-path.sh
USER mambauser

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
CMD ["bash"]
