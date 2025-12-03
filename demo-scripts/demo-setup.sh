#!/bin/bash
# AIB Demo Setup Script - Creates infrastructure and builds first image version

set -e  # Exit on error

LOCATION="westus3"
RG_AIB="rg-aib-images-wus3"
RG_GALLERY="rg-acg-wus3"
RG_DEMO="rg-demo-wus3"
GALLERY_NAME="acg_corp_images_wus3"
IMAGE_DEF="windows-iis-hardened"
IDENTITY_NAME="aib-identity-wus3"
TEMPLATE_NAME="aib-template-windows-iis-wus3"

echo "=========================================="
echo "Azure Image Builder Demo Setup"
echo "Location: $LOCATION"
echo "=========================================="

# Step 1: Create Resource Groups
echo ""
echo "Step 1: Creating resource groups..."
az group create --name $RG_AIB --location $LOCATION
az group create --name $RG_GALLERY --location $LOCATION
az group create --name $RG_DEMO --location $LOCATION

# Step 2: Create Managed Identity
echo ""
echo "Step 2: Creating managed identity..."
az identity create \
  --resource-group $RG_AIB \
  --name $IDENTITY_NAME \
  --location $LOCATION

IDENTITY_ID=$(az identity show --resource-group $RG_AIB --name $IDENTITY_NAME --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --resource-group $RG_AIB --name $IDENTITY_NAME --query clientId -o tsv)

echo "Identity created: $IDENTITY_ID"

# Step 3: Assign Contributor role to managed identity on gallery resource group
echo ""
echo "Step 3: Assigning Contributor role to identity..."
az role assignment create \
  --assignee $IDENTITY_CLIENT_ID \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_GALLERY

# Step 4: Create Azure Compute Gallery
echo ""
echo "Step 4: Creating Azure Compute Gallery..."
az sig create \
  --resource-group $RG_GALLERY \
  --gallery-name $GALLERY_NAME \
  --location $LOCATION

# Step 5: Create Image Definition
echo ""
echo "Step 5: Creating image definition..."
az sig image-definition create \
  --resource-group $RG_GALLERY \
  --gallery-name $GALLERY_NAME \
  --gallery-image-definition $IMAGE_DEF \
  --publisher MyCompany \
  --offer WindowsServer \
  --sku 2022-IIS \
  --os-type Windows \
  --os-state Generalized \
  --hyper-v-generation V2 \
  --features SecurityType=TrustedLaunch \
  --location $LOCATION

# Step 6: Update AIB template with subscription ID and identity
echo ""
echo "Step 6: Creating AIB template..."

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Update the template file with correct subscription ID and identity
sed -i "s|/subscriptions/[^/]*/|/subscriptions/$SUBSCRIPTION_ID/|g" aib-template-windows-iis.json

# Step 7: Create AIB template resource
echo ""
echo "Step 7: Creating AIB template resource..."
az image builder create \
  --resource-group $RG_AIB \
  --name $TEMPLATE_NAME \
  --image-template aib-template-windows-iis.json \
  --location $LOCATION

# Step 8: Start the image build
echo ""
echo "Step 8: Starting image build (this takes 30-45 minutes)..."
az image builder run \
  --resource-group $RG_AIB \
  --name $TEMPLATE_NAME

echo ""
echo "=========================================="
echo "Build started successfully!"
echo "=========================================="
echo ""
echo "Monitor build progress with:"
echo "az image builder show-runs --resource-group $RG_AIB --name $TEMPLATE_NAME"
echo ""
echo "Once complete, verify the image version:"
echo "az sig image-version list --resource-group $RG_GALLERY --gallery-name $GALLERY_NAME --gallery-image-definition $IMAGE_DEF --output table"
