[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/push-image.yml)

Personal container for Beaker interactive sessions.

### Setup

1. Clone this repo
2. Update references for `davidh` to your workspace/image name
3. Set `BEAKER_TOKEN` secret in https://github.com/[user]/[repo]/settings/secrets/actions

4. Add secrets to your beaker workspace:
```sh
cat ~/.ssh/id_rsa | beaker secret write ssh-key
cat ~/.aws/credentials | beaker secret write aws-creds
echo $HF_TOKEN | beaker secret write HF_TOKEN
echo $OPENAI_API_KEY | beaker secret write OPENAI_API_KEY
echo $ANTHROPIC_API_KEY | beaker secret write ANTHROPIC_API_KEY
echo $BEAKER_TOKEN | beaker secret write BEAKER_TOKEN
# to use git, add the pubkey for ~/.ssh/id_rsa to: https://github.com/settings/keys
beaker secret list
```

### TODO
- Install this .bashrc (instead of using remote bashrc)
- Install vscode server locally (with extensions)?
- Hook up secrets in env: HF_TOKEN, OPENAI_API_KEY
- Hook up secrets for applications: Git, Beaker user_token
- Install authorized_keys (as ssh pubkeys) in docker
- Install bin/ files

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