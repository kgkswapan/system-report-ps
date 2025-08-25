<#
.SYNOPSIS
Generates a simple system report and saves it to a timestamped text file.

.DESCRIPTION
Collects OS, uptime, CPU, memory, and disk usage. Saves to Desktop by default.
Optionally choose a different folder with -Path and open the saved report with -Open.

.PARAMETER Path
Folder to save the report into. Defaults to the current user's Desktop.

.PARAMETER Open
If supplied, opens the saved report after writing it.

.PARAMETER Version
Print the script version and exit.

.EXAMPLE
PS> .\SystemReport.ps1
Creates a report on your Desktop and prints the contents.

.EXAMPLE
PS> .\SystemReport.ps1 -Open
Creates a report and opens it with your default editor.

.EXAMPLE
PS> .\SystemReport.ps1 -Path "C:\Temp"
Saves the report to C:\Temp instead of Desktop.

.EXAMPLE
PS> .\SystemReport.ps1 -Version
Shows the script version and exits.

.NOTES
Author: You
#>

[CmdletBinding(PositionalBinding = $false)]

param(
    [string]$path,
    [switch]$Open = $true, # default to open
    [switch]$Version
)

# Version banner
$Script:ScriptVersion = '1.0.0'
if ($Version.IsPresent) {
    Write-Output "SystemReport.ps1" v$Script:ScriptVersion
    return
}

$ErrorActionPreference = 'Stop' # fail fast

# Get computer info to variables
$now = Get-Date
$computer = $env:COMPUTERNAME
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime

#CPU
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)

#Memory
$cs = Get-CimInstance Win32_ComputerSystem
$totalMemGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$freeMemGB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 1)
$usedMemGB = [math]::Round([math]::Max($totalMemGB - $freeMemGB, 0), 1)
$memPctUsed = [math]::Round(($usedMemGB / $totalMemGB) *100)

#Disk
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$diskLines = foreach ($d in $disks){
    $sizeGB = if ($d.Size) { [math]::Round($d.Size / 1GB, 1) } else { 0 }
    $freeGB = if ($d.FreeSpace) { [math]::Round($d.FreeSpace / 1GB, 1) } else { 0 }
    $usedGB = [math]::Round([math]::Max($sizeGB - $freeGB, 0), 1)
    $pct = if ($sizeGB -ne 0) { [math]::Round(($usedGB / $sizeGB) * 100)} else { 0 }
    "{0}: {1}/{2} GB ({3}% used)" -f $d.DeviceID, $usedGB, $sizeGB, $pct
}
$diskSummary = $diskLines -join [System.Environment]::NewLine

# Build the report text
$report = @"
******************** System Report ********************
Computer: $computer
Generated: $($now.ToString('dd-MM-yyyy HH:mm:ss'))
OS: $($os.Caption) ($($os.Version))
Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m
CPU: $cpu
Memory: $usedMemGB/$totalMemGB GB ($memPctUsed% used)
Disks:
$diskSummary
************************* End *************************
"@

# Decide save folder
$folder = if ($PSBoundParameters.ContainsKey('Path') -and $path) {
    $path
} else {
    [System.Environment]::GetFolderPath('Desktop')
}

# Ensure folder exists
if (-not (Test-Path -LiteralPath $folder)) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

# Save to folder with timestamped filename
$filename = "SystemReport_$($now.ToString('yyyy-MM-dd_HHmmss')).txt"
$savePath = Join-Path $folder $filename
$report | Set-Content -Path $savePath -Encoding UTF8

# Also print to screen
Write-Host $report
Write-Host "Saved to: $savePath"

# Optionally open the file
if($Open.IsPresent) {
    try {
        Start-Process -FilePath $savePath -ErrorAction Stop
    } catch {
        Write-Warning "Default app failed to open the file: $($_.Exception.Message)"
        try {
            # Fallback: open Explorer with the file pre-selected
            Start-Process -FilePath "explorer.exe" -ArgumentList "/select,`"$savePath`"" -ErrorAction Stop
        } catch {
            Write-Warning "Exlorer fallback also failed: $($_.Exception.Message)"
        }
    }
}
