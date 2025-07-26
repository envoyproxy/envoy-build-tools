# OCI Artifact Collector Action

This GitHub Action collects OCI artifacts from build jobs and creates/pushes multi-architecture manifests to container registries.

The action uses `regctl` which provides reliable handling of OCI artifacts and multi-architecture manifest lists, making it ideal for creating unified multi-arch images from separately built architecture-specific OCI artifacts.

## Features

- Downloads OCI artifacts from GitHub Actions artifacts
- Creates multi-architecture manifests using regctl
- Supports Docker Hub and Google Container Registry
- Dry-run mode for testing in pull requests
- Flexible artifact pattern matching
- Support for additional tags
- Automatic cleanup of temporary architecture-specific tags

## Usage

This action is used in the envoy-build-tools workflow to collect OCI artifacts built separately for each architecture and combine them into multi-arch manifests.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `artifacts-pattern` | Pattern to match artifact names | No | `oci-*` |
| `artifacts-path` | Path to download artifacts to | No | `./oci-images` |
| `manifest-config` | JSON configuration for manifests to create | Yes | - |
| `dry-run` | Run without actually pushing images | No | `false` |
| `dockerhub-username` | Docker Hub username | No | - |
| `dockerhub-password` | Docker Hub password | No | - |
| `gcr-service-account-key` | GCP service account key (base64 encoded) | No | - |

### Manifest Configuration Format

```json
{
  "manifests": [
    {
      "name": "image-name",
      "tag": "tag-name",
      "registry": "docker.io/org",
      "architectures": ["amd64", "arm64"],
      "artifact-pattern": "oci-{arch}/image-{arch}.tar",
      "additional-tags": ["latest"],
      "push": true
    }
  ]
}
```

## Authentication

The action supports authentication to Docker Hub and Google Container Registry:

- **Docker Hub**: Provide `dockerhub-username` and `dockerhub-password`
- **GCR**: Provide `gcr-service-account-key` (base64 encoded)

Credentials are only used if provided and are passed directly to the authentication commands without being stored or logged.

## Implementation Details

The action uses `regctl` (v0.8.3) to:
1. Import OCI archives as images with architecture-specific tags
2. Create multi-architecture manifest lists from the imported images
3. Push manifest lists to configured registries
4. Clean up temporary architecture-specific tags

The artifact pattern supports `{arch}` placeholder which gets replaced with the actual architecture name when looking for files.

### Workflow

1. Each OCI artifact is imported using `regctl image import` with an arch-specific tag (e.g., `myimage:tag-amd64`)
2. A manifest list is created using `regctl manifest put` that combines all architectures
3. Additional tags are created using `regctl image copy`
4. Temporary arch-specific tags are cleaned up after the manifest is created
