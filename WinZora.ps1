# Check Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[-] Please run WinZora as Administrator!" -ForegroundColor Red
    Exit
}

Clear-Host
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                     WINZORA ISO BUILDER v1.0                                " -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan

# 1. SELECT ISO FILE VIA GRAPHICAL DIALOG
Write-Host "[+] Please select your Windows 11 ISO file from the popup window..." -ForegroundColor Green
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Filter = "ISO Files (*.iso)|*.iso"
$OpenFileDialog.Title = "Select Windows 11 ISO File"

if ($OpenFileDialog.ShowDialog() -eq "OK") {
    $SourceISO =$OpenFileDialog.FileName
    Write-Host "[+] Selected ISO: $SourceISO" -ForegroundColor Cyan
} else {
    Write-Host "[-] No ISO selected. Exiting." -ForegroundColor Red
    Exit
}

# Paths & Variables
$WorkDir     = "C:\WinZora"
$ISO_Path    = "C:\ISO"
$Final_ISO   = "C:\WinZora.iso"
$OscdimgPath = "$WorkDir\oscdimg.exe"

$OscdimgUrl  = "https://raw.githubusercontent.com/Rauseen/WinZora/main/oscdimg.exe"
$UnattendUrl = "https://raw.githubusercontent.com/Rauseen/WinZora/main/autounattend.xml"

# Setup Workspace & Download Required Tools
if (-not (Test-Path -Path $WorkDir)) { 
    New-Item -ItemType Directory -Path $WorkDir | Out-Null 
}

if (-not (Test-Path -Path $OscdimgPath)) {
    Write-Host "[+] Downloading Oscdimg tool..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $OscdimgUrl -OutFile$OscdimgPath -UseBasicParsing
}

# 2. MOUNT ISO & COPY CONTENTS
Write-Host "[+] Mounting selected ISO..." -ForegroundColor Cyan
$Mounted = Mount-DiskImage -ImagePath$SourceISO -PassThru
$DriveLetter = ($Mounted | Get-Volume).DriveLetter + ":"

Write-Host "[+] Copying ISO contents to working directory ($ISO_Path)..." -ForegroundColor Cyan
if (-not (Test-Path -Path $ISO_Path)) { 
    New-Item -ItemType Directory -Path $ISO_Path | Out-Null 
}
Copy-Item -Path "$DriveLetter\*" -Destination $ISO_Path -Recurse -Force
Get-ChildItem -Path $ISO_Path -Recurse \vert{} ForEach-Object {$_.Attributes = 'Normal' }

# Unmount original ISO
Dismount-DiskImage -ImagePath $SourceISO | Out-Null

# 3. INJECT AUTOUNATTEND.XML
Write-Host "[+] Injecting autounattend.xml..." -ForegroundColor Green
Invoke-WebRequest -Uri $UnattendUrl -OutFile "$ISO_Path\autounattend.xml" -UseBasicParsing

# 4. CLEANUP UNNECESSARY FOLDERS
Write-Host "[+] Cleaning unnecessary folders..." -ForegroundColor Green
$TrashFolders = @(
    "$ISO_Path\support",
    "$ISO_Path\sources\asz",
    "$ISO_Path\sources\tdb",
    "$ISO_Path\sources\uup",
    "$ISO_Path\sources\_manifest",
    "$ISO_Path\sources\ca-es",
    "$ISO_Path\sources\eu-es",
    "$ISO_Path\sources\gl-es",
    "$ISO_Path\sources\id-id",
    "$ISO_Path\sources\vi-vn"
)

$TrashFolders | ForEach-Object {
    if (Test-Path -Path $_) { 
        Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue 
    }
}

if (Test-Path -Path "$ISO_Path\__chunk_data") { 
    Remove-Item -Path "$ISO_Path\__chunk_data" -Force -ErrorAction SilentlyContinue 
}

# 5. BUILD ISO
Write-Host "[+] Building bootable ISO ($Final_ISO)..." -ForegroundColor Yellow
$OscdimgArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$ISO_Path\boot\etfsboot.com`"#pEF,e,b`"$ISO_Path\efi\microsoft\boot\efisys.bin`" `"$ISO_Path`" `"$Final_ISO`""
Start-Process -FilePath $OscdimgPath -ArgumentList$OscdimgArgs -Wait -NoNewWindow

# 6. FINAL CLEANUP
Write-Host "[+] Cleaning up temporary files..." -ForegroundColor Red
if (Test-Path -Path $ISO_Path) { 
    Remove-Item -Path $ISO_Path -Recurse -Force -ErrorAction SilentlyContinue 
}
if (Test-Path -Path $WorkDir) { 
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue 
}

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] WinZora ISO Created Successfully: $Final_ISO" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Cyan
