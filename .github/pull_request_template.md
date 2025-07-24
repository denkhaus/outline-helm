# Pull Request

## 📋 Description
<!-- Provide a brief description of the changes in this PR -->

## 🔗 Related Issue
<!-- Link to the issue this PR addresses -->
Fixes #(issue number)

## 🚀 Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🧪 Test improvement
- [ ] 🔧 Maintenance/refactoring
- [ ] ⚡ Performance improvement
- [ ] 🔒 Security improvement

## 🧪 Testing
<!-- Describe the tests you ran to verify your changes -->
- [ ] I have run `make test` and all tests pass
- [ ] I have run `make lint` and linting passes
- [ ] I have tested the chart installation locally
- [ ] I have tested with different configuration scenarios

### Test Commands Run:
```bash
# Add the commands you used to test your changes
make test
make lint
helm template test charts/outline --dry-run
```

## 📝 Changes Made
<!-- List the specific changes made in this PR -->
- 
- 
- 

## 🔧 Configuration Changes
<!-- If this PR changes configuration options, provide examples -->
```yaml
# Example of new/changed configuration
newFeature:
  enabled: true
  setting: "value"
```

## 📚 Documentation
<!-- Check all that apply -->
- [ ] I have updated the README.md if needed
- [ ] I have updated the CHANGELOG.md
- [ ] I have added/updated examples in the examples/ directory
- [ ] I have updated the values.yaml comments
- [ ] Documentation changes are not needed

## ⚠️ Breaking Changes
<!-- If this is a breaking change, describe what users need to do to migrate -->
- [ ] This PR introduces breaking changes
- [ ] Migration guide has been updated
- [ ] CHANGELOG.md reflects breaking changes

### Migration Required:
<!-- Describe what users need to do to migrate -->

## 🔍 Checklist
<!-- Ensure all items are completed before submitting -->
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## 📸 Screenshots
<!-- If applicable, add screenshots to help explain your changes -->

## 🔗 Additional Context
<!-- Add any other context about the PR here -->

---

### For Maintainers
- [ ] Labels have been applied
- [ ] Milestone has been set (if applicable)
- [ ] Security implications have been considered
- [ ] Performance implications have been considered