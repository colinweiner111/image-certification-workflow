#!/bin/bash
# AIB Demo Commands - Run these in order

# Step 1: Create Resource Groups
echo "Creating resource groups..."
az group create --name rg-aib-images --location eastus
az group create --name rg-acg --location eastus
az group create --name rg-demo --location eastus

# Step 2: Create Azure Compute Gallery
echo "Creating Azure Compute Gallery..."
az sig create \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --location eastus

# Step 3: Create Image Definition
echo "Creating image definition..."
az sig image-definition create \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --gallery-image-definition windows-iis-hardened \
  --publisher MyCompany \
  --offer WindowsServer \
  --sku 2022-IIS \
  --os-type Windows \
  --os-state Generalized \
  --location eastus

# Step 4: Get your subscription ID (you'll need this for the template)
echo ""
echo "Your subscription ID:"
az account show --query id -o tsv

echo ""
echo "Now update the aib-template-windows-iis.json file with your subscription ID"
echo "Then create the AIB template resource with:"
echo "az image builder create --resource-group rg-aib-images --name aib-template-windows-iis --image-template aib-template-windows-iis.json"
