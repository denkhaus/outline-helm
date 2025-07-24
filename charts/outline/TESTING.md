# Testing Guide for Outline Helm Chart

This document describes the testing strategy and how to run tests for the Outline Helm chart.

## 🧪 Test Structure

### Unit Tests (`tests/unit/`)
- **`deployment_test.yaml`** - Tests deployment configuration, environment variables, and secret loading
- **`ingress_test.yaml`** - Tests ingress configuration and conditional rendering
- **`secrets_test.yaml`** - Tests secret management and conditional secret loading

### Integration Tests (`tests/integration/`)
- **`full_deployment_test.yaml`** - Tests complete deployment scenarios with all components

## 🚀 Running Tests

### Quick Test (Recommended before committing)
```bash
cd charts/outline
./test.sh
```

### Manual Testing
```bash
# Lint the chart
helm lint .

# Validate templates
helm template test . --dry-run

# Run unit tests (requires helm unittest plugin)
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest .
```

### Test Different Configurations
```bash
# Test with ingress disabled
helm template test . --set ingress.enabled=false --dry-run

# Test with external dependencies disabled
helm template test . \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --set minio.enabled=false \
  --dry-run

# Test with authentication providers
helm template test . \
  --set env.SLACK_CLIENT_ID=test \
  --set env.GOOGLE_CLIENT_ID=test \
  --set env.OIDC_CLIENT_ID=test \
  --dry-run

# Test with custom secrets
helm template test . \
  --set secrets.name=custom-secrets \
  --set postgresql.existingSecret=pg-creds \
  --set minio.existingSecret=minio-creds \
  --dry-run
```

## 🔍 Test Coverage

### ✅ What We Test

#### Core Functionality
- [x] Deployment renders correctly with default values
- [x] Correct Outline v0.85.1 image is used
- [x] Environment variables are set properly
- [x] Secrets are loaded from Kubernetes secrets
- [x] Service is configured correctly

#### Conditional Features
- [x] Ingress renders only when enabled
- [x] TLS configuration works correctly
- [x] Database URL is set when PostgreSQL is enabled
- [x] Redis URL is set when Redis is enabled
- [x] S3 configuration is set when MinIO is enabled

#### Secret Management
- [x] Core secrets (SECRET_KEY, UTILS_SECRET) are always loaded
- [x] Auth provider secrets are loaded conditionally
- [x] Integration secrets are loaded conditionally
- [x] SMTP password is loaded when SMTP is configured
- [x] Custom secret names and keys work correctly

#### Security
- [x] Hardcoded passwords don't appear in template output
- [x] Sensitive values are properly referenced from secrets
- [x] Auth provider secrets are only loaded when providers are configured

#### Compatibility
- [x] Outline v0.85.1 environment variables are present
- [x] New features (rate limiting, file storage) are configured
- [x] Multiple authentication providers work correctly

### 🎯 Test Scenarios

1. **Default Configuration** - Basic deployment with all defaults
2. **Production Configuration** - Ingress + TLS + all auth providers
3. **Minimal Configuration** - No ingress, no external dependencies
4. **External Dependencies** - Using external PostgreSQL/Redis/S3
5. **Custom Secrets** - Custom secret names and configurations

## 🔧 CI/CD Integration

### GitHub Actions
Tests run automatically on:
- Push to main branch (when charts/ directory changes)
- Pull requests (when charts/ directory changes)

### Workflows
- **`.github/workflows/test-chart.yml`** - Dedicated chart testing
- **`.github/workflows/lint-test.yml`** - Includes unit tests in CT workflow

## 📋 Pre-Commit Checklist

Before committing changes, ensure:

1. **Lint passes**: `helm lint .`
2. **Templates validate**: `helm template test . --dry-run`
3. **Unit tests pass**: `helm unittest .`
4. **Integration tests pass**: `./test.sh`
5. **Security check**: No hardcoded secrets in output
6. **Version compatibility**: Outline v0.85.1 features work

## 🐛 Debugging Failed Tests

### Common Issues

1. **Template validation fails**
   - Check YAML syntax in templates
   - Verify helper function calls
   - Check conditional logic

2. **Secret tests fail**
   - Verify secret key names match between values.yaml and helpers
   - Check conditional logic for auth providers
   - Ensure secret references are correct

3. **Environment variable tests fail**
   - Check if new env vars are added to helpers
   - Verify conditional loading logic
   - Check for typos in variable names

### Debug Commands
```bash
# See full template output
helm template test . --debug

# Test specific values
helm template test . --set key=value --debug

# Check specific document in output
helm template test . | yq eval 'select(.kind == "Deployment")'
```

## 📚 Adding New Tests

When adding new features:

1. **Add unit tests** for the specific feature
2. **Update integration tests** if needed
3. **Add test scenarios** to `test.sh`
4. **Document** the new test coverage
5. **Update** this testing guide

### Test File Template
```yaml
suite: test new feature
templates:
  - templates/outline.yaml
tests:
  - it: should test new feature
    set:
      newFeature.enabled: true
    asserts:
      - equal:
          path: spec.some.path
          value: expected-value
```