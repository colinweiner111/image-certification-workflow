## POC - Azure Image Builder

---

## Table of Contents

- [Azure Prerequisites](#azure-prerequisites)
- [Golden Image Challenges](#golden-image-challenges)
- [The Solution](#the-solution)
- [Architecture & Key Concepts](#architecture--key-concepts)
- [Demo — Windows Server with IIS](#demo--windows-server-with-iis)
  - [Part 1: Review the AIB Template](#part-1-review-the-aib-template)
  - [Part 2: Create Infrastructure](#part-2-create-infrastructure)
  - [Part 3: Trigger the Build](#part-3-trigger-the-build)
  - [Part 4: Verify Image in ACG](#part-4-verify-image-in-acg)
  - [Part 5: Deploy VM from Gallery Image](#part-5-deploy-vm-from-gallery-image)
  - [Part 6: Update the Image & Redeploy](#part-6-update-the-image--redeploy)
  - [Part 7: Verify Image Metadata](#part-7-verify-image-metadata)
- [Cleanup](#cleanup)

---

### Golden Image Challenges

**Current Reality:**
- ❌ Manual image builds on VMs → no audit trail, no versioning
- ❌ Marketplace images deployed directly to production → not hardened, no compliance
- ❌ Configuration drift over time → click ops
- ❌ No way to prove image provenance during security audits

**Common Questions:**
- "How do we know which VMs have which hardening level?"
- "We can't roll back if an image breaks production."
- "Compliance audit asked for our image build logs—we had none."
- "Our on-prem teams want the same hardened image we use in Azure, but we can't export it."

**The Cost:**
- Unplanned downtime from untested images
- Compliance violations (FedRAMP, NIST 800-53)
- Security incidents from missing patches
- Manual rework each time a new image is needed

---

### The Solution

**Declarative, Versioned, Auditable Images**

```
AIB Template (Source Control)
    ↓
Automated Build + Hardening + Tattoo
    ↓
Azure Compute Gallery (Versioned)
    ↓
Defender Scanning + Compliance Check
    ↓
Sandbox Testing + Approval (GRC)
    ↓
Deploy to Azure / Export to Hybrid
    ↓
Continuous Rebuilds (Monthly or Triggered)
```

**What You Get:**
- ✅ **Compliance**: Full audit trail (GRC tickets, build logs, image metadata tattoos)
- ✅ **Security**: Automated Defender scanning, CIS/NIST baselines, pre-installed agents
- ✅ **Speed**: Monthly automated rebuilds, same-day critical patches, repeatable process
- ✅ **Cost**: Reusable across Azure + hybrid environments (VMware, AVS, on-prem)
- ✅ **Reliability**: Immutable infrastructure, no configuration drift, rollback capability

**Reference**: See `README.md` → **Section 1 (Purpose)**

---

## Architecture & Key Concepts

### High-Level Workflow Diagram

Display the architecture from `README.md` → **Section 2.2**:

```
┌─────────────────────────────────────────────────────────────────┐
│              Image Certification Workflow                        │
└─────────────────────────────────────────────────────────────────┘

[Client Request / GRC Ticket]
           ↓
[Pre-Validation Gateway]
           ↓
[Azure Image Builder (BYOS Subnet)]
    • OS Patching
    • Agent Installation
    • Customizers (PS/Bash/DSC)
    • Image Tattooing
    • Sysprep/Generalization
           ↓
[Azure Compute Gallery]
    • Image Version Created
    • Metadata Tagged
    • Regional Replication
           ↓
[Defender for Cloud] → [Automatic Image Scanning]
           ↓
[Sandbox Testing]
    • Functional Tests
    • Integration Tests
    • Performance Validation
           ↓
[Approval & Documentation]
    • Security Review
    • GRC Sign-off
    • Artifact Package
           ↓
[Distribution]
    • Azure: VMSS, VMs, DevOps Pipelines
    • Hybrid: VHD Export → AVS/VMware
           ↓
[Continuous Update Loop]
    • Source Image Triggers
    • Scheduled Rebuilds
    • Lifecycle Policies
```

---

### Key Concepts — Deep Dive

**Reference**: `README.md` → **Section 1.1 (Key Concepts)**

Present each concept with a **What** + **Why** format:

---

#### **Concept 1: Azure Image Builder (AIB)**
- **What**: Managed service that automates OS image creation, hardening, and customization using declarative templates.
- **Why**: Removes manual image builds, ensures consistency, enables source control, integrates with CI/CD.
- **Foundation**: Built on HashiCorp Packer—Microsoft manages the infrastructure, you provide the template.

**Key Packer Integration:**
- AIB is a managed Azure wrapper around Packer
- Build logs show "PACKER OUT" and "PACKER ERR" messages
- You get Packer's proven capabilities without managing Packer yourself
- Azure handles versioning, security, and execution infrastructure

---

#### **Concept 2: Azure Compute Gallery (ACG)**
- **What**: Centralized repository for storing, versioning, and replicating VM images across regions and subscriptions.
- **Why**: Single source of truth for images, automatic regional replication, lifecycle management, Defender scanning integration.

---

#### **Concept 3: Bring Your Own Subnet (BYOS)**
- **What**: AIB feature allowing builds to run in customer-controlled VNets for network isolation.
- **Why**: Compliance requirement—builds happen in your network, not Azure's shared infrastructure.

---

#### **Concept 4: Image Tattooing**
- **What**: Embedding metadata (build ID, timestamp, customizers) into the OS registry/filesystem.
- **Why**: Audit trail—you can prove which image is on a VM, when it was built, by whom.

---

#### **Concept 5: Source Image Triggers**
- **What**: Automatic AIB rebuild when the base marketplace image is updated.
- **Why**: Keeps images current with latest OS patches; no manual intervention needed.
- **Example**: Windows Server 2022 marketplace image updated → AIB auto-rebuilds → new version published

---

### Why This Architecture Matters

**Single Image, Multiple Deployments:**
- Build once in AIB template ✅
- Publish to ACG ✅
- Deploy to Azure VMs ✅
- Deploy to Azure VMSS ✅
- Same hardening, same configuration, same audit trail everywhere

**Full Compliance Audit Trail:**
- AIB build logs → What was customized
- Image tattoo metadata → Which image is on which VM
- Build timestamps → When images were created
- Version history → Track all image releases

**Zero Configuration Drift:**
- Bake everything into the image (OS patches, agents, apps)
- Redeploy monthly even if no changes
- Immutable infrastructure = no snowflake VMs
- Azure Policy blocks post-deployment SSH/manual changes

---

### Demo — Windows Server with IIS

**Demo Scenario**: Build a Windows Server 2022 image with IIS + custom landing page, deploy it, then update it.

#### Lab Workflow Overview

This lab demonstrates the complete AIB workflow by creating two image versions:

```
┌──────────────────────────────────────────────────────────────┐
│                    Lab Workflow - Two Versions               │
└──────────────────────────────────────────────────────────────┘

📋 Part 1-2: Setup
  • Create AIB template (aib-template-windows-iis-wus3.json)
  • Create infrastructure (resource groups, gallery, identity)

🔨 Part 3-4: Build Version 1.0.1
  [Marketplace Image: Windows Server 2022]
           ↓
  [AIB Customizations]
    • Install IIS
    • Configure auto-start
    • Deploy landing page (RED/ORANGE gradient)
    • Windows Restart
           ↓
  [Azure Compute Gallery]
    • Image version 1.0.1 created
    • Metadata tagged
           ↓
  [Deploy vm-iis-test-v1]
    • Public IP assigned
    • HTTP port opened
    • Landing page: "Reboot Works!" (red/orange)

✅ Verify: http://<public-ip> shows version 1.0.1

🔄 Part 6: Build Version 2.0.1
  [Same Base Image]
           ↓
  [AIB Customizations - UPDATED]
    • Install IIS
    • Configure auto-start
    • Deploy landing page (PURPLE gradient) ← NEW
    • Windows Restart
           ↓
  [Azure Compute Gallery]
    • Image version 2.0.1 created ← NEW VERSION
    • Both 1.0.1 and 2.0.1 available
           ↓
  [Deploy vm-iis-test-v2]
    • Public IP assigned
    • HTTP port opened
    • Landing page: "Updated Template Demo!" (purple)

✅ Verify: Both VMs running side-by-side
  • vm-iis-test-v1: version 1.0.1 (red/orange)
  • vm-iis-test-v2: version 2.0.1 (purple)

🎯 Demo Outcomes:
  ✓ Versioned, reproducible images
  ✓ Visual proof of customization differences
  ✓ Rollback capability (deploy either version)
  ✓ Audit trail via image tattoo metadata
  ✓ Zero downtime (v1 runs while v2 builds)
```

**Demo Scripts Available**: 
- **Option 1 - Manual**: Follow Part 1 (Show the AIB Template), Part 2 (Create Infrastructure), Part 3 (Trigger the Build), Part 4 (Verify Image), Part 5 (Deploy VM), etc. below to run each step individually and understand the workflow
- **Option 2 - Automated**: Use the pre-built scripts in [`/demo-scripts/`](./demo-scripts/) to run infrastructure setup unattended
  - [`demo-setup.sh`](./demo-scripts/demo-setup.sh) - Creates all Azure resources (resource groups, gallery, image definition)
  - [`aib-template-windows-iis-wus3.json`](./demo-scripts/aib-template-windows-iis-wus3.json) - AIB template with IIS customization
  - [`cleanup.sh`](./demo-scripts/cleanup.sh) - Removes all demo resources

**Download Demo Scripts to Your Local Machine:**
```bash
# Clone the entire repository
git clone https://github.com/colinweiner111/image-certification-workflow.git
cd image-certification-workflow/demo-scripts

# Or download just the demo-scripts folder
mkdir -p ~/aib-demo
cd ~/aib-demo
curl -O https://raw.githubusercontent.com/colinweiner111/image-certification-workflow/master/demo-scripts/demo-setup.sh
curl -O https://raw.githubusercontent.com/colinweiner111/image-certification-workflow/master/demo-scripts/aib-template-windows-iis-wus3.json
curl -O https://raw.githubusercontent.com/colinweiner111/image-certification-workflow/master/demo-scripts/cleanup.sh
chmod +x *.sh

# Now you can run the scripts
bash demo-setup.sh
```

**Prerequisites**: Run the infrastructure setup script first (see setup section below or use `demo-setup.sh`).

---

### **Part 1: Review the AIB Template**

> 📝 **Before you begin**: Review [Azure Prerequisites](#azure-prerequisites) to ensure your environment is ready for the demo.

Open your AIB template JSON in VS Code (`C:\_Labs\demo-aib\aib-template-windows-iis-wus3.json` or [`/demo-scripts/aib-template-windows-iis-wus3.json`](./demo-scripts/aib-template-windows-iis-wus3.json)):

```json
{
  "type": "Microsoft.VirtualMachineImages/imageTemplates",
  "name": "aib-template-windows-iis-wus3",
  "location": "westus3",
  "identity": {
    "type": "UserAssigned",
    "userAssignedIdentities": {
      "/subscriptions/{sub}/resourcegroups/rg-aib-images-wus3/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aib-identity-wus3": {}
    }
  },
  "properties": {
    "buildTimeoutInMinutes": 120,
    "vmProfile": {
      "vmSize": "Standard_B2as_v2"
    },
    "source": {
      "type": "PlatformImage",
      "publisher": "MicrosoftWindowsServer",
      "offer": "WindowsServer",
      "sku": "2022-datacenter-g2",
      "version": "latest"
    },
    "customize": [
      {
        "type": "PowerShell",
        "name": "Install IIS",
        "inline": [
          "Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature",
          "Install-WindowsFeature -Name Web-Asp-Net45",
          "Set-Service -Name W3SVC -StartupType Automatic",
          "Start-Service -Name W3SVC"
        ]
      },
      {
        "type": "PowerShell",
        "name": "Deploy Custom Landing Page",
        "inline": [
          "$html = '<!DOCTYPE html><html><head><title>Welcome</title></head>'",
          "$html += '<body style=\"background: linear-gradient(135deg, #ff6b6b 0%, #ff8e53 100%); color: white; text-align: center; font-family: Segoe UI, Tahoma, sans-serif; padding: 50px;\">'",
          "$html += '<pre style=\"font-size: 1.2em; line-height: 1.2; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); margin: 20px auto; display: inline-block;\">'",
          "$html += '    ___                        '",
          "$html += '   /   |____  __  __________   '",
          "$html += '  / /| /_  / / / / / ___/ _ \\  '",
          "$html += ' / ___ |/ /_/ /_/ / /  /  __/  '",
          "$html += '/_/  |_/___/\\__,_/_/   \\___/   '",
          "$html += '                               '",
          "$html += '  Image Builder v1.0.3         '",
          "$html += '</pre>'",
          "$html += '<h1 style=\"font-size: 3em; font-weight: bold; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); margin: 30px 0;\">Welcome to Our Hardened Windows Server</h1>'",
          "$html += '<p style=\"font-size: 1.4em; font-weight: 600; margin: 20px 0;\">*** This image was built with Azure Image Builder ***</p>'",
          "$html += '<p style=\"font-size: 1.3em; font-weight: 500; background: rgba(255,255,255,0.2); padding: 15px; border-radius: 10px; display: inline-block;\">Build Version: 1.0.3 | Built: 2025-12-05 | Region: West US 3 | >> Updated with IIS Auto-Start!</p>'",
          "$html += '</body></html>'",
          "Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $html"
        ]
      }
    ],
    "distribute": [
      {
        "type": "SharedImage",
        "galleryImageId": "/subscriptions/{sub}/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.3",
        "runOutputName": "windows-iis-hardened-1.0.3",
        "replicationRegions": [
          "westus3"
        ]
      }
    ]
  }
}
```

**Files Location**: All demo files are in the repo under `/demo-scripts/`:
- `aib-template-windows-iis-wus3.json` - AIB template
- `demo-setup.sh` - Infrastructure setup script
- `cleanup.sh` - Cleanup script

**Key Template Requirements**:
- ✅ `location` field is required
- ✅ `identity` with user-assigned managed identity is required
- ✅ Source image SKU must match image definition Hyper-V generation (use `2022-datacenter-g2` for Gen2)
- ✅ `distribute` must use `SharedImage` type (not `ManagedImage`) for ACG
- ✅ Replace `{sub}` with your actual subscription ID

**Talking Point**: "This template is declarative, source-controlled, and repeatable. We can build this same image 100 times and get identical results."

---

### **Part 2: Create Infrastructure**

> **Note**: Commands shown in both **Bash** (for Linux/macOS/WSL/Cloud Shell) and **PowerShell** (for Windows) formats.

### **Manual Steps:**

1. **Create the three resource groups**:

**🐧 Bash:**
```bash
az group create --name rg-aib-images-wus3 --location westus3
az group create --name rg-acg-wus3 --location westus3
az group create --name rg-demo-wus3 --location westus3
```

**💻 PowerShell:**
```powershell
az group create --name rg-aib-images-wus3 --location westus3
az group create --name rg-acg-wus3 --location westus3
az group create --name rg-demo-wus3 --location westus3
```

**Messages:**
- "We separate resources into three groups for security and lifecycle management."
- "Build infrastructure (rg-aib-images-wus3) can be deleted without affecting stored images."
- "Gallery (rg-acg-wus3) persists image versions long-term."
- "Demo VMs (rg-demo-wus3) are ephemeral for testing."

2. **Create managed identity**:

**🐧 Bash:**
```bash
az identity create \
  --resource-group rg-aib-images-wus3 \
  --name aib-identity-wus3 \
  --location westus3
```

**💻 PowerShell:**
```powershell
az identity create --resource-group rg-aib-images-wus3 --name aib-identity-wus3 --location westus3
```

3. **Assign Contributor role to the identity on the gallery resource group**:

**🐧 Bash:**
```bash
# Get the principal ID
principalId=$(az identity show \
  --resource-group rg-aib-images-wus3 \
  --name aib-identity-wus3 \
  --query principalId -o tsv)

# Assign the role
az role assignment create \
  --assignee-object-id $principalId \
  --role Contributor \
  --scope /subscriptions/{sub}/resourceGroups/rg-acg-wus3 \
  --assignee-principal-type ServicePrincipal
```

**💻 PowerShell:**
```powershell
# Get the principal ID
$principalId = az identity show --resource-group rg-aib-images-wus3 --name aib-identity-wus3 --query principalId -o tsv

# Get subscription ID
$subscriptionId = az account show --query id -o tsv

# Assign the role
az role assignment create --assignee-object-id $principalId --role Contributor --scope "/subscriptions/$subscriptionId/resourceGroups/rg-acg-wus3" --assignee-principal-type ServicePrincipal
```

**Talking Point**: "The managed identity needs Contributor access to publish images to the gallery. This follows least-privilege principles."

4. **Create Azure Compute Gallery**:

**🐧 Bash:**
```bash
az sig create \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --location westus3
```

**💻 PowerShell:**
```powershell
az sig create --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --location westus3
```

**Talking Point**: "The gallery is our version-controlled image repository. It supports multi-region replication and RBAC."

5. **Create Image Definition**:

**🐧 Bash:**
```bash
az sig image-definition create \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --publisher MyCompany \
  --offer WindowsServer \
  --sku 2022-IIS \
  --os-type Windows \
  --os-state Generalized \
  --hyper-v-generation V2 \
  --features SecurityType=TrustedLaunch \
  --location westus3
```

**💻 PowerShell:**
```powershell
az sig image-definition create --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --publisher MyCompany --offer WindowsServer --sku 2022-IIS --os-type Windows --os-state Generalized --hyper-v-generation V2 --features SecurityType=TrustedLaunch --location westus3
```

**Messages:**
- "The image definition is like a container for versions - 1.0.1, 1.0.2, 1.0.3, etc."
- "We're specifying Gen2 and TrustedLaunch for enhanced security."
- "Publisher/Offer/SKU helps us organize different image families."

---

### **Part 3: Trigger the Build**

### **Manual Steps:**

1. **Create the AIB template resource** (first time only):

**🐧 Bash:**
```bash
az image builder create \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --image-template aib-template-windows-iis-wus3.json
```

**💻 PowerShell:**
```powershell
az image builder create --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3 --image-template aib-template-windows-iis-wus3.json
```

**Note**: If you get a conflict error about template already existing, delete it first:

**🐧 Bash:**
```bash
az image builder delete --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3
```

**💻 PowerShell:**
```powershell
az image builder delete --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3
```

2. **Trigger the build**:

   > ⏱️ **Note**: This build process takes approximately **30-35 minutes** to complete.

**🐧 Bash:**
```bash
az image builder run \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --no-wait

echo "Build started. Monitoring progress..."
```

**💻 PowerShell:**
```powershell
az image builder run --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3 --no-wait

Write-Host "Build started. Monitoring progress..."
```

3. **Check build status** (run this every few minutes to monitor progress):

**🐧 Bash:**
```bash
# Check current run status
az image builder show \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --query "lastRunStatus"

# Expected output during build:
# {
#   "runState": "Running",
#   "runSubState": "Building",
#   "startTime": "2025-12-06T00:56:01.816893+00:00"
# }

# Check all historical runs
az image builder show-runs \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --query "[0].[runState, runOutputName]" -o table
```

**💻 PowerShell:**
```powershell
# Check current run status
az image builder show --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3 --query "lastRunStatus"

# Check all historical runs
az image builder show-runs --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3 --query "[0].[runState, runOutputName]" -o table
```

---

### **Part 4: Verify Image in ACG**

### **Manual Steps:**

1. **List all image versions**:

**🐧 Bash:**
```bash
az sig image-version list \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --output table
```

**💻 PowerShell:**
```powershell
az sig image-version list --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --output table
```

2. **Show image metadata (tattoo)**:

   > ⚠️ **Note**: Make sure the version number matches what you built. If you're following this test run, use `1.0.3` instead of `1.0.1`.

**🐧 Bash:**
```bash
az sig image-version show \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --gallery-image-version 1.0.1 \
  --query "{Version:name, PublishedDate:publishingProfile.publishedDate, SourceImage:tags.VMImageBuilderSource, CorrelationId:tags.correlationId, DateCreated:tags.DateCreated}" \
  --output table
```

**💻 PowerShell:**
```powershell
az sig image-version show --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --gallery-image-version 1.0.1 --query "{Version:name, PublishedDate:publishingProfile.publishedDate, SourceImage:tags.VMImageBuilderSource, CorrelationId:tags.correlationId, DateCreated:tags.DateCreated}" --output table
```

**Messages:**
- "The image is now versioned and available for deployment."
- "Defender automatically scanned it for vulnerabilities within 24 hours."
- "The metadata tattoo proves who built it, when, and what was customized."

---

### **Part 5: Deploy VM from Gallery Image**

### **Manual Steps:**

1. **Deploy VM from ACG image**:

   > ⚠️ **Note**: Update the version number in the `--image` path to match what you built (e.g., `1.0.3` instead of `1.0.1`).

**🐧 Bash:**
```bash
az vm create \
  --resource-group rg-demo-wus3 \
  --name vm-iis-test-v1 \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.1" \
  --size Standard_B2as_v2 \
  --admin-username azureuser \
  --admin-password "ComplexPassword123!" \
  --nsg-rule RDP \
  --public-ip-sku Standard \
  --security-type TrustedLaunch
```

**💻 PowerShell:**
```powershell
# Get subscription ID
$subscriptionId = az account show --query id -o tsv

# Deploy VM
az vm create --resource-group rg-demo-wus3 --name vm-iis-test-v1 --image "/subscriptions/$subscriptionId/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.1" --size Standard_B2as_v2 --admin-username azureuser --admin-password "ComplexPassword123!" --nsg-rule RDP --public-ip-sku Standard --security-type TrustedLaunch
```

2. **Open HTTP port 80**:

**🐧 Bash:**
```bash
# Get NSG name
nsgName=$(az network nsg list --resource-group rg-demo-wus3 --query "[0].name" -o tsv)

# Add HTTP rule
az network nsg rule create \
  --resource-group rg-demo-wus3 \
  --nsg-name $nsgName \
  --name AllowHTTP \
  --priority 1001 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow
```

**💻 PowerShell:**
```powershell
# Get NSG name
$nsgName = az network nsg list --resource-group rg-demo-wus3 --query "[0].name" -o tsv

# Add HTTP rule
az network nsg rule create --resource-group rg-demo-wus3 --nsg-name $nsgName --name AllowHTTP --priority 1001 --destination-port-ranges 80 --protocol Tcp --access Allow
```

3. **Get the public IP**:

**🐧 Bash:**
```bash
publicIp=$(az vm show \
  --resource-group rg-demo-wus3 \
  --name vm-iis-test-v1 \
  --show-details \
  --query publicIps -o tsv)

echo "VM deployed! Access it at: http://$publicIp"
```

**💻 PowerShell:**
```powershell
$publicIp = az vm show --resource-group rg-demo-wus3 --name vm-iis-test-v1 --show-details --query publicIps -o tsv

Write-Host "VM deployed! Access it at: http://$publicIp"
```

**Verify**: Open a browser and navigate to the public IP. The custom IIS landing page is immediately available—everything was baked into the image.

---

### **Part 6: Update the Image & Redeploy**

For this demo, we'll use a separate JSON template file (v2) to avoid any confusion with version numbers and to show how you can maintain multiple template configurations in parallel. In production, you'd typically update the existing template and use Git as your source of truth—but for demo purposes, this approach keeps things crystal clear.

**🔍 Important Note for Production:**
In a real-world enterprise scenario, you would:
1. Update the **existing** JSON file with your changes (modify version number, update customizers, etc.)
2. **Delete** the existing Azure template resource: `az image builder delete --name aib-template-windows-iis-wus3`
3. **Recreate** it with the same name from your updated JSON: `az image builder create --name aib-template-windows-iis-wus3`
4. Build the new version to the same gallery definition

> **📚 Reference**: [Azure Image Builder overview - Microsoft Learn](https://learn.microsoft.com/azure/virtual-machines/image-builder-overview)  
> **Best Practice**: Use a single template per image definition (e.g., one template for "windows-iis-hardened"). The template is ephemeral—your JSON file in Git is the source of truth. Image versioning happens in the Azure Compute Gallery (1.0.1, 1.0.2, etc.), not by creating multiple templates. This follows Infrastructure as Code principles and keeps your resource management clean.

### **Manual Steps:**

1. **Use the new v2 template** (already created: `aib-template-windows-iis-wus3-v2.json`):
   - **New version**: 2.0.1 (purple gradient landing page)
   - **IIS auto-start fix**: WindowsRestart customizer ensures IIS starts on first boot
   - **Visual difference**: Purple theme vs red/orange (easy to distinguish in demo)

2. **Create the new template** (no delete needed - this is a brand new template):

**🐧 Bash:**
```bash
# Create new template with v2 configuration
az image builder create \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3-v2 \
  --image-template aib-template-windows-iis-wus3-v2.json
```

**💻 PowerShell:**
```powershell
# Create new template with v2 configuration
az image builder create --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3-v2 --image-template aib-template-windows-iis-wus3-v2.json
```

3. **Trigger new build**:

**🐧 Bash:**
```bash
az image builder run \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3-v2 \
  --no-wait

# Monitor build progress
az image builder show \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3-v2 \
  --query "lastRunStatus"
```

**💻 PowerShell:**
```powershell
az image builder run --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3-v2 --no-wait

# Monitor build progress
az image builder show --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3-v2 --query "lastRunStatus"
```

**⏱️ Build Time**: ~30-40 minutes (use this time to discuss architecture, compliance, hybrid export capabilities)

4. **Once complete (Succeeded), verify in gallery**:

**🐧 Bash:**
```bash
az sig image-version list \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --output table
```

**💻 PowerShell:**
```powershell
az sig image-version list --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --output table
```

5. **Deploy NEW VM from version 2.0.1**:

**🐧 Bash:**
```bash
az vm create \
  --resource-group rg-demo-wus3 \
  --name vm-iis-test-v2 \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/2.0.1" \
  --size Standard_B2as_v2 \
  --admin-username azureuser \
  --admin-password "Password123!" \
  --public-ip-sku Standard \
  --nsg-rule RDP \
  --security-type TrustedLaunch
```

**💻 PowerShell:**
```powershell
$subscriptionId = az account show --query id -o tsv

az vm create --resource-group rg-demo-wus3 --name vm-iis-test-v2 --image "/subscriptions/$subscriptionId/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/2.0.1" --size Standard_B2as_v2 --admin-username azureuser --admin-password "Password123!" --public-ip-sku Standard --nsg-rule RDP --security-type TrustedLaunch
```

6. **Open HTTP port**:

**🐧 Bash:**
```bash
nsgName=$(az network nsg list --resource-group rg-demo-wus3 --query "[?contains(name, 'vm-iis-test-v2')].name" -o tsv)

az network nsg rule create \
  --resource-group rg-demo-wus3 \
  --nsg-name $nsgName \
  --name AllowHTTP \
  --priority 1001 \
  --destination-port-ranges 80 \
  --protocol Tcp \
  --access Allow
```

**💻 PowerShell:**
```powershell
$nsgName = az network nsg list --resource-group rg-demo-wus3 --query "[?contains(name, 'vm-iis-test-v2')].name" -o tsv

az network nsg rule create --resource-group rg-demo-wus3 --nsg-name $nsgName --name AllowHTTP --priority 1001 --destination-port-ranges 80 --protocol Tcp --access Allow
```

7. **Get public IP and test the landing page**:

**💻 PowerShell:**
```powershell
$publicIp = az vm show --resource-group rg-demo-wus3 --name vm-iis-test-v2 --show-details --query publicIps -o tsv
Write-Host "Browse to: http://$publicIp"
Start-Process "http://$publicIp"
```

**Highlights:**
- **Version 1.0.1** (red/orange) vs **Version 2.0.1** (purple) - visual proof of versioning
- **IIS auto-start fixed** - Windows restart during build ensures services start on first boot
- **Git as source of truth** - Templates stored in GitHub, Azure resources are ephemeral
- **Rollback capability** - Can deploy either version at any time from the gallery

8. **Show both image versions in the gallery**:

**🐧 Bash:**
```bash
az vm list \
  --resource-group rg-demo-wus3 \
  --show-details \
  --query "[].{Name:name, PublicIP:publicIps}" -o table
```

**💻 PowerShell:**
```powershell
az vm list --resource-group rg-demo-wus3 --show-details --query "[].{Name:name, PublicIP:publicIps}" -o table
```

8. **Browse to both IPs to see visual difference**:
   - vm-iis-test-v1: Version 1.0.1 landing page (red/orange gradient)
   - vm-iis-test-v2: Version 2.0.1 landing page (purple gradient)

---

### **Part 7: Verify Image Metadata**

### **Manual Steps:**

1. **Query the image version metadata from the Azure Compute Gallery**:

**🐧 Bash:**
```bash
# Show the image tattoo (provenance metadata) for version 1.0.1
az sig image-version show \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --gallery-image-version 1.0.1 \
  --query "{Name:name, PublishedDate:publishingProfile.publishedDate, SourceImage:tags.VMImageBuilderSource, CorrelationId:tags.correlationId}" \
  --output json
```

**💻 PowerShell:**
```powershell
az sig image-version show --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --gallery-image-version 1.0.1 --query "{Name:name, PublishedDate:publishingProfile.publishedDate, SourceImage:tags.VMImageBuilderSource, CorrelationId:tags.correlationId}" --output json
```

**Output example**:
```json
{
  "CorrelationId": "5d49a6f3-7195-4df5-99c3-edee245be4b6",
  "Name": "1.0.1",
  "PublishedDate": "2025-12-06T01:18:37.5837189+00:00",
  "SourceImage": "PlatformImage MicrosoftWindowsServer::WindowsServer::2022-datacenter-g2::latest (20348.4405.251112)"
}
```

2. **Show all tags for complete audit trail**:

**🐧 Bash:**
```bash
az sig image-version show \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --gallery-image-version 1.0.1 \
  --query "tags" \
  --output json
```

**💻 PowerShell:**
```powershell
az sig image-version show --resource-group rg-acg-wus3 --gallery-name acg_corp_images_wus3 --gallery-image-definition windows-iis-hardened --gallery-image-version 1.0.1 --query "tags" --output json
```

**Messages:**
- "The image tattoo is automatically embedded by Azure Image Builder in the gallery image version tags."
- "This shows the exact source image (Windows Server 2022 build 20348.4405), publication timestamp, and unique correlation ID."
- "During security audits, we can prove the complete provenance chain: source image → AIB template → gallery version → deployed VM."
- "If a CVE is discovered in build 20348.4405, we can instantly query which images and VMs are affected."
- "Full compliance with audit requirements - immutable metadata that can't be tampered with."

---

**Resource Group Architecture:**

The demo uses three separate resource groups for security and lifecycle management:

| Resource Group | Purpose | Contains |
|---------------|---------|----------|
| **rg-aib-images-wus3** | Build infrastructure | AIB templates, managed identities, build VMs (temporary) |
| **rg-acg-wus3** | Image storage | Azure Compute Gallery, image definitions, image versions |
| **rg-demo-wus3** | Test deployments | VMs deployed from gallery for testing/validation |

**Why separate resource groups?**
- ✅ **Security**: Different teams get different permissions (developers read gallery, only DevOps triggers builds)
- ✅ **Lifecycle**: Delete build resources without affecting stored images
- ✅ **Cost tracking**: See costs per function (building vs storage vs testing)
- ✅ **Replication**: Gallery can replicate across regions independently

---

**Automated Setup:**
Create a `demo-setup.sh` script to automate all infrastructure creation:

```bash
#!/bin/bash
# AIB Demo Commands - Run these in order

# Step 1: Create Resource Groups
echo "Creating resource groups..."
az group create --name rg-aib-images-wus3 --location westus3
az group create --name rg-acg-wus3 --location westus3
az group create --name rg-demo-wus3 --location westus3

# Step 2: Create Managed Identity for AIB
echo "Creating managed identity..."
az identity create \
  --resource-group rg-aib-images-wus3 \
  --name aib-identity-wus3 \
  --location westus3

# Get the identity IDs
identityPrincipalId=$(az identity show --resource-group rg-aib-images-wus3 --name aib-identity-wus3 --query principalId -o tsv)

# Step 3: Assign Contributor role to identity on gallery resource group
echo "Assigning Contributor role (waiting 10 seconds for identity replication)..."
sleep 10
az role assignment create \
  --assignee $identityPrincipalId \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/rg-acg-wus3

# Step 4: Create Azure Compute Gallery
echo "Creating Azure Compute Gallery..."
az sig create \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --location westus3

# Step 5: Create Image Definition
echo "Creating image definition..."
az sig image-definition create \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --publisher MyCompany \
  --offer WindowsServer \
  --sku 2022-IIS \
  --os-type Windows \
  --os-state Generalized \
  --hyper-v-generation V2 \
  --features SecurityType=TrustedLaunch \
  --location westus3

# Step 6: Get your subscription ID (you'll need this for the template)
echo ""
echo "Your subscription ID:"
az account show --query id -o tsv

echo ""
echo "Now update the aib-template-windows-iis-wus3.json file with your subscription ID"
echo "Then create the AIB template resource with:"
echo "az image builder create --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3 --image-template aib-template-windows-iis-wus3.json"
```

**Cleanup Script** (for resetting demo environment):
```bash
#!/bin/bash
# Cleanup all demo resources
az group delete --name rg-aib-images-wus3 --yes --no-wait
az group delete --name rg-acg-wus3 --yes --no-wait
az group delete --name rg-demo-wus3 --yes --no-wait
```

---

#### **Azure Prerequisites**

Before the demo, ensure you have:

**Shell Environment:**
- ✅ **Bash shell** - Use one of the following:
  - **Azure Cloud Shell** (recommended - no local setup needed)
  - **WSL (Windows Subsystem for Linux)** on Windows
  - **Git Bash** on Windows
  - **Native bash** on macOS/Linux
- ✅ Azure CLI installed and authenticated (`az login`) - pre-installed in Cloud Shell

**Azure Subscription & Permissions:**
- ✅ Active Azure subscription with owner or contributor access
- ✅ Ability to create Resource Groups, Storage Accounts, and Role Assignments
- ✅ Azure Image Builder resource provider registered (`Microsoft.VirtualMachineImages`)
- ✅ Compute Gallery (ACG) resource provider registered (`Microsoft.Compute`)

**Required Azure Services:**
- ✅ Azure Image Builder (AIB) — enabled in your subscription
- ✅ Azure Compute Gallery (ACG) — create a gallery and image definition
- ✅ Azure Storage Account — for AIB staging artifacts
- ✅ Azure Virtual Network (VNet) — for demo VM deployment
- ✅ Network Security Group (NSG) — with RDP (port 3389) and HTTPS (port 443) rules

---

## Cleanup

After completing the demo, clean up all resources to avoid ongoing costs:

**🐧 Bash:**
```bash
# Delete all demo resource groups
az group delete --name rg-demo-wus3 --yes --no-wait
az group delete --name rg-aib-images-wus3 --yes --no-wait
az group delete --name rg-acg-wus3 --yes --no-wait
```

**💻 PowerShell:**
```powershell
# Delete all demo resource groups
az group delete --name rg-demo-wus3 --yes --no-wait
az group delete --name rg-aib-images-wus3 --yes --no-wait
az group delete --name rg-acg-wus3 --yes --no-wait
```

**What gets deleted:**
- All VMs and associated resources (NICs, disks, public IPs, NSGs)
- Azure Image Builder templates and staging resources
- Azure Compute Gallery with all image versions
- Managed identities and role assignments

**⚠️ Important Notes:**
- The `--no-wait` flag allows deletion to run in the background
- Deletion typically takes 5-10 minutes to complete
- You can verify deletion in the Azure Portal or by running:
  ```bash
  az group list --output table
  ```
