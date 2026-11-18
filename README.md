
# Windows Enterprise Homelab

A hands-on Windows enterprise infrastructure and security administration lab built using Microsoft Hyper-V, Windows Server 2025, and Active Directory Domain Services.

## Project Overview

This project simulates a small enterprise Windows environment for developing practical skills in:

- Windows Server administration
- Active Directory and identity management
- Network infrastructure and DNS
- PowerShell automation
- Security hardening and access control
- Security monitoring and event log analysis
- Backup and disaster recovery

The environment is hosted on a dedicated Windows 11 Pro workstation named **ARGUS**.

The goal is to build, secure, document, and maintain an enterprise-style environment using repeatable administrative procedures and security best practices.

## Infrastructure

| Component | Configuration |
|-----------|---------------|
| Hyper-V Host | ARGUS |
| Host Operating System | Windows 11 Pro |
| Processor | AMD Ryzen 9 9955HX |
| Memory | 64 GB RAM |
| Virtualization Platform | Microsoft Hyper-V |
| Domain Controller | DC01 - Windows Server 2025 Standard Evaluation |
| Domain-Joined Client | CLIENT01 - Windows 11 Enterprise Evaluation |
| Active Directory Domain | corp.example.com |
| Domain NetBIOS Name | CORP |
| Hyper-V Virtual Switch | LAB-Internal (Internal) |
| Recovery Test Switch | RECOVERY-PRIVATE (Private) |
| Host Lab IP | 10.50.10.1/24 |
| Domain Controller IP | 10.50.10.10/24 |

The primary lab uses an isolated Hyper-V internal virtual switch for communication between ARGUS and the domain environment.

A separate private Hyper-V switch, RECOVERY-PRIVATE, supports isolated virtual machine recovery testing without connecting restored domain controllers to the original lab network.

### Storage Architecture

| Volume | Purpose |
|--------|---------|
| C: | Windows host operating system, applications, and project repositories |
| D: | Hyper-V virtual machines, virtual hard disks, and recovery test storage |
| E: | External Seagate USB SSD - BitLocker-encrypted offline backup storage |

The external backup drive is disconnected when not actively performing backup or recovery operations.

## Active Directory Environment

The domain controller DC01 provides:

- Active Directory Domain Services (AD DS)
- DNS services
- LDAP-based directory services
- Kerberos authentication infrastructure
- Global Catalog functionality

### Organizational Unit Structure

The Active Directory structure separates users, computers, groups, and service accounts.

```text
corp.example.com
├── Domain Controllers
└── CORP
    ├── Users
    │   ├── IT
    │   ├── HR
    │   ├── Finance
    │   └── Operations
    ├── Workstations
    ├── Servers
    ├── Groups
    └── ServiceAccounts
```

### Departmental Security Groups

Four Global Security groups have been created:

| Security Group | Department |
|----------------|------------|
| GG_IT_Users | IT |
| GG_HR_Users | Human Resources |
| GG_Finance_Users | Finance |
| GG_Operations_Users | Operations |

Four fictional employee accounts have been provisioned and assigned to their respective departmental security groups.

## Security Implementation

The lab incorporates security controls designed to support least privilege, data protection, administrative accountability, and separation of production-like infrastructure from recovery testing.

Implemented security measures include:

- Separation of standard-user and privileged administrator accounts on ARGUS.
- Disabled built-in Windows Administrator account.
- Windows Hello PIN authentication for daily host access.
- Windows Defender Firewall rules restricting lab connectivity.
- Isolated Hyper-V networking for Active Directory infrastructure.
- Dedicated private virtual networking for recovery testing.
- SSH key-based authentication for GitHub.
- NTFS repository ownership and permission management.
- BitLocker encryption for the ARGUS host storage and external backup drive.
- Offline backup storage disconnected when not in use.


### Group Policy — Workstation Security Baseline

A custom Active Directory Group Policy Object (`GPO-Workstation-Security-Baseline`) has been deployed to the `CORP/Workstations` organizational unit.

The initial security baseline enforces a 900-second (15-minute) interactive session inactivity timeout on domain-joined workstations.

Deployment was validated on CLIENT01 using:

- `gpupdate /force` to refresh Group Policy.
- `gpresult /r /scope computer` to confirm GPO application.
- Windows Registry inspection to verify the configured timeout.
- Functional testing to confirm automatic workstation locking.

**Documentation:** [Workstation Security Baseline — Group Policy](docs/03-GroupPolicy/01-workstation-security-baseline.md)

Additional Active Directory security hardening, Group Policy configurations, and centralized security auditing are planned.

### Administrative Account Separation

| Account | Role |
|---------|------|
| ARGUS\edwad | Standard daily-use account |
| ARGUS\LabAdmin | Dedicated local administrator |
| Built-in Administrator | Disabled |

