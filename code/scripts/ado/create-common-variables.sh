#!/bin/bash
# =============================================================================
# Azure DevOps Variable Groups - Create/Update Common Variables
# =============================================================================
# This script creates or updates the 'common-variables' variable group
# containing shared variables used across all infrastructure pipelines.
# =============================================================================

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "${SCRIPT_DIR}/lib.sh"
source "${SCRIPT_DIR}/config.sh"

# Set ADO PAT for authentication
export AZURE_DEVOPS_EXT_PAT="${ADO_PAT_TOKEN}"

# =============================================================================
# Configuration
# =============================================================================

GROUP_NAME="common-variables"
GROUP_DESCRIPTION="Common variables shared across all infrastructure deployment pipelines"

# Default values (can be overridden in config.sh)
AZURE_SERVICE_CONNECTION_NAME="${AZURE_SERVICE_CONNECTION_NAME:-azure-infra-connection}"
DEPLOYMENT_LOCATION="${DEPLOYMENT_LOCATION:-canadacentral}"
DEFAULT_LOCATION_CODE="${DEFAULT_LOCATION_CODE:-cac}"
DEFAULT_OWNER="${DEFAULT_OWNER:-}"
MANAGED_BY="${MANAGED_BY:-Bicep}"
DEFAULT_DENY_SETTINGS_MODE="${DEFAULT_DENY_SETTINGS_MODE:-denyWriteAndDelete}"
DEFAULT_ACTION_ON_UNMANAGE="${DEFAULT_ACTION_ON_UNMANAGE:-detachAll}"

# Billing configuration (for subscription vending)
# Either INVOICE_SECTION_ID (MCA) or ENROLLMENT_ACCOUNT_ID (EA) should be provided, not both
BILLING_ACCOUNT_ID="${BILLING_ACCOUNT_ID:-}"
INVOICE_SECTION_ID="${INVOICE_SECTION_ID:-}"
ENROLLMENT_ACCOUNT_ID="${ENROLLMENT_ACCOUNT_ID:-}"

# Variable definitions for this group
declare -A COMMON_VARIABLES=(
    ["azureServiceConnection"]="${AZURE_SERVICE_CONNECTION_NAME}"
    ["deploymentLocation"]="${DEPLOYMENT_LOCATION}"
    ["azureTenantId"]="${AAD_TENANT_ID}"
    ["locationCode"]="${DEFAULT_LOCATION_CODE}"
    ["defaultOwner"]="${DEFAULT_OWNER}"
    ["managedBy"]="${MANAGED_BY}"
    ["denySettingsMode"]="${DEFAULT_DENY_SETTINGS_MODE}"
    ["actionOnUnmanage"]="${DEFAULT_ACTION_ON_UNMANAGE}"
    ["billingAccountId"]="${BILLING_ACCOUNT_ID}"
    ["invoiceSectionId"]="${INVOICE_SECTION_ID}"
    ["enrollmentAccountId"]="${ENROLLMENT_ACCOUNT_ID}"
)

# =============================================================================
# Functions
# =============================================================================

# Create or update the common-variables group
create_common_variables_group() {
    echo ""
    log_info "Processing variable group: ${GROUP_NAME}"
    log_info "Description: ${GROUP_DESCRIPTION}"
    echo ""
    
    local group_id
    group_id=$(get_or_create_variable_group "$GROUP_NAME" "$GROUP_DESCRIPTION")
    
    if [[ -z "$group_id" ]]; then
        log_error "Failed to get or create variable group"
        return 1
    fi
    
    # Update/Create all variables
    log_step "Setting variables..."
    
    for var_name in "${!COMMON_VARIABLES[@]}"; do
        local var_value="${COMMON_VARIABLES[$var_name]}"
        log_info "  Setting ${var_name}..."
        update_variable "$group_id" "$var_name" "$var_value" "false"
    done
    
    # Remove the dummy placeholder variable if it exists
    delete_variable "$group_id" "dummy"
    
    log_success "Variable group '${GROUP_NAME}' configured successfully"
    
    # Display the variables
    echo ""
    log_info "Variables in '${GROUP_NAME}':"
    for var_name in "${!COMMON_VARIABLES[@]}"; do
        local var_value="${COMMON_VARIABLES[$var_name]}"
        echo "  - ${var_name}: ${var_value}"
    done
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create/update variable group: ${GROUP_NAME}"
    echo ""
    log_info "Variables that would be set:"
    for var_name in "${!COMMON_VARIABLES[@]}"; do
        local var_value="${COMMON_VARIABLES[$var_name]}"
        echo "  - ${var_name}: ${var_value}"
    done
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create or update the 'common-variables' Azure DevOps variable group."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo ""
    echo "This script is typically called by create-variable-groups.sh"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                dry_run_mode=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Dry run mode
    if [[ "$dry_run_mode" == "true" ]]; then
        dry_run
        exit 0
    fi
    
    # Create/update the variable group
    create_common_variables_group
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
