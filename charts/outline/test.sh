#!/bin/bash
set -e

echo "🧪 Running Helm Chart Tests for Outline"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${YELLOW}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_status "ERROR" "Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if helm unittest plugin is installed
if ! helm plugin list | grep -q unittest; then
    print_status "INFO" "Installing helm unittest plugin..."
    helm plugin install https://github.com/helm-unittest/helm-unittest
fi

print_status "INFO" "Running Helm lint..."
if helm lint .; then
    print_status "SUCCESS" "Helm lint passed"
else
    print_status "ERROR" "Helm lint failed"
    exit 1
fi

print_status "INFO" "Running Helm template validation..."
if helm template test . --dry-run > /dev/null; then
    print_status "SUCCESS" "Helm template validation passed"
else
    print_status "ERROR" "Helm template validation failed"
    exit 1
fi

print_status "INFO" "Running unit tests..."
if helm unittest .; then
    print_status "SUCCESS" "Unit tests passed"
else
    print_status "ERROR" "Unit tests failed"
    exit 1
fi

print_status "INFO" "Testing with different configurations..."

# Test with ingress disabled
print_status "INFO" "Testing with ingress disabled..."
if helm template test . --set ingress.enabled=false --dry-run > /dev/null; then
    print_status "SUCCESS" "Ingress disabled test passed"
else
    print_status "ERROR" "Ingress disabled test failed"
    exit 1
fi

# Test with external dependencies disabled
print_status "INFO" "Testing with external dependencies disabled..."
if helm template test . --set postgresql.enabled=false --set redis.enabled=false --set minio.enabled=false --dry-run > /dev/null; then
    print_status "SUCCESS" "External dependencies disabled test passed"
else
    print_status "ERROR" "External dependencies disabled test failed"
    exit 1
fi

# Test with authentication providers configured
print_status "INFO" "Testing with authentication providers..."
if helm template test . --set env.SLACK_CLIENT_ID=test --set env.GOOGLE_CLIENT_ID=test --set env.OIDC_CLIENT_ID=test --dry-run > /dev/null; then
    print_status "SUCCESS" "Authentication providers test passed"
else
    print_status "ERROR" "Authentication providers test failed"
    exit 1
fi

# Test with custom secret names
print_status "INFO" "Testing with custom secret configuration..."
if helm template test . --set secrets.name=custom-secrets --set secrets.secretKeyName=CUSTOM_SECRET --dry-run > /dev/null; then
    print_status "SUCCESS" "Custom secret configuration test passed"
else
    print_status "ERROR" "Custom secret configuration test failed"
    exit 1
fi

print_status "SUCCESS" "All tests passed! ✅"
echo ""
echo "🚀 Chart is ready for deployment!"
echo "📋 Test Summary:"
echo "   ✅ Helm lint"
echo "   ✅ Template validation"
echo "   ✅ Unit tests"
echo "   ✅ Ingress configuration"
echo "   ✅ External dependencies"
echo "   ✅ Authentication providers"
echo "   ✅ Custom secrets"
echo ""
echo "💡 To run tests manually:"
echo "   helm lint ."
echo "   helm unittest ."
echo "   helm template test . --dry-run"