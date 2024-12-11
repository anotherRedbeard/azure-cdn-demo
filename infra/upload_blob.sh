#!/bin/bash

# Log the fetched values
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "Container Name: $STATIC_ASSETS_CONTAINER_NAME"

# Get the storage account key
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $AZURE_RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query "[0].value" \
  -o tsv)

# Upload a blob
az storage blob upload \
  --account-name $STORAGE_ACCOUNT_NAME \
  --container-name $STATIC_ASSETS_CONTAINER_NAME \
  --file "./infra/pete.jpg" \
  --name "pete.jpg" --overwrite

# Upload a blob
az storage blob upload \
  --account-name $STORAGE_ACCOUNT_NAME \
  --container-name $STATIC_ASSETS_CONTAINER_NAME \
  --file "./infra/wilson.jpg" \
  --name "wilson.jpg" --overwrite

# Disable all public network access for the storage account
az storage account update \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --default-action Deny \
  --public-network-access Disabled

echo "Blobs uploaded and storage account locked down to deny public network access."

# Fetch the private endpoint connection ID
PRIVATE_ENDPOINT_CONNECTION_NAME=$(az network private-endpoint-connection list \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT_NAME \
  --type Microsoft.Storage/storageAccounts \
  --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].name" \
  -o tsv)
  
# Check if there's a pending connection
if [ -z "$PRIVATE_ENDPOINT_CONNECTION_NAME" ]; then
  echo "No pending private endpoint connection found."
  exit 0
fi

# Approve the private endpoint connection
echo "Approving the private endpoint connection: $PRIVATE_ENDPOINT_CONNECTION_NAME"
az network private-endpoint-connection approve \
  -n $PRIVATE_ENDPOINT_CONNECTION_NAME \
  -g $AZURE_RESOURCE_GROUP \
  --resource-name $STORAGE_ACCOUNT_NAME \
  --type Microsoft.Storage/storageAccounts \
  --description "Automated approval for private endpoint connection"

echo "Private endpoint connection approved successfully."