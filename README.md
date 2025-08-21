[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/build-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/build-image.yml)

This repo auto-builds the image `beaker://davidh/davidh-interactive`. Pairs well with [cuvette](https://github.com/davidheineman/cuvette).

### quick start

```sh
# install cuvette
pip install cuvette

# launch interactive session
bl -c ai2/phobos-cirrascale

# enter the session
ssh ai2
```

<details>
<summary>manual launch</summary>

```sh
beaker session create \
    --name quick-start \
    --cluster ai2/phobos-cirrascale \
    --image beaker://davidh/davidh-interactive \
    --workspace ai2/davidh \
    --priority normal \
    --budget ai2/oe-base \
    --bare --detach --port 8080 \
    --workdir /oe-eval-default/davidh \
    --mount src=weka,ref=oe-eval-default,dst=/oe-eval-default \
    --mount src=weka,ref=oe-training-default,dst=/oe-training-default \
    --mount src=weka,ref=oe-data-default,dst=/oe-data-default \
    --mount src=weka,ref=oe-adapt-default,dst=/oe-adapt-default \
    --mount src=secret,ref=davidh-ssh-key,dst=/root/.ssh/id_rsa \
    -- /entrypoint.sh
```

(of course, `--gpus` for GPUs, e.g. `--cluster ai2/neptune-cirrascale --gpus 1`)

</details>

### notes

- Only users with pubkeys in [`src/.ssh/authorized_keys`](./src/.ssh/authorized_keys) can connect. 
- VS code extensions are pre-installed in [`src/code_extensions.txt`](./src/code_extensions.txt)
- This includes a conda installation, but I prefer uv (`uvinit` to initalize, `uva` to activate)

<details>
<summary>setup tutorial</summary>

### tutorial
1. Fork this repo
2. Update references for `davidh` to your workspace/desired image name
3. Grab your [Beaker user token](https://beaker.allen.ai/user/davidh/settings/token) and set it to the `BEAKER_TOKEN` secret in GitHub Actions: https://github.com/davidheineman/beaker_image/settings/secrets/actions
4. To use git on the remote, add your pubkey (`cat ~/.ssh/id_rsa.pub`) to your GitHub account: https://github.com/settings/keys. Then, update your GitHub email in `src/.gitconfig`:
```sh
[user]
    name = [YOUR GIT NAME]
    email = [YOUR GIT EMAIL]

[safe]
    directory = [YOUR WEKA DIR]
```
5. [Optional] Test your build locally:
```sh
docker build -t davidh-interactive .
docker run -it -p 8080:8080 davidh-interactive
# docker run --rm davidh-interactive
ssh -p 8080 root@127.0.0.1
beaker image delete davidh/davidh-interactive
beaker image create --name davidh-interactive davidh-interactive
```

</details>
