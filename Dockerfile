# https://github.com/allenai/docker-images/pkgs/container/cuda/versions
# https://hub.docker.com/r/nvidia/cuda/tags
FROM --platform=linux/amd64 nvidia/cuda:12.9.1-cudnn-devel-ubuntu22.04
ENV OS_VER=ubuntu22.04

WORKDIR /root
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="America/Los_Angeles"

### https://github.com/allenai/docker-images/blob/main/cuda/Dockerfile
# Add cuda path
ENV PATH="/usr/local/cuda/bin:$PATH"
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Install NVCC 12.9 (make sure to update ~/.bashrc if you change this)
RUN apt-get update && apt-get install -y cuda-toolkit-12-9 && apt-get clean
ENV PATH="/usr/local/cuda-12.9/bin:$PATH"
ENV LD_LIBRARY_PATH=/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH

# Install CUDA utils
RUN apt-get update && apt-get install -y libcusparselt0-cuda-12 libnvshmem3-cuda-12 && apt-get clean
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libcusparseLt/12:/usr/lib/x86_64-linux-gnu/nvshmem/12:$LD_LIBRARY_PATH

# Disable welcome messages
RUN chmod -x /etc/update-motd.d/* && touch ~/.hushlogin && touch /root/.hushlogin

# Install apt packages
RUN apt-get update && apt-get install -y \
    build-essential cmake \
    cowsay \
    curl \
    figlet \
    git \
    git-lfs \
    htop \
    iproute2 \
    jq \
    libsentencepiece-dev \
    libsqlite3-dev \
    libssl-dev \
    lolcat \
    nano \
    neofetch \
    net-tools \
    ncdu \
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
    weka \
    iputils-ping \
    zstd \
    && apt-get clean

# Install docker utils (incl. dockerx)
RUN apt-get update && apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3.8-3.13 and tools (uv will point to this)
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
        python3.8 python3.8-venv python3.8-dev \
        python3.9 python3.9-venv python3.9-dev \
        python3.10 python3.10-venv python3.10-dev \
        python3.11 python3.11-venv python3.11-dev \
        python3.12 python3.12-venv python3.12-dev \
        python3.13 python3.13-venv python3.13-dev \
        python3-pip && \
    ln -sf /usr/bin/python3.13 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install dust
RUN wget https://github.com/bootandy/dust/releases/download/v1.2.2/dust-v1.2.2-x86_64-unknown-linux-gnu.tar.gz && \
    tar -xzf dust-v1.2.2-x86_64-unknown-linux-gnu.tar.gz && \
    mv dust-v1.2.2-x86_64-unknown-linux-gnu/dust /usr/local/bin/ && \
    rm -rf dust-v1.2.2-x86_64-unknown-linux-gnu/ && \
    rm dust-v1.2.2-x86_64-unknown-linux-gnu.tar.gz && \
    chmod +x /usr/local/bin/dust

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

###########
###########

# Install rust (I think you need the second thing to complete the install)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN . "$HOME/.cargo/env"

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install s5cmd
ARG S5CMD_VERSION=2.3.0
RUN set -eux; \
    cd /tmp; \
    wget -q "https://github.com/peak/s5cmd/releases/download/v${S5CMD_VERSION}/s5cmd_${S5CMD_VERSION}_Linux-64bit.tar.gz"; \
    tar -xzf "s5cmd_${S5CMD_VERSION}_Linux-64bit.tar.gz"; \
    install -m 0755 s5cmd /usr/local/bin/s5cmd; \
    rm -rf /tmp/*

# Install Beaker
RUN apt-get update && apt-get install -y curl sudo && \
    curl -s 'https://beaker.org/api/v3/release/cli?os=linux&arch=amd64' | sudo tar -zxv -C /usr/local/bin ./beaker && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install VSCode Server
# ENV PATH="/root/.vscode-server/bin:/root/.vscode-server/bin/bin:$PATH"
# RUN mkdir -p /root/.vscode-server
# RUN curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable \
#     -o /root/.vscode-server/code-server.tar.gz && \
#     mkdir -p /root/.vscode-server/bin && \
#     tar -xzf /root/.vscode-server/code-server.tar.gz -C /root/.vscode-server/bin --strip-components 1 && \
#     rm /root/.vscode-server/code-server.tar.gz

# Install Cursor Server
ENV PATH="/root/.cursor-server/bin:/root/.cursor-server/bin/bin:$PATH"
RUN mkdir -p /root/.cursor-server
RUN curl -fsSL https://cursor.blob.core.windows.net/remote-releases/0.11.8-769e57fc532d17f247b121cdf4b6c37f1cccb540/vscode-reh-linux-x64.tar.gz \
    -o /root/.cursor-server/cursor-server.tar.gz && \
    mkdir -p /root/.cursor-server/bin && \
    tar -xzf /root/.cursor-server/cursor-server.tar.gz -C /root/.cursor-server/bin --strip-components 1 && \
    rm /root/.cursor-server/cursor-server.tar.gz

COPY src/code_extensions.txt /.code_extensions.txt

# Install VSCode Extensions
# RUN while read -r extension; do \
#     code-server --install-extension "$extension"; \
# done < /.code_extensions.txt

# Install Cursor Extensions
RUN while read -r extension; do \
    cursor-server --install-extension "$extension"; \
done < /.code_extensions.txt

# (Disabled) Install Cursor-only Extensions
# RUN cursor-server \
#     --install-extension AnySphere.cursor-pyright || true

# Uninstall some default extensions
# RUN code-server \
#     --uninstall-extension davidanson.vscode-markdownlint || true
RUN cursor-server \
    --uninstall-extension davidanson.vscode-markdownlint || true

# Manual fix for Python in Cursor
RUN cursor-server \
    --uninstall-extension ms-python.vscode-pylance || true
RUN cursor-server \
    --install-extension AnySphere.cursor-pyright || true

# Attempt to install NPM + Claude Code
# RUN apt-get update && apt-get upgrade -y && \
#     apt-get install -y curl && \
#     curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
#     apt-get install -y nodejs && \
#     npm install -g @anthropic-ai/claude-code && \
#     rm -rf /var/lib/apt/lists/*
# RUN set -eux; \
#     apt-get update; \
#     apt-get install -y --no-install-recommends ca-certificates curl gnupg; \
#     mkdir -p /etc/apt/keyrings; \
#     curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
#       | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
#     echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
#       > /etc/apt/sources.list.d/nodesource.list; \
#     apt-get update; \
#     apt-get install -y --no-install-recommends nodejs; \
#     npm install -g @anthropic-ai/claude-code; \
#     npm cache clean --force; \
#     apt-get purge -y curl gnupg; \
#     rm -rf /var/lib/apt/lists/*

# Verify installation
# RUN claude --help

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

# # Add custom beaker aliases
# RUN mkdir -p /root/.beaker_tools
# COPY tools /root/.beaker_tools
# RUN chmod +x /root/.beaker_tools/aliases.sh
# RUN chmod +x /root/.beaker_tools/update_port.sh

# Add custom commands (like ChatGPT!)
RUN mkdir -p /root/.bin
COPY src/.bin/ /root/.bin/
RUN chmod +x /root/.bin/*

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# ENTRYPOINT ["/usr/sbin/sshd", "-D"]
