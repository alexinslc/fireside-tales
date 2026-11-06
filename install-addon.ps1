#Requires -Version 7.0
<#
.SYNOPSIS
    Links the addon into WoW Forever's AddOns folder, or removes that link.
.DESCRIPTION
    For working on the addon: the game reads the project's copy directly, through a
    junction on Windows or a symbolic link on macOS. -Uninstall removes only the
    link, never the project's files. To simply play, use the zip instead.
#>
[CmdletBinding()]
param(
    [string]$WowPath = $(if ($IsMacOS) { '/Applications/World of Warcraft/_forever_' } else { 'C:\Program Files (x86)\World of Warcraft\_forever_' }),
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path (Join-Path $PSScriptRoot 'addon' 'FiresideTales')).Path
$addons = Join-Path $WowPath 'Interface' 'AddOns'
if (-not (Test-Path -LiteralPath $addons)) { throw "AddOns folder not found: $addons. Pass the game folder with -WowPath." }
$link = Join-Path $addons 'FiresideTales'

$existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
$isLink = $existing -and $existing.LinkType

if ($Uninstall) {
    if (-not $existing) { Write-Host 'Not installed.'; return }
    if (-not $isLink) { throw "$link is a regular folder, not this script's link, so it was left alone." }
    if ($IsMacOS) { [IO.File]::Delete($link) } else { [IO.Directory]::Delete($link) }   # Removes the link, not the target.
    Write-Host "Removed the link at $link"
    return
}

if ($existing) {
    if ($isLink -and $existing.Target -contains $source) { Write-Host "Already installed at $link"; return }
    throw "$link already exists and doesn't point at this project, so it was left alone."
}
$linkType = if ($IsMacOS) { 'SymbolicLink' } else { 'Junction' }
New-Item -ItemType $linkType -Path $link -Target $source | Out-Null
Write-Host "Installed: $link -> $source"
Write-Host 'Restart the game so it finds the new addon.'
