# Outline wiki helm chart

> **Note**: This is a fork of the original [encircle360-oss/outline-helm-chart](https://github.com/encircle360-oss/outline-helm-chart) which appears to be unmaintained. This fork is maintained to keep the chart up-to-date and accessible.

This helm chart provides you with a ready to use [outline wiki](https://github.com/outline/outline) stack ready to deploy in your kubernetes cluster.
It provides:
 - Outline
 - PostgreSQL
 - Redis
 - Minio S3 Storage

You can enable or disable every outline dependency like postgresql, minio or redis and also provide your own with your own configuration.
You are also able to re-configure most of all settings from the provided dependencies and defaults.

## Quick start

At first check all variables that need to be set, especially the credentials and secrets within the [values.yaml](charts/outline/values.yaml).
Do only use self-generated secrets and credentials for production environments.
```
helm upgrade --install -n outline --create-namespace --set postgresql.postgresqlPassword=some-secret-db-pass,postgresql.postgresqlPostgresPassword=some-secret-admin-db-pass,minio.secretKey.password=some-secret-s3-secret,minio.accessKey.password=some-secret-s3-accesskey,env.SLACK_SECRET=slack-oidc-secret,env.SLACK_KEY=slack-oidc-key outline charts/outline/
```

To find out more configuration possibilities also check the [values.yaml](charts/outline/values.yaml).

## Example values.yaml with slack as oidc provider and tls via cert-manager
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

## Installation

### Using Helm Repository

```bash
helm repo add outline-helm https://denkhaus.github.io/outline-helm
helm repo update
helm install outline outline-helm/outline
```

### From Source

```bash
git clone https://github.com/denkhaus/outline-helm.git
cd outline-helm
helm install outline charts/outline/
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

## Contribute
Feel free to contribute and create pull requests. We will review and merge them.

### Credits
This chart is based on the original work by [encircle360](https://encircle360.com). This fork is maintained by [denkhaus](https://github.com/denkhaus).