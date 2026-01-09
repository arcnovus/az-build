#!/usr/bin/env bash
#
# lookup-subscription.sh
#
# Looks up an existing Azure subscription by display name and returns its ID.
# This script computes the subscription alias name from input parameters and
# searches for a matching subscription.
#
# Usage:
#   bash lookup-subscription.sh <workloadAlias> <environment> <locationCode> <instanceNumber>
#
# Output:
#   - Sets Azure DevOps pipeline variable: EXISTING_SUBSCRIPTION_ID
#   - If found: The subscription ID (GUID)
#   - If not found: Empty string
#
# Example:
#   bash lookup-subscription.sh "hub" "prod" "cac" "001"
#   # Looks for subscription named: subcr-hub-prod-cac-001
#

set -euo pipefail

# Parameters
WORKLOAD_ALIAS="${1:-}"
ENVIRONMENT="${2:-}"
LOCATION_CODE="${3:-}"
INSTANCE_NUMBER="${4:-}"

# Validate required parameters
if [[ -z "$WORKLOAD_ALIAS" || -z "$ENVIRONMENT" || -z "$LOCATION_CODE" || -z "$INSTANCE_NUMBER" ]]; then
    echo "##[error]Missing required parameters."
    echo "Usage: bash lookup-subscription.sh <workloadAlias> <environment> <locationCode> <instanceNumber>"
    exit 1
fi

# Compute the subscription alias name using the same convention as the Bicep
# Convention: subcr-<workloadAlias>-<environment>-<locationcode>-<instance number>
SUBSCRIPTION_ALIAS_NAME="subcr-${WORKLOAD_ALIAS}-${ENVIRONMENT}-${LOCATION_CODE}-${INSTANCE_NUMBER}"

echo "Looking for existing subscription with name: ${SUBSCRIPTION_ALIAS_NAME}"

# Query Azure for a subscription with this display name
# Using --query to filter by displayName and return the subscriptionId
EXISTING_SUBSCRIPTION_ID=$(az account list \
    --query "[?name=='${SUBSCRIPTION_ALIAS_NAME}'].id" \
    --output tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_SUBSCRIPTION_ID" ]]; then
    echo "✓ Found existing subscription: ${SUBSCRIPTION_ALIAS_NAME}"
    echo "  Subscription ID: ${EXISTING_SUBSCRIPTION_ID}"
    
    # Set Azure DevOps pipeline variable
    echo "##vso[task.setvariable variable=EXISTING_SUBSCRIPTION_ID;isOutput=true]${EXISTING_SUBSCRIPTION_ID}"
else
    echo "✓ No existing subscription found with name: ${SUBSCRIPTION_ALIAS_NAME}"
    echo "  A new subscription will be created."
    
    # Set empty variable for pipeline
    echo "##vso[task.setvariable variable=EXISTING_SUBSCRIPTION_ID;isOutput=true]"
fi

# Also output the computed alias name for reference
echo "##vso[task.setvariable variable=SUBSCRIPTION_ALIAS_NAME;isOutput=true]${SUBSCRIPTION_ALIAS_NAME}"
