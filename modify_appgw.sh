#!/bin/bash

# Read environment variables
resourceGroupName=$resourceGroupName
appGatewayName=$appGatewayName

# Prompt user for input
# read -p "Enter backend pool name: " backendPoolName
# read -p "Enter listener name: " listenerName
# read -p "Enter frontend port: " frontendPort
# read -p "Enter backend port: " backendPort
# read -p "Enter backend address: " backendAddress
# read -p "Enter domain name: " domainName

# Define usage function
function usage {
    echo "Usage: $0 <resourceGroupName> <appGatewayName> <backendPoolName> <listenerName> <frontendPort> <backendPort> <backendAddress> <domainName>"
    exit 1
}

# Check if all required parameters are present
if [ $# -ne 8 ]; then
    usage
fi

resourceGroupName=$1
appGatewayName=$2
backendPoolName=$3
listenerName=$4
frontendPort=$5
backendPort=$6
backendAddress=$7
domainName=$8

# Get current maximum rule priority
maxPriority=$(az network application-gateway rule list \
    --resource-group $resourceGroupName \
    --gateway-name $appGatewayName \
    --query "[].priority" \
    --output tsv | sort -rn | head -n 1)


# Set new rule priority to maxPriority + 1
newPriority=$((maxPriority + 1))


# Create backend pool
az network application-gateway address-pool create \
    --resource-group $resourceGroupName \
    --gateway-name $appGatewayName \
    --name $backendPoolName \
    --servers $backendAddress


# Add backend address to pool
# az network application-gateway address-pool address add \
#     --resource-group $resourceGroupName \
#     --gateway-name $appGatewayName \
#     --pool-name $backendPoolName \
#     --servers $backendAddress

# Create listener
az network application-gateway http-listener create \
    --resource-group $resourceGroupName \
    --gateway-name $appGatewayName \
    --name $listenerName \
    --frontend-port "port_443" \
    --ssl-cert "star-nomadtribehub-com-certs" \
    --host-name $domainName \
    --frontend-ip "appGwPublicFrontendIpIPv4"

# Create BackendSettings
az network application-gateway http-settings create \
    --resource-group $resourceGroupName \
    --gateway-name $appGatewayName \
    --name "backendSetting_$backendPoolName" \
    --port $backendPort \
    --protocol Https \
    --cookie-based-affinity Disabled \
    --timeout 30
    # --probe "appGatewayBackendHealthProbe"

# Create rule
az network application-gateway rule create \
    --resource-group $resourceGroupName \
    --gateway-name $appGatewayName \
    --name "rule_$listenerName" \
    --http-listener $listenerName \
    --rule-type Basic \
    --address-pool $backendPoolName \
    --http-settings "backendSetting_$backendPoolName" \
    --priority $newPriority