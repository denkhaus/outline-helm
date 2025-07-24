# Migration Guide: Outline v0.69.1 → v0.85.1

This document outlines the environment variable changes when upgrading from Outline v0.69.1 to v0.85.1.

## 🚨 Breaking Changes in Environment Variables

### Authentication Variables

| **Old (v0.69.1)** | **New (v0.85.1)** | **Notes** |
|-------------------|-------------------|-----------|
| `SLACK_KEY` | `SLACK_CLIENT_ID` | Now non-sensitive (can be in values.yaml) |
| `SLACK_SECRET` | `SLACK_CLIENT_SECRET` | Still sensitive (must be in secret) |
| N/A | `GOOGLE_CLIENT_ID` | New: Google OAuth support |
| N/A | `GOOGLE_CLIENT_SECRET` | New: Google OAuth secret |
| N/A | `AZURE_CLIENT_ID` | New: Microsoft Entra/Azure AD support |
| N/A | `AZURE_CLIENT_SECRET` | New: Azure OAuth secret |
| N/A | `DISCORD_CLIENT_ID` | New: Discord OAuth support |
| N/A | `DISCORD_CLIENT_SECRET` | New: Discord OAuth secret |
| N/A | `OIDC_CLIENT_ID` | New: Generic OIDC support |
| N/A | `OIDC_CLIENT_SECRET` | New: OIDC secret |

### New Environment Variables in v0.85.1

#### Core Configuration
- `DEFAULT_LANGUAGE` - Interface language (default: en_US)
- `WEB_CONCURRENCY` - Number of processes to spawn
- `FILE_STORAGE` - Storage backend (s3 or local)
- `FILE_STORAGE_UPLOAD_MAX_SIZE` - Max upload size
- `RATE_LIMITER_ENABLED` - Enable rate limiting
- `RATE_LIMITER_REQUESTS` - Requests per window
- `RATE_LIMITER_DURATION_WINDOW` - Rate limit window

#### OIDC Configuration
- `OIDC_AUTH_URI` - OIDC authorization endpoint
- `OIDC_TOKEN_URI` - OIDC token endpoint  
- `OIDC_USERINFO_URI` - OIDC userinfo endpoint
- `OIDC_LOGOUT_URI` - OIDC logout endpoint
- `OIDC_USERNAME_CLAIM` - JWT claim for username
- `OIDC_DISPLAY_NAME` - Display name for OIDC provider
- `OIDC_SCOPES` - OAuth scopes

#### Integration Secrets
- `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` - GitHub integration
- `GITHUB_WEBHOOK_SECRET` - GitHub webhook verification
- `GITHUB_APP_PRIVATE_KEY` - GitHub app authentication
- `LINEAR_CLIENT_ID` / `LINEAR_CLIENT_SECRET` - Linear integration
- `NOTION_CLIENT_ID` / `NOTION_CLIENT_SECRET` - Notion import
- `SLACK_VERIFICATION_TOKEN` - Slack app verification

#### Additional Features
- `ENABLE_UPDATES` - Check for updates
- `LOG_LEVEL` - Logging verbosity
- `DEBUG` - Debug categories

## 📋 Migration Checklist

### 1. Update Secret Names
```bash
# Old secret format (v0.69.1)
kubectl create secret generic outline-secrets \
  --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
  --from-literal=UTILS_SECRET="$(openssl rand -hex 32)" \
  --from-literal=SLACK_KEY="your-slack-key" \
  --from-literal=SLACK_SECRET="your-slack-secret"

# New secret format (v0.85.1)
kubectl create secret generic outline-secrets \
  --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
  --from-literal=UTILS_SECRET="$(openssl rand -hex 32)" \
  --from-literal=SLACK_CLIENT_SECRET="your-slack-client-secret"
```

### 2. Update values.yaml
```yaml
# Old format (v0.69.1)
env:
  SLACK_KEY: "your-slack-key"  # This was wrong - should have been in secret

# New format (v0.85.1)
env:
  SLACK_CLIENT_ID: "your-slack-client-id"  # Non-sensitive, can be here
  # SLACK_CLIENT_SECRET goes in Kubernetes secret
```

### 3. Configure Authentication Provider
Choose at least one authentication provider and configure both the client ID (in values.yaml) and client secret (in Kubernetes secret).

### 4. Optional: Configure New Features
```yaml
env:
  # Rate limiting
  RATE_LIMITER_ENABLED: "true"
  RATE_LIMITER_REQUESTS: "1000"
  
  # File storage
  FILE_STORAGE: "s3"
  FILE_STORAGE_UPLOAD_MAX_SIZE: "262144000"
  
  # OIDC (if using)
  OIDC_CLIENT_ID: "your-oidc-client-id"
  OIDC_AUTH_URI: "https://provider.com/auth"
  OIDC_TOKEN_URI: "https://provider.com/token"
```

## 🔧 Chart Configuration Changes

### Secret Configuration
```yaml
# Old (v0.x)
existingSecret:
  enabled: true
  name: "outline-secrets"
  slackKeyName: "SLACK_KEY"
  slackSecretName: "SLACK_SECRET"

# New (v1.x)
secrets:
  name: "outline-secrets"
  slackClientSecretName: "SLACK_CLIENT_SECRET"
  googleClientSecretName: "GOOGLE_CLIENT_SECRET"
  # ... additional providers
```

## 📚 Resources

- [Outline v0.85.1 Release Notes](https://github.com/outline/outline/releases/tag/v0.85.1)
- [Outline Authentication Documentation](https://docs.getoutline.com/s/hosting)
- [Chart Examples](./examples/README.md)