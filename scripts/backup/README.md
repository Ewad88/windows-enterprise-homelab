# ARGUS Hyper-V Backup Automation

## Overview

This project implements a PowerShell-based backup workflow for the ARGUS Windows enterprise homelab.

The script exports two Hyper-V virtual machines, DC01 and CLIENT01, to an encrypted external USB drive. Before beginning an export, it performs a series of checks designed to prevent backups to an incorrect destination or under unexpected operating conditions.

The workflow includes timestamped backup directories, disk identity verification, BitLocker protection checks, virtual machine state validation, exported VHDX validation, and persistent logging.

## Objectives

- Automate repeatable Hyper-V virtual machine exports.
- Verify the identity and readiness of the backup destination.
- Require both virtual machines to be powered off before exporting.
- Validate exported virtual disks for structural integrity and parent disk dependencies.
- Maintain an auditable record of backup operations.
- Separate machine-specific configuration from publicly version-controlled source code.

## Current Status

Successful Hyper-V exports and VHDX validation have been demonstrated for both DC01 and CLIENT01.

On November 16, 2026, controlled recovery tests were successfully performed for both virtual machines using exports created on November 11, 2026. Both VMs were imported as independent copies with new Hyper-V identifiers and successfully booted from recovered virtual disks stored on ARGUS.

CLIENT01 recovery included successful Windows sign-in using cached domain credentials while isolated from the original domain network.

DC01 recovery included successful Active Directory Domain Services and DNS startup, domain controller discovery, SYSVOL initialization, and targeted diagnostic validation. An isolated private Hyper-V network was required to restore DFS Replication configuration access. A Windows Time advertising warning remains documented for follow-up.

These tests validate VM-level recovery from the existing exports, but do not constitute a complete Active Directory forest recovery test.

The configuration-loading mechanism has been independently tested. A full backup run using the revised configuration remains outstanding.

## Environment

The backup automation was developed and tested in the following homelab environment:

| Component | Configuration |
|-----------|---------------|
| Hyper-V Host | ARGUS |
| Host operating system | Windows 11 Pro |
| PowerShell | PowerShell 7.6.6 |
| Virtualization platform | Microsoft Hyper-V |
| Domain controller VM | DC01 - Windows Server 2025 Evaluation |
| Client VM | CLIENT01 - Windows 11 Enterprise Evaluation |
| Backup destination | External USB SSD (ARGUS-BACKUP) |
| Backup volume | NTFS |
| Drive encryption | BitLocker XTS-AES-256 |
| Backup method | Hyper-V Export-VM |

The external backup drive is intended to remain disconnected when not actively performing backup operations.

## Prerequisites

Before executing the script, ensure the following requirements are met:

1. **Administrator privileges:** Run PowerShell with elevated permissions to manage Hyper-V and inspect storage security settings.
2. **Hyper-V:** The Hyper-V platform and management PowerShell cmdlets must be available on the host.
3. **Backup drive:** Connect and unlock the designated BitLocker-encrypted external drive.
4. **Virtual machine state:** Shut down both DC01 and CLIENT01 before initiating the backup.
5. **Available storage:** Ensure the backup destination has at least 100 GB of free space.
6. **Local configuration:** Create backup-config.local.ps1 from the provided configuration template and supply the expected physical disk identifier.

The script performs preflight checks before exporting virtual machines. If a required condition is not satisfied, the backup operation is designed to stop rather than proceed with an unverified destination or unsupported VM state.

## Backup Workflow and Security Checks

### 1. Backup Destination Verification

The script verifies the following properties of the connected backup drive:

- Expected volume label (ARGUS-BACKUP).
- Expected physical disk identifier, loaded from the local configuration file.
- USB connection type.
- Healthy storage status.
- At least 100 GB of available space.

Verifying the physical disk identifier provides an additional safeguard beyond relying solely on the assigned drive letter or volume label.

### 2. BitLocker Verification

Before exporting virtual machines, the script checks that the backup volume is:

- Fully encrypted.
- Protected by BitLocker.
- Unlocked and accessible.

The designated backup drive uses BitLocker XTS-AES-256 encryption to protect stored virtual machine data.

### 3. Virtual Machine State Verification

Both DC01 and CLIENT01 must be powered off before the backup operation proceeds.

This requirement provides a consistent offline export workflow and avoids relying on live VM backup mechanisms.

### 4. Hyper-V Export

After the preflight checks pass, the script:

