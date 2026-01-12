# Azure Build Foundation

> **⚠️ Disclaimer: Personal Reference Project**
> 
> This repository is a **personal and opinionated project** created for my own use and learning. It is **not intended for production use** and should **not be relied upon** to build your Azure environment without significant review, customization, and testing.
> 
> **Important Notes:**
> - This project is **subject to change** at any time without notice
> - It reflects my personal preferences and may not align with your organization's requirements or best practices
> - It is **not maintained** for general public use or production scenarios
> - While made publicly available, it is **not designed to be reusable** by the general population
> 
> **Intended Use:**
> - Use as a **reference** for ideas, patterns, or approaches
> - **Clone and enhance** to your own specifications and requirements
> - Learn from the structure and implementation patterns
> - Adapt and customize for your own needs
> 
> **You are responsible for:**
> - Reviewing all code and configurations before use
> - Testing thoroughly in non-production environments
> - Customizing to meet your specific requirements
> - Ensuring compliance with your organization's policies and standards
> - Understanding the security and operational implications of any deployment

---

A personal Azure infrastructure foundation using Bicep templates and Azure DevOps pipelines. This project demonstrates a structured approach to deploying Azure environments following Azure Landing Zone patterns, leveraging Azure Verified Modules (AVM) and Cloud Adoption Framework (CAF) best practices.

## Structure

### Infrastructure as Code (`code/bicep/`)
- **mg-hierarchy/** - Management group structure and policies
- **monitoring/** - Azure Monitor, Log Analytics, and observability
- **governance/** - Azure Policy definitions and assignments
- **hub/** - Hub networking (Virtual Networks, Gateways, Firewalls, IPAM)
- **spoke/** - Spoke networking infrastructure and IPAM configuration
- **cloudops/** - Operational tooling and automation (DevCenter, agent pools)
- **sub-vending/** - Subscription provisioning and management (direct Bicep implementation)

### CI/CD Pipelines (`code/pipelines/`)
Azure DevOps pipelines for infrastructure deployment:
- `mg-hierarchy-pipeline.yaml` - Management groups and hierarchy
- `monitoring-pipeline.yaml` - Monitoring infrastructure (Azure Monitor, Log Analytics)
- `governance-pipeline.yaml` - Policy definitions and assignments
- `hub-pipeline.yaml` - Hub networking infrastructure (Virtual Networks, Gateways, Firewalls)
- `spoke-networking-pipeline.yaml` - Spoke networking infrastructure
- `cloudops-pipeline.yaml` - Operational tooling and automation
- `cloudops-devcenter-pipeline.yaml` - Azure DevCenter configuration
- `sub-vending-pipeline.yaml` - Subscription provisioning and management
- `sub-vending/sub-vending-pipeline.yaml` - Alternative subscription vending implementation

**Pipeline Templates:**
- `templates/` - Reusable shell scripts for common operations (subscription lookup, resource alias computation)

### Automation Scripts (`code/scripts/`)
- **ado/** - Azure DevOps setup and configuration scripts
  - `setup-ado.sh` - Main setup script for Azure DevOps configuration
  - `create-variable-groups.sh` - Create variable groups for pipelines
  - `create-*-variables.sh` - Environment-specific variable creation scripts
  - `check-prerequisites.sh` - Validate prerequisites before setup

## Getting Started

**⚠️ Remember: This is a personal reference project. Review, test, and customize everything before use.**

1. **Review the codebase** - Understand the structure, patterns, and implementation details
2. **Clone and customize** - Adapt the Bicep templates in `code/bicep/` to your specific requirements
3. **Configure pipelines** - Modify the pipelines in `code/pipelines/` for your Azure DevOps environment
4. **Test thoroughly** - Deploy and test in non-production environments first
5. **Document your changes** - Maintain your own documentation for your customized version

## Prerequisites

- Azure subscription with appropriate permissions
- Azure DevOps organization and project
- Azure CLI or PowerShell with Azure modules
- **Service Principal with required RBAC permissions** - See [RBAC Requirements](docs/RBAC-Requirements.md)

## Documentation

- **[Overview](docs/Overview.md)** - Deployment order, phases, and component dependencies
- [RBAC Requirements](docs/RBAC-Requirements.md) - Complete guide to service principal permissions
- [Management Group Hierarchy](docs/Management-Group-Hierarchy.md) - Creating and managing management groups
- [Hub Infrastructure](docs/Hub-Infrastructure.md) - Hub networking setup
- [Spoke Infrastructure](docs/Spoke-Infrastructure.md) - Spoke networking setup
- [Monitoring Infrastructure](docs/Monitoring-Infrastructure.md) - Monitoring and observability
- [Subscription Vending](docs/Subscription-Vending.md) - Automated subscription provisioning
- [CloudOps](docs/CloudOps.md) - DevOps agent pools and automation

## Deployment

**⚠️ Important:** Deployment order and dependencies should be carefully reviewed and tested for your specific environment. The suggested order below is a reference only:

1. Management Group Hierarchy
2. Monitoring Infrastructure
3. Governance (Policies)
4. Hub Networking
5. Spoke Networking
6. CloudOps / DevCenter
7. Subscription Vending

**Note:** Dependencies between components should be validated before deployment. Review each pipeline's requirements and adjust the sequence based on your needs.

### Initial Setup: Service Principal Permissions

Before running any pipelines, ensure your service principal has the required RBAC permissions. For a simplified initial setup:

```bash
SP_OBJECT_ID="<your-service-principal-object-id>"
TENANT_ROOT_MG=$(az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv)

# Assign Owner at Tenant Root MG (covers most deployment scenarios)
az role assignment create \
  --assignee "$SP_OBJECT_ID" \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ROOT_MG"
```

See [RBAC Requirements](docs/RBAC-Requirements.md) for detailed per-pipeline permissions.