This configuration follows the principle of least privilege by separating everyday activities from privileged system administration.

## Backup and Recovery

The lab implements a PowerShell-based Hyper-V backup workflow using a dedicated 2 TB external Seagate USB SSD protected by BitLocker XTS-AES-256 encryption.

The backup process includes:

- Offline exports of DC01 and CLIENT01.
- Backup destination identity and storage health verification.
- BitLocker protection and available-space checks.
- Virtual machine state validation.
- Timestamped backup directories and persistent logging.
- Exported VHDX validation using Hyper-V PowerShell cmdlets.
- Local configuration separation to prevent machine-specific settings from being committed to GitHub.

Backups are stored beneath:

```text
E:\Hyper-V-Backups\
```

### Recovery Validation

On November 16, 2026, both DC01 and CLIENT01 were successfully restored as independent Hyper-V virtual machines from previously created exports.

CLIENT01 successfully booted and supported offline Windows authentication.

DC01 successfully booted and demonstrated functioning Active Directory Domain Services, DNS, domain controller discovery, and SYSVOL initialization within a dedicated isolated recovery network.

The recovery exercise also demonstrated Active Directory VM-Generation ID safeguards and included troubleshooting of DFS Replication configuration access.

Remaining work: A complete backup execution using the revised script configuration, Active Directory-aware system-state recovery testing, and investigation of the domain controller's Windows Time advertising warning.

These tests establish VM-level recoverability but do not constitute a complete Active Directory forest disaster-recovery validation.

For implementation details, recovery procedures, test results, and limitations, see the Hyper-V Backup Automation documentation.

## Project Roadmap

### Completed Milestones

- [x] Configure Hyper-V host and isolated networking.
- [x] Deploy Windows Server 2025 domain controller.
- [x] Configure Active Directory and DNS.
- [x] Create organizational units and departmental security groups.
- [x] Provision fictional employee accounts and group memberships.
- [x] Configure dedicated host administrator and standard-user accounts.
- [x] Establish Git and GitHub repository.
- [x] Configure and validate BitLocker encryption on host and backup storage.
- [x] Deploy Windows 11 Enterprise domain-joined client (CLIENT01).
- [x] Develop and document PowerShell based Hyper-V backup automation.
- [x] Validate exported virtual hard disks.
- [x] Successfully perform isolated VM-level recovery tests for DC01 and CLIENT01.
- [x] Document recovery procedures, test results, and limitations.
- [x] Deploy and validate workstation inactivity security policy using Active Directory Group Policy.

### Upcoming Milestones

- [ ] Validate a complete backup run using the revised configuration.
- [ ] Expand workstation security baseline with additional Group Policy configurations.
- [ ] Develop reusable PowerShell administration scripts.
- [ ] Configure Windows security auditing and event log analysis.
- [ ] Investigate and resolve the domain controller's Windows Time advertising warning.
- [ ] Implement additional Active Directory security hardening.
- [ ] Explore centralized log collection and security monitoring.
- [ ] Develop and test Active Directory-aware system-state backup and recovery procedures.

## Repository Structure

```text
windows-enterprise-homelab/
├── docs/
│   ├── 01-Infrastructure/
│   ├── 02-ActiveDirectory/
│   ├── 03-GroupPolicy/
│   └── 04-ClientDeployment/
├── scripts/
│   ├── active-directory/
│   ├── backup/
│   │   ├── Backup-HyperVVMs.ps1
│   │   ├── backup-config.example.ps1
│   │   └── README.md
│   └── infrastructure/
├── screenshots/
├── .gitignore
├── .gitattributes
└── README.md
```

## Documentation and Security

This repository contains sanitized lab documentation, configuration examples, and PowerShell scripts.

Passwords, private SSH keys, BitLocker recovery keys, virtual machine disks, and other sensitive material are excluded from version control.

All employee identities and organizational details are fictional and intended for educational use.

## Project Status

**Active Development — November 2026**

The core Windows enterprise environment is operational, including the ARGUS Hyper-V host, DC01 domain controller, and domain-joined CLIENT01 workstation.

Foundational Active Directory configuration, departmental security groups, account provisioning, host security controls, encrypted backup storage, and Hyper-V backup automation have been established.

Controlled recovery exercises completed on November 16, 2026, demonstrated successful VM-level restoration of both DC01 and CLIENT01. Recovery findings, troubleshooting procedures, and outstanding limitations are documented in the backup project README.

Current development focus: Active Directory administration, Group Policy implementation, endpoint security configuration, and PowerShell automation.

Future work will expand into Windows security auditing, centralized event collection, and practical cybersecurity monitoring exercises.