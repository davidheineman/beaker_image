# https://github.com/allenai/docker-images/pkgs/container/cuda/versions

# FROM ubuntu
# FROM ghcr.io/allenai/conda:latest
# FROM ghcr.io/allenai/pytorch:latest

# FROM ghcr.io/allenai/pytorch:2.4.0-cuda12.1-python3.11
# FROM ghcr.io/allenai/cuda:12.1-cudnn8-dev-ubuntu20.04-v1.2.118

# https://hub.docker.com/r/nvidia/cuda/tags
# FROM --platform=linux/amd64 nvidia/cuda:12.8-cudnn8-ubuntu20.04
# ENV OS_VER=ubuntu20.04

# This one works
FROM --platform=linux/amd64 nvidia/cuda:12.8.0-base-ubuntu22.04

# Ships with NVCC and CuDNN! (cudnn-devel breaks the github runner for some reason)
# FROM --platform=linux/amd64 nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04
# FROM --platform=linux/amd64 nvidia/cuda:12.8.0-devel-ubuntu22.04
# ENV OS_VER=ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="America/Los_Angeles"

# Add cuda path
# ENV CUDA_HOME=/usr/local/cuda
ENV PATH="/usr/local/cuda/bin:$PATH"

# Weird fix for NVCC on CUDA 12.1
# https://github.com/pytorch/pytorch/issues/111469
# RUN conda install -c nvidia libnvjitlink -y
# ENV LD_LIBRARY_PATH="/root/ai2/miniconda3/envs/ultrafastbert/lib/python3.10/site-packages/nvidia/nvjitlink/lib:$LD_LIBRARY_PATH"

### https://github.com/allenai/docker-images/blob/main/cuda/Dockerfile
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

WORKDIR /root

