## POC - Hybrid Image Workshop

---

### The Challenge

**Current Reality:**
- ❌ Manual image builds on VMs → no audit trail, no versioning
- ❌ Marketplace images deployed directly to production → not hardened, no compliance
- ❌ Configuration drift over time → "works on my VM" problem
- ❌ No way to prove image provenance during security audits

**What Teams Are Asking:**
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

**Key Takeaway:**  
"Every image has a complete audit trail from request through production, with no manual steps."

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
- **Query Example**:
  ```powershell
  # Windows
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure Image Builder"
  
  # Linux
  cat /var/lib/azure-image-builder/metadata.json | jq
  ```

---

#### **Concept 5: Source Image Triggers**
- **What**: Automatic AIB rebuild when the base marketplace image is updated.
- **Why**: Keeps images current with latest OS patches; no manual intervention needed.
- **Example**: Windows Server 2022 marketplace image updated → AIB auto-rebuilds → new version published

---

#### **Concept 6: GRC (Governance, Risk, Compliance)**
- **What**: Tracking system for image certification requests, approvals, audit trails.
- **Why**: Audit requirement—prove who requested, who approved, what changed.

---

#### **Concept 7: VHD Export (Hybrid Environments)**
- **What**: Portable disk format for exporting images to on-prem (VMware, Hyper-V, AVS).
- **Why**: "Build once in Azure, run anywhere."

---

### Why This Architecture Matters

**Single Image, Multiple Environments:**
- Build once in AIB template ✅
- Publish to ACG ✅
- Deploy to Azure VMSS ✅
- Export as VHD for VMware/AVS ✅
- Same hardening, same configuration, same audit trail everywhere

**Full Compliance Audit Trail:**
- GRC ticket + build timestamp → Request provenance
- AIB build logs → What was customized
- Image tattoo metadata → Which image is on which VM
- Defender scan results → Vulnerability assessment
- Approval sign-off → Authorization

**Zero Configuration Drift:**
- Bake everything into the image (OS patches, agents, apps)
- Redeploy monthly even if no changes
- Immutable infrastructure = no snowflake VMs
- Azure Policy blocks post-deployment SSH/manual changes

---

### Live Lab Demo — Windows Server with IIS

**Demo Scenario**: Build a Windows Server 2022 image with IIS + custom landing page, deploy it, then update it.

**Demo Scripts Available**: 
- **Option 1 - Manual**: Follow Part 1, Part 2, Part 3, etc. below to run each step individually and understand the workflow
- **Option 2 - Automated**: Use the pre-built scripts in [`/demo-scripts/`](./demo-scripts/) to run infrastructure setup unattended
  - [`demo-setup.sh`](./demo-scripts/demo-setup.sh) - Creates all Azure resources (resource groups, gallery, image definition)
  - [`aib-template-windows-iis.json`](./demo-scripts/aib-template-windows-iis.json) - AIB template with IIS customization
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
curl -O https://raw.githubusercontent.com/colinweiner111/image-certification-workflow/master/demo-scripts/aib-template-windows-iis.json
curl -O https://raw.githubusercontent.com/colinweiner111/image-certification-workflow/master/demo-scripts/cleanup.sh
chmod +x *.sh

# Now you can run the scripts
bash demo-setup.sh
```

**Prerequisites**: Run the infrastructure setup script first (see setup section below or use `demo-setup.sh`).

---

#### **Part 1: Show the AIB Template**

Open your AIB template JSON in VS Code (`C:\_Labs\demo-aib\aib-template-windows-iis.json` or [`/demo-scripts/aib-template-windows-iis.json`](./demo-scripts/aib-template-windows-iis.json)):

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
          "Set-Service -Name W3SVC -StartupType Automatic"
        ]
      },
      {
        "type": "PowerShell",
        "name": "Deploy Custom Landing Page",
        "inline": [
          "$html = '<!DOCTYPE html><html><head><title>Welcome</title></head>'",
          "$html += '<body style=\"background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; font-family: Arial;\">'",
          "$html += '<h1>Welcome to Our Hardened Windows Server</h1>'",
          "$html += '<p>This image was built with Azure Image Builder</p>'",
          "$html += '<p>Build Version: 1.0.1 | Built: 2025-12-05 | Region: West US 3</p>'",
          "$html += '</body></html>'",
          "Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $html"
        ]
      }
    ],
    "distribute": [
      {
        "type": "SharedImage",
        "galleryImageId": "/subscriptions/{sub}/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.1",
        "runOutputName": "windows-iis-hardened-1.0.1",
        "replicationRegions": [
          "westus3"
        ]
      }
    ]
  }
}
```

