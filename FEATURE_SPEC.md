# Feature Specification: Template Refactoring & Variable Naming Consistency

> **Feature Branch**: `feature/refactor-templates-and-naming`
> **Version**: 1.1.0
> **Created**: 2025-01-08
> **Status**: In Development

## 🎯 Overview

Refactor the Helm chart to improve maintainability, consistency, and modularity by:
1. Standardizing variable naming conventions in `values.yaml`
2. Ensuring template helpers reflect the updated variable names and requirements
3. Splitting the monolithic `outline.yaml` into separate, focused template files
4. Enhancing template helpers for better reusability and simplicity

## 🔍 Current State Analysis

### Issues Identified
1. **Inconsistent Naming**: Variable names in `values.yaml` don't follow consistent patterns
2. **Template Mismatch**: Some template helpers reference old variable names
3. **Monolithic Template**: `outline.yaml` contains Deployment, Service, and Ingress in one file
4. **Complex Helpers**: Some template helpers are overly complex and could be simplified
5. **Comment Requirements**: Variable comments define requirements not enforced in templates

### Current Structure
```
charts/outline/templates/
├── _helpers.tpl     # All template helpers (9.4KB)
├── outline.yaml     # Deployment + Service + Ingress (2.4KB)
└── NOTES.txt        # Installation notes
```

## 🎯 Goals & Success Criteria

### Primary Goals
- [ ] **Consistent Naming**: All variables follow clear naming conventions
- [ ] **Template Alignment**: All helpers reflect current `values.yaml` structure
- [ ] **Modular Templates**: Separate files for each Kubernetes resource type
- [ ] **Simplified Helpers**: Cleaner, more focused template helpers
- [ ] **Requirement Enforcement**: Templates validate requirements from comments

### Success Criteria
- [ ] All template rendering tests pass
- [ ] No breaking changes to existing functionality
- [ ] Improved code maintainability and readability
- [ ] Clear separation of concerns in template files
- [ ] Comprehensive validation of user inputs

## 📋 Detailed Requirements

### 1. Variable Naming Standardization

#### Current Issues in `values.yaml`
```yaml
# Inconsistent naming patterns
secrets:
  secretKeySecretKeyName: "SECRET_KEY"           # Redundant "SecretKey"
  utilsSecretSecretKeyName: "UTILS_SECRET"       # Redundant "Secret"
  slackClientSecretSecretKeyName: "SLACK_CLIENT_SECRET"  # Too verbose
  
# Missing validation for requirements
env:
  URL: http://outline.yourdomain.tld             # Comment says "takes precedence" but no validation
  REDIS_URL: redis://...                         # Comment says "takes precedence" but no logic
  DATABASE_URL: postgres://...                   # Comment says "takes precedence" but no logic
```

#### Proposed Naming Convention
```yaml
secrets:
  name: "outline-secrets"
  keys:
    # Core secrets (mandatory)
    secretKey: "SECRET_KEY"
    utilsSecret: "UTILS_SECRET"
    
    # Authentication secrets (conditional)
    slack:
      clientSecret: "SLACK_CLIENT_SECRET"
    google:
      clientSecret: "GOOGLE_CLIENT_SECRET"
    azure:
      clientSecret: "AZURE_CLIENT_SECRET"
    discord:
      clientSecret: "DISCORD_CLIENT_SECRET"
    oidc:
      clientSecret: "OIDC_CLIENT_SECRET"
    
    # Infrastructure secrets
    smtp:
      password: "SMTP_PASSWORD"
    redis:
      password: "REDIS_PASSWORD"
    postgres:
      password: "POSTGRES_PASSWORD"
      adminPassword: "POSTGRES_ADMIN_PASSWORD"
    minio:
      accessKey: "MINIO_ACCESS_KEY"
      secretKey: "MINIO_SECRET_KEY"
```

### 2. Template File Structure

#### Target Structure
```
charts/outline/templates/
├── _helpers.tpl           # Template helpers
├── deployment.yaml        # Deployment resource
├── service.yaml          # Service resource  
├── ingress.yaml          # Ingress resource
├── configmap.yaml        # ConfigMap for non-sensitive config
├── secrets.yaml          # Secret validation/references
└── NOTES.txt             # Installation notes
```

