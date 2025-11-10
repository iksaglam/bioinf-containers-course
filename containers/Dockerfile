# syntax=docker/dockerfile:1

# Preinstalls micromamba a fast, minimal Conda implementation
FROM mambaorg/micromamba:1.5.10

# Copy your conda environment specification into the build context inside the image
COPY containers/environment.yml /tmp/environment.yml

# install the packages specified in environment.yml & clean cache
RUN micromamba install -y -n base -f /tmp/environment.yml && \
    micromamba clean -a -y

# ensure login shells (bash -l / bash -lc) have /opt/conda/bin on PATH
USER root
RUN printf 'export PATH=/opt/conda/bin:$PATH\n' > /etc/profile.d/00-conda-path.sh
USER mambauser

# Set the default directory inside the container where commands run.
WORKDIR /workspace

#set up micromamba basics
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]

# Default command
CMD ["bash"]
