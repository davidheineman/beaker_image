# Setup commands
# mkdir -p ~/ai2/miniconda3 && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/ai2/miniconda.sh && chmod +x ~/ai2/miniconda.sh && ./miniconda.sh

# CLI color coding
PS1_RESET='\[\e[0m\]'
PS1_BOLD='\[\e[1m\]'
PS1_DIM='\[\e[2m\]'
PS1_UNDERLINE='\[\e[4m\]'
PS1_BLACK_WHITE='\[\e[0;30m\]'
PS1_WHITE_BLACK='\[\e[97m\]'
PS1_CYAN_BLACK='\[\e[36m\]'
PS1_GREEN_BLACK='\[\e[32m\]'
export PS1="${PS1_CYAN_BLACK}${PS1_BOLD}\u${PS1_DIM}@${PS1_BOLD}\h ${PS1_RESET}${PS1_GREEN_BLACK}${PS1_BOLD}\w${PS1_RESET}$ ${PS1_RESET}"
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export force_color_prompt=yes

# Change HF caches
export HF_DATASETS_CACHE="/oe-eval-default/davidh/.cache/huggingface/datasets"
export HUGGINGFACE_HUB_CACHE="/oe-eval-default/davidh/.cache/huggingface/hub"
export HF_HOME="/oe-eval-default/davidh/.cache/huggingface/hub"

# Change terminal formatting to UTF-8 for Python
export PYTHONIOENCODING=utf8

# We install NVCC manually, so we need to link the PATH here
export PATH="/usr/local/cuda-12.9/bin:$PATH"
export LD_LIBRARY_PATH="/usr/local/cuda-12.9/lib64:$LD_LIBRARY_PATH"

# Add ChatGPT!
export PATH="/root/.bin:$PATH"

# # Add Beaker aliases
# source /root/.beaker_tools/aliases.sh

# Change conda dir to remote
rm -rf /root/.conda # <- Will exist on some beaker images
ln -sfn /oe-eval-default/davidh/miniconda3 /root/.conda-remote || true
export CONDA_ENVS_DIRS=/root/.conda-remote/envs
export CONDA_PKGS_DIRS=/root/.conda-remote/pkgs

# Lazy load conda
conda() {
    unset -f conda
    source /root/.conda_init
    conda "$@"
}

# Eager load conda
# source /root/.conda_init

# Change default cache dir
export XDG_CACHE_HOME="/oe-eval-default/davidh/.cache"

# Link NFS directory to home
ln -sfn /oe-eval-default/davidh ~/ai2 || true
ln -sfn /oe-eval-default/davidh/.aws ~/.aws || true
ln -sfn /oe-eval-default/davidh/.gcp ~/.gcp || true
ln -sfn /oe-eval-default/davidh/.kaggle ~/.kaggle || true
ln -sfn /oe-eval-default/davidh/.cache ~/.cache || true

# Some scripts use /weka/oe-training-default. Create symlink for this
mkdir -p /weka
ln -sfn /oe-training-default /weka/oe-training-default
ln -sfn /oe-adapt-default /weka/oe-adapt-default
ln -sfn /oe-eval-default /weka/oe-eval-default
ln -sfn /oe-data-default /weka/oe-data-default

# Verify github
# I wish this could be run with .bashrc, but it causes
gitlogin() {
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
    ssh -T git@github.com
}

# Make directory safe
git config --global --add safe.directory /oe-eval-default/davidh

# Verify gcp
gcplogin() {
    export SERVICE_ACCOUNT=olmo-gcs@ai2-allennlp.iam.gserviceaccount.com
    gcloud auth activate-service-account $SERVICE_ACCOUNT --key-file=/root/.gcp/service-account.json
}

# Verify Docker
dockerlogin() {
    echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
}

alias uvinit='uv venv --python 3.12 && source .venv/bin/activate'
alias uva='source .venv/bin/activate'
alias uvinstall='uv pip install -r requirements.txt'

# disable pip (to encourage uv usage)
pip_path=$(which pip)
[ -n "$pip_path" ] && sudo mv "$pip_path" "$(dirname "$pip_path")/pipforce"
alias pip="uv pip" # Error: pip is disabled (use uv/uvinit/uva instead, its better). if you need to use it, call pipforce

# Welcome command!
if [[ $- == *i* ]]; then
    if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
        figlet "ai2remote" | lolcat
    fi
    if command -v nvidia-smi &> /dev/null && command -v lolcat &> /dev/null; then
        nvidia-smi --query-gpu=name,utilization.gpu,memory.total,memory.free,memory.used --format=csv,noheader,nounits | \
        awk -F, '{print "" $1 " | id ="$2", mem ="$3 " MB, free ="$4 " MB, used ="$5 " MB"}' | lolcat
    fi
fi

condacreate() {
    env_name=$1
    conda create -y -n "$env_name"
    conda install -y -n "$env_name" pip
    conda install -y -n "$env_name" python=3.10
    conda activate "$env_name"
}
alias nv='nvidia-smi | lolcat'
alias nvwatch="watch -n 1 nvidia-smi"

# beaker config set user_token $BEAKER_TOKEN
# beaker config set default_workspace ai2/davidh

if [ "$PWD" = "$HOME" ]; then
    cd ~/ai2
fi

# kill current vscode servers (not a great solution but it works)
alias vscodereset="rm -rf ~/.vscode-server/cli/servers"

# S3 variables for olmo-core
export WEKA_PROFILE=oe-training-s3
export S3_PROFILE=S3
export WEKA_ENDPOINT_URL=https://weka-aus.beaker.org:9000
export GOOGLE_CLOUD_PROJECT=ai2-allennlp

if [ ! -f /root/.ssh/environment ]; then
    # SLOW: Copy env variables from docker process (such as HF_TOKEN)
    # process_info=$(ps -e -o user,pid,cmd | grep "/usr/sbin/sshd -D" | grep "^root")
    # pids=$(echo "$process_info" | awk '{print $2}')
    # for pid in $pids; do
    #     env_vars=$(cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n')
    #     for env_var in $env_vars; do
    #         key=$(echo "$env_var" | cut -d= -f1)
    #         value=$(echo "$env_var" | cut -d= -f2-)
    #         if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    #             if [ -z "${!key}" ]; then
    #                 export "$env_var"
    #             fi
    #         fi
    #     done
    # done

    # Fast version of env copying (assuming OpenSSH is process 1)
    # if [ -r /proc/1/environ ]; then
    #     env_vars=$(cat /proc/1/environ 2>/dev/null | tr "\0" "\n")
    #     for env_var in $env_vars; do
    #         key=$(echo "$env_var" | cut -d= -f1)
    #         value=$(echo "$env_var" | cut -d= -f2-)
    #         if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    #             if [ -z "${!key}" ]; then
    #                 export "$env_var"
    #             fi
    #         fi
    #     done
    # fi
    # printenv > /root/.ssh/environment

    # Clear out env file
    > /root/.ssh/environment
    > /root/.ssh/environment_multiline

    # Paste beaker args
    if [ -r /proc/1/environ ]; then
        while IFS= read -r -d '' env_var; do
            key="${env_var%%=*}"
            value="${env_var#*=}"
            export $key="$value"
            if [[ "$value" != *$'\n'* ]]; then
                echo "$key=$value" >> /root/.ssh/environment
            else
                echo "$key=\"$value\"" >> /root/.ssh/environment_multiline
            fi
        done < /proc/1/environ
    fi
fi

if [ -f /root/.ssh/environment_multiline ]; then
    set -a
    . /root/.ssh/environment_multiline
    set +a
fi