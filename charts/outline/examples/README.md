# Outline Helm Chart Examples

This directory contains example configurations for deploying Outline using this Helm chart.

## 📋 Prerequisites

Before deploying, you **MUST** create a Kubernetes secret with sensitive values:

```bash
kubectl create secret generic outline-secrets \
  --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
  --from-literal=UTILS_SECRET="$(openssl rand -hex 32)" \
  --from-literal=SLACK_CLIENT_SECRET="your-slack-client-secret" \
  --from-literal=SMTP_PASSWORD="your-smtp-password" \
  --namespace=outline
```

## 🚀 Basic Examples

### 1. Minimal Deployment (No Ingress)

For testing or when using LoadBalancer/NodePort:

```yaml
# values-minimal.yaml
ingress:
  enabled: false

secrets:
  name: "outline-secrets"

env:
  SMTP_HOST: "smtp.gmail.com"
  SMTP_PORT: "587"
  SMTP_USERNAME: "noreply@example.com"
  SMTP_FROM_EMAIL: "noreply@example.com"
  SMTP_SECURE: "true"
```

Deploy:
```bash
helm install outline outline-helm/outline -f values-minimal.yaml
```

### 2. Production with Ingress & TLS

```yaml
# values-production.yaml
ingress:
  enabled: true
  className: nginx
  host: outline.company.com
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  tls:
    enabled: true

secrets:
  name: "outline-secrets"

env:
  SMTP_USERNAME: "outline@company.com"
  SMTP_FROM_EMAIL: "outline@company.com"

postgresql:
  # Use existing secret for database credentials (recommended)
  existingSecret: "postgresql-credentials"
  existingSecretPasswordKey: "postgresql-password"
  existingSecretPostgresPasswordKey: "postgresql-postgres-password"
  persistence:
    storageClass: "fast-ssd"
    size: 10Gi

redis:
  persistence:
    storageClass: "fast-ssd"
    size: 5Gi

minio:
  # Use existing secret for storage credentials (recommended)
  existingSecret: "minio-credentials"
  existingSecretAccessKeyKey: "access-key"
  existingSecretSecretKeyKey: "secret-key"
  persistence:
    storageClass: "standard"
    size: 50Gi
  ingress:
    hostname: "outline-storage.company.com"
    certManager: true
    tls: true
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### 3. External Dependencies

Using external PostgreSQL, Redis, and S3:

```yaml
# values-external.yaml
ingress:
  enabled: true
  host: outline.example.com

secrets:
  name: "outline-secrets"

# Disable internal dependencies
postgresql:
  enabled: false

redis:
  enabled: false

minio:
  enabled: false

env:
  # External database
  DATABASE_URL: "postgres://user:pass@external-postgres:5432/outline"
  
  # External Redis
  REDIS_URL: "redis://external-redis:6379"
  
  # External S3
  AWS_ACCESS_KEY_ID: "your-access-key"
  AWS_SECRET_ACCESS_KEY: "your-secret-key"
  AWS_REGION: "us-east-1"
  AWS_S3_UPLOAD_BUCKET_URL: "https://s3.amazonaws.com"
  AWS_S3_UPLOAD_BUCKET_NAME: "outline-storage"
  
  # SMTP
  SMTP_HOST: "smtp.example.com"
  SMTP_PORT: "587"
  SMTP_USERNAME: "noreply@example.com"
  SMTP_FROM_EMAIL: "noreply@example.com"
  SMTP_SECURE: "true"
```

### 4. Development Environment

```yaml
# values-dev.yaml
ingress:
  enabled: true
  className: nginx
  host: outline.dev.local
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  tls:
    enabled: false

secrets:
  name: "outline-dev-secrets"

env:
  SMTP_HOST: "mailhog"
  SMTP_PORT: "1025"
  SMTP_USERNAME: ""
  SMTP_FROM_EMAIL: "dev@outline.local"
  SMTP_SECURE: "false"

# Smaller resources for development
postgresql:
  persistence:
    size: 1Gi

redis:
  persistence:
    size: 1Gi

minio:
  persistence:
    size: 5Gi
```

## 🔧 Advanced Configuration

### Custom Secret Names

If you have existing secrets with different names:

```yaml
secrets:
  name: "my-custom-secret"
  secretKeyName: "OUTLINE_SECRET_KEY"
  utilsSecretName: "OUTLINE_UTILS_SECRET"
  slackKeyName: "SLACK_OAUTH_KEY"
  slackSecretName: "SLACK_OAUTH_SECRET"
  smtpPasswordName: "EMAIL_PASSWORD"
```

### Multiple Replicas

```yaml
replicas: 3

# Add resource limits for production
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

## 📝 Deployment Commands

### Install
```bash
helm repo add outline-helm https://denkhaus.github.io/outline-helm
helm repo update
helm install outline outline-helm/outline -f your-values.yaml
```

### Upgrade
```bash
helm upgrade outline outline-helm/outline -f your-values.yaml
```

### Uninstall
```bash
helm uninstall outline
```

## 🔍 Troubleshooting

### Check if secrets exist:
```bash
kubectl get secret outline-secrets -o yaml
```

### View pod logs:
```bash
kubectl logs -l app=outline
```

### Check ingress:
```bash
kubectl get ingress
kubectl describe ingress outline
```

## 🔐 Secret Management Examples

### Application Secrets
- [secret.yaml](./secret.yaml) - Main Outline application secrets
- [postgresql-secret.yaml](./postgresql-secret.yaml) - PostgreSQL credentials
- [minio-secret.yaml](./minio-secret.yaml) - MinIO/S3 credentials

### Ingress Examples
- [ingress-examples.yaml](./ingress-examples.yaml) - Various ingress configurations

## 📚 Additional Resources

- [Outline Documentation](https://docs.getoutline.com/)
- [Slack OAuth Setup](https://docs.getoutline.com/s/hosting/doc/slack-authentication-5yCpJQGqMw)
- [SMTP Configuration](https://docs.getoutline.com/s/hosting/doc/email-configuration-5yCpJQGqMw)
- [PostgreSQL Secret Management](https://github.com/bitnami/charts/tree/main/bitnami/postgresql#use-existing-secret)
- [MinIO Secret Management](https://github.com/bitnami/charts/tree/main/bitnami/minio#use-existing-secret)