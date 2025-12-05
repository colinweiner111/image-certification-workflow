## POC - Hybrid Image Workshop

---

## Welcome & Problem Statement

---

### The Challenge

**Current Reality:**
- ❌ Manual image builds on VMs → no audit trail, no versioning
- ❌ Marketplace images deployed directly to production → not hardened, no compliance
- ❌ Configuration drift over time → "works on my VM" problem
- ❌ No way to prove image provenance during security audits

**Customer Frustration Points:**
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

**Business Value:**
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

## Build → Scan → Test → Approve Pipeline

### Production vs. Dev/Test Requirements

**Reference**: `README.md` → **Section 2.1 (Production vs Non-Production)**

| Requirement | Dev/Test | Production |
|------------|----------|------------|
| **Security agents** | Optional | Mandatory |
| **CIS/NIST hardening** | Minimal | Full benchmark |
| **Vulnerability scanning** | Optional | Required + manual review |
| **Functional testing** | Smoke tests | Full validation suite |
| **GRC approval** | Optional | Required with audit trail |
| **Build frequency** | Daily/On-demand | Monthly (post Patch Tuesday) |
| **Image retention** | 2 versions | 5+ versions |
| **Critical patch SLA** | Best effort | 24 hours |

**Key Insight:**  
"You match your rigor to your environment risk. Dev is fast; production is bulletproof."

---

### Step-by-Step Pipeline Walkthrough

**Reference**: `README.md` → **Section 3 (Workflow Details)**

| Phase | Owner | Duration | Key Output | Go/No-Go? |
|-------|-------|----------|------------|-----------|
| **Pre-Validation** | Security | 1 day | Baseline checklist | OS supported? Agents OK? |
| **AIB Build** | DevOps | 30–60 min | Hardened image in ACG | Build succeeded? |
| **Defender Scan** | Automated | 24 hours | CVE report | CVE threshold met? |
| **Sandbox Test** | QA | 2–5 days | Test results | All pass criteria met? |
| **Approval** | Security + IT Mgr | 1 day | GRC sign-off + artifacts | Release to production? |
| **Distribution** | DevOps | Immediate | VMSS/VHD deployed | Health check passed? |

**Total Timeline**: Request → Approved = **5 business days target**

---

### Live Lab Demo — Windows Server with IIS

**Demo Scenario**: Build a Windows Server 2022 image with IIS + custom landing page, deploy it, then update it.

---

#### **Part 1: Show the AIB Template**

Open your AIB template JSON in VS Code:

```json
{
  "type": "Microsoft.VirtualMachineImages/imageTemplates",
  "name": "aib-template-windows-iis",
  "properties": {
    "source": {
      "type": "PlatformImage",
      "publisher": "MicrosoftWindowsServer",
      "offer": "WindowsServer",
      "sku": "2022-datacenter",
      "version": "latest"
    },
    "customize": [
      {
        "type": "PowerShell",
        "name": "Install IIS",
        "inline": [
          "Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature",
          "Install-WindowsFeature -Name Web-Asp-Net45"
        ]
      },
      {
        "type": "PowerShell",
        "name": "Deploy Custom Landing Page",
        "inline": [
          "$html = @'",
          "<!DOCTYPE html>",
          "<html>",
          "<head><title>Welcome</title></head>",
          "<body style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; font-family: Arial;'>",
          "<h1>Welcome to Our Hardened Windows Server</h1>",
          "<p>This image was built with Azure Image Builder</p>",
          "<p>Build Version: 1.0.1 | Built: 2025-12-04</p>",
          "</body>",
          "</html>",
          "'@",
          "Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value $html"
        ]
      }
    ],
    "distribute": [
      {
        "type": "ManagedImage",
        "imageId": "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-iis-hardened/versions/1.0.1"
      }
    ]
  }
}
```

**Talking Point**: "This template is declarative, source-controlled, and repeatable. We can build this same image 100 times and get identical results."

---

#### **Part 2: Trigger the Build**

Run this in PowerShell:

