Envoy's CI has a build run called `build_image`. On a commit to main, `docker/push.sh`
checks if the commit has changed the `docker` directory. If there are changes, CI builds a new `envoyproxy/envoy-build`
image. The image is pushed to [dockerhub](https://hub.docker.com/r/envoyproxy/envoy-build/tags/) under `latest` and under the commit sha.

After the PR that changes `docker` has been merged, and the new image gets pushed,
a second PR is needed to update `envoy_build_sha.sh`. In order to pull the new tagged version of
the build image, change ENVOY_BUILD_SHA [here](https://github.com/envoyproxy/envoy/blob/main/envoy_build_sha.sh).
Any PRs that depend on this image change will have to merge main after the change to `envoy_build_sha.sh` has been merged to main.

## CI Optimization for Pull Requests

The CI workflow is optimized to build only the necessary images based on which files changed in a pull request:

- **Debian-only changes**: If only files in `docker/linux/debian/` or `docker/linux/debian_build.sh` are modified, only Debian images are built.
- **Ubuntu-only changes**: If only files in `docker/linux/ubuntu/` are modified, only Ubuntu images are built.
- **Shared file changes**: If shared build scripts (e.g., `docker/push.sh`, `docker/linux/build.sh`, `docker/linux/common_fun.sh`) are modified, both Debian and Ubuntu images are built.
- **Push to main**: All images are always built on commits to the main branch.

This optimization significantly reduces CI time, especially for Ubuntu-specific changes which take considerably longer to build.

## Envoy health warning for the CentOS 7 build container

The current CentOS 7 build container has no CI integration and generally has older versions of the build tools needed to compile Envoy. So this health warning is to encourage any users of this build image to test Envoy throughly to ensure that it satisfies your requirements.

See further details on the latest status of building Envoy on CentOS 7 [here](https://github.com/envoyproxy/envoy-build-tools/blob/main/docker/CENTOS7_BUILD_STATUS.md).
