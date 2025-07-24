# Changelog

## [1.0.5] - 2024-07-24

### 🔧 Changed
- **Redis URL Construction**: Corrected logic for assembling `REDIS_URL` from `REDIS_HOST` to properly handle optional passwords via `secrets.enableRedisPassword`.

## [1.0.4] - 2024-07-24

### ✨ Added
- **External Redis URL Construction**: `REDIS_URL` can now be assembled from `REDIS_HOST` and an optional `REDIS_PASSWORD` from an existing secret, even when the internal Redis is disabled.

### 🔧 Changed
- **URL Environment Variable Handling**: Ensured `URL` environment variable is set only once, prioritizing user-defined `env.URL` over ingress-derived values.

## [1.0.0] - 2024-07-24

### 🚨 BREAKING CHANGES
- **Security**: All sensitive values must now come from Kubernetes secrets
- **Updated**: Outline version 0.69.1 → **0.85.1** (latest)
- **Authentication**: Updated to new OAuth variable names (SLACK_CLIENT_SECRET vs SLACK_SECRET)
- **Removed**: `secretKey` and `utilsSecret` from values.yaml
- **Removed**: `envSecrets` legacy configuration
- **Removed**: `existingSecret.enabled` flag - secrets are now mandatory
- **Changed**: `existingSecret` renamed to `secrets` for clarity

### ✨ Added
- **Latest Outline v0.85.1** with all new features:
  - Document mentions with `@`
  - New installation screen
  - Table cell merging/splitting
  - OIDC `.well-known` discovery support
  - GitHub and Linear integrations
  - OAuth provider functionality
  - Enhanced editor improvements
- **Multiple Authentication Providers**: Slack, Google, Azure/Microsoft, Discord, OIDC
- **New Integrations**: GitHub, Linear, Notion import support
- **Advanced Configuration**: Rate limiting, file storage options, debugging
- Mandatory Kubernetes secret integration for all sensitive values
- Clean helper template structure
- Example secret configuration in `examples/secret.yaml`
- Validation to prevent sensitive values in values.yaml

### 🔧 Changed
- Chart API version upgraded to v2
- Simplified configuration structure
- Better separation of concerns between config and secrets
- Updated environment variables to match Outline v0.85.1
- Enhanced secret management for multiple auth providers

### 🛡️ Security
- **REQUIRED**: SECRET_KEY, UTILS_SECRET, and at least one auth provider secret must be in Kubernetes secrets
- Support for multiple OAuth providers with individual secrets
- No more hardcoded secrets in values files
- Follows Kubernetes security best practices

### 📚 Migration Guide
1. Create a Kubernetes secret with required values:
   ```bash
   kubectl create secret generic outline-secrets \
     --from-literal=SECRET_KEY="$(openssl rand -hex 32)" \
     --from-literal=UTILS_SECRET="$(openssl rand -hex 32)" \
     --from-literal=SLACK_KEY="your-slack-key" \
     --from-literal=SLACK_SECRET="your-slack-secret" \
     --from-literal=SMTP_PASSWORD="your-smtp-password"
   ```

2. Update your values.yaml:
   ```yaml
   # OLD (v0.x)
   existingSecret:
     enabled: true
     name: "my-secret"
   
   # NEW (v1.x)
   secrets:
     name: "my-secret"
   ```

3. Remove any sensitive values from your values.yaml files