param(
    [switch]$Install,
    [switch]$Remove
)

$ErrorActionPreference = 'Stop'

# Registry paths for both Backgrounds and Direct Items (Tree/Panel icons)
$MenuKeys_Background = @(
    'HKCU:\Software\Classes\Directory\Background\shell\RobocopyPaste',
    'HKCU:\Software\Classes\Drive\Background\shell\RobocopyPaste'
)

$MenuKeys_Item = @(
    'HKCU:\Software\Classes\Directory\shell\RobocopyPaste',
    'HKCU:\Software\Classes\Drive\shell\RobocopyPaste'
)

$HelperDir  = Join-Path $env:LOCALAPPDATA 'RoboCopyQuick'
$HelperFile = Join-Path $HelperDir 'RoboPaste.ps1'


function Install-Helper {

    New-Item -ItemType Directory -Path $HelperDir -Force | Out-Null

    $Helper = @'
param(
    [string]$TargetFolder = ""
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms

# Black console styling
$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host

$Destination = $null

# Safely check if a valid direct target was passed (from tree/item right-click)
if ($TargetFolder -and $TargetFolder -ne '%1' -and $TargetFolder -ne '""') {
    try {
        if (Test-Path -LiteralPath $TargetFolder -ErrorAction SilentlyContinue) {
            $Destination = (Get-Item -LiteralPath $TargetFolder -Force).FullName
        }
    } catch {}
}

# Fallback to active Explorer window COM automation if no direct target
if (-not $Destination) {
    try {
        $shellApp = New-Object -ComObject Shell.Application
        foreach ($window in $shellApp.Windows()) {
            $fullName = $window.FullName
            if ($fullName -and $fullName -like "*explorer.exe") {
                $doc = $window.Document
                if ($doc -and $doc.Folder -and $doc.Folder.Self) {
                    $path = $doc.Folder.Self.Path
                    if ($path) { 
                        $Destination = $path 
                        break
                    }
                }
            }
        }
    } catch {}
}

if (-not $Destination -or -not (Test-Path -LiteralPath $Destination)) {
    $Destination = (Get-Location).Path
}

$Destination = (Get-Item -LiteralPath $Destination -Force).FullName

Write-Host "Destination : $Destination"
Write-Host ""

# Get clipboard items
$Files = [System.Windows.Forms.Clipboard]::GetFileDropList()

if (-not $Files -or $Files.Count -eq 0) {
    Write-Host "Clipboard does not contain a copied file or folder."
    Write-Host ""
    Read-Host "Press ENTER to close"
    exit 1
}

# Process each item
foreach ($Source in $Files) {

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "Source does not exist: $Source"
        continue
    }

    $Item = Get-Item -LiteralPath $Source -Force

    Write-Host "Source      : $($Item.FullName)"
    Write-Host "Destination : $Destination"
    Write-Host ""

    # If pasting into the EXACT same folder, duplicate it (Windows-style paste)
    if ($Item.DirectoryName -eq $Destination) {
        $BaseName = $Item.BaseName
        $Extension = $Item.Extension
        $NewName = "$BaseName - Copy$Extension"
        $Counter = 1
        
        while (Test-Path (Join-Path $Destination $NewName)) {
            $NewName = "$BaseName - Copy ($Counter)$Extension"
            $Counter++
        }

        $DestPath = Join-Path $Destination $NewName
        Write-Host "Duplicating to : $DestPath"
        Copy-Item -LiteralPath $Item.FullName -Destination $DestPath -Force
        Write-Host "Duplication finished."
    }
    else {
        # Different folder -> Use Robocopy with your exact options including /IS
        if ($Item.PSIsContainer) {
            $cmdArgs = @(
                $Item.FullName,
                (Join-Path $Destination $Item.Name),
                "/E", "/NDL", "/DCOPY:DA", "/COPY:DAT", "/J", "/ETA", "/MT:32", "/R:0", "/W:0", "/IS"
            )
        }
        else {
            $cmdArgs = @(
                $Item.DirectoryName,
                $Destination,
                $Item.Name,
                "/NDL", "/DCOPY:DA", "/COPY:DAT", "/J", "/ETA", "/MT:32", "/R:0", "/W:0", "/IS"
            )
        }

        Write-Host "Command: robocopy.exe $($cmdArgs -join ' ')"
        & robocopy.exe @cmdArgs
    }

    Write-Host ""
}

Write-Host "========================================"
Write-Host " TRANSFER FINISHED"
Write-Host "========================================"
Write-Host ""
Read-Host "Press ENTER to close"
'@

    Set-Content -LiteralPath $HelperFile -Value $Helper -Encoding UTF8
}


function Register-MenuPath($RootPath, [bool]$PassTarget) {
    New-Item -Path $RootPath -Force | Out-Null

    Set-ItemProperty -Path $RootPath -Name 'MUIVerb' -Value 'Paste (Robocopy)'

    $CommandKey = "$RootPath\command"
    New-Item -Path $CommandKey -Force | Out-Null

    if ($PassTarget) {
        $Command = 'powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "' + $HelperFile + '" -TargetFolder "%1"'
    } else {
        $Command = 'powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "' + $HelperFile + '"'
    }

    Set-ItemProperty -Path $CommandKey -Name '(default)' -Value $Command
}


function Install-Menu {
    Write-Host "Installing Robocopy Paste..." -ForegroundColor Cyan

    foreach ($Key in $MenuKeys_Background) { if (Test-Path $Key) { Remove-Item -Path $Key -Recurse -Force } }
    foreach ($Key in $MenuKeys_Item)       { if (Test-Path $Key) { Remove-Item -Path $Key -Recurse -Force } }
    if (Test-Path $HelperFile)             { Remove-Item -LiteralPath $HelperFile -Force }

    Install-Helper

    foreach ($Key in $MenuKeys_Background) { Register-MenuPath $Key -PassTarget $false }
    foreach ($Key in $MenuKeys_Item)       { Register-MenuPath $Key -PassTarget $true }

    Write-Host "Installed successfully." -ForegroundColor Green
}


function Remove-Menu {
    foreach ($Key in $MenuKeys_Background) { if (Test-Path $Key) { Remove-Item -Path $Key -Recurse -Force } }
    foreach ($Key in $MenuKeys_Item)       { if (Test-Path $Key) { Remove-Item -Path $Key -Recurse -Force } }
    if (Test-Path $HelperDir)              { Remove-Item -Path $HelperDir -Recurse -Force }

    Write-Host "Robocopy Paste removed." -ForegroundColor Green
}


function Restart-Explorer {
    Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
}


if ($Install) {
    Install-Menu
    Restart-Explorer
}
elseif ($Remove) {
    Remove-Menu
    Restart-Explorer
}
else {
    Write-Host "Install : .\Robo.ps1 -Install"
    Write-Host "Remove  : .\Robo.ps1 -Remove"
}