```powershell
# Trigger AIB build
az image builder run `
  --resource-group rg-aib-images `
  --name aib-template-windows-iis `
  --no-wait

Write-Host "Build started. Monitoring progress..."

# Wait for build to complete (typically 45-90 minutes)
# For demo purposes, show the status command
az image builder show-runs `
  --resource-group rg-aib-images `
  --name aib-template-windows-iis `
  --query "[0].[runState, runOutputName]" -o table
```

**Demo Note**: For a live customer call, you'd either:
- Pre-stage a completed build to show results immediately
- Show a build-in-progress and explain the timeline
- Show historical builds to demonstrate success rate

---

#### **Part 3: Verify Image in ACG**

Show the image published to the gallery:

```powershell
# List ACG image versions
az sig image-version list `
  --resource-group rg-acg `
  --gallery-name acg_corp_images `
  --gallery-image-definition windows-iis-hardened `
  --output table

# Show image metadata (tattoo)
az sig image-version show `
  --resource-group rg-acg `
  --gallery-name acg_corp_images `
  --gallery-image-definition windows-iis-hardened `
  --gallery-image-version 1.0.1 `
  --output json | jq '.tags'
```

**Talking Points:**
- "The image is now versioned, replicated to 3 regions, and available for deployment."
- "Defender automatically scanned it for vulnerabilities within 24 hours."
- "The metadata tattoo proves who built it, when, and what was customized."

---

#### **Part 4: Deploy VM from Gallery Image**

Create a VM using the gallery image:

```powershell
# Deploy VM from ACG image
az vm create `
  --resource-group rg-demo `
  --name vm-iis-demo-001 `
  --image "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-iis-hardened/versions/1.0.1" `
  --size Standard_B2s `
  --admin-username azureuser `
  --admin-password "ComplexPassword123!" `
  --nsg-rule RDP `
  --public-ip-sku Standard

# Get the public IP
$publicIp = az vm show `
  --resource-group rg-demo `
  --name vm-iis-demo-001 `
  --show-details `
  --query publicIps -o tsv

Write-Host "VM deployed! Access it at: http://$publicIp"
```

**Demo**: Open a browser and navigate to the public IP to show the custom landing page is already there (no post-deployment installation needed).

**Talking Point**: "The image arrived fully configured with IIS and our landing page. No manual setup, no configuration drift, completely reproducible."

---

#### **Part 5: Update the Image & Redeploy**

Now update the image with a new version:

```powershell
# Edit the template: update version to 1.0.2 and change landing page text
# (show quick edit in VS Code)

# Trigger new build
az image builder run `
  --resource-group rg-aib-images `
  --name aib-template-windows-iis `
  --no-wait

# Once complete, deploy NEW version to VMSS or new VM
az vm create `
  --resource-group rg-demo `
  --name vm-iis-demo-002 `
  --image "/subscriptions/{sub}/resourceGroups/rg-acg/providers/Microsoft.Compute/galleries/acg_corp_images/images/windows-iis-hardened/versions/1.0.2" `
  --size Standard_B2s

# Show both VMs running, each with their own version
az vm list `
  --resource-group rg-demo `
  --show-details `
  --query "[].{Name:name, PublicIP:publicIps}" -o table
