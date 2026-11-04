
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
| Domain Controller | DC01 |
| Server Operating System | Windows Server 2025 Standard Evaluation |
| Active Directory Domain | corp.example.com |
| Domain NetBIOS Name | CORP |
| Hyper-V Virtual Switch | LAB-Internal |
| Host Lab IP | 10.50.10.1/24 |
| Domain Controller IP | 10.50.10.10/24 |

The lab uses an isolated Hyper-V internal virtual switch to separate domain infrastructure traffic from the host's normal internet connection.

### Storage Architecture

| Volume | Purpose |
|--------|---------|
| C: | Windows host operating system and applications |
| D: | Hyper-V virtual machines and virtual hard disks |
| E: | External Seagate backup and recovery storage |

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

Security measures implemented or currently being developed include:

- Separation of standard-user and administrator accounts on ARGUS
- Disabled built-in Windows Administrator account
- Windows Hello PIN authentication for daily host access
- Windows Defender Firewall rules restricting lab connectivity
- SSH key authentication for GitHub
- NTFS repository ownership and permission management
- BitLocker encryption for host and backup storage (in progress)

### Administrative Account Separation

| Account | Role |
|---------|------|
| ARGUS\edwad | Standard daily-use account |
| ARGUS\LabAdmin | Dedicated local administrator |
| Built-in Administrator | Disabled |

This configuration follows the principle of least privilege by separating everyday activities from privileged system administration.

## Backup and Recovery

The lab uses a 2 TB external Seagate hard drive for offline backup storage.

A Hyper-V export of DC01 has been created and its virtual disk validated.

Backup location:

```text
E:\Hyper-V-Exports\DC01\
```

The external backup drive is undergoing BitLocker encryption.

Future work includes Active Directory system-state backups, isolated restoration testing, and backup automation.

## Project Roadmap

- [x] Configure Hyper-V host and isolated networking
- [x] Deploy Windows Server 2025 domain controller
- [x] Configure Active Directory and DNS
- [x] Create organizational units and departmental security groups
- [x] Provision employee accounts and group memberships
- [x] Configure dedicated host administrator and standard-user accounts
- [x] Establish Git and GitHub repository
- [ ] Complete BitLocker encryption and validation
- [ ] Deploy Windows 11 domain-joined client
- [ ] Implement Group Policy Objects (GPOs)
- [ ] Develop reusable PowerShell administration scripts
- [ ] Configure security auditing and event log analysis
- [ ] Test Active Directory and virtual machine recovery procedures

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

The core Active Directory environment is operational. Current work focuses on host security hardening, documentation, and preparation for Windows client deployment.