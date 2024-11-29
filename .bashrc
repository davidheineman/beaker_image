# Setup commands
# mkdir -p ~/ai2/miniconda3 && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/ai2/miniconda3/miniconda.sh

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
# export TRANSFORMERS_CACHE="/input/oe-eval-default/davidh/.cache/huggingface/hub"
export HF_DATASETS_CACHE="/input/oe-eval-default/davidh/.cache/huggingface/datasets"
export HUGGINGFACE_HUB_CACHE="/input/oe-eval-default/davidh/.cache/huggingface/hub"
export HF_HOME="/input/oe-eval-default/davidh/.cache/huggingface/hub"

# Change terminal formatting to UTF-8 for Python
export PYTHONIOENCODING=utf8

# Add ChatGPT!
export PATH="/root/bin:$PATH"

# Overwrite home .bashrc with this one
echo "source /input/oe-eval-default/davidh/.bashrc" > ~/.bashrc

# Change conda dir to remote
rm -rf /root/.conda
source /input/oe-eval-default/davidh/.conda_init
ln -s ~/ai2/miniconda3 /root/.conda || true

# Link NFS directory to home
ln -sfn /input/oe-eval-default/davidh ~/ai2 || true
ln -sfn /input/oe-eval-default/davidh/.aws ~/.aws || true
ln -sfn /input/oe-eval-default/davidh/.cache ~/.cache || true

# Verify github
# I wish this could be run with .bashrc, but it causes
gitlogin() {
    cp /input/oe-eval-default/davidh/.ssh_david/id_rsa ~/.ssh/id_rsa
    chmod 600 /root/.ssh/id_rsa
    ssh-keyscan -H github.com >> ~/.ssh/known_hosts
    ssh -T git@github.com
}
alias gitlogin='gitlogin'

# Make directory safe
git config --global --add safe.directory /input/oe-eval-default/davidh

# Welcome command!
if command -v figlet &> /dev/null && command -v lolcat &> /dev/null; then
    figlet "ai2remote" | lolcat
fi
if command -v nvidia-smi &> /dev/null && command -v lolcat &> /dev/null; then
    nvidia-smi --query-gpu=name,utilization.gpu,memory.total,memory.free,memory.used --format=csv,noheader,nounits | \
    awk -F, '{print "" $1 " | id ="$2", mem ="$3 " MB, free ="$4 " MB, used ="$5 " MB"}' | lolcat
fi

condacreate() {
    env_name=$1
    conda create -y -n "$env_name"
    conda install -y -n "$env_name" pip
    conda install -y -n "$env_name" python=3.10
    conda activate "$env_name"
}
alias nv='nvidia-smi'

# beaker config set user_token $BEAKER_TOKEN
# beaker config set default_workspace ai2/davidh

if [ "$PWD" = "$HOME" ]; then
    cd ~/ai2
fi

# experimental: kill current vscode servers (not a great solution but it works)
# rm -rf ~/.vscode-server/cli/servers
alias vscodereset="rm -rf ~/.vscode-server/cli/servers"
