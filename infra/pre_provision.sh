#!/bin/bash

# Check if AZURE_RESOURCE_GROUP is already set in the azd environment
RESOURCE_GROUP=$(azd env get-values --output json | jq -r '.AZURE_RESOURCE_GROUP')

if [ -z "$RESOURCE_GROUP" ] || [ "$RESOURCE_GROUP" == "null" ]; then
  # List all resource groups in the current subscription
  echo "Current resource groups in the subscription:"
  az group list --query "[].name" -o tsv

  # Prompt the user for the resource group name until a valid name is provided
  while [ -z "$RESOURCE_GROUP" ] || [ "$RESOURCE_GROUP" == "null" ]; do
    read -p "Enter the resource group name: " RESOURCE_GROUP
  done

  # Set the resource group name in the environment
  azd env set AZURE_RESOURCE_GROUP $RESOURCE_GROUP

  echo "Resource group name set to: $RESOURCE_GROUP"
else
  echo "Resource group name is already set to: $RESOURCE_GROUP"
fi