1. Creates a timestamped directory under E:\Hyper-V-Backups.
2. Exports CLIENT01 using the Hyper-V Export-VM cmdlet.
3. Exports DC01 using the same procedure.
4. Records the results of each operation in the backup log.

Each backup run is stored in a separate directory to distinguish it from previous exports.

### 5. Exported Disk Validation

Following export, the script performs validation of the exported virtual hard disks using Hyper-V PowerShell cmdlets.

The validation includes:

- Checking exported VHDX files using `Test-VHD`.
- Inspecting virtual disk parent dependencies.
- Verifying the expected dynamic disk type for CLIENT01.

These checks provide evidence that the exported virtual disks are structurally accessible, but they do not guarantee that a restored virtual machine will boot successfully.

A controlled restore test is required to establish practical recoverability.

## Configuration and Execution

### 1. Configure the Backup Disk Identifier

The repository includes a configuration template named backup-config.example.ps1.

Create a local configuration file in the same directory as the backup script:

```powershell
Copy-Item .\scripts\backup\backup-config.example.ps1 .\scripts\backup\backup-config.local.ps1
```

Edit backup-config.local.ps1 and replace the placeholder with the physical disk identifier of the intended backup device.

```powershell
Get-Partition -DriveLetter E | Get-Disk | Select-Object FriendlyName, UniqueId, BusType
```

The local configuration should contain:

```text
$ExpectedDiskUniqueId = 'YOUR_BACKUP_DISK_UNIQUE_ID'
```

The script loads this file using PowerShell dot-sourcing. The .gitignore file excludes backup-config.local.ps1 from version control, allowing machine-specific configuration to remain local.

**Note:** The current implementation uses ARGUS-specific settings, including VM names, drive letter, volume label, and backup paths. These must be reviewed before adapting the script to another environment.

### 2. Prepare the Backup Environment

Before running the script:

1. Connect the designated external backup drive.
2. Unlock the BitLocker-protected volume.
3. Shut down DC01 and CLIENT01.
4. Verify that the drive is accessible as E:.
5. Open PowerShell 7 as administrator.

### 3. Execute the Backup Script

From the repository root directory, run:

```powershell
.\scripts\backup\Backup-HyperVVMs.ps1
```

The script performs its preflight checks before initiating the Hyper-V exports.

If a required check fails, the script is designed to stop and report the failure rather than proceed with the backup.

Successful execution creates a timestamped export directory beneath:

```text
E:\Hyper-V-Backups\
```

Backup logs are written to:

```text
C:\ProgramData\ARGUS\BackupLogs\
```

**Security consideration:** The local configuration file is executable PowerShell code. Only use a configuration file you trust, and restrict write access to authorized administrators.

## Logging and Validation

### Backup Logging

The script maintains timestamped log files in:

```text
C:\ProgramData\ARGUS\BackupLogs\
```

Log entries include timestamps and status indicators:

- [INFO] - Operational information and progress.
- [PASS] - Successfully completed checks or operations.
- [FAIL] - Failed checks or operations.

Logs provide a record of backup execution, including preflight checks, virtual machine exports, validation results, and reported failures.

### Export Validation

Following each virtual machine export, the script uses Hyper-V PowerShell cmdlets to inspect the exported virtual hard disks.

Validation includes:

- `Test-VHD` to check virtual disk accessibility and structural integrity.
- `Get-VHD` to inspect disk properties and parent dependencies.
- Verification of the expected dynamic VHDX type for CLIENT01.

Successful validation confirms that the exported disks passed these checks. It does not independently establish that the guest operating systems, applications, or AD services can be successfully recovered.

### Limitations and Future Improvements

The current implementation has several intentional limitations:

1. **Offline backups:** Both virtual machines must be powered off before export.
2. **Environment-specific configuration:** Some paths, drive properties, and virtual machine names are specific to ARGUS.
3. **No automated retention:** Previous backup directories are not automatically deleted or rotated.
4. **No automated scheduling:** Backups are initiated manually.
5. **Recovery Scope:** Controlled VM-level recovery tests have been completed, but comprehensive Active Directory forest recovery and system-state restoration have not been tested.
6. **No automated notifications:** Backup results are recorded locally rather than sent through email or another notification service.

### Recovery Testing

**Test date:** November 16, 2026
**Backup source:** `E:\Hyper-V-Backups\2026-11-11_171954`
**Recovery destination:** `D:\Hyper-V\RecoveryTests`

