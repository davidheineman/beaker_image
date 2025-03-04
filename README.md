[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml)

Personal container for Beaker interactive sessions.

### Setup

1. Fork this repo
2. Update references for `davidh` to your workspace/desired image name
3. Set `BEAKER_TOKEN` secret in https://github.com/[user]/[repo]/settings/secrets/actions to your [Beaker User Token](https://beaker.allen.ai/user/davidh/settings/token)
4. Install [aliases](./deps/aliases.sh) to terminal path
```sh
ALIASES_PATH=$(cd ./deps && pwd)/aliases.sh
chmod +x $ALIASES_PATH # make it executable
grep -qxF "source $ALIASES_PATH" ~/.zshrc || echo "\n# Initialize beaker aliases\nsource $ALIASES_PATH" >> ~/.zshrc # add to terminal init
```
4. Add secrets to your beaker workspace:
```sh
bsecrets ai2/davidh

# Sanity check: 
# beaker secret read OPENAI_API_KEY
```
5. To use git on the remote, add your pubkey `~/.ssh/id_rsa.pub` to your GitHub account: https://github.com/settings/keys (and update the email in .gitconfig)
```sh
[user]
    name = [YOUR GIT NAME]
    email = [YOUR GIT EMAIL]

[safe]
    directory = [YOUR WEKA DIR]
```
6. Test out some of the [aliases](./deps/aliases.sh)
```sh
bl # use interactive session launcher
bd # show current session
bdall # show all jobs
bstop # stop current session
blist # list current sessions
bport # change port for "ai2" host
ai2code . # launch remote code
ai2cursor . # launch remote cursor
ai2cleanup # run ai2 cleaning utils
blogs # get logs for job
bstream # stream logs for job
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

### Debugging
1. If the port failes to auto-update, add this to your `~/.ssh/config` (the XXXXX will be string replaced by `update_port.sh`):
```sh
Host ai2
    User root
    Hostname XXXXX
    IdentityFile ~/.ssh/id_rsa
    Port XXXXX
```