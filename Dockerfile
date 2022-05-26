# based on https://hub.docker.com/r/bitnami/kubectl/
# https://github.com/bitnami/bitnami-docker-kubectl/blob/master/1.21/debian-10/Dockerfile
FROM ubuntu:18.04
LABEL maintainer="Carsten Hufe <carsten.hufe@dremio.com>"

ENV HOME="/root" \
    OS_ARCH="amd64" \
    OS_NAME="linux"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y ca-certificates curl gzip jq procps tar wget gnupg2

RUN cd /tmp ; curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
RUN rm -f /tmp/kubectl
RUN apt install -y python3.8

# AWS CLI
RUN apt install -y awscli
# Azure CLI
RUN wget https://aka.ms/downloadazcopy-v10-linux
RUN tar -xvf downloadazcopy-v10-linux
RUN cp ./azcopy_linux_amd64_*/azcopy /usr/bin/
RUN rm -f downloadazcopy-v10-linux
RUN rm -rf ./azcopy_linux_amd64_*

# gsutil for GCS
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update
RUN apt-get install -y google-cloud-sdk

RUN mkdir -p /opt/dremio/bin
RUN mkdir -p /opt/dremio/dremio_queries
RUN mkdir -p /opt/dremio/dremio_queries/scrubbed
ADD docker/gather_queries_docker_k8s.sh /opt/dremio/bin/
ADD scripts/get-error-messages.py /opt/dremio/bin/
ADD scripts/refresh-pds.py        /opt/dremio/bin/
ADD scripts/scrub-queries-json.py /opt/dremio/bin/
RUN chmod 755 /opt/dremio/bin/gather_queries_docker_k8s.sh
#RUN sed -i 's/TLSv1\.2/TLSv1.0/g' /etc/ssl/openssl.cnf
#RUN sed -i 's/DEFAULT@SECLEVEL=2/DEFAULT@SECLEVEL=1/g' /etc/ssl/openssl.cnf

ENV DREMIO_ENDPOINT="http://dremio-client:9047" \
    DREMIO_USERNAME="dremio" \
    DREMIO_PASSWORD="dremio" \
    DREMIO_STORAGE_TYPE="s3" \
    DREMIO_STORAGE_PATH="/" \
    DREMIO_NUM_ARCHIVE_DAYS="30" \
    AWS_ACCESS_KEY_ID=NOTSET \
    AWS_SECRET_ACCESS_KEY=NOTSET \
    AWS_DEFAULT_REGION=us-east-1 \
    AZURE_SAS_URL=NOTSET \
    GCS_SERVICE_PRINCIPAL=NOTSET \
    DREMIO_LOG_DIR="/opt/dremio/data/log"

CMD [ "sh", "-c", "/opt/dremio/bin/gather_queries_docker_k8s.sh" ]
# CMD [ "sh", "-c", "sleep infinity" ]