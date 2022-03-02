Envoy's CI has a build run called `build_image`. On a commit to main, `ci/build_container/docker_push.sh`
checks if the commit has changed the `ci/build_container` directory. If there are changes, CI builds a new `envoyproxy/envoy-build`
image. The image is pushed to [dockerhub](https://hub.docker.com/r/envoyproxy/envoy-build/tags/) under `latest` and under the commit sha.

After the PR that changes `ci/build_container` has been merged, and the new image gets pushed,
a second PR is needed to update `ci/envoy_build_sha.sh`. In order to pull the new tagged version of
the build image, change ENVOY_BUILD_SHA [here](https://github.com/envoyproxy/envoy/blob/main/ci/envoy_build_sha.sh).
Any PRs that depend on this image change will have to merge main after the change to `ci/envoy_build_sha.sh` has been merged to main.

## Envoy health warning for the CentOS 7 build container

The current CentOS 7 build container has no CI integration and generally has older versions of the build tools needed to compile Envoy. So this health warning is to encourage any users of this build image to test Envoy throughly to ensure that it satisfies your requirements.

See further details on the latest status of building Envoy on CentOS 7 [here](https://github.com/envoyproxy/envoy-build-tools/blob/main/build_container/CENTOS7_BUILD_STATUS.md).