# envoy-build-tools

**This repository is archived.**

It built the `envoyproxy/envoy-build-ubuntu` images used by Envoy CI up to release 1.36.

Envoy 1.37 and later use the `envoyproxy/envoy-build` images, which are built from
[envoyproxy/toolshed](https://github.com/envoyproxy/toolshed) (`docker/build/linux/debian`),
with Envoy's own pins in [`.github/config.yml`](https://github.com/envoyproxy/envoy/blob/main/.github/config.yml).

Existing `envoy-build-ubuntu` tags remain on Docker Hub for older release branches, but no new
tags will be published.
