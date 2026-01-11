#!/usr/bin/env bash
#
# hub-deploy-stack.sh
# Location: code/pipelines/hub/
#
# Deploys the hub deployment stack at subscription scope.
#
# Usage:
#   bash hub-deploy-stack.sh \
#     <subscriptionId> \
#     <templateFile> \
#     <parametersFile> \
#     <deploymentLocation> \
#     <stackName> \
#     <denySettingsMode> \
#     <actionOnUnmanage> \
#     <workloadAlias> \
#     <environment> \
#     <locationCode> \
#     <instanceNumber> \
#     <location> \
#     <privateDnsZoneName> \
#     <hubVnetAddressSpace> \
#     <logAnalyticsWorkspaceResourceId> \
#     <owner> \
#     <managedBy> \
#     <avnmManagementGroupId> \
#     <enableAppGatewayWAF> \
#     <enableFrontDoor> \
#     <enableVpnGateway> \
#     <enableAzureFirewall> \
#     <enableDDoSProtection> \
#     <enableDnsResolver> \
#     <enableIpamPool> \
#     <ipamPoolAddressSpace> \
#     <ipamPoolDescription> \
#     <vpnClientAddressPoolPrefix> \
#     <azureFirewallTier>
#
# Exit codes:
#   0 - Deployment succeeded
#   1 - Deployment failed

set -euo pipefail

# Parameters
SUBSCRIPTION_ID="${1:-}"
TEMPLATE_FILE="${2:-}"
PARAMETERS_FILE="${3:-}"
DEPLOYMENT_LOCATION="${4:-}"
STACK_NAME="${5:-}"
DENY_SETTINGS_MODE="${6:-}"
ACTION_ON_UNMANAGE="${7:-}"
WORKLOAD_ALIAS="${8:-}"
ENVIRONMENT="${9:-}"
LOCATION_CODE="${10:-}"
INSTANCE_NUMBER="${11:-}"
LOCATION="${12:-}"
PRIVATE_DNS_ZONE_NAME="${13:-}"
HUB_VNET_ADDRESS_SPACE="${14:-}"
LOG_ANALYTICS_WORKSPACE_RESOURCE_ID="${15:-}"
OWNER="${16:-}"
MANAGED_BY="${17:-}"
AVNM_MANAGEMENT_GROUP_ID="${18:-}"
ENABLE_APP_GATEWAY_WAF="${19:-}"
ENABLE_FRONT_DOOR="${20:-}"
ENABLE_VPN_GATEWAY="${21:-}"
ENABLE_AZURE_FIREWALL="${22:-}"
ENABLE_DDOS_PROTECTION="${23:-}"
ENABLE_DNS_RESOLVER="${24:-}"
ENABLE_IPAM_POOL="${25:-}"
IPAM_POOL_ADDRESS_SPACE="${26:-}"
IPAM_POOL_DESCRIPTION="${27:-}"
VPN_CLIENT_ADDRESS_POOL_PREFIX="${28:-}"
AZURE_FIREWALL_TIER="${29:-}"

PARAMS=""
if [ -n "$WORKLOAD_ALIAS" ]; then
  PARAMS="$PARAMS --parameters workloadAlias='$WORKLOAD_ALIAS'"
fi
if [ -n "$ENVIRONMENT" ]; then
  PARAMS="$PARAMS --parameters environment='$ENVIRONMENT'"
fi
if [ -n "$LOCATION_CODE" ]; then
  PARAMS="$PARAMS --parameters locationCode='$LOCATION_CODE'"
fi
if [ -n "$INSTANCE_NUMBER" ]; then
  PARAMS="$PARAMS --parameters instanceNumber='$INSTANCE_NUMBER'"
fi
if [ -n "$LOCATION" ]; then
  PARAMS="$PARAMS --parameters location='$LOCATION'"
fi
if [ -n "$PRIVATE_DNS_ZONE_NAME" ]; then
  PARAMS="$PARAMS --parameters privateDnsZoneName='$PRIVATE_DNS_ZONE_NAME'"
fi
if [ -n "$HUB_VNET_ADDRESS_SPACE" ]; then
  PARAMS="$PARAMS --parameters hubVnetAddressSpace='$HUB_VNET_ADDRESS_SPACE'"
fi
if [ -n "$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID" ]; then
  PARAMS="$PARAMS --parameters logAnalyticsWorkspaceResourceId='$LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'"
fi
if [ -n "$OWNER" ]; then
  PARAMS="$PARAMS --parameters owner='$OWNER'"
fi
if [ -n "$MANAGED_BY" ]; then
  PARAMS="$PARAMS --parameters managedBy='$MANAGED_BY'"
fi
if [ -n "$AVNM_MANAGEMENT_GROUP_ID" ]; then
  PARAMS="$PARAMS --parameters avnmManagementGroupId='$AVNM_MANAGEMENT_GROUP_ID'"
fi
# Optional resource flags
PARAMS="$PARAMS --parameters enableAppGatewayWAF=$ENABLE_APP_GATEWAY_WAF"
PARAMS="$PARAMS --parameters enableFrontDoor=$ENABLE_FRONT_DOOR"
PARAMS="$PARAMS --parameters enableVpnGateway=$ENABLE_VPN_GATEWAY"
PARAMS="$PARAMS --parameters enableAzureFirewall=$ENABLE_AZURE_FIREWALL"
PARAMS="$PARAMS --parameters enableDDoSProtection=$ENABLE_DDOS_PROTECTION"
PARAMS="$PARAMS --parameters enableDnsResolver=$ENABLE_DNS_RESOLVER"
PARAMS="$PARAMS --parameters enableIpamPool=$ENABLE_IPAM_POOL"
if [ -n "$IPAM_POOL_ADDRESS_SPACE" ]; then
  PARAMS="$PARAMS --parameters ipamPoolAddressSpace='$IPAM_POOL_ADDRESS_SPACE'"
fi
if [ -n "$IPAM_POOL_DESCRIPTION" ]; then
  PARAMS="$PARAMS --parameters ipamPoolDescription='$IPAM_POOL_DESCRIPTION'"
fi
# Optional resource configuration
if [ -n "$VPN_CLIENT_ADDRESS_POOL_PREFIX" ]; then
  PARAMS="$PARAMS --parameters vpnClientAddressPoolPrefix='$VPN_CLIENT_ADDRESS_POOL_PREFIX'"
fi
if [ -n "$AZURE_FIREWALL_TIER" ]; then
  PARAMS="$PARAMS --parameters azureFirewallTier='$AZURE_FIREWALL_TIER'"
fi

az stack sub create \
  --name "$STACK_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --location "$DEPLOYMENT_LOCATION" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --deny-settings-mode "$DENY_SETTINGS_MODE" \
  --action-on-unmanage "$ACTION_ON_UNMANAGE" \
  --yes \
  $PARAMS
