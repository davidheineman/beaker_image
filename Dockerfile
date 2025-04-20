# https://github.com/allenai/docker-images/blob/main/cuda/Dockerfile

# FROM ubuntu
# FROM ghcr.io/allenai/conda:latest
# FROM ghcr.io/allenai/pytorch:latest

# FROM ghcr.io/allenai/pytorch:2.4.0-cuda12.1-python3.11
FROM ghcr.io/allenai/cuda:12.1-cudnn8-dev-ubuntu20.04-v1.2.118
# FROM ghcr.io/allenai/cuda:12.1-dev-ubuntu20.04-v1.2.118
ENV DEBIAN_FRONTEND=noninteractive

# Add cuda path
# ENV CUDA_HOME=/usr/local/cuda
ENV PATH="/usr/local/cuda/bin:$PATH"

# Weird fix for NVCC on CUDA 12.1
# https://github.com/pytorch/pytorch/issues/111469
# RUN conda install -c nvidia libnvjitlink -y
# export LD_LIBRARY_PATH="/root/.conda/envs/metaeval/lib/python3.10/site-packages/nvidia/nvjitlink/lib:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="/root/.conda/envs/base/lib/python3.10/site-packages/nvidia/nvjitlink/lib:$LD_LIBRARY_PATH"
ENV LD_LIBRARY_PATH="/root/ai2/miniconda3/envs/ultrafastbert/lib/python3.10/site-packages/nvidia/nvjitlink/lib:$LD_LIBRARY_PATH"

WORKDIR /root

# Disable welcome messages
RUN chmod -x /etc/update-motd.d/* && touch ~/.hushlogin && touch /root/.hushlogin

# Install apt packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    figlet \
    lolcat \
    sl \
    cowsay \
    tree \
    nano \
    jq \
    curl \
    wget \
    git \
    git-lfs \
    software-properties-common \
    pkg-config \
    libsentencepiece-dev \
    docker.io \
    ninja-build \
    smem \
    build-essential cmake \
    protobuf-compiler \
    libssl-dev \
    rename \
    socat \
    redis-server \
    psmisc \
    nvtop \
    && apt-get clean

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
COPY code_extensions.txt /.code_extensions.txt
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
COPY .ssh/authorized_keys /root/.ssh/authorized_keys

# Add .gitconfig
COPY .gitconfig /root/.gitconfig

# Add .bashrc
COPY .bashrc /root/.bashrc
COPY .conda_init /root/.conda_init
RUN chmod 644 /root/.bashrc
RUN chmod 644 /root/.conda_init

# Add custom beaker aliases
RUN mkdir -p /root/.beaker_tools
COPY deps /root/.beaker_tools
RUN chmod +x /root/.beaker_tools/aliases.sh
RUN chmod +x /root/.beaker_tools/update_port.sh

# Add custom commands (like ChatGPT!)
RUN mkdir -p /root/.bin
COPY .bin/ /root/.bin/
RUN chmod +x /root/.bin/*

# Add docker daemon override
COPY etc/docker/daemon.json /etc/docker/daemon.json

ENTRYPOINT ["/usr/sbin/sshd", "-D"]

# attempt to get code command working on remote
# export PATH="/root/.vscode-server/bin/bin/remote-cli:$PATH"
# nohup code-server --accept-server-license-terms > /tmp/code-server.out 2>&1 &
# export VSCODE_IPC_HOOK_CLI="/tmp/ipc-0.sock"
# nc -lU $VSCODE_IPC_HOOK_CLI &