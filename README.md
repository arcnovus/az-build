# Azure Build Foundation

A reusable Azure infrastructure foundation using Bicep templates and Azure DevOps pipelines. This project provides a structured approach to deploying enterprise Azure environments following Azure Landing Zone patterns, leveraging Azure Verified Modules (AVM) and Cloud Adoption Framework (CAF) best practices.

## Structure

### Infrastructure as Code (`code/bicep/`)
- **mg-hierarchy/** - Management group structure and policies
- **monitoring/** - Azure Monitor, Log Analytics, and observability
- **governance/** - Azure Policy definitions and assignments
- **hub/** - Hub networking (Virtual Networks, Gateways, Firewalls)
- **cloudops/** - Operational tooling and automation
- **sub-vending/** - Subscription provisioning and management

### CI/CD Pipelines (`code/pipelines/`)
Sequential deployment pipelines for ordered infrastructure provisioning:
1. `01-mg-hierarchy-pipeline.yaml` - Management groups and hierarchy
2. `02-monitoring-sub-pipeline.yaml` - Monitoring subscription setup
3. `03-monitoring-pipeline.yaml` - Monitoring infrastructure
4. `04-governance-pipeline.yaml` - Policy and compliance
5. `05-hub-sub-pipeline.yaml` - Hub subscription setup
6. `06-hub-pipeline` - Hub networking infrastructure
7. `07-cloudops-pipeline.yaml` - Operational tooling
8. `workload-sub-pipeline.yaml` - Workload subscription provisioning

## Getting Started

1. Clone this repository as a starting point for your Azure infrastructure project
2. Customize the Bicep templates in `code/bicep/` for your requirements
3. Configure the pipelines in `code/pipelines/` with your Azure DevOps environment
4. Deploy infrastructure following the numbered pipeline sequence

## Prerequisites

- Azure subscription with appropriate permissions
- Azure DevOps organization and project
- Azure CLI or PowerShell with Azure modules
- **Service Principal with required RBAC permissions** - See [RBAC Requirements](docs/RBAC-Requirements.md)

## Documentation

- [RBAC Requirements](docs/RBAC-Requirements.md) - Complete guide to service principal permissions
- [Management Group Hierarchy](docs/Management-Group-Hierarchy.md) - Creating and managing management groups
- [Hub Infrastructure](docs/Hub-Infrastructure.md) - Hub networking setup
- [Spoke Infrastructure](docs/Spoke-Infrastructure.md) - Spoke networking setup
- [Monitoring Infrastructure](docs/Monitoring-Infrastructure.md) - Monitoring and observability
- [Subscription Vending](docs/Subscription-Vending.md) - Automated subscription provisioning
- [CloudOps](docs/CloudOps.md) - DevOps agent pools and automation

## Deployment

Run the pipelines in numerical order to ensure proper dependency management and resource provisioning.

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