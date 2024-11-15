# syntax=docker/dockerfile:1

ARG BASE_IMAGE=quay.io/centos/centos:stream9@sha256:e5fdd83894773a25f22fbdf0b5253c63677d0cbaf8d3a8366b165a3ef5902964

FROM $BASE_IMAGE

LABEL org.opencontainers.image.url="https://github.com/metal3-io/ironic-ipa-downloader"
LABEL org.opencontainers.image.title="Metal3 Ironic-IPA-Downloader"
LABEL org.opencontainers.image.description="Container image to run OpenStack Ironic as part of Metal³"
LABEL org.opencontainers.image.documentation="https://github.com/metal3-io/ironic-ipa-downloader"
LABEL org.opencontainers.image.version="v26.0.1"
LABEL org.opencontainers.image.vendor="Metal3-io"
LABEL org.opencontainers.image.licenses="Apache License 2.0"

ADD http://certificates.intel.com/repository/certificates/IntelSHA2RootChain-Base64.zip /opt/intel/certs/intel-sha2-root-chain.zip
ADD http://certificates.intel.com/repository/certificates/Intel%20Root%20Certificate%20Chain%20Base64.zip /opt/intel/certs/intel-root-ca-chain.zip
ADD http://certificates.intel.com/repository/certificates/PublicSHA2RootChain-Base64-crosssigned.zip /opt/intel/certs/public-sha2-root-crsigned.zip

RUN dnf upgrade -y && \
    dnf install -y \
        tar \
        unzip \
        ca-certificates && \
    dnf clean all && \
    rm -rf /var/cache/{yum,dnf}/* && \
    unzip /opt/intel/certs/intel-root-ca-chain.zip -d /usr/local/share/ca-certificates && \
    unzip /opt/intel/certs/intel-sha2-root-chain.zip -d /usr/local/share/ca-certificates && \
    unzip /opt/intel/certs/public-sha2-root-crsigned.zip -d /usr/local/share/ca-certificates && \
    rm -rf /opt/intel/certs && \
    update-ca-certificates

COPY ./get-resource.sh /usr/local/bin/get-resource.sh

ENTRYPOINT ["usr/local/bin/get-resource.sh"]
