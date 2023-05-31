#! /usr/bin/bash

# This scripts is used to configure the CAE DNS suffix and fetch certs from Key Vault. 
# The scripts also generates self-signed certs and store them in Key Vault.

# Use Azure Cli to create self-signed certs by KeyVault

# Set variables by command line arguments
while getopts ":k:d:n:g:" opt; do
    case $opt in
        k) keyVaultName="$OPTARG"
        ;;
        d) dnsSuffix="$OPTARG"
        ;;
        n) containerEnvName="$OPTARG"
        ;;
        g) resourceGroupName="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
done


# Convert DNS suffix to subject name
# dnsSuffix = "test.com" and subjectName = "CN=*.test.com"
# dnsSuffix=$(echo $subjectName | sed 's/CN=//; s/\*\.//')
# Input is dnsSuffix and output is subjectName
subjectName="CN=*.$dnsSuffix"

# Convert DNS suffix to certName
# dnsSuffix = "test.com" and certName = "star-test-com-self-signed-cert"
certName=$(echo $subjectName | sed 's/CN=//; s/\*\.//; s/\*//; s/\./-/g; s/$/-self-signed-cert/')

# Generate command usage() function
function usage() {
    echo "Usage: $0 -k <key-vault-name> -d <dns-suffix> -n <container-env-name> -g <resource-group-name>"
    exit 1
}

# Finally the scripts to generate self-signed certs and add custom DNS suffix to Azure Container Environment
if [ -z "$keyVaultName" ] || [ -z "$dnsSuffix" ] || [ -z "$containerEnvName" ] || [ -z "$resourceGroupName" ]
then
    usage
fi

# Create a self-signed certificate use Default policy
function createSelfSignedCert() {
    az keyvault certificate create --vault-name $keyVaultName -n $certName --policy "$(az keyvault certificate get-default-policy)"
}

# Create a self-signed certificate use Custom policy
function createSelfSignedCertWithPolicy() {
    az keyvault certificate create --vault-name $keyVaultName -n $certName --policy "$(az keyvault certificate get-default-policy | sed 's/"lifetime_in_months": 12/"lifetime_in_months": 24/')"
}

# Create a self-signed certificate use Custom policy with subject name, the subject name should be injected into the policy
function createSelfSignedCertWithSubjectName() {
    az keyvault certificate create --vault-name $keyVaultName -n $certName --policy "$(az keyvault certificate get-default-policy | sed 's/"validityInMonths": 12/"validityInMonths": 24/; s/"subject": "CN=CLIGetDefaultPolicy"/"subject": "CN='"$subjectName"'"/')"
}  

# Get self-signed certificate from Key Vault
function getSelfSignedCert() {
    # az keyvault certificate download --vault-name $keyVaultName -n $certName -f $certName.pem
    az keyvault secret download --vault-name $keyVaultName -n $certName -f $certName.pfx --encoding base64

    # Random generate a password and set it as $passwd
    # passwd=$(openssl rand -base64 32)
}

# Add custom DNS suffix to Azure Container Environment
function addCustomDNSSuffix() {
    # Save self-signed cert to local
    # Output
    # echo "Download Cert from Key Vault"
    echo "Download Cert from Key Vault"
    getSelfSignedCert

    # Add custom DNS suffix to Azure Container Environment
    # Output
    # echo "Add custom DNS suffix to Azure Container Environment"
    echo "Add custom DNS suffix to Azure Container Environment"
    az containerapp env update -n $containerEnvName -g $resourceGroupName --dns-suffix $dnsSuffix --certificate-file $certName.pfx

    # Remove self-signed cert from local
    # Output
    # echo "Remove Cert from local"
    echo "Remove Temp Cert from local"
    rm $certName.pfx
}

# Create a self-signed certificate use Custom policy
createSelfSignedCertWithSubjectName
addCustomDNSSuffix