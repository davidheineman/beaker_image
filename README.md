[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml)

Personal container for Beaker interactive sessions.

### Setup

1. Fork this repo
2. Update references for `davidh` to your workspace/desired image name
3. Set `BEAKER_TOKEN` secret in https://github.com/[user]/[repo]/settings/secrets/actions
4. Install aliases to terminal path
```sh
ALIASES_PATH=$(cd ./deps && pwd)/aliases.sh
chmod +x $ALIASES_PATH # make it executable
grep -qxF "source $ALIASES_PATH" ~/.zshrc || echo "\n# Initialize beaker aliases\nsource $ALIASES_PATH" >> ~/.zshrc # add to terminal init
```
4. Add secrets to your beaker workspace:
```sh
bsecrets() {
    WORKSPACE_NAME="$1"
    echo "Adding secrets to $WORKSPACE_NAME..."
    cat ~/.ssh/id_rsa | beaker secret write -w $WORKSPACE_NAME ssh-key
    cat ~/.aws/credentials | beaker secret write -w $WORKSPACE_NAME aws-creds
    echo -n $HF_TOKEN | beaker secret write -w $WORKSPACE_NAME HF_TOKEN
    echo -n $HF_TOKEN | beaker secret write -w $WORKSPACE_NAME HF_TOKEN_READ_ONLY # <- for oe-eval
    echo -n $OPENAI_API_KEY | beaker secret write -w $WORKSPACE_NAME OPENAI_API_KEY
    echo -n $ANTHROPIC_API_KEY | beaker secret write -w $WORKSPACE_NAME ANTHROPIC_API_KEY
    echo -n $BEAKER_TOKEN | beaker secret write -w $WORKSPACE_NAME BEAKER_TOKEN
    echo -n $WANDB_API_KEY | beaker secret write -w $WORKSPACE_NAME WANDB_API_KEY
    echo -n $WANDB_API_KEY | beaker secret write -w $WORKSPACE_NAME DAVIDH_WANDB_API_KEY
    echo -n $AWS_SECRET_ACCESS_KEY | beaker secret write -w $WORKSPACE_NAME AWS_SECRET_ACCESS_KEY
    echo -n $AWS_ACCESS_KEY_ID | beaker secret write -w $WORKSPACE_NAME AWS_ACCESS_KEY_ID
    echo -n $AWS_SECRET_ACCESS_KEY | beaker secret write -w $WORKSPACE_NAME DAVIDH_AWS_SECRET_ACCESS_KEY
    echo -n $AWS_ACCESS_KEY_ID | beaker secret write -w $WORKSPACE_NAME DAVIDH_AWS_ACCESS_KEY_ID
    echo -n $GOOGLE_API_KEY | beaker secret write -w $WORKSPACE_NAME GOOGLE_API_KEY
    beaker secret list -w $WORKSPACE_NAME
}
bsecrets ai2/davidh

# Sanity check: 
# beaker secret read OPENAI_API_KEY
```
5. To use git on the remote, add your pubkey `~/.ssh/id_rsa.pub` to your GitHub account: https://github.com/settings/keys (and update the email in .gitconfig)
6. Add aliases to your `~/.zshrc` or `~/.bashrc`:
```sh
# Beaker utilities
alias bd='beaker session describe' # show current session
alias bstop='beaker session stop' # stop current session
alias bl='python ~/[PATH_TO_YOUR]/beaker_image/deps/launcher.py' # use interactive session launcher
blist() { beaker session list --all --author "$(beaker user current)" | grep running; } # list current sessions
bport() { source ~/[PATH_TO_YOUR]/beaker_image/deps/update_ai2_port.sh; } # change port for "ai2" host

# Remote session utilities
ai2code() {
    # Connect to remote vscode
    if [ -z "$1" ]; then
        code --remote ssh-remote+ai2 /root/ai2
    else
        local remote_path="${1:-}"
        code --remote ssh-remote+ai2 /root/ai2/$remote_path
    fi
}
ai2codereset() {
    # Remove the remote vscode server folder
    ai2 'rm -rf ~/.vscode-server/cli/servers'
}
ai2cleanup() {
    # Run standard python linting libraries in AI2 projects
    isort . && black . && ruff check . && mypy .
}
```
7. [Optional] Install conda on remote
```sh
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh 
chmod +x ~/miniconda.sh 
./miniconda.sh # install to ~/ai2/miniconda3
```
8. [Optional] Test your build locally:
```sh
docker build -t davidh-interactive .
docker run -it -p 8080:8080 davidh-interactive
# docker run --rm davidh-interactive
ssh -p 8080 root@127.0.0.1
beaker image delete davidh/davidh-interactive
beaker image create --name davidh-interactive davidh-interactive
```

### TODO
- [ ] Use a lightweight container instead of provided container
- [ ] Fix LD_LIBRARY_PATH
- [ ] Prevent /root/.conda (for new enviornment installs)
- [ ] Ensure pytorch works on a fresh image

How to reference secrets in a normal setup
```sh
# envVars:
# - name: HF_TOKEN
#   secret: HF_TOKEN
# - name: OPENAI_API_KEY
#   secret: OPENAI_API_KEY
# - name: ANTHROPIC_API_KEY
#   secret: ANTHROPIC_API_KEY
# - name: BEAKER_TOKEN
#   secret: BEAKER_TOKEN
# datasets:
# - mountPath: /root/.ssh/id_rsa
#   source:
#     secret: SECRET_NAME
```

### Debugging
1. If the port failes to auto-update, add this to your `~/.ssh/config` (the XXXXX will be string replaced by `update_port.sh`):
```sh
Host ai2
    User root
    Hostname XXXXX
    IdentityFile ~/.ssh/id_rsa
    Port XXXXX
```