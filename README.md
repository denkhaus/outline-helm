# Outline Wiki Helm Chart

[![Helm Chart Version](https://img.shields.io/github/v/release/denkhaus/outline-helm?label=Chart%20Version&color=blue)](https://github.com/denkhaus/outline-helm/releases)
[![Outline Version](https://img.shields.io/badge/Outline-v0.85.1-green)](https://github.com/outline/outline/releases/tag/v0.85.1)
[![License](https://img.shields.io/github/license/denkhaus/outline-helm?color=blue)](https://github.com/denkhaus/outline-helm/blob/main/LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/denkhaus/outline-helm/test-chart.yml?branch=main&label=Tests)](https://github.com/denkhaus/outline-helm/actions/workflows/test-chart.yml)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/denkhaus/outline-helm/lint-test.yml?branch=main&label=Lint)](https://github.com/denkhaus/outline-helm/actions/workflows/lint-test.yml)

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.19%2B-blue?logo=kubernetes)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.0%2B-blue?logo=helm)](https://helm.sh/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16.3.0-blue?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-20.5.0-red?logo=redis)](https://redis.io/)
[![MinIO](https://img.shields.io/badge/MinIO-14.8.6-orange?logo=minio)](https://min.io/)

[![Dependabot](https://img.shields.io/badge/Dependabot-enabled-brightgreen?logo=dependabot)](https://github.com/denkhaus/outline-helm/blob/main/.github/dependabot.yml)
[![Security](https://img.shields.io/badge/Security-Kubernetes%20Secrets-green?logo=kubernetes)](https://kubernetes.io/docs/concepts/configuration/secret/)
[![Maintenance](https://img.shields.io/badge/Maintained-yes-green.svg)](https://github.com/denkhaus/outline-helm/graphs/commit-activity)

> **🚨 BREAKING CHANGES**: Version 1.0.0 introduces breaking changes for improved security. See [Migration Guide](#-migration-from-v0x-to-v10) below.

> **Note**: This is a fork of the original [encircle360-oss/outline-helm-chart](https://github.com/encircle360-oss/outline-helm-chart) which appears to be unmaintained. This fork is maintained to keep the chart up-to-date and accessible.

A secure, production-ready Helm chart for deploying [Outline wiki](https://github.com/outline/outline) in Kubernetes clusters with mandatory secret management.

## ✨ Features

- **🛡️ Security First**: All sensitive values must come from Kubernetes secrets
- **📦 Complete Stack**: Outline + PostgreSQL + Redis + MinIO S3 storage
- **🔧 Flexible**: Optional ingress, configurable dependencies
- **🚀 Production Ready**: Follows Kubernetes best practices
- **📚 Well Documented**: Comprehensive examples and migration guides

## 🚀 Quick Start

### 1. Create Required Secret

**REQUIRED**: Create a Kubernetes secret with sensitive values before installation:

```bash
kubectl create secret generic outline-secrets \
  --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
  --from-literal=UTILS_SECRET="$(openssl rand -hex 32)" \
  --from-literal=SLACK_CLIENT_SECRET="your-slack-client-secret" \
  --from-literal=SMTP_PASSWORD="your-smtp-password" \
  --namespace=outline
```

### 2. Install the Chart

```bash
helm repo add outline-helm https://denkhaus.github.io/outline-helm
helm repo update
helm install outline outline-helm/outline --namespace outline --create-namespace
```

### 3. Access Outline

If using the default ingress configuration, Outline will be available at `http://outline.yourdomain.tld`

For more configuration options, see [values.yaml](charts/outline/values.yaml) and [examples](charts/outline/examples/).

## 📋 Configuration Examples

### Basic Configuration with Ingress

```yaml
# values.yaml
ingress:
  enabled: true
  className: nginx
  host: outline.company.com
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    enabled: true

secrets:
  name: "outline-secrets"

env:
  SMTP_HOST: "smtp.company.com"
  SMTP_PORT: "587"
  SMTP_USERNAME: "outline@company.com"
  SMTP_FROM_EMAIL: "outline@company.com"
  SMTP_SECURE: "true"
```

### Without Ingress (LoadBalancer/NodePort)

```yaml
# values.yaml
ingress:
  enabled: false

secrets:
  name: "outline-secrets"

env:
  SMTP_HOST: "smtp.example.com"
  SMTP_PORT: "587"
  SMTP_USERNAME: "noreply@example.com"
  SMTP_FROM_EMAIL: "noreply@example.com"
  SMTP_SECURE: "true"
```

### Legacy Example (v0.x format - DO NOT USE)
```
secretKey: "to-generate-see-values-yaml-docs"
utilsSecret: "to-generate-see-values-yaml-docs"
ingress:
  host: outline.somedomain.tld
  tls:
    enabled: true
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-staging"
env:
  SLACK_KEY: "your-slack-app-key"
  SLACK_SECRET: "your-slack-secret"
  SMTP_HOST: "some-smtp-host"
  SMTP_PORT: "25"
  SMTP_USERNAME: "smtp-user"
  SMTP_PASSWORD: "smtp-passwd"
  SMTP_FROM_EMAIL: "no-reply@outline.somedomain.tld"
  SMTP_REPLY_EMAIL: "hello@somedomain.tld"
  SMTP_SECURE: "false"
postgresql:
  postgresqlPassword: "some-secret-pw"
  postgresqlPostgresPassword: "some-secret-pw-admin"
  persistence:
    storageClass: "some-storage-class"
    size: 6Gi
redis:
  persistence:
    storageClass: "some-storage-class"
    size: 3Gi
minio:
  ingress:
    hostname: "data.outline.somedomain.tld"
    certManager: true
    tls: true
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-staging"
  secretKey:
    password: "some-secret-pw"
  accessKey:
    password: "some-secret-pw"
  persistence:
    storageClass: "some-storage-class"
    size: 30Gi
```

## Tips
If you have problems with loading images or some kind of contentType mismatch while loading avatars or images there might be some fix you need to apply to minio s3 server.
Open a shell in the minio pod/container or connect with a minio mc client to the minio server and execute the following policies.
This bugfix is also documented [here](https://github.com/outline/outline/issues/1236#issuecomment-780542120).
### Example within the minio pod (e.g. minio runs on localhost)
```
mc alias set minio http://localhost:9000 your-minio-access-key your-minio-secret
mc policy set public minio/ol-data/public
```
The path for the policy targets the `public` directory in the outline s3 bucket.

## 🚨 Migration from v0.x to v1.0

### Breaking Changes in v1.0.0

1. **Mandatory Secrets**: All sensitive values must now come from Kubernetes secrets
2. **Configuration Changes**: 
   - `existingSecret` → `secrets`
   - Removed `secretKey` and `utilsSecret` from values.yaml
   - Removed `envSecrets` legacy configuration
3. **Chart API**: Upgraded to Helm Chart API v2

### Migration Steps

1. **Create the required secret** (see Quick Start above)

2. **Update your values.yaml**:
   ```yaml
   # OLD (v0.x) - DON'T USE
   existingSecret:
     enabled: true
     name: "my-secret"
   secretKey: "hardcoded-key"
   
   # NEW (v1.x) - USE THIS
   secrets:
     name: "my-secret"
   # No more hardcoded secrets!
   ```

3. **Remove sensitive values** from your values.yaml files

4. **Upgrade**:
   ```bash
   helm upgrade outline outline-helm/outline -f your-updated-values.yaml
   ```

## 📦 Installation

### Using Helm Repository

```bash
helm repo add outline-helm https://denkhaus.github.io/outline-helm
helm repo update
helm install outline outline-helm/outline -f your-values.yaml
```

### From Source

```bash
git clone https://github.com/denkhaus/outline-helm.git
cd outline-helm
helm install outline charts/outline/ -f your-values.yaml
```

## Deployment

This Helm chart is automatically built and published using GitHub Actions:

- **Chart Releases**: Automatically created when changes are pushed to the main branch
- **GitHub Pages**: Serves the Helm repository index at `https://denkhaus.github.io/outline-helm`
- **Chart Testing**: All charts are linted and tested on pull requests and pushes

### Repository Structure

```
charts/outline/          # Main Helm chart
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── requirements.yaml   # Chart dependencies
└── templates/          # Kubernetes manifests
.github/workflows/      # GitHub Actions workflows
├── release.yml         # Chart release automation
├── lint-test.yml       # Chart testing
└── pages.yml           # GitHub Pages deployment
index.yaml             # Helm repository index
```

### Automated Releases

The chart is automatically released when:
1. Changes are pushed to the `main` branch
2. The chart version in `Chart.yaml` is incremented
3. GitHub Actions builds and publishes the chart to GitHub Releases
4. The Helm repository index is updated on GitHub Pages

## 📚 Documentation

- [Configuration Examples](charts/outline/examples/README.md)
- [Ingress Examples](charts/outline/examples/ingress-examples.yaml)
- [Chart Values](charts/outline/values.yaml)
- [Changelog](charts/outline/CHANGELOG.md)
- [Outline Documentation](https://docs.getoutline.com/)

## 🔧 Requirements

- Kubernetes 1.19+
- Helm 3.0+
- A Kubernetes secret with required sensitive values

## 🤝 Contributing

Feel free to contribute and create pull requests. We will review and merge them.

### Credits
This chart is based on the original work by [encircle360](https://encircle360.com). This fork is maintained by [denkhaus](https://github.com/denkhaus) with security improvements and modern best practices.