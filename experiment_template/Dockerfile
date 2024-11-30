FROM ghcr.io/allenai/cuda:12.1-cudnn8-dev-ubuntu20.04-v1.2.118

# Set environment variables for CUDA
ENV CUDA_HOME=/opt/conda
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

WORKDIR /app

# Install linux deps
RUN apt-get update && apt-get install -y \
    cowsay \
    && apt-get clean

# Install python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && pip cache purge

# Copy repo
COPY . .

RUN chmod +x ./your_experiment.sh
ENTRYPOINT ["/bin/bash"]
CMD ["./your_experiment.sh"]

# docker build -t your-image -f src/scrape/beaker/Dockerfile .
# docker run -it your-image
# docker run -it -e HF_TOKEN=$HF_TOKEN your-image 
# beaker image delete davidh/your-image
# beaker image create --name your-image your-image
# beaker experiment create src/scrape/beaker/beaker-conf.yml