**Files Location**: All demo files are in the repo under `/demo-scripts/`:
- `aib-template-windows-iis.json` - AIB template
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

#### **Part 2: Trigger the Build**

**Prerequisites** (if not using demo-setup.sh):

1. **Create managed identity and grant permissions**:
```bash
# Create identity
az identity create \
  --resource-group rg-aib-images \
  --name aib-identity

# Get the client ID
clientId=$(az identity show \
  --resource-group rg-aib-images \
  --name aib-identity \
  --query clientId -o tsv)

# Grant Contributor access to ACG resource group
az role assignment create \
  --assignee $clientId \
  --role "Contributor" \
  --scope "/subscriptions/{sub}/resourceGroups/rg-acg"
```

2. **Update template with your subscription ID**:
```bash
# Get subscription ID
subId=$(az account show --query id -o tsv)
echo "Your subscription ID: $subId"

# Manually replace {sub} in aib-template-windows-iis.json
# Or use sed:
sed "s/{sub}/$subId/g" aib-template-windows-iis.json > aib-template-windows-iis-updated.json
```

**Manual Steps:**

1. **Create the AIB template resource** (first time only):
```bash
az image builder create \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --image-template aib-template-windows-iis-wus3.json
```

**Note**: If you get a conflict error about template already existing, delete it first:
```bash
az image builder delete --resource-group rg-aib-images-wus3 --name aib-template-windows-iis-wus3
```

2. **Trigger the build**:
```bash
az image builder run \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --no-wait

echo "Build started. Monitoring progress..."
```

3. **Check build status**:
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

**Demo Note**: For a live customer call, you'd either:
- Pre-stage a completed build to show results immediately
- Show a build-in-progress and explain the timeline
- Show historical builds to demonstrate success rate

---

#### **Part 3: Verify Image in ACG**

**Manual Steps:**

1. **List all image versions**:
```bash
az sig image-version list \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --output table
```

2. **Show image metadata (tattoo)**:
```bash
az sig image-version show \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --gallery-image-version 1.0.1 \
  --output json | jq '.tags'
```

**Talking Points:**
- "The image is now versioned, replicated to 3 regions, and available for deployment."
- "Defender automatically scanned it for vulnerabilities within 24 hours."
- "The metadata tattoo proves who built it, when, and what was customized."

---

#### **Part 4: Deploy VM from Gallery Image**

**Manual Steps:**

1. **Deploy VM from ACG image**:
```bash
az vm create \
  --resource-group rg-demo-wus3 \
  --name vm-iis-demo-001 \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.1" \
  --size Standard_B2as_v2 \
  --admin-username azureuser \
  --admin-password "ComplexPassword123!" \
  --nsg-rule RDP \
  --public-ip-sku Standard
```

2. **Get the public IP**:
```bash
publicIp=$(az vm show \
  --resource-group rg-demo-wus3 \
  --name vm-iis-demo-001 \
  --show-details \
  --query publicIps -o tsv)

echo "VM deployed! Access it at: http://$publicIp"
```

**Demo**: Open a browser and navigate to the public IP to show the custom landing page is already there (no post-deployment installation needed).

**Talking Point**: "The image arrived fully configured with IIS and our landing page. No manual setup, no configuration drift, completely reproducible."

---

#### **Part 5: Update the Image & Redeploy**

**Manual Steps:**

1. **Edit the template** - Update version to 1.0.2 and change landing page style:
   - Change gradient colors from purple to orange/red (`#ff6b6b` to `#ff8e53`)
   - Add ASCII art logo
   - Update version text to "1.0.2"
   - **Important**: Avoid using emoji characters in PowerShell inline scripts (UTF-8 encoding issues)

2. **Delete the old template and recreate with updated JSON**:
```bash
# AIB doesn't support updates - must delete and recreate
az image builder delete \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3

az image builder create \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --image-template aib-template-windows-iis-wus3.json
```

3. **Trigger new build**:
```bash
az image builder run \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --no-wait

# Monitor build progress
az image builder show \
  --resource-group rg-aib-images-wus3 \
  --name aib-template-windows-iis-wus3 \
  --query "lastRunStatus"
```

