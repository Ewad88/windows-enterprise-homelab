# ARGUS Hyper-V Backup Automation
# Purpose: Back up DC01 and CLIENT01 to encrypted external storage.

# Stop execution when PowerShell encounters an error
$ErrorActionPreference = 'Stop'

# Backup configuration
$BackupDrive = 'E:'
$ExpectedVolumeLabel = 'ARGUS-BACKUP'
$MinimumFreeSpaceGB = 100

# Load machine-specific configuration
$LocalConfigPath = Join-Path $PSScriptRoot 'backup-config.local.ps1'

if (-not (Test-Path -LiteralPath $LocalConfigPath)) {
    throw "Local backup configuration not found: $LocalConfigPath"
}

. $LocalConfigPath

if ([string]::IsNullOrWhiteSpace($ExpectedDiskUniqueId)) {
    throw 'Expected backup disk identifier is missing from local configuration.'
}

# Virtual machines included in the backup
$VMNames = @(
    'DC01'
    'CLIENT01'
)

# Backup destination configuration
$BackupRoot = Join-Path $BackupDrive 'Hyper-V-Backups'
$BackupTimestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$BackupPath = Join-Path $BackupRoot $BackupTimestamp

# -----------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------
$LogDirectory = 'C:\ProgramData\ARGUS\BackupLogs'
$LogTimestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$LogFile = Join-Path $LogDirectory "Backup_$LogTimestamp.log"

# Write timestamped messages to the backup log
function Write-BackupLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$Timestamp [$Level] $Message"

    Add-Content -Path $LogFile -Value $LogEntry
    Write-Host $LogEntry
}
Write-BackupLog -Message 'ARGUS backup preflight started.'

try {
# Verify the backup drive identity
$Volume = Get-Volume -DriveLetter $BackupDrive.TrimEnd(':')

if ($Volume.FileSystemLabel -eq $ExpectedVolumeLabel) {
    Write-Host "PASS: Correct backup drive detected." -ForegroundColor Green
}
else {
    throw "FAIL: Unexpected backup drive. Expected $ExpectedVolumeLabel." 
}

# Verify backup volume health
if ($Volume.HealthStatus -ne 'Healthy') {
    throw "FAIL: Backup drive health is $($Volume.HealthStatus)."
}
Write-Host "PASS: Backup volume reports healthy status." -ForegroundColor Green

# Verify the physical backup disk identity
$PhysicalDisk = Get-Partition -DriveLetter $BackupDrive.TrimEnd(':') | Get-Disk

if ($PhysicalDisk.UniqueId -ne $ExpectedDiskUniqueId) {
    throw "FAIL: Unexpected physical backup disk detected."
}
if ($PhysicalDisk.BusType -ne 'USB') {
    throw "FAIL: Backup disk is not connected through USB."
}
Write-Host "PASS: Seagate backup disk identity verified." -ForegroundColor Green

# Verify sufficient free space on the backup drive
$FreeSpaceGB = [math]::Round($Volume.SizeRemaining / 1GB, 2)

if ($FreeSpaceGB -ge $MinimumFreeSpaceGB) {
    Write-Host "PASS: $FreeSpaceGB GB available on backup drive." -ForegroundColor Green
}
else {
    throw "FAIL: Insufficient backup storage. Only $FreeSpaceGB GB available." 
}

# Verify that all required virtual machines are powered off
foreach ($VMName in $VMNames) {
    $VM = Get-VM -Name $VMName -ErrorAction Stop

    if ($VM.State -eq "Off") {
        Write-Host "PASS: $VMName exists and is powered off." -ForegroundColor Green
    }
    else {
        throw "FAIL: $VMName must be powered off. Current state: $($VM.State)"
    }
}

# Verify BitLocker protection on the backup drive
$BitLocker = Get-BitLockerVolume -MountPoint $BackupDrive

if ($BitLocker.VolumeStatus -ne 'FullyEncrypted') {
    throw "FAIL: Backup drive is not fully encrypted."
}
if ($BitLocker.ProtectionStatus -ne 'On') {
    throw "FAIL: BitLocker protection is not enabled."
}
if ($BitLocker.LockStatus -ne 'Unlocked') {
    throw "FAIL: Backup drive is locked."
}
Write-Host "PASS: BitLocker encryption and protection verified" -ForegroundColor Green

Write-BackupLog -Message 'All preflight checks passed.' -Level 'PASS'

# Prepare a unique directory for this backup session
if (Test-Path -LiteralPath $BackupPath) {
    throw "Backup directory already exists: $BackupPath"
}

New-Item -ItemType Directory -Path $BackupPath -ErrorAction Stop | Out-Null

# Confirm the new backup directory is empty
$ExistingItems = @(Get-ChildItem -LiteralPath $BackupPath -Force)

if ($ExistingItems.Count -gt 0) {
    throw "Backup directory is not empty: $BackupPath"
}

Write-BackupLog -Message "Created backup directory: $BackupPath" -Level 'PASS'

#Export CLIENT01 to the validated backup destination
Write-BackupLog -Message 'Starting CLIENT01 export.'

Export-VM -Name 'CLIENT01' -Path $BackupPath -ErrorAction Stop

Write-BackupLog -Message 'CLIENT01 export completed.' -Level 'PASS'

# Validate the exported CLIENT01 virtual disk
$ExportedDiskPath = Join-Path $BackupPath 'CLIENT01\Virtual Hard Disks\CLIENT01.vhdx'

Write-BackupLog -Message 'Validating exported CLIENT01 disk.'

if (-not (Test-VHD -Path $ExportedDiskPath -ErrorAction Stop)) {
    throw 'CLIENT01 exported virtual disk failed validation.'
}

$ExportedDisk = Get-VHD -Path $ExportedDiskPath -ErrorAction Stop

if ($ExportedDisk.VhdType -ne 'Dynamic') {
    throw "Unexpected CLIENT01 disk type: $($ExportedDisk.VhdType)"
}

if ($ExportedDisk.ParentPath) {
    throw 'CLIENT01 exported disk has a parent dependency.'
}

Write-BackupLog -Message 'CLIENT01 exported disk validation passed.' -Level 'PASS'

# Export DC01
Write-BackupLog -Message 'Starting DC01 export.'

Export-VM -Name 'DC01' -Path $BackupPath -ErrorAction Stop

Write-BackupLog -Message 'DC01 export completed.' -Level 'PASS'

# Validate the exported DC01 virtual disk
$DC01DiskPath = Join-Path $BackupPath 'DC01\Virtual Hard Disks\DC01.vhdx'

Write-BackupLog -Message 'Validating exported DC01 disk.'

if (-not (Test-VHD -Path $DC01DiskPath -ErrorAction Stop)) {
    throw 'DC01 exported virtual disk failed validation.'
}

$DC01Disk = Get-VHD -Path $DC01DiskPath -ErrorAction Stop

if ($DC01Disk.ParentPath) {
    throw 'DC01 exported disk has a parent dependency.'
}

Write-BackupLog -Message 'DC01 exported disk validation passed.' -Level 'PASS'

# Record successful completion of the backup operation
Write-BackupLog -Message "ARGUS backup completed successfully: $BackupPath" -Level 'PASS'

}
catch {
    Write-BackupLog -Message $_.Exception.Message -Level 'FAIL'
    throw
}
