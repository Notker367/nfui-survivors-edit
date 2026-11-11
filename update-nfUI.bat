@echo off
rem nfUI Survivors Edit updater. Put it in the game folder, next to benilla-config, and run it.
rem Optional argument: a zip already on this computer, installed instead of the latest release.
rem The previous version is kept in benilla-config\nfUI-update-<date>; only the latest such copy stays.
setlocal
set "NFUI_DIR=%~dp0"
set "NFUI_ZIP=%~1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=Get-Content -LiteralPath '%~f0' -Raw; Invoke-Expression ($s.Substring($s.LastIndexOf('#POWERSHELL#')+12))"
set "NFUI_RESULT=%errorlevel%"
if "%~1"=="" pause
exit /b %NFUI_RESULT%
#POWERSHELL#
$ErrorActionPreference='Stop'
$repo='Notker367/nfui-survivors-edit'; $assetName='nfUI-survivors-edit.zip'
function Fail($message){ Write-Host "ERROR: $message"; exit 1 }
$config=@($env:NFUI_DIR, (Join-Path $env:NFUI_DIR 'benilla-config')) | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'AddOns') } | Select-Object -First 1
if(-not $config){ Fail 'AddOns folder not found. Put this file next to benilla-config.' }
$addons=Join-Path $config 'AddOns'; $live=Join-Path $addons 'nfUI'
$installed=''
$toc=Join-Path $live 'nfUI.toc'
if(Test-Path -LiteralPath $toc){ $line=Select-String -LiteralPath $toc -Pattern '^## Version:\s*(.+?)\s*$' | Select-Object -First 1; if($line){ $installed=$line.Matches[0].Groups[1].Value } }
Write-Host "Installed: $(if($installed){$installed}else{'none'})"
$work=Join-Path $config ('nfUI-update-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
$zip=$env:NFUI_ZIP; $expected=$null
if(-not $zip){
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    $headers=@{'User-Agent'='nfUI-updater';'Accept'='application/vnd.github+json'}
    try{ $release=Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $headers }
    catch{ Fail "Could not read the latest release: $($_.Exception.Message)" }
    $latest=$release.tag_name -replace '^v',''
    Write-Host "Latest:    $latest"
    if($latest -eq $installed){ Write-Host 'Already up to date.'; exit 0 }
    $asset=$release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if(-not $asset){ Fail "The release has no $assetName." }
    if($asset.digest -match '^sha256:(.+)$'){ $expected=$Matches[1] }
    New-Item -ItemType Directory -Path $work | Out-Null
    $zip=Join-Path $work $assetName
    Write-Host 'Downloading...'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing -Headers @{'User-Agent'='nfUI-updater'}
    if($expected -and (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expected.ToUpper()){ Remove-Item -LiteralPath $work -Recurse -Force; Fail 'The download does not match the release checksum. Nothing was changed.' }
}
if(-not (Test-Path -LiteralPath $zip)){ Fail "File not found: $zip" }
if(-not (Test-Path -LiteralPath $work)){ New-Item -ItemType Directory -Path $work | Out-Null }
$unpacked=Join-Path $work 'unpacked'
Expand-Archive -LiteralPath $zip -DestinationPath $unpacked
if(-not (Test-Path -LiteralPath (Join-Path $unpacked 'nfUI\nfUI.toc'))){ Remove-Item -LiteralPath $work -Recurse -Force; Fail 'This zip does not contain nfUI\nfUI.toc. Nothing was changed.' }
$backup=$null
if(Test-Path -LiteralPath $live){ $backup=Join-Path $work 'previous-nfUI'; Move-Item -LiteralPath $live -Destination $backup }
try{ Move-Item -LiteralPath (Join-Path $unpacked 'nfUI') -Destination $live }
catch{ if($backup){ Move-Item -LiteralPath $backup -Destination $live }; Fail "Install failed, the old version was restored: $($_.Exception.Message)" }
Remove-Item -LiteralPath $unpacked -Recurse -Force
if($zip -like "$work*"){ Remove-Item -LiteralPath $zip -Force }
# Only the latest backup is kept: older update folders of this script go, and an empty one too.
Get-ChildItem -LiteralPath $config -Directory | Where-Object { $_.Name -match '^nfUI-update-\d{8}-\d{6}$' -and $_.FullName -ne $work } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
if(-not $backup){ Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
Write-Host 'Updated. Restart the game fully; your settings are kept.'
if($backup){ Write-Host "Previous version (only the latest is kept): $backup" }
exit 0