4. **Once complete (Succeeded), verify in gallery**:
```bash
az sig image-version list \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --output table
```

5. **Deploy NEW VM from version 1.0.2**:
```bash
az vm create \
  --resource-group rg-demo-wus3 \
  --name vm-iis-test-002 \
  --image "/subscriptions/f4c81bdc-9009-4c72-89ae-f96947f57d27/resourceGroups/rg-acg-wus3/providers/Microsoft.Compute/galleries/acg_corp_images_wus3/images/windows-iis-hardened/versions/1.0.2" \
  --size Standard_B2s \
  --admin-username azureuser \
  --admin-password "P@ssw0rd123!AzureVM" \
  --public-ip-sku Standard \
  --nsg-rule RDP

# Open HTTP port
az vm open-port \
  --resource-group rg-demo-wus3 \
  --name vm-iis-test-002 \
  --port 80 \
  --priority 1001
```

6. **Show both VMs running with different versions**:
```bash
az vm list \
  --resource-group rg-demo-wus3 \
  --show-details \
  --query "[].{Name:name, PublicIP:publicIps}" -o table
```

7. **Browse to both IPs to see visual difference**:
   - vm-iis-test-001: Purple gradient (version 1.0.1)
   - vm-iis-test-002: Orange gradient with ASCII art (version 1.0.2)

**Talking Points:**
- "We updated the template, triggered a new build (30-35 min), and deployed v1.0.2 in parallel with v1.0.1."
- "Zero downtime. Existing VMs on v1.0.1 stay running while new deployments get v1.0.2."
- "Rollback is instant: just deploy from v1.0.1 again or update VMSS model."
- "Both versions remain in the gallery - immutable version history for compliance."

---

#### **Part 6: Show Image Tattoo (Provenance Metadata)**

**Manual Steps:**

1. **Query the image version metadata from the Azure Compute Gallery**:

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

```bash
az sig image-version show \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --gallery-image-definition windows-iis-hardened \
  --gallery-image-version 1.0.1 \
  --query "tags" \
  --output json
```

**Talking Points:**
- "The image tattoo is automatically embedded by Azure Image Builder in the gallery image version tags."
- "This shows the exact source image (Windows Server 2022 build 20348.4405), publication timestamp, and unique correlation ID."
- "During security audits, we can prove the complete provenance chain: source image → AIB template → gallery version → deployed VM."
- "If a CVE is discovered in build 20348.4405, we can instantly query which images and VMs are affected."
- "Full compliance with audit requirements - immutable metadata that can't be tampered with."

---

**Total Demo Time**: 10 minutes  
**Audience Impact**: High—shows real-world hardening workflow, reproducibility, versioning, and audit trail all in action.

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

# Step 2: Create Azure Compute Gallery
echo "Creating Azure Compute Gallery..."
az sig create \
  --resource-group rg-acg-wus3 \
  --gallery-name acg_corp_images_wus3 \
  --location westus3

# Step 3: Create Image Definition
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

# Step 4: Get your subscription ID (you'll need this for the template)
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

**Demo Tools:**
- ✅ VS Code (optional but recommended for showing templates)
- ✅ Web browser for testing deployed IIS landing page
- ✅ RDP client for Windows VM access
- ✅ Two monitors recommended (one for terminal, one for browser/Portal)

**Demo-Specific Setup:**
- ✅ Run `demo-setup.sh` to create all infrastructure
- ✅ AIB template JSON file created and ready (see Part 1)
- ✅ Pre-staged AIB build running or recently completed
- ✅ At least one image version published in ACG
- ✅ Test VM deployed from gallery image (pre-built, running)
- ✅ RDP credentials saved and tested

---

#### **Pre-Demo Setup Checklist**

Before the customer call:
- [ ] Run `demo-setup.sh` to create infrastructure
- [ ] Create AIB template JSON (use template above)
- [ ] Pre-stage a completed build (or have one running)
- [ ] Verify ACG has the image versions published
- [ ] Test VM deployment from gallery image once
- [ ] Verify IIS landing page loads correctly in browser
- [ ] Test RDP access to a VM
- [ ] Have VS Code open with template ready
- [ ] Prepare PowerShell terminal with commands in a script file
- [ ] Set up two monitors (one for terminal, one for browser/Portal)

---

#### **If Build Fails or Times Out During Demo**

