Envoy's CI has a build run called `build_image`. On a commit to main, `docker/push.sh`
checks if the commit has changed the `docker` directory. If there are changes, CI builds a new `envoyproxy/envoy-build-ubuntu`
image. The image is pushed to [dockerhub](https://hub.docker.com/r/envoyproxy/envoy-build-ubuntu/tags/) under `latest` and under the commit sha.

After the PR that changes `docker` has been merged, and the new image gets pushed,
a second PR is needed to update `envoy_build_sha.sh`. In order to pull the new tagged version of
the build image, change ENVOY_BUILD_SHA [here](https://github.com/envoyproxy/envoy/blob/main/envoy_build_sha.sh).
Any PRs that depend on this image change will have to merge main after the change to `envoy_build_sha.sh` has been merged to main.

Debian images are now published from [`envoyproxy/toolshed`](https://github.com/envoyproxy/toolshed).
This repository will be retired once all Envoy branches relying on the Ubuntu images reach EOL.