```

**Talking Points:**
- "We updated the template, triggered a new build, and deployed v1.0.2 in parallel with v1.0.1."
- "Zero downtime. Customers on v1.0.1 stay running while new deployments get v1.0.2."
- "Rollback is one command: just point VMSS/VMs back to v1.0.1."

---

#### **Part 6: Show Image Tattoo Query**n+

RDP into one of the VMs and query the image metadata:

```powershell
# From within the VM (via RDP)
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Azure Image Builder"
```

**Output example:**:
```
BuildId                : 20251204-001
TemplateName           : aib-template-windows-iis
SourceImage            : MicrosoftWindowsServer/WindowsServer/2022-datacenter
BuildDate              : 2025-12-04T14:32:15Z
CustomizerCount        : 2
Customizers            : Install IIS, Deploy Custom Landing Page
```

**Talking Point**: "This metadata is embedded in every VM deployed from this image. During a security audit, we can prove exactly which image is on which VM and when it was built."

---

**Total Demo Time**: 10 minutes  
**Audience Impact**: High—shows real-world hardening workflow, reproducibility, versioning, and audit trail all in action.

---

#### **Azure Prerequisites**

Before the demo, ensure you have:

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

**CLI & Tools:**
- ✅ Azure CLI installed and authenticated (`az login`)
- ✅ PowerShell 7+ installed
- ✅ VS Code with template files ready
- ✅ Two monitors recommended (one for terminal, one for browser/Portal)

**Demo-Specific Setup:**
- ✅ AIB template JSON file created and ready (see Slide 3.3, Part 1)
- ✅ Pre-staged AIB build running or recently completed
- ✅ At least one image version published in ACG
- ✅ Test VM deployed from gallery image (pre-built, running)
- ✅ RDP credentials saved and tested

---

#### **Pre-Demo Setup Checklist**

Before the customer call:
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

---

### Configuration Drift Prevention

**Reference**: `README.md` → **Section 3.8 (Avoiding Configuration Drift)**

**The Problem:**
```
VMs gradually diverge from baseline
    ↓
Manual SSH changes accumulate
    ↓
Compliance violations (NIST 800-53, FedRAMP)
    ↓
Security incidents + audit failures
```

**The Fix: Immutable Infrastructure**
```
Update AIB template → Rebuild image → Redeploy VMs
    ↓
No manual SSH changes allowed (Azure Policy blocks it)
    ↓
Monthly rebuilds keep everything current
    ↓
100% audit trail + zero drift
    ↓
