#!/bin/bash
# =============================================================================
# Azure DevOps Environments - Create/Update Environments
# =============================================================================
# This script creates Azure DevOps environments used by deployment pipelines.
# Environments align with the environment parameter values used across pipelines.
#
# Prerequisites:
#   - Azure CLI with azure-devops extension
#   - config.sh with ADO_PAT_TOKEN set
#
# Required PAT Permissions:
#   - Environment: Read & Manage (under Pipelines in PAT creation UI)
#   - Project and Team: Read (under Project in PAT creation UI)
#
# Usage:
#   bash create-environments.sh           # Create all environments
#   bash create-environments.sh --dry-run # Preview changes
#   bash create-environments.sh --list    # List existing environments
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

# Environments configuration (from config.sh)
# If not set in config.sh, use default environments
if [[ -z "${ENVIRONMENTS[*]:-}" ]]; then
    ENVIRONMENTS=("nonprod" "dev" "test" "uat" "staging" "prod" "live")
fi

# =============================================================================
# Functions
# =============================================================================

# Create all environments from the ENVIRONMENTS array
create_all_environments() {
    echo ""
    log_info "Creating Azure DevOps environments..."
    log_info "Environments to create: ${ENVIRONMENTS[*]}"
    echo ""
    
    local created=0
    local skipped=0
    local failed=0
    
    for env_name in "${ENVIRONMENTS[@]}"; do
        if environment_exists "$env_name"; then
            log_info "Environment '${env_name}' already exists, skipping..."
            ((skipped++))
        else
            log_info "Creating environment '${env_name}'..."
            if env_id=$(create_environment "$env_name"); then
                log_success "Created environment '${env_name}' with ID: ${env_id}"
                ((created++))
            else
                log_error "Failed to create environment '${env_name}'"
                ((failed++))
            fi
        fi
    done
    
    echo ""
    log_info "Summary:"
    echo "  - Created: ${created}"
    echo "  - Already existed: ${skipped}"
    if [[ $failed -gt 0 ]]; then
        log_error "  - Failed: ${failed}"
        return 1
    fi
    
    log_success "All environments processed successfully"
}

# Dry run - show what would be done
dry_run() {
    echo ""
    log_info "DRY RUN - No changes will be made"
    echo ""
    
    log_info "Would create the following environments:"
    for env_name in "${ENVIRONMENTS[@]}"; do
        if environment_exists "$env_name"; then
            echo "  - ${env_name} (already exists, would skip)"
        else
            echo "  - ${env_name} (would create)"
        fi
    done
    echo ""
    
    log_info "Configuration:"
    echo "  - Organization: ${ADO_ORGANIZATION_URL}"
    echo "  - Project: ${ADO_PROJECT_NAME}"
}

# List existing environments
list_environments() {
    log_info "Listing environments in project '${ADO_PROJECT_NAME}'..."
    echo ""
    
    az pipelines environment list \
        --org "${ADO_ORGANIZATION_URL}" \
        --project "${ADO_PROJECT_NAME}" \
        --query "[].{Name:name, ID:id}" \
        -o table
}

# Display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create Azure DevOps environments used by deployment pipelines."
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -d, --dry-run       Show what would be done without making changes"
    echo "  -l, --list          List existing environments"
    echo ""
    echo "Environments to be created (from config.sh):"
    for env_name in "${ENVIRONMENTS[@]}"; do
        echo "  - ${env_name}"
    done
    echo ""
    echo "This script is typically called by setup-ado.sh"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local dry_run_mode=false
    local list_mode=false
    
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
            -l|--list)
                list_mode=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # List mode
    if [[ "$list_mode" == "true" ]]; then
        list_environments
        exit 0
    fi
    
    # Dry run mode
    if [[ "$dry_run_mode" == "true" ]]; then
        dry_run
        exit 0
    fi
    
    # Create all environments
    create_all_environments
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
