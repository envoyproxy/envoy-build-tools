# Bazel Toolchains

This directory contains toolchains config generated for Bazel [RBE](https://docs.bazel.build/versions/master/remote-execution.html) and
[Docker sandbox](https://docs.bazel.build/versions/master/remote-execution-sandbox.html).

To regenerate toolchain configs, update the JSON toolchain configs and run following command in an
environment with the latest Bazel and Docker installed:

```
toolchains/regenerate.sh
```

This will generate configs in `toolchains/configs`, check in those files so they can be used in CI.

You can also set docker image information in `BUILD`. This does not require the toolchains to be rebuilt.

Once the toolchains/docker settings are updated, update the `envoy_build_tools` dependency in Envoy.