Compliance confidence
```

---

## Next Steps & Closing

### Immediate Action Items (Week 1)

**Three critical decisions to make:**

1. **Align on Image Baseline**
   - Which OS versions? (Windows Server 2022, Ubuntu 22.04, etc.)
   - Which security agents? (Defender, AMA, EDR vendor, monitoring tools)
   - CIS/NIST compliance scope? (Full benchmark or partial)
   - **Owner**: Security team + Infrastructure team
   - **Deliverable**: Written baseline document

2. **Plan ACG & Storage**
   - Which subscription for ACG? (shared vs. per-environment)
   - Regional replication strategy? (1 for dev, 3+ for prod)
   - Image retention policy? (5 versions minimum for compliance)
   - **Owner**: Cloud infrastructure team
   - **Deliverable**: ACG design document

3. **Network Planning (BYOS)**
   - Dedicated VNet for AIB builds?
   - Routing/NSG rules for agent downloads?
   - **Owner**: Network team
   - **Deliverable**: VNet design, NSG rules, connectivity diagram

---

### Short-Term Roadmap (Weeks 2–4)

| Week | Task | Owner | Deliverable |
|------|------|-------|-------------|
| **2–3** | Create AIB template (base OS + customizers) | DevOps | JSON template in source control |
| **2–3** | Set up ACG + replication | Cloud Ops | Gallery created, regions configured |
| **3–4** | Build CI/CD pipeline (GitHub Actions or AzDO) | DevOps | Pipeline code, test run successful |
| **4** | Sandbox testing framework | QA | Test scripts, pass/fail criteria documented |

---

### Medium-Term Vision (Month 2+)

**By End of Month 2:**
- ✅ First production image built, scanned, tested, approved
- ✅ Monthly automated rebuilds scheduled
- ✅ VMSS consuming ACG images
- ✅ VHD export process validated (hybrid teams can consume)
- ✅ Critical patching procedure tested

**Metrics to Track:**
- Build success rate (target: ≥95%)
- Time from request to approval (target: ≤5 business days)
- Vulnerabilities per image (target: ≤5 high/critical CVEs)
- Image adoption rate (target: ≥80% of VMs use certified images)

**Reference**: `README.md` → **Section 5 (Metrics & KPIs)**

---

### Key Questions for Customer (Q&A, 3–5 min)

**Ask these to understand their priorities:**

1. **"What's your biggest blocker today—compliance, speed, or tooling?"**
   - Compliance → Focus on GRC, audit trail, tattooing
   - Speed → Focus on CI/CD, automation, monthly rebuilds
   - Tooling → Focus on ACG, AIB, Azure Monitor integration

2. **"Which OS versions are priority for hardening?"**
   - Windows Server 2022? Ubuntu 22.04? Others?

3. **"Do you need on-prem (VHD) export from day one?"**
   - If yes → Plan VHD snapshot, conversion, delivery process early
   - If no → Build Azure first, add hybrid later

4. **"How many regions do you deploy to?"**
   - 1 → Dev only, minimal cost
   - 3+ → Production, higher cost but full DR

5. **"Who owns compliance/security approvals in your org?"**
   - Get them in the room for the next meeting

---

### Closing Remarks

**Recap:**
> "We've covered the end-to-end workflow: from request through build, scan, test, approval, and distribution to Azure and hybrid environments. The key is **declarative, versioned, auditable images**—same hardening, same compliance, deployed everywhere."

**Next Meeting (Schedule Now):**
- **Attendees**: Security, Infrastructure, DevOps, Compliance
- **Duration**: 1–2 hours
- **Agenda**:
  1. Align on image baseline (OS, agents, hardening)
  2. Design ACG & BYOS network
  3. Assign template ownership
  4. Confirm timeline & success metrics

**Take-Home Materials:**
- ✅ `README.md` (full reference document)
- ✅ Sample AIB template (JSON)
- ✅ Sample CI/CD pipeline (GitHub Actions YAML)
- ✅ GRC ticket template
- ✅ Sandbox test checklist

---

## Appendix: Speaker Tips & Timekeeping

| Section | Duration | Flexibility |
|---------|----------|------------|
| **Welcome & Problem** | 5 min | Adjust if customer has deep questions |
| **Architecture & Concepts** | 15 min | Skip demo if short on time (5 min savings) |
| **Pipeline Walkthrough** | 15 min | Spend more time if customer has process questions |
| **Production & Cost** | 15 min | Emphasize cost if budget is concern (5 min extra) |
| **Anti-Patterns** (Bonus) | 5–10 min | Include if time permits; strong value-add |
| **Next Steps & Closing** | 10 min | Always allocate full 10 min for action items |

---

## Backup Q&A Scripts

**Q: "How long does a full build cycle take?"**
A: AIB build + Defender scan (24h automatic) + sandbox test (2–5 days) + approval (1–2 days) = **5 business days target**. Critical patches can skip some testing and be done in 24 hours.

**Q: "Can we use the same image for Azure and on-prem?"**
A: **Absolutely.** Build once in AIB, publish to ACG for Azure VMs, export as VHD for VMware/AVS/Hyper-V. Same customizers, same hardening, different deployment formats. See `README.md` → **Section 3.7 (VHD Export)**.

**Q: "What if an image build fails?"**
A: Azure Monitor captures all build logs. We investigate the failure, fix the template, trigger a retry. The previous version remains available for rollback if needed. See `README.md` → **Section 3.3 (Build Failure Handling)**.

**Q: "How do we prevent configuration drift on deployed VMs?"**
A: Immutable infrastructure principle: bake everything into the image, redeploy VMs monthly even if nothing changed, use Azure Policy to block manual SSH edits. See `README.md` → **Section 3.8 (Avoiding Configuration Drift)**.

**Q: "What's the cost difference between Dev and Production?"**
A: Production requires more agents, hardening, scanning, and replication—roughly 2–3x the cost. Example: Dev ~$15/month, Prod ~$50–80/month. See `README.md` → **Section 3.8 (Cost Management)**.

**Q: "Can we integrate this with our existing GRC system?"**
A: Yes. The GRC ticket triggers the build request. We log all steps (build, scan, test, approval) back to the ticket. You can query image tattoo metadata for audit reports. See `README.md` → **Section 3.6 (Compliance & Audit Trail)**.

---

**Created**: December 4, 2025  
**Deck Version**: 1.0  
**Supporting Doc**: `README.md`  
**Next Review**: Post-customer-session feedback




