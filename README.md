[![Build davidh Image](https://github.com/davidheineman/beaker_image/actions/workflows/build-image.yml/badge.svg)](https://github.com/davidheineman/beaker_image/actions/workflows/build-image.yml)

This repo auto-builds the image `beaker://davidh/davidh-interactive`. Pairs well with [cuvette](https://github.com/davidheineman/cuvette).

### quick start

```sh
pip install cuvette
```

```sh
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
