#!/bin/bash

# Do not ever set -x here, it is a security hazard as it will place the credentials below in the
# CI logs.
set -e

# Enable docker experimental
export DOCKER_CLI_EXPERIMENTAL=enabled

CONTAINER_SHA=$(git log -1 --pretty=format:"%H" .)

echo "Building envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}"
if curl -sSLf "https://index.docker.io/v1/repositories/envoyproxy/envoy-build-${OS_DISTRO}/tags/${CONTAINER_SHA}" > /dev/null; then
  echo "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA} exists."
  exit 0
fi

CONTAINER_TAG=${CONTAINER_SHA} "./docker_build_${OS_FAMILY}.sh"

if [[ "${SOURCE_BRANCH}" == "refs/heads/master" ]]; then
    docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD"

    MANIFESTS=""
    for arch in ${IMAGE_ARCH}
    do
        docker push "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}"
        MANIFESTS="${MANIFESTS} envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}"
    done

    docker manifest create --amend "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}" $MANIFESTS

    for arch in ${IMAGE_ARCH}
    do
        docker manifest annotate "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}" \
            "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-${arch}" \
            --os ${OS_FAMILY} --arch ${arch}
    done

    docker manifest push "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}"

    if [[ "${PUSH_GCR_IMAGE}" == "true" ]]; then
        echo ${GCP_SERVICE_ACCOUNT_KEY} | base64 --decode | gcloud auth activate-service-account --key-file=-
        gcloud auth configure-docker --quiet

        echo "Updating gcr.io/envoy-ci/${GCR_IMAGE_NAME} image"
        docker tag "envoyproxy/envoy-build-${OS_DISTRO}:${CONTAINER_SHA}-amd64" "gcr.io/envoy-ci/${GCR_IMAGE_NAME}:${CONTAINER_SHA}"
        docker push "gcr.io/envoy-ci/${GCR_IMAGE_NAME}:${CONTAINER_SHA}"
    fi

else
    echo 'Ignoring PR branch for docker push.'
fi
