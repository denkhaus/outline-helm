# Outline Helm Chart

This directory contains the Helm chart for deploying [Outline](https://www.getoutline.com/), a modern, open-source knowledge base.

## Chart Details

The chart is designed to be flexible and configurable for various deployment scenarios, from simple setups to more complex, production-ready environments.

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) (version 3.x)
- [Kubernetes](https://kubernetes.io/docs/setup/) cluster (or a local equivalent like [Minikube](https://minikube.sigs.k8s.io/docs/start/) or [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/))
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) configured to connect to your cluster

## Getting Started

To get started with this chart, you can add the repository and install it with the following commands:

```bash
helm repo add outline-helm https://denkhaus.github.io/outline-helm
helm repo update
helm install my-outline outline-helm/outline
```

For more detailed installation instructions and configuration options, see the [examples](examples/) and the `values.yaml` file.

## Development

This section provides guidance for developing and contributing to the Outline Helm chart.

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/)
- [Go](https://golang.org/doc/install) (for some development tools)
- [Docker](https://docs.docker.com/get-docker/) (for running local clusters)

### Linting

To lint the chart, run the following command from the root of the repository:

```bash
make lint
```

This will check for common issues and ensure the chart follows best practices.

### Testing

The chart includes both unit and integration tests.

#### Unit Tests

Unit tests are handled by the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin. To run them, use the following command:

```bash
make unittest
```

These tests check the rendered templates for correctness without needing a running Kubernetes cluster.

#### Integration Tests

Integration tests use [chart-testing](https.github.com/helm/chart-testing) to deploy the chart to a temporary [Kind](https://kind.sigs.k8s.io/) cluster and verify its functionality. To run these tests, you can use the `test` target in the `Makefile`:

```bash
make test
```

This will run all tests, including linting, template validation, and unit tests, as well as the integration tests.

### Contributing

We welcome contributions to this chart! Please see the [contribution guidelines](../../.github/CONTRIBUTING.md) for more information.
