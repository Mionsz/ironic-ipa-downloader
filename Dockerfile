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

ARG http_proxy
ARG https_proxy
ARG no_proxy

ENV http_proxy="${http_proxy}"   \
    https_proxy="${https_proxy}" \
    no_proxy="${no_proxy}"
ENV IRONIC_UID=997 \
    IRONIC_GID=994

ADD http://certificates.intel.com/repository/certificates/IntelSHA2RootChain-Base64.zip /opt/intel/certs/intel-sha2-root-chain.zip
ADD http://certificates.intel.com/repository/certificates/Intel%20Root%20Certificate%20Chain%20Base64.zip /opt/intel/certs/intel-root-ca-chain.zip
ADD http://certificates.intel.com/repository/certificates/PublicSHA2RootChain-Base64-crosssigned.zip /opt/intel/certs/public-sha2-root-crsigned.zip

SHELL ["/bin/bash", "-ex", "-o", "pipefail", "-c"]
RUN dnf upgrade -y && \
    dnf install -y \
        sudo \
        passwd \
        tar \
        unzip \
        ca-certificates && \
    dnf clean all && \
    mkdir -m 2775 -p /config /assets /shared && \
    unzip /opt/intel/certs/intel-root-ca-chain.zip -d /usr/local/share/ca-certificates && \
    unzip /opt/intel/certs/intel-sha2-root-chain.zip -d /usr/local/share/ca-certificates && \
    unzip /opt/intel/certs/public-sha2-root-crsigned.zip -d /usr/local/share/ca-certificates && \
    rm -rf /opt/intel/certs /var/cache/{yum,dnf}/* && \
    update-ca-trust && \
    { getent group ironic > /dev/null || groupadd -r ironic -g "${IRONIC_GID}"; } && \
    { getent passwd ironic > /dev/null || useradd -r -g ironic -u "${IRONIC_UID}" -s /bin/bash ironic; } && \
    passwd -d ironic && \
    usermod -aG wheel ironic && \
    echo "ironic ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R root:${IRONIC_GID} /config /assets /shared

COPY ./get-resource.sh /usr/local/bin/get-resource.sh

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["usr/local/bin/get-resource.sh"]