# Disable welcome messages
RUN chmod -x /etc/update-motd.d/* && touch ~/.hushlogin && touch /root/.hushlogin

# Install apt packages
RUN apt-get update && apt-get install -y \
    build-essential cmake \
    cowsay \
    curl \
    docker.io \
    figlet \
    git \
    git-lfs \
    htop \
    jq \
    libsentencepiece-dev \
    libsqlite3-dev \
    libssl-dev \
    lolcat \
    nano \
    neofetch \
    ninja-build \
    nvtop \
    openssh-server \
    pkg-config \
    protobuf-compiler \
    psmisc \
    redis-server \
    rename \
    sl \
    smem \
    socat \
    software-properties-common \
    tree \
    wget \
    && apt-get clean


# Install nvcc. Workaround because using a developer container is too big for GitHub
RUN apt-get update && apt-get install -y nvidia-cuda-toolkit && apt-get clean

###########
# https://github.com/allenai/docker-images/blob/main/cuda/Dockerfile
###########

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip

# Install Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
        | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update -y && apt-get install google-cloud-sdk -y

# # Install MLNX OFED user-space drivers
# # See https://docs.nvidia.com/networking/pages/releaseview.action?pageId=15049785#Howto:DeployRDMAacceleratedDockercontaineroverInfiniBandfabric.-Dockerfile
# ENV MOFED_VER=24.01-0.3.3.1
# ENV PLATFORM=x86_64
# RUN wget --quiet https://content.mellanox.com/ofed/MLNX_OFED-${MOFED_VER}/MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz && \
#     tar -xvf MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz && \
#     MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}/mlnxofedinstall --basic --user-space-only --without-fw-update -q && \
#     rm -rf MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM} && \
#     rm MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz

# # Install DOCA OFED user-space drivers
# # See https://docs.nvidia.com/doca/sdk/doca-host+installation+and+upgrade/index.html
# # doca-ofed-userspace ver 2.10.0 depends on mft=4.31.0-149
# ENV MFT_VER 4.31.0-149
# RUN wget https://www.mellanox.com/downloads/MFT/mft-${MFT_VER}-x86_64-deb.tgz && \
#     tar -xzf mft-${MFT_VER}-x86_64-deb.tgz && \
#     mft-${MFT_VER}-x86_64-deb/install.sh --without-kernel && \
#     rm mft-${MFT_VER}-x86_64-deb.tgz

# ENV DOFED_VER 2.10.0
# ENV OS_VER ubuntu2204
# RUN wget https://www.mellanox.com/downloads/DOCA/DOCA_v${DOFED_VER}/host/doca-host_${DOFED_VER}-093000-25.01-${OS_VER}_amd64.deb && \
#     dpkg -i doca-host_${DOFED_VER}-093000-25.01-${OS_VER}_amd64.deb && \
#     apt-get update && apt-get -y install doca-ofed-userspace && \
#     rm doca-host_${DOFED_VER}-093000-25.01-${OS_VER}_amd64.deb

###########
###########

# Install rust (I think you need the second thing to complete the install)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN . "$HOME/.cargo/env"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Beaker
RUN apt-get update && apt-get install -y curl sudo && \
    curl -s 'https://beaker.org/api/v3/release/cli?os=linux&arch=amd64' | sudo tar -zxv -C /usr/local/bin ./beaker && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install VSCode Server
ENV PATH="/root/.vscode-server/bin:/root/.vscode-server/bin/bin:$PATH"
RUN mkdir -p /root/.vscode-server
RUN curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable \
    -o /root/.vscode-server/code-server.tar.gz && \
    mkdir -p /root/.vscode-server/bin && \
    tar -xzf /root/.vscode-server/code-server.tar.gz -C /root/.vscode-server/bin --strip-components 1 && \
    rm /root/.vscode-server/code-server.tar.gz

# Install Cursor Server
ENV PATH="/root/.cursor-server/bin:/root/.cursor-server/bin/bin:$PATH"
RUN mkdir -p /root/.cursor-server
RUN curl -fsSL https://cursor.blob.core.windows.net/remote-releases/0.11.8-769e57fc532d17f247b121cdf4b6c37f1cccb540/vscode-reh-linux-x64.tar.gz \
    -o /root/.cursor-server/cursor-server.tar.gz && \
    mkdir -p /root/.cursor-server/bin && \
    tar -xzf /root/.cursor-server/cursor-server.tar.gz -C /root/.cursor-server/bin --strip-components 1 && \
    rm /root/.cursor-server/cursor-server.tar.gz

# Install VSCode Extensions
COPY src/code_extensions.txt /.code_extensions.txt
RUN while read -r extension; do \
    code-server --install-extension "$extension"; \
done < /.code_extensions.txt

# Install Cursor Extensions
RUN while read -r extension; do \
    cursor-server --install-extension "$extension"; \
done < /.code_extensions.txt

# (Disabled) Install Cursor-only Extensions
# RUN cursor-server \
#     --install-extension detachhead.basedpyright || true

# Uninstall some default extensions
RUN code-server \
    --uninstall-extension davidanson.vscode-markdownlint || true

RUN cursor-server \
    --uninstall-extension davidanson.vscode-markdownlint || true

# Expose OpenSSH/VS Code and Jupyter ports
EXPOSE 8080 8888

# Configure OpenSSH (allow external connections, port 8080)
RUN mkdir -p /run/sshd && chmod 755 /run/sshd && \
    sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/; s/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 8080/' /etc/ssh/sshd_config
RUN sed -i '$ a\AcceptEnv *' /etc/ssh/sshd_config
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Re-update apt list
RUN apt-get update

# Add SSH pubkeys
COPY src/.ssh/authorized_keys /root/.ssh/authorized_keys

# Add .gitconfig
COPY src/.gitconfig /root/.gitconfig

# Add .bashrc
COPY src/.bashrc /root/.bashrc
COPY src/.conda_init /root/.conda_init
RUN chmod 644 /root/.bashrc
RUN chmod 644 /root/.conda_init

# Add custom beaker aliases
RUN mkdir -p /root/.beaker_tools
COPY tools /root/.beaker_tools
RUN chmod +x /root/.beaker_tools/aliases.sh
RUN chmod +x /root/.beaker_tools/update_port.sh

# Add custom commands (like ChatGPT!)
RUN mkdir -p /root/.bin
COPY src/.bin/ /root/.bin/
RUN chmod +x /root/.bin/*

# Add docker daemon override
COPY src/etc/docker/daemon.json /etc/docker/daemon.json

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# ENTRYPOINT ["/usr/sbin/sshd", "-D"]
