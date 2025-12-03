
# Azure Image Builder Image Creation, Certification & Continuous Update Workflow
### Using Azure Image Builder (AIB) + Azure Compute Gallery (ACG)

---

## 🚀 Quick Start

**Want to see this in action?** Check out the hands-on workshop:
- **[POC - Hybrid OS Image Certification Workflow](./POC-Hybrid-Image-Workshop.md)** - Complete walkthrough with step-by-step commands for building versioned Windows IIS images (1.0.1 and 2.0.1)

---

## Table of Contents

- [1. Purpose](#1-purpose)
  - [1.1 Key Concepts](#11-key-concepts)
- [2. High-Level Workflow Stages](#2-high-level-workflow-stages)
  - [2.1 Production vs Non-Production Build Requirements](#21-production-vs-non-production-build-requirements)
  - [2.2 Architecture Flow Diagram](#22-architecture-flow-diagram)
- [POC - Hybrid OS Image Certification Workflow](./POC-Hybrid-Image-Workshop.md)
- [3. Workflow Details](#3-workflow-details)
  - [3.1 Initiation & Request](#31-initiation--request)
  - [3.2 Pre-Validation & Baseline Alignment](#32-pre‑validation--baseline-alignment)
  - [3.3 Image Build (Azure Image Builder)](#33-image-build-azure-image-builder)
  - [3.4 Vulnerability & Malware Scanning](#34-vulnerability--malware-scanning)
  - [3.5 Functional & Integration Testing](#35-functional--integration-testing)
  - [3.6 Documentation & Approval](#36-documentation--approval)
  - [3.7 Publication & Distribution](#37-publication--distribution)
  - [3.8 Continuous Updates (Critical)](#38-continuous-updates-critical)
- [4. Summary Workflow Diagram](#4-summary-workflow-diagram-text)
  - [4.5 Anti-Patterns & Common Mistakes](#45-anti-patterns--common-mistakes)
- [5. Metrics & KPIs](#5-metrics--kpis)
- [6. Appendix](#6-appendix)
- [7. Change Log](#7-change-log)

---

## 1. Purpose  
**Azure Image Builder** provides a managed, declarative approach to creating, hardening, certifying, and continuously updating OS images for deployment across hybrid environments—including Azure, Azure VMware Solution (AVS), on-premises VMware, and Hyper‑V. This document describes the complete workflow for leveraging Azure Image Builder with Azure Compute Gallery to maintain consistent, compliant images at scale.

---

## 1.1 Key Concepts

**AIB (Azure Image Builder)**  
Managed service that automates OS image creation, hardening, and customization using declarative templates.

**ACG (Azure Compute Gallery)**  
Centralized repository for storing, versioning, and replicating VM images across regions and subscriptions. Formerly called Shared Image Gallery (SIG).

**Managed Image**  
Azure-native VM image format stored in ACG with metadata, versioning, and replication capabilities.

**Image Version**  
Specific build of an image definition (e.g., `1.0.6`). ACG maintains multiple versions with lifecycle policies.

**Image Tattooing**  
Embedding metadata (build ID, timestamp, customizers) into the OS registry/filesystem for traceability and audit compliance.

**Bring Your Own Subnet (BYOS)**  
AIB feature allowing builds to run in customer-controlled VNets for network isolation and compliance.

**Source Image Trigger**  
Automatic AIB rebuild when the base marketplace image is updated (e.g., new Windows Server patch).

**GRC (Governance, Risk, Compliance)**  
Tracking system for image certification requests, approvals, and audit trails.

**VMSS (Virtual Machine Scale Sets)**  
Azure service for deploying and managing groups of identical VMs from a single image definition.

**VHD (Virtual Hard Disk)**  
Portable disk format for exporting images to non-Azure environments (VMware, Hyper-V, AVS).

---

## 2. High-Level Workflow Stages  
```
Request → Pre-Validation → Image Build → Scanning → Functional Testing → Approval → Publish → Continuous Update
```

Each phase ensures the produced image is secure, compliant, reproducible, versioned, and ready for DevOps consumption.

---

## 2.1 Production vs Non-Production Build Requirements

Different environments require different rigor levels. This table defines minimum requirements per environment type.

| Requirement | Dev/Test | Staging/QA | Production |
|------------|----------|------------|------------|
| **Security Agent Install** | Optional | Recommended | Mandatory |
| **CIS/NIST Hardening** | Minimal | Partial | Full Benchmark |
| **Defender Sensitivity** | Low | Medium | High |
| **Vulnerability Scanning** | Optional | Required | Required + Manual Review |
| **Functional Testing** | Smoke Tests | Integration Tests | Full Validation Suite |
| **Peer Review** | Optional | Recommended | Required (Security Team) |
| **GRC Ticket** | Optional | Recommended | Required with Approval |
| **Build Frequency** | Daily/On-Demand | Weekly | Monthly (Post Patch Tuesday) |
| **Image Retention** | 2 versions | 3 versions | 5+ versions (compliance) |
| **Replication Regions** | 1 (local) | 2 | 3+ (DR requirements) |
| **Audit Logging** | Basic | Standard | Enhanced + SIEM Integration |
| **Critical Patching SLA** | Best Effort | 48 hours | 24 hours |

**Key Differences:**
- **Dev/Test**: Speed and iteration over security rigor
- **Staging/QA**: Balance of testing thoroughness and approval process
- **Production**: Maximum security, compliance, and change control

**Compliance Notes:**
- Production images require FedRAMP/NIST 800-53 alignment
- GRC ticket retention: 7 years minimum
- All production builds must have tamper-proof audit trail
- Critical patches require post-implementation review within 72 hours

---

## 2.2 Architecture Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Image Certification Workflow                 │
└─────────────────────────────────────────────────────────────────┘

    [Client Request / GRC Ticket]
                ↓
    ┌───────────────────────────┐
    │   Pre-Validation Gateway  │
    │  - OS Lifecycle Check     │
    │  - Baseline Alignment     │
    └───────────────────────────┘
                ↓
    ┌───────────────────────────────────────────────┐
    │     Azure Image Builder Service (AIB)         │
    │  ┌─────────────────────────────────────────┐  │
    │  │  AIB Orchestration Service              │  │
    │  │  - Template Processing                  │  │
    │  │  - Build VM Provisioning                │  │
    │  └─────────────────────────────────────────┘  │
    │                    ↓                          │
    │  ┌─────────────────────────────────────────┐  │
    │  │  Isolated Build VM (BYOS Subnet)        │  │
    │  │  - OS Patching                          │  │
    │  │  - Agent Installation                   │  │
    │  │  - Customizers (PS/Bash/DSC)            │  │
    │  │  - Image Tattooing                      │  │
    │  │  - Sysprep/Generalization               │  │
    │  └─────────────────────────────────────────┘  │
    └───────────────────────────────────────────────┘
                ↓
    ┌───────────────────────────┐
    │ Azure Compute Gallery     │
    │  - Image Version Created  │
    │  - Metadata Tagged        │
    │  - Regional Replication   │
    └───────────────────────────┘
                ↓
    ┌───────────────────────────┐
    │ Defender for Cloud        │
    │  - Auto Image Scanning    │
    │  - CVE Mapping            │
    │  - Severity Assignment    │
    └───────────────────────────┘
                ↓
    ┌───────────────────────────┐
    │ Sandbox Testing           │
    │  - Functional Tests       │
    │  - Integration Tests      │
    │  - Performance Validation │
    └───────────────────────────┘
                ↓
    ┌───────────────────────────┐
    │ Approval & Documentation  │
    │  - Security Review        │
    │  - GRC Sign-off           │
    │  - Artifact Package       │
    └───────────────────────────┘
                ↓
    ┌───────────────────────────────────────────┐
    │         Image Distribution                │
    │  ┌─────────────────────────────────────┐  │
    │  │  Azure: VMSS, VMs, DevOps Pipelines │  │
    │  └─────────────────────────────────────┘  │
    │  ┌─────────────────────────────────────┐  │
    │  │  Hybrid: VHD Export → AVS/VMware    │  │
    │  └─────────────────────────────────────┘  │
    └───────────────────────────────────────────┘
                ↓
    ┌───────────────────────────┐
    │ Continuous Update Loop    │
    │  - Source Image Triggers  │
    │  - Scheduled Rebuilds     │
    │  - Lifecycle Policies     │
    └───────────────────────────┘
```

**Key Architecture Components:**
- **Network Isolation**: AIB builds run in customer VNet (BYOS) for compliance
- **Monitoring**: Azure Monitor captures all build logs and telemetry
- **Security**: Defender auto-scans all ACG images within 24 hours
- **Audit Trail**: GRC ticket + tattoo metadata + build logs = full traceability

---

## 3. Workflow Details

---

## 3.1 Initiation & Request  
**Purpose:** Begin the certification process for a new or updated OS image.

**Steps**  
- Image request submitted by Cloud/Server team  
- Identify deployment environment (Azure, AVS, on-prem, hybrid)  
- Create GRC tracking ticket  
- Assign tracking ID  

_No automation occurs yet. This is a governance entry point._

---

## 3.2 Pre‑Validation & Baseline Alignment  
**Purpose:** Ensure image meets approved OS baselines before build.

### Pre‑Validation Checks  
- Validate OS lifecycle status (mainstream support, not EOL)  
- Validate patch baseline (MSRC Patch Tuesday)  
- Validate CIS/NIST configuration baseline  
- Validate required security/monitoring agents  
- Validate compliance with your hardening standard  

### Microsoft Docs  
- OS lifecycle: https://learn.microsoft.com/lifecycle  
- CIS benchmark intro: https://learn.microsoft.com/azure/security/benchmarks/overview  
- Windows security baseline: https://learn.microsoft.com/windows/security/threat-protection/windows-security-baselines  

---

## 3.3 Image Build (Azure Image Builder)

**Purpose:** Build, harden, tattoo, and prepare the OS image.

Azure Image Builder performs:  
- Spins up a build VM  
- Applies OS updates  
- Installs packages  
- Runs PowerShell/Bash customizers  
- Runs DSC/Ansible/Chef/Puppet if enabled  
- Installs security agents (Defender, MMA/AMA, Tanium, CrowdStrike, etc.)  
- Runs post‑configuration validation checks  
- Embeds image **tattoo metadata**  
- Produces hardened output image  

### Critical Feature: Image Tattooing  
AIB embeds metadata inside the VM image for traceability:  
- Build ID  
- Template name  
- Source image  
- Timestamp  
- Customizer sequence  

Tattoo location:  
- Windows: `HKLM\SOFTWARE\Microsoft\Azure Image Builder`  
- Linux: `/var/lib/azure-image-builder/metadata.json`

**Query Image Tattoo:**
```powershell
# Windows - Query tattoo metadata
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure Image Builder"

# Linux - Query tattoo metadata
cat /var/lib/azure-image-builder/metadata.json | jq
```

### Automation Example: GitHub Actions
```yaml
name: Build AIB Image
on:
  schedule:
    - cron: '0 2 * * 2'  # Weekly on Tuesday after Patch Tuesday
  workflow_dispatch:

jobs:
  build-image:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Trigger AIB Build
        run: |
          az image builder run \
            --resource-group rg-aib-images \
            --name aib-template-windows2022 \
            --no-wait
      
      - name: Wait for Build Completion
        run: |
          az image builder show-runs \
            --resource-group rg-aib-images \
            --name aib-template-windows2022 \
            --output table
```

### Build Failure Handling
**Common Failures & Resolutions:**
- **Timeout (4 hours)**: Break customizers into smaller chunks, use faster VM SKU
- **Network isolation issues**: Verify NSG rules, check AIB subnet configuration
- **Agent installation failures**: Pre-download installers to Azure Storage, use retry logic
- **Sysprep failures**: Review Windows Event Logs, validate customizer execution order

**Emergency Rollback:**
```powershell
# Revert to previous certified version
az sig image-version update \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --gallery-image-definition windows-2022-hardened \
  --gallery-image-version 1.0.5 \
  --target-regions "eastus=1" "westus2=1" \
  --exclude-from-latest false
```

### Azure Image Builder & Packer Foundation
**AIB is built on HashiCorp Packer:**
- AIB is a **managed Azure service wrapper** around Packer
- Microsoft handles Packer infrastructure, versioning, and execution
- You don't install or manage Packer yourself
- AIB templates use Azure-specific JSON schema (not native Packer HCL)
- Under the hood, AIB converts templates to Packer configurations
- Build logs show "PACKER OUT" and "PACKER ERR" messages

**Benefits:**
- Proven image building capabilities from Packer
- Azure provides infrastructure, security, and isolation
- Built-in integration with Azure services (ACG, managed identities, VNets)
- Enterprise-grade logging and monitoring through Azure
- No Packer version management or dependency conflicts

### Microsoft Docs  
- Azure Image Builder Overview: https://learn.microsoft.com/azure/virtual-machines/image-builder-overview  
- Image Customizers: https://learn.microsoft.com/azure/virtual-machines/linux/image-builder-json  
- AIB Security/Isolation Model: https://learn.microsoft.com/azure/virtual-machines/security-isolated-image-builds-image-builder  
- AIB Image Triggers: https://learn.microsoft.com/azure/virtual-machines/image-builder-triggers-how-to  
- AIB Troubleshooting: https://learn.microsoft.com/azure/virtual-machines/linux/image-builder-troubleshoot  

---

## 3.4 Vulnerability & Malware Scanning  
**Purpose:** Ensure the hardened image meets security risk requirements.

### Automatic Defender for Cloud Image Scanning  
Once the image is published into Azure Compute Gallery:  
- Defender automatically scans gallery images **if Defender for Servers Plan 2 or Defender CSPM is enabled**  
- CVEs are mapped  
- Severity assigned  
- Results appear under **Defender → Recommendations → VM Image Vulnerabilities**  

> **Note:** Defender does not scan Compute Gallery images by default. Image scanning requires an active Defender for Servers Plan 2 or Defender CSPM subscription.

### Optional Third‑Party Scanners  
- Tenable  
- Wiz  
- Prisma Cloud  
- Qualys  

### Microsoft Docs  
- Defender Image Scanning: https://learn.microsoft.com/azure/defender-for-cloud/agentless-vulnerability-assessment-azure  
- Container Registry Image Scanning: https://learn.microsoft.com/azure/container-registry/scan-images-defender  

---

## 3.5 Functional & Integration Testing  
**Purpose:** Validate image behavior before approval.

### Required Tests  
- Deploy image into sandbox VNet  
- Validate log pipeline (Sentinel, Defender, Arc)  
- Validate identity integration (ADDS, AAD, AADDS, IAM)  
- Validate network agents (firewall, EDR, monitoring)  
- Validate that post‑build configuration persists after generalization  

### Performance & Compatibility Testing
**Boot Time Validation:**
```powershell
# Measure boot time
$BootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$BootDuration = (Get-Date) - $BootTime
Write-Host "Boot completed in: $($BootDuration.TotalSeconds) seconds"

# Target: < 2 minutes for Windows Server, < 90 seconds for Windows 11
```

**Application Compatibility Matrix:**
| Application | Test Method | Pass/Fail Criteria |
|-------------|-------------|---------------------|
| Domain Join | Join test domain | Must succeed within 30s |
| Group Policy | gpupdate /force | All policies apply without errors |
| Azure Monitor Agent | Service status check | Running and reporting |
| Microsoft Defender | Security Center status | All protections enabled |
| Custom LOB Apps | Smoke test suite | All critical functions work |

**Rollback Procedure:**
If testing fails:
1. Mark image version as `Excluded from latest`
2. Revert ACG pointer to previous certified version
3. Document failure in GRC ticket
4. Rebuild with fixes or restore previous template

```powershell
# Exclude failed version from latest
az sig image-version update \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --gallery-image-definition windows-2022-hardened \
  --gallery-image-version 1.0.6 \
  --exclude-from-latest true
```

### Microsoft Docs  
- VM provisioning & sysprep: https://learn.microsoft.com/azure/virtual-machines/generalize  
- Agent installation docs: https://learn.microsoft.com/azure/azure-monitor/agents/agents-overview  
- VM boot diagnostics: https://learn.microsoft.com/azure/virtual-machines/boot-diagnostics  

---

## 3.6 Documentation & Approval  
**Purpose:** Produce an auditable certification package.

### Required Artifacts  
- Vulnerability scan report  
- Hardening results  
- Customizer logs  
- Image Builder build logs  
- CIS/NIST comparison results  
- Final approval sign‑off  

### Compliance & Audit Trail
**Azure Policy Integration:**
```json
{
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
        },
        {
          "field": "Microsoft.Compute/virtualMachines/storageProfile.imageReference.id",
          "notContains": "/galleries/acg_corp_images/"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

**Query Image Tattoo at Scale:**
```powershell
# Query all VMs for image metadata
$VMs = Get-AzVM -Status
$ImageInventory = foreach ($VM in $VMs) {
    $VMDetail = Get-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
    [PSCustomObject]@{
        VMName = $VM.Name
        ImageReference = $VMDetail.StorageProfile.ImageReference.Id
        ImageVersion = ($VMDetail.StorageProfile.ImageReference.Id -split '/')[-1]
        PowerState = $VM.PowerState
    }
}
$ImageInventory | Export-Csv -Path "vm-image-inventory.csv" -NoTypeInformation
```

**GRC Ticket Lifecycle Mapping:**
| Stage | GRC Ticket Status | Required Approvers |
|-------|-------------------|-------------------|
| Request | New | Team Lead |
| Pre-Validation | In Progress | Security Team |
| Build Complete | Pending Scan | Automated |
| Scan Complete | Pending Test | QA Team |
| Test Complete | Pending Approval | Security + IT Manager |
| Approved | Closed - Certified | N/A |

**Audit Log Retention:**
- AIB build logs: 90 days in Azure Monitor
- Defender scan results: 1 year in Defender portal
- GRC ticket artifacts: 7 years per compliance requirements
- ACG image metadata: Retained for image lifetime

### Microsoft Docs  
- AIB Logging: https://learn.microsoft.com/azure/virtual-machines/linux/image-builder-troubleshoot  
- Azure Policy for VMs: https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies#compute  
- Azure Monitor Logs: https://learn.microsoft.com/azure/azure-monitor/logs/data-retention-archive  

---

## 3.7 Publication & Distribution  
**Purpose:** Publish the approved image and make it available to DevOps.

### Azure Compute Gallery (ACG) Output Types  
| Output | Best For | Notes |
|--------|----------|-------|
| **Managed Image Versions** | Azure DevOps, VMSS, CI/CD | Versioning, replication, lifecycle, Defender scanning |
| **VHD (Storage Account)** | AVS, VMware, Hyper‑V, AWS | Portable raw disk, no versioning |

### Distribution Target Types in Azure Image Builder

Azure Image Builder supports three distribution target types in the `distribute` section of your template:

#### 1. Azure Compute Gallery (SharedImage) - **RECOMMENDED**
Most common and recommended approach for enterprise environments.

**Capabilities:**
- **Versioning**: Semantic versioning support (e.g., 1.0.1, 1.0.2)
- **Multi-region replication**: Automatically replicate to multiple Azure regions
- **Cross-subscription/tenant sharing**: Share images with other subscriptions or tenants via RBAC
- **Version lifecycle management**: Mark versions as "latest", set end-of-life dates, exclude from latest
- **Security integration**: Automatic Defender for Cloud scanning
- **Hyper-V generation support**: Gen1/Gen2 with TrustedLaunch and ConfidentialVM capabilities
- **RBAC-controlled access**: Fine-grained permissions for image consumption

**Use Cases:**
- Production enterprise deployments
- Multi-region applications requiring consistent images
- DevOps pipelines requiring versioned artifacts
- Compliance scenarios requiring audit trails

**Template Example:**
```json
"distribute": [
  {
    "type": "SharedImage",
    "galleryImageId": "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-iis-hardened/versions/1.0.1",
    "runOutputName": "windows-iis-hardened-1.0.1",
    "replicationRegions": ["westus3", "eastus2", "northeurope"]
  }
]
```

#### 2. Managed Image (ManagedImage)
Creates a traditional Azure Managed Image in a specific resource group.

**Capabilities:**
- Simpler configuration than Compute Gallery
- Region-specific (no automatic multi-region distribution)
- No built-in versioning or lifecycle management
- Stored as a standalone resource in a resource group

**Limitations:**
- Being de-emphasized by Microsoft in favor of Compute Gallery
- Limited support for modern features (TrustedLaunch, Gen2)
- Harder to manage at scale
- No automatic replication

**Use Cases:**
- Simple, single-region scenarios
- Proof-of-concept or development environments
- Legacy workflows not yet migrated to Compute Gallery

**Template Example:**
```json
"distribute": [
  {
    "type": "ManagedImage",
    "imageId": "/subscriptions/{sub}/resourceGroups/rg-images/providers/Microsoft.Compute/images/windows-2022-basic",
    "location": "westus3",
    "runOutputName": "windows-2022-basic"
  }
]
```

#### 3. VHD (Virtual Hard Disk)
Exports the image as a VHD file to an Azure Storage Account.

**Capabilities:**
- Portable disk format compatible with multiple platforms
- Can be downloaded locally for offline use
- Supports hybrid cloud and on-premises scenarios

**Limitations:**
- Not directly deployable in Azure (must be imported first)
- No versioning or lifecycle management
- Manual management required
- Additional storage costs

**Use Cases:**
- Hybrid scenarios (Azure Stack, on-premises VMware/Hyper-V)
- Migration to other cloud providers (AWS, GCP)
- Archival and disaster recovery
- Air-gapped environments requiring offline images

**Template Example:**
```json
"distribute": [
  {
    "type": "VHD",
    "runOutputName": "windows-iis-vhd-export"
  }
]
```

#### Multiple Distribution Targets
A single AIB template can distribute to multiple targets simultaneously. This is useful for backup, hybrid scenarios, or multi-cloud strategies.

**Example - Compute Gallery + VHD Backup:**
```json
"distribute": [
  {
    "type": "SharedImage",
    "galleryImageId": "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-iis/versions/1.0.1",
    "runOutputName": "windows-iis-acg",
    "replicationRegions": ["westus3", "eastus2"]
  },
  {
    "type": "VHD",
    "runOutputName": "windows-iis-vhd-backup"
  }
]
```

**Best Practice Recommendations:**
- **Use Azure Compute Gallery (SharedImage)** for all Azure-native deployments
- **Use VHD** only for hybrid/on-premises scenarios or archival
- **Avoid ManagedImage** for new projects - migrate to Compute Gallery
- **Enable multi-region replication** for disaster recovery and global deployments
- **Use semantic versioning** (major.minor.patch) for image versions
- **Tag versions** with metadata (environment, compliance level, build date)

### Multi-Tenancy & Access Control
**Image Sharing Across Subscriptions:**
```powershell
# Share gallery with another subscription
az sig share add \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --subscription-ids "sub-id-dev" "sub-id-test" "sub-id-prod"

# RBAC assignment for image consumption
az role assignment create \
  --assignee "devops-team@contoso.com" \
  --role "Compute Gallery Sharing Admin" \
  --scope "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images"
```

**Environment Separation Strategy:**
| Environment | Gallery Name | Access Control | Update Frequency |
|-------------|--------------|----------------|------------------|
| Development | acg_dev_images | DevOps Team | Daily |
| Testing | acg_test_images | QA + DevOps | Weekly |
| Production | acg_prod_images | Approved Images Only | Monthly |

### Deployment Examples
**Deploy Latest Certified Image:**
```powershell
# Azure CLI
az vm create \
  --resource-group rg-production \
  --name vm-app-001 \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/latest" \
  --size Standard_D4s_v5 \
  --admin-username azureuser

# PowerShell
New-AzVm `
  -ResourceGroupName "rg-production" `
  -Name "vm-app-001" `
  -ImageName "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/latest" `
  -Size "Standard_D4s_v5"

# Bicep
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-app-001'
  location: location
  properties: {
    storageProfile: {
      imageReference: {
        id: '/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/latest'
      }
    }
  }
}
```

### VHD Export for Hybrid Environments
**Automated Export to AVS/VMware:**

> **Important:** You cannot directly snapshot a gallery image version. You must deploy a temporary VM from the image, then snapshot its OS disk.

```powershell
# Step 1: Deploy temporary VM from gallery image
$imageVersion = "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/1.0.6"

New-AzVm `
  -ResourceGroupName "rg-export" `
  -Name "vm-export-temp" `
  -Image $imageVersion `
  -Size "Standard_D2s_v5" `
  -Location "eastus"

# Step 2: Stop VM
Stop-AzVM -ResourceGroupName "rg-export" -Name "vm-export-temp" -Force

# Step 3: Create snapshot from the VM's OS disk
$vm = Get-AzVM -ResourceGroupName "rg-export" -Name "vm-export-temp"
$osDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id

$snapshotConfig = New-AzSnapshotConfig `
  -Location "eastus" `
  -CreateOption Copy `
  -SourceResourceId $osDiskId

$snapshot = New-AzSnapshot `
  -ResourceGroupName "rg-export" `
  -SnapshotName "snapshot-export-001" `
  -Snapshot $snapshotConfig

# Grant SAS access
$sasUrl = Grant-AzSnapshotAccess `
  -ResourceGroupName "rg-export" `
  -SnapshotName "snapshot-export-001" `
  -DurationInSecond 3600 `
  -Access Read

# Download VHD (use azcopy for large files)
azcopy copy $sasUrl "C:\exported-images\windows-2022-hardened.vhd"
```

**Convert for VMware (VMDK):**
```powershell
# Using qemu-img (install from https://www.qemu.org)
qemu-img convert -f vpc -O vmdk windows-2022-hardened.vhd windows-2022-hardened.vmdk

# Verify integrity
qemu-img check windows-2022-hardened.vmdk
```

**Convert for Hyper-V (VHDX):**
```powershell
Convert-VHD -Path "C:\exported-images\windows-2022-hardened.vhd" `
  -DestinationPath "C:\exported-images\windows-2022-hardened.vhdx" `
  -VHDType Dynamic
```

### Microsoft Docs  
- Compute Gallery Overview: https://learn.microsoft.com/azure/virtual-machines/shared-image-galleries  
- Image Versioning: https://learn.microsoft.com/azure/virtual-machines/shared-image-gallery-versioning  
- Managed Images: https://learn.microsoft.com/azure/virtual-machines/windows/capture-image  
- Download VHD: https://learn.microsoft.com/azure/virtual-machines/linux/download-vhd  
- Gallery Sharing: https://learn.microsoft.com/azure/virtual-machines/share-gallery  

---

## 3.8 Continuous Updates (Critical)  
**Purpose:** Keep images updated automatically.

### Automated Update Strategy  
1. **AIB Source Image Trigger**  
   Automatically rebuilds image when the base image is updated.  
   Docs: https://learn.microsoft.com/azure/virtual-machines/image-builder-triggers-how-to  

2. **Scheduled Rebuilds**  
   Weekly or monthly builds driven by CI/CD (GitHub Actions/AzDO).

3. **ACG Lifecycle Policies**  
   - Deprecate older versions  
   - Retire out‑of‑date versions  
   - Enforce “Latest” tag for auto‑rollout  

4. **DevOps Integration**  
   CI/CD pulls the “latest stable” gallery image as the base for:  
   - VMSS updates  
   - ephemeral test VMs  
   - environment deployments  

### Microsoft Docs  
- ACG Image Lifecycle: https://learn.microsoft.com/azure/virtual-machines/shared-image-gallery-versioning#lifecycle  
- VMSS with SIG Images: https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-sig-image  
- VMSS Rolling Upgrades: https://learn.microsoft.com/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-upgrade-policy  
- Azure Pricing Calculator: https://azure.microsoft.com/pricing/calculator/

### Agent Management Strategy
**Baked-In vs. Post-Deployment:**
| Component | Deployment Method | Update Strategy | Reasoning |
|-----------|------------------|-----------------|-----------|
| Azure Monitor Agent | Baked-in | Rebuild image monthly | Core monitoring requirement |
| Microsoft Defender | Baked-in | Rebuild + auto-update | Security baseline |
| Custom LOB Agents | Baked-in | Rebuild when updated | Configuration drift prevention |
| Azure Extensions | Post-deployment | VM Extension auto-update | Azure-managed lifecycle |
| Application Software | Post-deployment | App-specific update tool | Rapid iteration needs |

**Extension vs. Installed Agent Trade-offs:**
- **Extensions**: Azure-managed, auto-updated, easier to deploy at scale, limited customization
- **Installed Agents**: Full control, can be baked into image, requires manual update orchestration

### Azure DevOps Pipeline Example
```yaml
trigger:
  schedule:
    - cron: "0 2 * * 2"  # Tuesday 2 AM (post Patch Tuesday)
      branches:
        include:
          - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureCLI@2
    displayName: 'Trigger AIB Build'
    inputs:
      azureSubscription: 'Azure-Prod-ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az image builder run \
          --resource-group rg-aib-images \
          --name aib-template-windows2022
  
  - task: AzureCLI@2
    displayName: 'Wait for Build'
    inputs:
      azureSubscription: 'Azure-Prod-ServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        while true; do
          STATUS=$(az image builder show \
            --resource-group rg-aib-images \
            --name aib-template-windows2022 \
            --query 'lastRunStatus.runState' -o tsv)
          
          if [ "$STATUS" == "Succeeded" ]; then
            echo "Build succeeded"
            break
          elif [ "$STATUS" == "Failed" ]; then
            echo "Build failed"
            exit 1
          fi
          
          sleep 60
        done
```

### Cost Management
**Monthly Cost Estimates (Example):**
| Resource | Configuration | Monthly Cost (USD) |
|----------|--------------|-------------------|
| AIB Build VM | Standard_D4s_v5, 2hr/week | ~$15 |
| ACG Storage | 3 image versions, 30GB each | ~$5 |
| ACG Replication | 3 regions, 3 versions | ~$10 |
| Defender Scanning | Requires Plan 2/CSPM | Variable (see plan) |
| Network Egress | VHD downloads | Variable (~$5-50) |
| **Total** | | **~$35-80/month** |

> **Note:** ACG replication costs are storage-only (no compute or per-replication fees). Typical cost: $0.15-$0.25/GB/month per region. A 30GB Windows Server image replicated to 3 regions costs approximately $18/month ($0.20 × 30GB × 3). Small Linux images typically cost $3-8/month total.

**Cost Optimization Strategies:**
1. **Version Retention Policy:**
```powershell
# Keep only last 3 versions
az sig image-version delete \
  --resource-group rg-acg \
  --gallery-name acg_corp_images \
  --gallery-image-definition windows-2022-hardened \
  --gallery-image-version 1.0.3
```

2. **Regional Replication:**
   - Only replicate to regions where VMs will deploy
   - Use zone-redundant storage (ZRS) only in critical regions

3. **Build VM Rightsizing:**
   - Use B-series burstable VMs for small images
   - Use D-series for complex builds with many customizers

### Critical Patching Procedures
**Critical Vulnerability Response:**
1. **Identify Scope**: Query all VMs using vulnerable image version
2. **Critical Build**: Trigger AIB with expedited approval
3. **Deploy Updated Image**: Use VM extension or VMSS rolling upgrade
4. **Verify Remediation**: Re-scan with Defender

```powershell
# Expedited build (skip some testing stages)
az image builder run \
  --resource-group rg-aib-images \
  --name aib-template-emergency-patch \
  --no-wait

# Force VMSS rolling upgrade
az vmss update \
  --resource-group rg-production \
  --name vmss-web-cluster \
  --set virtualMachineProfile.storageProfile.imageReference.id="/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/1.0.7"

az vmss update-instances \
  --resource-group rg-production \
  --name vmss-web-cluster \
  --instance-ids "*"
```

### Incident Response for Compromised Images
**Detection Indicators:**
- Defender alerts on deployed VMs
- Unexpected outbound connections
- Unauthorized configuration changes
- Failed compliance scans

**Response Procedure:**
1. **Immediately exclude image from latest**
2. **Quarantine all VMs deployed from image**
3. **Forensic analysis on build logs and customizers**
4. **Rebuild from clean baseline**
5. **Update GRC ticket with incident details**

### Avoiding Configuration Drift

**Configuration drift** occurs when VMs diverge from their original image state due to manual changes, failed updates, or inconsistent automation.

**Why Configuration Drift is Critical for SLED:**
- Violates compliance requirements (NIST 800-53, FedRAMP)
- Creates security vulnerabilities
- Makes troubleshooting impossible ("works on my VM")
- Breaks disaster recovery assumptions
- Fails audit inspections

**Prevention Strategies:**

**1. Embrace Immutable Infrastructure**
```
❌ SSH into VM → manually install package → hope it sticks
✅ Update AIB template → rebuild image → redeploy VMs
```

**2. Bake Everything into the Image**
| Component | Deployment Method | Drift Risk |
|-----------|------------------|------------|
| OS patches | AIB customizer | ✅ No drift |
| Security agents | AIB customizer | ✅ No drift |
| Monitoring tools | AIB customizer | ✅ No drift |
| Application binaries | AIB customizer | ✅ No drift |
| GPO settings | Post-deployment | ⚠️ Medium drift |
| User data | Post-deployment | ⚠️ Medium drift |
| Manual SSH changes | Ad-hoc | ❌ High drift |

**3. Use VM Extensions Only for Azure-Managed Components**
```powershell
# Good: Azure-managed extension (auto-updated, no drift)
Set-AzVMExtension -ResourceGroupName "rg-prod" `
  -VMName "vm-web-01" `
  -Name "MicrosoftMonitoringAgent" `
  -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
  -ExtensionType "MicrosoftMonitoringAgent"

# Bad: Custom script extension (drift-prone, hard to track)
Set-AzVMExtension -ResourceGroupName "rg-prod" `
  -VMName "vm-web-01" `
  -Name "CustomScript" `
  -FileUri "https://mystorageaccount/install-app.ps1"
```

**4. Prohibit Post-Deployment Configuration Changes**
```powershell
# Enforce with Azure Policy - deny script extensions
{
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines/extensions"
        },
        {
          "field": "Microsoft.Compute/virtualMachines/extensions/type",
          "equals": "CustomScriptExtension"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

**5. Redeploy Images Monthly Even If Nothing Changed**
```yaml
# Azure DevOps scheduled pipeline
schedules:
  - cron: "0 0 1 * *"  # First day of every month
    branches:
      include:
        - main
    always: true  # Run even if no code changes
```

**Why monthly rebuilds prevent drift:**
- Applies latest OS patches from marketplace base image
- Refreshes security agent definitions
- Resets any accumulated state
- Validates build pipeline still works
- Maintains compliance audit trail

**6. Enforce CI/CD Deployments from ACG Image IDs**
```bicep
// Bicep template - only allow ACG images
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    storageProfile: {
      imageReference: {
        // ✅ Good: ACG image with version control
        id: '/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/latest'
        
        // ❌ Bad: Marketplace image (not hardened)
        // publisher: 'MicrosoftWindowsServer'
        // offer: 'WindowsServer'
        // sku: '2022-datacenter'
      }
    }
  }
}
```

**7. Detect Drift with Azure Policy Guest Configuration**
```powershell
# Deploy guest configuration to detect drift
New-AzPolicyAssignment `
  -Name "Audit-VM-Configuration-Drift" `
  -PolicyDefinition (Get-AzPolicyDefinition -Name "Audit Windows VMs that do not match Azure security baseline") `
  -Scope "/subscriptions/{subscription-id}"
```

**Configuration Drift Detection Dashboard:**
```kusto
// Azure Monitor query - find VMs with unexpected software
ConfigurationData
| where ConfigDataType == "Software"
| where SoftwareName !in ("ExpectedApp1", "ExpectedApp2", "AzureMonitorAgent")
| summarize UnexpectedSoftware = make_set(SoftwareName) by Computer
| where array_length(UnexpectedSoftware) > 0
```

**Enforcement Checklist:**
- [ ] Azure Policy blocks manual script extensions
- [ ] ACG images are the only deployment source
- [ ] Monthly automated rebuilds scheduled
- [ ] Guest Configuration audits enabled
- [ ] SSH/RDP access logged and reviewed
- [ ] Immutable infrastructure documented in runbooks
- [ ] VM redeployment process tested quarterly

---

## 4. Summary Workflow Diagram (Text)

```
[Request]
   ↓
[Pre-Validation]
   ↓
[AIB Build + Tattoo + Hardening]
   ↓
[ACG Publish → Defender Image Scan]
   ↓
[Sandbox Deployment Testing]
   ↓
[Approval & Documentation]
   ↓
[ACG Managed Image Versioning]
   ↓
[DevOps Consumption]
   ↓
[Triggers / Scheduled Rebuilds]
   ↓
[Continuous Updated Images]
```

---

## 4.5 Anti-Patterns & Common Mistakes

**What NOT to do when managing OS images. These are real-world failures observed in enterprise deployments.**

### ❌ **Building Images Manually on a VM**
**Problem:**  
- No traceability (who built it? when? what changed?)  
- No versioning or rollback capability  
- No automated scanning or compliance checks  
- Configuration drift over time  

**Instead:** Always use AIB with declarative templates stored in source control.

---

### ❌ **Using Marketplace Images Directly in Production**
**Problem:**  
- Marketplace images lack organizational hardening  
- No pre-installed monitoring/security agents  
- No compliance baseline applied  
- Not approved through GRC process  

**Instead:** Use marketplace images as source for AIB templates, then apply customizers.

---

### ❌ **Installing Applications via Group Policy Post-Deployment**
**Problem:**  
- Slow boot times (apps install on first login)  
- Inconsistent state (some VMs may fail GPO application)  
- No image-level validation  
- Creates configuration drift  

**Instead:** Bake applications into the image via AIB customizers. Use GPO only for user-specific settings.

---

### ❌ **Using VHDs for Azure-Native Pipelines**
**Problem:**  
- No Defender scanning  
- No versioning or lifecycle management  
- Manual upload/download process  
- No regional replication  
- No integration with VMSS  

**Instead:** Use ACG Managed Images for Azure workloads. Export VHD only for hybrid/on-prem scenarios.

---

### ❌ **Deploying Images Older Than 90 Days**
**Problem:**  
- Missing critical security patches  
- Out of compliance with NIST/CIS requirements  
- High CVE count from Defender scans  
- Increased attack surface  

**Instead:** Set ACG lifecycle policies to deprecate images after 90 days. Force rebuilds monthly.

---

### ❌ **Skipping AIB Image Tattooing**
**Problem:**  
- No audit trail (can't prove image provenance)  
- Can't identify which VMs use which image version  
- Fails compliance audits  
- No forensics capability during incidents  

**Instead:** Always enable tattooing. Query it during audits:
```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure Image Builder"
```

---

### ❌ **Manual Post-Deployment Configuration Changes**
**Problem:**  
- Creates "snowflake" VMs (each slightly different)  
- Breaks immutable infrastructure principles  
- No rollback capability  
- Complicates troubleshooting  

**Instead:** Treat VMs as disposable. If config change needed, rebuild image and redeploy.

---

### ❌ **Not Testing Images Before Production Deployment**
**Problem:**  
- Production outages from boot failures  
- Agent installation issues discovered live  
- Application compatibility problems  
- Rollback complexity  

**Instead:** Always deploy to sandbox environment first. Run validation suite before approving.

---

### ❌ **Storing Secrets in Image Templates**
**Problem:**  
- Credentials baked into image  
- Exposed in AIB logs and build artifacts  
- Compliance violation  
- Security incident risk  

**Instead:** Use Azure Key Vault references in AIB templates. Inject secrets at runtime.

---

### ❌ **Ignoring Build Failures**
**Problem:**  
- Builds fail silently in background  
- Stale images remain in use  
- Security patches don't get applied  
- False sense of compliance  

**Instead:** Set up Azure Monitor alerts for AIB build failures. Integrate with ticketing system.

---

### ✅ **Best Practice Summary**
| Anti-Pattern | Correct Approach |
|--------------|------------------|
| Manual VM builds | AIB with source-controlled templates |
| Marketplace images in prod | Marketplace → AIB → ACG → Prod |
| GPO app installs | Bake apps into image |
| VHDs for Azure | ACG Managed Images |
| 90+ day old images | Monthly rebuilds + lifecycle policies |
| No tattooing | Always enable metadata embedding |
| Post-deployment changes | Immutable infrastructure + redeploy |
| Skip testing | Sandbox validation before prod |
| Secrets in templates | Key Vault references |
| Ignored failures | Monitoring + alerting |

---

## 5. Metrics & KPIs

### Image Certification Success Metrics
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Build Success Rate | ≥ 95% | (Successful builds / Total builds) × 100 |
| Time from Request to Approval | ≤ 5 business days | GRC ticket timestamp analysis |
| Vulnerabilities per Image | ≤ 5 High/Critical CVEs | Defender scan results |
| Image Deployment Success Rate | ≥ 98% | VM creation success from ACG |
| Image Adoption Rate | ≥ 80% of VMs use certified images | Azure Policy compliance reporting |
| Mean Time to Patch (MTTP) | ≤ 72 hours post-release | Time from patch release to image update |
| Cost per Image Version | ≤ $50 | Azure Cost Management + Allocation |

### Monitoring Queries
**Build Success Rate (Last 30 Days):**
```kusto
AzureActivity
| where OperationNameValue == "Microsoft.VirtualMachineImages/imageTemplates/run/action"
| where TimeGenerated > ago(30d)
| summarize Total = count(), 
            Successful = countif(ActivityStatusValue == "Success"),
            Failed = countif(ActivityStatusValue == "Failed")
| extend SuccessRate = (Successful * 100.0) / Total
| project SuccessRate, Successful, Failed, Total
```

**Image Adoption by Subscription:**
```kusto
Resources
| where type == "microsoft.compute/virtualmachines"
| extend ImageId = tostring(properties.storageProfile.imageReference.id)
| where ImageId contains "/galleries/"
| summarize VMCount = count() by ImageId, subscriptionId
| order by VMCount desc
```

**Vulnerability Trends:**
```kusto
SecurityRecommendation
| where RecommendationName == "Vulnerabilities in Azure Container Registry images should be remediated"
| where TimeGenerated > ago(90d)
| summarize HighCVEs = countif(RecommendationSeverity == "High"),
            CriticalCVEs = countif(RecommendationSeverity == "Critical")
            by bin(TimeGenerated, 7d)
| render timechart
```

### Dashboard Recommendations
Create Azure Dashboards with:
- Build pipeline status (last 7 days)
- Active image versions per gallery
- VM count by image version
- Defender vulnerability summary
- Cost trend analysis
- Compliance score (Azure Policy)

---

## 6. Appendix  
### Recommended Build Frequency  
- Critical OS: Weekly  
- Windows Server: Monthly (post Patch Tuesday)  
- Linux: Weekly or bi-weekly  
- Third-party agents: When vendor releases new version  

### Recommended DevOps Consumption Pattern  
```powershell
# Always use 'latest' for ephemeral/test VMs
az vm create \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/latest"

# Pin to specific version for production (post-validation)
az vm create \
  --image "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-2022-hardened/versions/1.0.6"
```

### Additional Resources
- **AIB Best Practices**: https://learn.microsoft.com/azure/virtual-machines/image-builder-best-practices
- **ACG Security**: https://learn.microsoft.com/azure/virtual-machines/security-policy-definition-examples
- **Azure Cost Optimization**: https://learn.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks

---

## 7. Change Log  
- **v1.0** — Initial release  
- **v1.1** — Added automation examples, cost management, agent strategy, emergency procedures, metrics/KPIs
- **v1.2** — Added Key Concepts definitions, Production vs Non-Production requirements table, architecture flow diagram, anti-patterns section, configuration drift prevention guidance  
