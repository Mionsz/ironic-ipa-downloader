#!/bin/bash
#CACHEURL=http://172.22.0.1/images

set -eux

# Check and set http(s)_proxy. Required for cURL to use a proxy
export http_proxy="${http_proxy:-${HTTP_PROXY:-}}"
export https_proxy="${https_proxy:-${HTTPS_PROXY:-}}"
export no_proxy="${no_proxy:-${NO_PROXY:-}}"

# configurable variables
SHARED_DIR="${SHARED_DIR:-/shared}"
SHARED_IMAGES_DIR="${SHARED_DIR}/html/images"

curl_with_flags() {
    set +x
    if  [ "${CURL_INSECURE:-}" = true ]; then
        set -- --insecure "$@"
    fi
    curl "$@"
}

CACHEURL="https://af01p-igk.devtools.intel.com/artifactory/sed-vs-pol-automation-open-igk-local/iso-registry/metal3-ironic"
IPA_BASEURI="${IPA_BASEURI:-https://af01p-igk.devtools.intel.com/artifactory/sed-vs-pol-automation-open-igk-local/iso-registry/metal3-ironic}"
IPA_BRANCH="${IPA_BRANCH:-stable-2024.2}"
IPA_FLAVOR="${IPA_FLAVOR:-centos9}"

IPA_FILENAME="${IPA_FILENAME:-ipa-${IPA_FLAVOR}-${IPA_BRANCH}}"
IPA_FILENAME_EXT="${IPA_FILENAME_EXT:-.tar.gz}"
IPA_FFILENAME="${IPA_FILENAME}${IPA_FILENAME_EXT}"
DESTNAME="ironic-python-agent"

mkdir -p "${SHARED_IMAGES_DIR}" "${SHARED_DIR}/tmp"
cd "${SHARED_IMAGES_DIR}"

TMPDIR="$(mktemp -d -p "${SHARED_DIR}"/tmp)"

# If we have a CACHEURL and nothing has yet been downloaded
# get header info from the cache

if [ -n "${CACHEURL:-}" ] && [ ! -e "${IPA_FFILENAME}.headers" ]; then
    curl_with_flags -g --fail -O "${CACHEURL}/${IPA_FFILENAME}.headers" || true
fi

# Download the most recent version of IPA
if [ -r "${DESTNAME}.headers" ] ; then
    ETAG="$(awk '/ETag:/ {print $2}' "${DESTNAME}.headers" | tr -d "\r")"
    cd "${TMPDIR}"
    curl_with_flags -g --dump-header "${IPA_FFILENAME}.headers" \
        -O "${IPA_BASEURI}/${IPA_FFILENAME}" \
        --header "If-None-Match: ${ETAG}" || cp "${SHARED_DIR}/html/images/${IPA_FFILENAME}.headers" .

    # curl didn't download anything because we have the ETag already
    # but we don't have it in the images directory, its in the cache.
    ETAG="$(awk '/ETag:/ {print $2}' "${IPA_FFILENAME}.headers" | tr -d "\"\r")"
    if [ ! -s "${IPA_FFILENAME}" ] && [ ! -e "${SHARED_DIR}/html/images/${IPA_FILENAME}-${ETAG}/${IPA_FFILENAME}" ]; then
        mv "${SHARED_DIR}/html/images/${IPA_FFILENAME}.headers" .
        curl_with_flags -g -O "${CACHEURL}/${IPA_FILENAME}-${ETAG}/${IPA_FFILENAME}"
    fi
else
    cd "${TMPDIR}"
    curl_with_flags -g --dump-header "${IPA_FFILENAME}.headers" -O "${IPA_BASEURI}/${IPA_FFILENAME}"
fi

if [ -s "${IPA_FFILENAME}" ]; then
    tar -xaf "${IPA_FFILENAME}"

    ETAG="$(awk '/ETag:/ {print $2}' "${IPA_FFILENAME}.headers" | tr -d "\"\r")"
    cd -
    chmod 755 "${TMPDIR}"
    mv "${TMPDIR}" "${IPA_FILENAME}-${ETAG}"
    ln -sf "${IPA_FILENAME}-${ETAG}/${IPA_FFILENAME}.headers" "${DESTNAME}.headers"
    ln -sf "${IPA_FILENAME}-${ETAG}/${IPA_FILENAME}.initramfs" "${DESTNAME}.initramfs"
    ln -sf "${IPA_FILENAME}-${ETAG}/${IPA_FILENAME}.kernel" "${DESTNAME}.kernel"
else
    rm -rf "${TMPDIR}"
fi
