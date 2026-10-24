param(
    [switch]$Help
)

if ($Help) {
    Write-Host @'
Usage:
  Set-ExecutionPolicy -Scope Process Bypass
  .\Set-WindowsSetup.ps1
  .\Set-WindowsSetup.ps1 -Help

Run PowerShell as Administrator to apply the machine-wide Recall policy
and install Visual Studio. The script installs the listed applications
using WinGet and applies the OneDrive and File Explorer settings.
'@
    exit 0
}

$ErrorActionPreference = 'SilentlyContinue'

# --- Setup Dark Theme ---
$path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

New-Item -Path $path -Force | Out-Null
Set-ItemProperty -Path $path -Name AppsUseLightTheme -Type DWord -Value 0
Set-ItemProperty -Path $path -Name SystemUsesLightTheme -Type DWord -Value 0

# --- Conservative Windows 11 inbox-app cleanup ---

$AppPatterns = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($pattern in $AppPatterns) {
    # Remove the app for existing user accounts where it is installed
    Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "Removed: $($_.Name)"
            }
            catch {
                Write-Warning "Couldn't remove $($_.Name): $($_.Exception.Message)"
            }
        }

    # Stop Windows provisioning it for newly created user accounts
    Get-AppxProvisionedPackage -Online |
        Where-Object { $_.DisplayName -like $pattern } |
        ForEach-Object {
            try {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop |
                    Out-Null
                Write-Host "Deprovisioned: $($_.DisplayName)"
            }
            catch {
                Write-Warning "Couldn't deprovision $($_.DisplayName): $($_.Exception.Message)"
            }
        }
}

# --- Stop OneDrive and disable its current-user startup entry ---
Stop-Process -Name OneDrive -Force

$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
Remove-ItemProperty -Path $runKey -Name OneDrive

# --- File Explorer preferences ---
$advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

# Open to This PC
Set-ItemProperty -Path $advanced -Name LaunchTo -Type DWord -Value 1

# Hide recently used files and frequently used folders
Set-ItemProperty -Path $advanced -Name ShowRecent -Type DWord -Value 0
Set-ItemProperty -Path $advanced -Name ShowFrequent -Type DWord -Value 0

# Hide cloud files from Office.com in Quick Access/Home (if supported by this Windows build)
Set-ItemProperty -Path $advanced -Name ShowCloudFilesInQuickAccess -Type DWord -Value 0

# Show hidden files, but keep protected operating-system files hidden
Set-ItemProperty -Path $advanced -Name Hidden -Type DWord -Value 1
Set-ItemProperty -Path $advanced -Name ShowSuperHidden -Type DWord -Value 0

# --- Disable Windows Copilot policy for the current user ---
$copilotPolicy = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
New-Item -Path $copilotPolicy -Force | Out-Null
New-ItemProperty -Path $copilotPolicy -Name TurnOffWindowsCopilot `
    -PropertyType DWord -Value 1 -Force | Out-Null

# --- Block Recall enablement (machine-wide; requires Administrator) ---
if ([Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $windowsAIPolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI'
    New-Item -Path $windowsAIPolicy -Force | Out-Null
    New-ItemProperty -Path $windowsAIPolicy -Name AllowRecallEnablement `
        -PropertyType DWord -Value 0 -Force | Out-Null
} else {
    Write-Warning 'Not elevated: Recall machine policy was skipped. Rerun PowerShell as Administrator to apply it.'
}

# Restart Explorer so its settings refresh
Stop-Process -Name explorer -Force
Start-Process explorer.exe

Write-Host 'Settings applied. Restart Windows if Copilot or Recall changes are not reflected.'

# --- Ensure WinGet is installed ---
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'WinGet not found; registering or repairing App Installer...'

    try {
        # Register the built-in App Installer package if it is already present
        Add-AppxPackage -RegisterByFamilyName `
            -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe `
            -ErrorAction Stop
    }
    catch {
        # Bootstrap WinGet and its required dependencies from Microsoft's module
        Install-PackageProvider -Name NuGet -Force | Out-Null
        Install-Module -Name Microsoft.WinGet.Client `
            -Repository PSGallery -Force -Scope CurrentUser
        Import-Module Microsoft.WinGet.Client
        Repair-WinGetPackageManager -AllUsers
    }

    # Allow App Installer registration to finish, then check again
    Start-Sleep -Seconds 5
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'WinGet is still unavailable. Sign out and back in, then rerun the script.'
    }
}

# --- Install development tools (requires winget) ---
$packages = @(
    'Mozilla.Firefox'
    'Microsoft.VisualStudioCode'
)

foreach ($package in $packages) {
    winget install --exact --id $package --accept-package-agreements `
        --accept-source-agreements --silent

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget install failed for $package (exit code $LASTEXITCODE)."
    }
}