**Fallback Plan**:
1. Show the AIB template in VS Code
2. Show historical builds in the Portal (successful v1.0.0 and v1.0.1)
3. Show the images in ACG with replication status
4. Deploy from the latest version
5. Show the landing page in browser
6. Query the image tattoo from a deployed VM

This gives 90% of the impact without waiting for a live build.

---

## Production Requirements & Cost Management

### Security Agent Strategy

**Reference**: `README.md` → **Section 3.8 (Agent Management Strategy)**

| Component | Deployment Method | Update Strategy | Reasoning |
|-----------|------------------|-----------------|-----------|
| Azure Monitor Agent | **Baked-in** | Rebuild monthly | Core monitoring requirement |
| Microsoft Defender | **Baked-in** | Rebuild + auto-update | Security baseline |
| Custom LOB Agents | **Baked-in** | Rebuild when updated | Configuration drift prevention |
| Azure Extensions | Post-deployment | VM Extension auto-update | Azure-managed lifecycle |
| Application Software | Post-deployment | App-specific update tool | Rapid iteration needs |

**Why This Matters:**
- ✅ Baked-in = guaranteed on every VM, no drift, auditable
- ❌ Post-deployment = potential failures, inconsistency, hard to track
- **Rule**: If it's critical to your hardening baseline, bake it in.

---

### Production Compliance Checklist

**Compliance Notes:**

- ✅ Production images require FedRAMP/NIST 800-53 alignment
- ✅ GRC ticket retention: 7 years minimum
- ✅ All production builds must have tamper-proof audit trail
- ✅ Critical patches require post-implementation review within 72 hours
- ✅ Image tattoo metadata must be queryable for audit compliance
- ✅ Defender scan results reviewed by security team before release

**Ask the Customer:**
- "Do you have an existing FedRAMP/NIST certification?"
- "What's your GRC system today?"
- "Who signs off on image releases?"

---

### Cost Breakdown & Optimization

**Reference**: `README.md` → **Section 3.8 (Cost Management)**

**Monthly Cost Estimates (Example):**

| Resource | Configuration | Monthly Cost (USD) |
|----------|--------------|-------------------|
| AIB Build VM | Standard_D4s_v5, 2h/week | ~$15 |
| ACG Storage | 3 image versions, 30GB each | ~$5 |
| ACG Replication | 3 regions, 3 versions | ~$10 |
| Defender Scanning | Included (Plan 2/CSPM) | — |
| Network Egress | VHD downloads | ~$5–50 |
| **Total** | | **~$35–80/month** |

**Cost Optimization Tips:**
1. Keep only 3–5 versions, auto-retire old ones
2. Replicate only to regions where VMs deploy
3. Use B-series burstable VMs for small images, D-series for complex builds

**Ask the Customer:**
- "What's your current image build/storage spend?"
- "How many regions do you deploy to?"
- "How long do you retain image versions?"

---

### Critical Patching Procedure

**Reference**: `README.md` → **Section 3.8 (Critical Patching)**

**Scenario**: Critical CVE discovered in Windows Server 2022

**Response Timeline:**
1. **Identify Scope**: Query all VMs using vulnerable image
2. **Emergency Build** (1 hour): Trigger AIB with expedited approval
3. **Deploy Updated Image** (1 hour): Use VMSS rolling upgrade to apply new image
4. **Verify Remediation**: Re-scan with Defender

**Total SLA**: **24 hours from discovery to remediated VMs**

---

## Anti-Patterns & Real-World Lessons (Bonus)

### What NOT to Do

**Reference**: `README.md` → **Section 4.5 (Anti-Patterns & Common Mistakes)**

**Top 5 Mistakes:**

1. ❌ **Building Images Manually on a VM**
   - Problem: No audit trail, no versioning, configuration drift
   - Fix: Always use AIB with source-controlled templates

2. ❌ **Using Marketplace Images Directly in Production**
   - Problem: Not hardened, missing agents, not compliant
   - Fix: Marketplace → AIB customizers → ACG → Production

3. ❌ **Deploying Images Older Than 90 Days**
   - Problem: Missing security patches, high CVE count
   - Fix: Enforce ACG lifecycle policies, monthly rebuilds

4. ❌ **Skipping Image Tattooing**
   - Problem: Can't prove image provenance, audit failure
   - Fix: Always enable metadata embedding

5. ❌ **Not Testing Images Before Production**
   - Problem: Boot failures, agent issues, downtime
   - Fix: Always validate in sandbox first