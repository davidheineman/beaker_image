# Helpful docker commands
# docker build -t acl-search -f src/scrape/experiment/Dockerfile .
# docker run -it acl-search
# docker run -it -e HF_TOKEN=$HF_TOKEN acl-search 
# docker run -it --gpus '"device=0"' -e HF_TOKEN=$HF_TOKEN acl-search

docker build -t YOUR_IMAGE_NAME . && \
beaker image delete davidh/YOUR_IMAGE_NAME && \
beaker image create --name YOUR_IMAGE_NAME YOUR_IMAGE_NAME && \
beaker experiment create beaker-conf.yml