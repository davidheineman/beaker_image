# FROM ubuntu
# FROM ghcr.io/allenai/pytorch:2.4.0-cuda12.1-python3.11
FROM ghcr.io/allenai/cuda:12.1-cudnn8-dev-ubuntu20.04-v1.2.118
ENV CUDA_HOME=/opt/conda
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /root

# Disable welcome messages
RUN chmod -x /etc/update-motd.d/* && touch ~/.hushlogin && touch /root/.hushlogin

# Install apt packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    figlet \
    lolcat \
    cowsay \
    tree \
    nano \
    jq \
    curl \
    wget \
    git \
    software-properties-common \
    pkg-config \
    libsentencepiece-dev \
    docker.io \
    && apt-get clean

# Install Beaker
RUN apt-get update && apt-get install -y curl sudo && \
    curl -s 'https://beaker.org/api/v3/release/cli?os=linux&arch=amd64' | sudo tar -zxv -C /usr/local/bin ./beaker && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install VSCode Server
ENV PATH="/root/.vscode-server/bin:$PATH"
RUN mkdir -p /root/.vscode-server
RUN curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable \
    -o /root/.vscode-server/code-server.tar.gz && \
    mkdir -p /root/.vscode-server/bin && \
    tar -xzf /root/.vscode-server/code-server.tar.gz -C /root/.vscode-server/bin --strip-components 1 && \
    rm /root/.vscode-server/code-server.tar.gz

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