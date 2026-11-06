#Requires -Version 7.0
<#
.SYNOPSIS
    Links the addon into WoW Forever's AddOns folder, or removes that link.
.DESCRIPTION
    Creates a directory junction, so the game reads the project's copy directly.
    -Uninstall removes only the junction, never the project's files.
#>
[CmdletBinding()]
param(
    [string]$WowPath = 'C:\Program Files (x86)\World of Warcraft\_forever_',
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path (Join-Path $PSScriptRoot 'addon\FiresideTales')).Path
$addons = Join-Path $WowPath 'Interface\AddOns'
if (-not (Test-Path -LiteralPath $addons)) { throw "AddOns folder not found: $addons" }
$link = Join-Path $addons 'FiresideTales'

$existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
$isJunction = $existing -and $existing.LinkType -eq 'Junction'

if ($Uninstall) {
    if (-not $existing) { Write-Host 'Not installed.'; return }
    if (-not $isJunction) { throw "$link is a regular folder, not this script's link, so it was left alone." }
    [IO.Directory]::Delete($link)   # Non-recursive: removes the link, not the target.
    Write-Host "Removed the link at $link"
    return
}

if ($existing) {
    if ($isJunction -and $existing.Target -contains $source) { Write-Host "Already installed at $link"; return }
    throw "$link already exists and doesn't point at this project, so it was left alone."
}
New-Item -ItemType Junction -Path $link -Target $source | Out-Null
Write-Host "Installed: $link -> $source"
Write-Host 'Restart the game so it finds the new addon.'
