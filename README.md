[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml)

Personal container for Beaker interactive sessions.

### Setup

1. Fork this repo
2. Update references for `davidh` to your workspace/desired image name
3. Set `BEAKER_TOKEN` secret in https://github.com/[user]/[repo]/settings/secrets/actions
4. Add secrets to your beaker workspace:
```sh
cat ~/.ssh/id_rsa | beaker secret write ssh-key
cat ~/.aws/credentials | beaker secret write aws-creds
echo $HF_TOKEN | beaker secret write HF_TOKEN
echo $OPENAI_API_KEY | beaker secret write OPENAI_API_KEY
echo $ANTHROPIC_API_KEY | beaker secret write ANTHROPIC_API_KEY
echo $BEAKER_TOKEN | beaker secret write BEAKER_TOKEN
beaker secret list
# beaker secret read OPENAI_API_KEY
```
5. To use git on the remote, add your pubkey `~/.ssh/id_rsa.pub` to your GitHub account: https://github.com/settings/keys
6. [Optional] Test your build locally:
```sh
docker build -f Dockerfile_beaker -t davidh-interactive .
# docker run -it -p 8080:8080 davidh-interactive
docker run --rm davidh-interactive
ssh -p 8080 root@127.0.0.1
beaker image delete davidh/davidh-interactive
beaker image create --name davidh-interactive davidh-interactive
```


### TODO
[X] Install this .bashrc (instead of using remote bashrc)
[X] Install authorized_keys (as ssh pubkeys) in docker
[X] Hook up secrets in env: HF_TOKEN, OPENAI_API_KEY
[X] Hook up secrets for applications: Git, Beaker user_token
[X] Install bin/ files
[ ] Install vscode server locally (with extensions)?

- Install the cuda toolkit
```sh
sudo apt-get -y install cuda-toolkit-12-0
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
echo 'export PATH=/usr/local/cuda-12.0/bin${PATH: ~/.bashrc}' >> ~/.bashrc
```

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