#### File Responsibilities
- **deployment.yaml**: Pod specification, environment variables, health checks
- **service.yaml**: Service definition and port configuration
- **ingress.yaml**: Ingress rules, TLS, and annotations
- **configmap.yaml**: Non-sensitive configuration data
- **secrets.yaml**: Secret validation and reference templates

### 3. Template Helper Improvements

#### Current Helper Issues
```yaml
# Too complex and hard to maintain
{{- define "outline.requiredSecretEnv" -}}
{{- if .Values.env.SLACK_CLIENT_ID }}
- name: SLACK_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.secrets.name }}
      key: {{ .Values.secrets.slackClientSecretName }}  # Old naming
{{- end }}
```

#### Proposed Helper Structure
```yaml
{{/*
Generate secret environment variable for OAuth providers
Usage: {{ include "outline.oauthSecretEnv" (dict "provider" "slack" "context" .) }}
*/}}
{{- define "outline.oauthSecretEnv" -}}
{{- $provider := .provider }}
{{- $ctx := .context }}
{{- $clientIdKey := printf "%s_CLIENT_ID" ($provider | upper) }}
{{- if index $ctx.Values.env $clientIdKey }}
- name: {{ printf "%s_CLIENT_SECRET" ($provider | upper) }}
  valueFrom:
    secretKeyRef:
      name: {{ $ctx.Values.secrets.name }}
      key: {{ index $ctx.Values.secrets.keys $provider "clientSecret" }}
{{- end }}
{{- end }}
```

### 4. Validation Requirements

#### Mandatory Validations
```yaml
{{/*
Validate required secrets are configured
*/}}
{{- define "outline.validateSecrets" -}}
{{- if not .Values.secrets.name }}
{{- fail "secrets.name is required - you must specify a Kubernetes secret name" }}
{{- end }}
{{- if not .Values.secrets.keys.secretKey }}
{{- fail "secrets.keys.secretKey is required - must reference SECRET_KEY in your secret" }}
{{- end }}
{{- if not .Values.secrets.keys.utilsSecret }}
{{- fail "secrets.keys.utilsSecret is required - must reference UTILS_SECRET in your secret" }}
{{- end }}
{{- end }}
```

#### URL Precedence Logic
```yaml
{{/*
Generate application URL with precedence logic
Direct URL setting takes precedence over ingress-derived URL
*/}}
{{- define "outline.applicationUrl" -}}
{{- if .Values.env.URL }}
{{- .Values.env.URL }}
{{- else if .Values.ingress.enabled }}
{{- if .Values.ingress.tls.enabled }}
{{- printf "https://%s" .Values.ingress.host }}
{{- else }}
{{- printf "http://%s" .Values.ingress.host }}
{{- end }}
{{- else }}
{{- fail "Either env.URL must be set or ingress must be enabled to determine application URL" }}
{{- end }}
{{- end }}
```

## 🔧 Implementation Plan

### Phase 1: Preparation & Validation
- [ ] Create feature branch: `feature/refactor-templates-and-naming`
- [ ] Backup current template tests
- [ ] Document current variable usage patterns
- [ ] Create migration validation script

### Phase 2: Variable Naming Refactoring
- [ ] Update `values.yaml` with new naming convention
- [ ] Maintain backward compatibility where possible
- [ ] Add deprecation warnings for old variable names
- [ ] Update documentation and examples

### Phase 3: Template Helper Refactoring
- [ ] Simplify existing helpers in `_helpers.tpl`
- [ ] Create new modular helpers for common patterns
- [ ] Add validation helpers for requirements
- [ ] Implement URL precedence logic

### Phase 4: Template File Splitting
- [ ] Extract Deployment from `outline.yaml` → `deployment.yaml`
- [ ] Extract Service from `outline.yaml` → `service.yaml`
- [ ] Extract Ingress from `outline.yaml` → `ingress.yaml`
- [ ] Create `configmap.yaml` for non-sensitive config
- [ ] Create `secrets.yaml` for validation

