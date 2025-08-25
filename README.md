# system-report-ps
Windows system health report for trading/app servers (PowerShell). Generates a timestamped report with OS, uptime, CPU, memory, and disk usage.

## Requirements
- PowerShell 7+

## Run
```powershell
# Save to Desktop (default) and print report
.\SystemReport.ps1

# Custom output path and auto-open
.\SystemReport.ps1 -Path "C:\Temp" -Open

# Show version
.\SystemReport.ps1 -Version
