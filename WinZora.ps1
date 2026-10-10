# Check Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[-] Please run WinZora as Administrator!" -ForegroundColor Red
    Exit
}

Clear-Host
Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                                   WINZORA                                    " -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan

# Paths & Variables
$WorkDir      = "C:\WinZora"
$ISO_Path     = "C:\ISO"
$Final_ISO    = "C:\WinZora.iso"
$OscdimgPath  = "$WorkDir\oscdimg.exe"

# Direct raw links from repository root
$OscdimgUrl   = "https://raw.githubusercontent.com/Rauseen/WinZora/main/oscdimg.exe"
$UnattendUrl  = "https://raw.githubusercontent.com/Rauseen/WinZora/main/autounattend.xml"

# Setup Workspace & Download Required Tools
Write-Host "[+] Preparing workspace ($WorkDir)..." -ForegroundColor Green
if (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

if (!(Test-Path $OscdimgPath)) {
    Write-Host "[+] Downloading Oscdimg tool..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $OscdimgUrl -OutFile $OscdimgPath -UseBasicParsing
}

# Inject autounattend.xml into ISO Folder
Write-Host "[+] Injecting autounattend.xml into ISO directory..." -ForegroundColor Green
Invoke-WebRequest -Uri $UnattendUrl -OutFile "$ISO_Path\autounattend.xml" -UseBasicParsing

# Cleanup ISO Unnecessary Files & Folders
Write-Host "`n[+] Cleaning unnecessary folders from ISO..." -ForegroundColor Green
$TrashFolders = @(
    "$ISO_Path\support",
    "$ISO_Path\sources\asz", "$ISO_Path\sources\tdb", "$ISO_Path\sources\uup",
    "$ISO_Path\sources\_manifest", "$ISO_Path\sources\ca-es", "$ISO_Path\sources\eu-es",
    "$ISO_Path\sources\gl-es", "$ISO_Path\sources\id-id", "$ISO_Path\sources\vi-vn"
)
foreach ($Folder in$TrashFolders) {
    if (Test-Path $Folder) { Remove-Item -Path$Folder -Recurse -Force -ErrorAction SilentlyContinue }
}
if (Test-Path "$ISO_Path\__chunk_data") { Remove-Item -Path "$ISO_Path\__chunk_data" -Force }

# Build Bootable ISO Image
Write-Host "`n[+] Building bootable ISO ($Final_ISO)..." -ForegroundColor Yellow
$OscdimgArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$ISO_Path\boot\etfsboot.com`"#pEF,e,b`"$ISO_Path\efi\microsoft\boot\efisys.bin`" `"$ISO_Path`" `"$Final_ISO`""
Start-Process -FilePath $OscdimgPath -ArgumentList $OscdimgArgs -Wait -NoNewWindow

# Cleanup Temp Directories
Write-Host "`n[+] Cleaning up temporary files..." -ForegroundColor Red
if (Test-Path $ISO_Path) { Remove-Item -Path$ISO_Path -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path $WorkDir)  { Remove-Item -Path$WorkDir -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] WinZora ISO Created Successfully: $Final_ISO" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Cyan