### Phase 5: Testing & Validation
- [ ] Update unit tests for new structure
- [ ] Test backward compatibility
- [ ] Validate all template rendering scenarios
- [ ] Test with real Kubernetes cluster
- [ ] Performance testing for template rendering

### Phase 6: Documentation & Cleanup
- [ ] Update README with new structure
- [ ] Update examples with new variable names
- [ ] Create migration guide for users
- [ ] Clean up old template file

## 🧪 Testing Strategy

### Unit Tests
```yaml
# Test new helper functions
suite: test template helpers
templates:
  - _helpers.tpl
tests:
  - it: should generate correct OAuth secret env
    template: _helpers.tpl
    set:
      env.SLACK_CLIENT_ID: "slack-id"
      secrets.name: "test-secret"
      secrets.keys.slack.clientSecret: "SLACK_SECRET"
    asserts:
      - contains:
          path: spec.template.spec.containers[0].env
          content:
            name: SLACK_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: test-secret
                key: SLACK_SECRET
```

### Integration Tests
```yaml
# Test complete deployment
suite: test complete deployment
templates:
  - deployment.yaml
  - service.yaml
  - ingress.yaml
tests:
  - it: should create all resources with new naming
    values:
      - ../ci/test-values-new-naming.yaml
    asserts:
      - hasDocuments:
          count: 3
      - isKind:
          of: Deployment
        documentIndex: 0
      - isKind:
          of: Service
        documentIndex: 1
      - isKind:
          of: Ingress
        documentIndex: 2
```

### Backward Compatibility Tests
```yaml
# Test old variable names still work with warnings
suite: test backward compatibility
templates:
  - deployment.yaml
tests:
  - it: should work with old variable names
    values:
      - ../ci/test-values-old-naming.yaml
    asserts:
      - isKind:
          of: Deployment
      # Should include deprecation warnings in rendered output
```

## 📚 Documentation Updates

### Files to Update
- [ ] `charts/outline/README.md` - Configuration documentation
- [ ] `charts/outline/values.yaml` - Inline comments
- [ ] `charts/outline/examples/` - All example files
- [ ] Root `README.md` - Quick start guide
- [ ] `CHANGELOG.md` - Breaking changes documentation

### Migration Guide
```markdown
# Migration Guide: v1.0.x → v1.1.0

## Variable Name Changes

### Secrets Configuration
```yaml
# OLD (deprecated)
secrets:
  secretKeySecretKeyName: "SECRET_KEY"
  slackClientSecretSecretKeyName: "SLACK_CLIENT_SECRET"

# NEW (recommended)
secrets:
  keys:
    secretKey: "SECRET_KEY"
    slack:
      clientSecret: "SLACK_CLIENT_SECRET"
```

## 🚨 Breaking Changes

### Potential Breaking Changes
1. **Template Helper Names**: Some internal helpers may be renamed
2. **Variable Structure**: Nested structure for secrets configuration
3. **File Organization**: Templates split into multiple files

### Mitigation Strategies
1. **Deprecation Warnings**: Old variable names will show warnings
2. **Backward Compatibility**: Support old names for one major version
3. **Migration Script**: Provide automated migration tool
4. **Documentation**: Clear migration path documentation

## 📈 Benefits

### Maintainability
- **Clearer Structure**: Each template file has single responsibility
- **Easier Debugging**: Smaller, focused template files
- **Better Testing**: Isolated testing of individual components

### User Experience
- **Consistent Naming**: Predictable variable naming patterns
- **Better Validation**: Clear error messages for misconfigurations
- **Improved Documentation**: Self-documenting variable structure

### Developer Experience
- **Modular Helpers**: Reusable template functions
- **Simplified Logic**: Cleaner template code
- **Better IDE Support**: Smaller files for better editor performance

## 🔄 Rollback Plan

### If Issues Arise
1. **Immediate**: Revert to previous chart version
2. **Short-term**: Fix critical issues in patch release
3. **Long-term**: Address feedback in minor release

### Rollback Triggers
- Template rendering failures
- Kubernetes resource creation errors
- Significant user complaints about breaking changes
- Performance degradation in template rendering

---

**Next Steps**: Begin implementation with Phase 1 preparation and validation.