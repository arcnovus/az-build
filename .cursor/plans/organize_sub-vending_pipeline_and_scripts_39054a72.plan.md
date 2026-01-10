# Organize Sub-Vending Pipeline and Scripts

## Analysis

1. **validate-environment.sh** - REDUNDANT: The `environment` parameter already has a `values` list in the pipeline, which Azure DevOps enforces automatically.

2. **Sub-vending specific files**:
   - Pipeline: `code/pipelines/sub-vending-pipeline.yaml`
   - Scripts (all only used by sub-vending pipeline):
     - `lookup-subscription.sh`
     - `validate-permissions.sh`
     - `construct-billing-scope.sh`
     - `validate-deployment.sh`
     - `whatif-deployment.sh`
     - `deploy-subscription-vending.sh`

## Changes

1. **Create subfolder**:
   - Create `code/pipelines/sub-vending/` directory

2. **Move pipeline**:
   - Move `code/pipelines/sub-vending-pipeline.yaml` → `code/pipelines/sub-vending/sub-vending-pipeline.yaml`

3. **Move scripts**:
   - Move all sub-vending specific scripts from `code/pipelines/scripts/` directly to `code/pipelines/sub-vending/`:
     - `lookup-subscription.sh`
     - `validate-permissions.sh`
     - `construct-billing-scope.sh`
     - `validate-deployment.sh`
     - `whatif-deployment.sh`
     - `deploy-subscription-vending.sh`

4. **Remove redundant validation**:
   - Remove environment validation step from Validate stage in the pipeline
   - Delete `validate-environment.sh` (redundant - parameter already enforces values)

5. **Update pipeline references**:
   - Update `scriptsPath` variable in pipeline to point to `code/pipelines/sub-vending`
   - Update all script references to use the new paths
   - Update script file headers/comments to reflect new locations if needed
