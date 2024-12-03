# https://github.com/allenai/docker-images/blob/main/cuda/Dockerfile

# FROM ubuntu
FROM ghcr.io/allenai/conda:latest
# FROM ghcr.io/allenai/pytorch:latest
# FROM ghcr.io/allenai/cuda:latest

# FROM ghcr.io/allenai/pytorch:2.4.0-cuda12.1-python3.11
# FROM ghcr.io/allenai/cuda:12.1-cudnn8-dev-ubuntu20.04-v1.2.118
# FROM ghcr.io/allenai/cuda:12.1-dev-ubuntu20.04-v1.2.118
ENV CUDA_HOME=/usr/local/cuda
ENV DEBIAN_FRONTEND=noninteractive

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
    && apt-get clean

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

# Install VSCode Extensions
RUN code-server \
    --install-extension anseki.vscode-color \
    --install-extension blanu.vscode-styled-jsx \
    --install-extension bradlc.vscode-tailwindcss \
    --install-extension csstools.postcss \
    --install-extension davidanson.vscode-markdownlint \
    --install-extension dbaeumer.vscode-eslint \
    --install-extension dsznajder.es7-react-js-snippets \
    --install-extension ecmel.vscode-html-css \
    --install-extension esbenp.prettier-vscode \
    --install-extension github.copilot \
    --install-extension github.copilot-chat \
    --install-extension github.github-vscode-theme \
    --install-extension github.vscode-github-actions \
    --install-extension github.vscode-pull-request-github \
    --install-extension mechatroner.rainbow-csv \
    --install-extension mhutchie.git-graph \
    --install-extension miguelsolorio.fluent-icons \
    --install-extension mikestead.dotenv \
    --install-extension ms-azuretools.vscode-docker \
    --install-extension ms-dotnettools.csharp \
    --install-extension ms-dotnettools.vscode-dotnet-runtime \
    --install-extension ms-python.autopep8 \
    --install-extension ms-python.black-formatter \
    --install-extension ms-python.debugpy \
    --install-extension ms-python.flake8 \
    --install-extension ms-python.isort \
    --install-extension ms-python.python \
    --install-extension ms-python.vscode-pylance \
    --install-extension ms-toolsai.jupyter \
    --install-extension ms-toolsai.jupyter-keymap \
    --install-extension ms-toolsai.jupyter-renderers \
    --install-extension ms-toolsai.vscode-jupyter-cell-tags \
    --install-extension ms-toolsai.vscode-jupyter-slideshow \
    --install-extension ms-vscode-remote.remote-containers \
    --install-extension ms-vscode-remote.remote-ssh \
    --install-extension ms-vscode-remote.remote-ssh-edit \
    --install-extension ms-vscode.cmake-tools \
    --install-extension ms-vscode.cpptools \
    --install-extension ms-vscode.cpptools-extension-pack \
    --install-extension ms-vscode.cpptools-themes \
    --install-extension ms-vscode.live-server \
    --install-extension ms-vscode.makefile-tools \
    --install-extension ms-vscode.remote-explorer \
    --install-extension tamasfe.even-better-toml \
    --install-extension tomoki1207.pdf \
    --install-extension twxs.cmake \
    --install-extension vue.volar \
    --install-extension wekex.jsonlint

# Expose OpenSSH/VS Code and Jupyter ports
EXPOSE 8080 8888

# Configure OpenSSH (allow external connections, port 8080)
RUN mkdir -p /run/sshd && chmod 755 /run/sshd && \
    sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/; s/^#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 8080/' /etc/ssh/sshd_config
RUN sed -i '$ a\AcceptEnv *' /etc/ssh/sshd_config
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Add SSH pubkeys
COPY .ssh/authorized_keys /root/.ssh/authorized_keys

# Add .gitconfig
COPY .gitconfig /root/.gitconfig

# Add .bashrc
COPY .bashrc /root/.bashrc
COPY .conda_init /root/.conda_init
RUN chmod 644 /root/.bashrc
RUN chmod 644 /root/.conda_init

# Add custom commands (like ChatGPT!)
RUN mkdir -p /root/bin
COPY bin/ /root/bin/
RUN chmod +x /root/bin/*

# # Install core python dependencies
# COPY requirements_beaker.txt .
# RUN pip install -r requirements_beaker.txt
# RUN python -m nltk.downloader punkt
# RUN pip install "vllm>=0.6.2,<0.6.4" # Custom installation for vllm (0.6.2 actually installs pytorch 2.4.1)
# RUN pip install xformers
# RUN pip install git+https://github.com/allenai/OLMo.git@main # Install latest ai2-olmo from github 
# RUN pip cache purge

# ARG GIT_REF=""
# ENV GIT_REF=${GIT_REF}

# # Install Jupyter Notebook
# RUN pip install notebook
# jupyter notebook --port 8888 --ip 0.0.0.0 --no-browser --allow-root

ENTRYPOINT ["/usr/sbin/sshd", "-D"]