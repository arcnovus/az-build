# Remove Redundant Validations and Organize Sub-Vending Scripts

## Analysis

After reviewing all validations in the pipeline:

1. **validate-environment.sh** - REDUNDANT: The `environment` parameter already has a `values` list (lines 71-78 in `sub-vending-pipeline.yaml`), which Azure DevOps enforces automatically. The script checks against a variable group `$(environments)`, but this is unnecessary since the parameter definition already restricts values.

2. **All remaining scripts are sub-vending specific**: Based on grep analysis, all scripts in `code/pipelines/scripts/` are only used by `sub-vending-pipeline.yaml`:
   - `lookup-subscription.sh` - Looks up subscriptions by naming convention (sub-vending specific)
   - `validate-permissions.sh` - Validates permissions for subscription creation (sub-vending specific)
   - `construct-billing-scope.sh` - Constructs billing scope for subscription creation (sub-vending specific)
   - `validate-deployment.sh` - Validates Bicep deployment (only used by sub-vending)
   - `whatif-deployment.sh` - Runs what-if analysis (only used by sub-vending)
   - `deploy-subscription-vending.sh` - Already clearly named for sub-vending

## Changes

1. **Remove redundant validation**:
   - Remove the environment validation step from the Validate stage in [code/pipelines/sub-vending-pipeline.yaml](code/pipelines/sub-vending-pipeline.yaml) (lines 138-142)
   - Delete [code/pipelines/scripts/validate-environment.sh](code/pipelines/scripts/validate-environment.sh)

2. **Organize sub-vending scripts**:
   - Create subfolder: `code/pipelines/scripts/sub-vending/`
   - Move and rename scripts with "sub-vending-" prefix:
     - `lookup-subscription.sh` → `sub-vending/sub-vending-lookup-subscription.sh`
     - `validate-permissions.sh` → `sub-vending/sub-vending-validate-permissions.sh`
     - `construct-billing-scope.sh` → `sub-vending/sub-vending-construct-billing-scope.sh`
     - `validate-deployment.sh` → `sub-vending/sub-vending-validate-deployment.sh`
     - `whatif-deployment.sh` → `sub-vending/sub-vending-whatif-deployment.sh`
     - `deploy-subscription-vending.sh` → `sub-vending/sub-vending-deploy.sh` (simplified name since it's already in sub-vending folder)
   - Update all script references in [code/pipelines/sub-vending-pipeline.yaml](code/pipelines/sub-vending-pipeline.yaml) to use new paths
   - Update script file headers/comments to reflect new names