Controlled recovery tests were performed for both CLIENT01 and DC01 using previously exported Hyper-V virtual machines. Each VM was imported using `Import-VM -Copy -GenerateNewId` to create an independent recovery instance without overwriting the original VM.

Recovered virtual disks were stored on ARGUS's internal storage, and both original VMs remained powered off throughout their respective recovery tests.

#### CLIENT01 Recovery

The Windows 11 Enterprise Evaluation client was restored as `CLIENT01-RECOVERY`.

Validation included:

- Successful Hyper-V import with a new VM identifier.
- Verification of the independent recovered VHDX location.
- Disconnection from the original domain network.
- Successful Windows boot and interactive sign-in using cached domain credentials.
- Verification of the guest hostname, domain membership configuration, and operating system build.
- Graceful shutdown after testing.

**Result:** VM-level recovery successful. Live domain authentication and domain connectivity were intentionally not tested.

#### DC01 Recovery

The Windows Server 2025 Evaluation domain controller was restored as `DC01-RECOVERY`.

The recovered VM retained the original hostname, domain identity, and static IP address. It was never connected to the original `LAB-Internal` network.

Validation included:

- Successful Hyper-V import with a new VM identifier.
- Verification of the independent recovered VHDX location.
- Successful Windows Server boot and administrator sign-in.
- Confirmation that Active Directory Domain Services (NTDS) and DNS services were running.
- Observation of VM-Generation ID change detection and Active Directory recovery safeguards.
- Successful domain controller discovery using `nltest /dsgetdc:corp.example.com`.
- Successful DFS Replication configuration retrieval and SYSVOL initialization.
- Verification of the SYSVOL and NETLOGON shares.
- Verification of the Default Domain Policy and Default Domain Controllers Policy directories.
- Successful `dcdiag` Connectivity and SysVolCheck tests.
- Graceful shutdown after testing.

#### DFS Replication Troubleshooting

During the initial isolated boot, DFS Replication logged Event ID 1202 because it could not contact a domain controller to retrieve configuration information.

A dedicated private Hyper-V switch named `RECOVERY-PRIVATE` was created, and only DC01-RECOVERY was connected to it. This provided an active network link without connecting the recovered domain controller to the original lab network.

After restarting the recovered VM:

- Event ID 1206 confirmed successful retrieval of Active Directory configuration.
- Event ID 4602 confirmed successful SYSVOL initialization as the designated primary member.
- Event ID 1210 confirmed successful initialization of the DFS Replication RPC listener.

The recovery also triggered Active Directory VM-Generation ID safeguards, including an invocation ID change and SYSVOL recovery initialization.

#### Remaining Findings and Limitations

The `dcdiag` Advertising test reported that DC01 was not advertising as a time server. Windows Time reported an unsynchronized state while using the Hyper-V VM IC Time Synchronization Provider. This warning remains unresolved and is reserved for later investigation on the original DC01.

These tests demonstrate successful restoration and targeted service validation from the existing Hyper-V exports. They do not establish complete Active Directory forest recovery, comprehensive Group Policy integrity, or successful recovery from every possible failure scenario.

The exported backups were created before the revised configuration-loading mechanism was finalized. A complete backup execution using the revised configuration remains outstanding.

**Overall result:** Both VM-level recovery tests completed successfully, with the Windows Time advertising warning and broader disaster-recovery limitations documented.

## Project Status

- [x] Implement initial PowerShell backup automation.

- [x] Successfully export both Hyper-V virtual machines.

- [x] Validate exported virtual hard disks.

- [x] Implement timestamped logging.

- [x] Separate local disk configuration from version-controlled source code.

- [x] Independently test local configuration loading and disk identifier matching.

- [x] Perform a controlled CLIENT01 recovery test.

- [x] Perform a controlled DC01 recovery test on an isolated private Hyper-V network.

- [x] Validate recovered Active Directory services, domain controller discovery, and SYSVOL initialization.

- [x] Document recovery procedures, diagnostic findings, and limitations.

- [ ] Complete a full backup using the revised configuration.

- [ ] Investigate the Windows Time advertising warning on the original DC01.

- [ ] Develop and test an Active Directory-aware system-state backup and recovery procedure.

**Important:** Successful Hyper-V exports and VM-level recovery tests do not replace Active-Directory-aware system-state backups or comprehensive disaster-recovery planning.
