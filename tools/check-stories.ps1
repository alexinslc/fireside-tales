#Requires -Version 7.0
<#
.SYNOPSIS
    Checks the addon's story files for mistakes that would break the game's Lua or chat.
.DESCRIPTION
    Run it after editing stories. Every line of a story file must match the expected
    layout, so this also catches syntax errors. Pass -File to check just one file.
#>
[CmdletBinding()]
param(
    [string]$AddonDir = (Join-Path $PSScriptRoot '..' 'addon' 'FiresideTales'),
    [string]$File
)

$Moods = 'funny', 'heartfelt', 'dark', 'action', 'spooky', 'wise'
$MaxBytes = 250
$MaxSeconds = 60
$TargetFile = 'StoriesTargeted.lua'
$TargetRoom = 'x' * 24 # {target} is measured as a long character name.
$problems = [Collections.Generic.List[string]]::new()
$utf8 = [Text.Encoding]::UTF8
$lineRow = '^\s*\{ kind = "(say|emote)", text = "((?:[^"\\]|\\.)*)" \},$'
$structural = @(
    '^\s*$', '^\s*--', '^local _, ns = \.\.\.$', '^ns\.\w+ = \{$', '^\}$', '^\}\)$',
    '^ns\.AddStories\("(character|race|class)", "\w+", \{$', '^ns\.AddStories\("(zone|festival)", "[\w'' -]+", \{$', '^ns\.AddStories\("shared", nil, \{$',
    '^\s*\{$', '^\s*\},$', '^\s*lines = \{$', '^\s*theme = "[^"\\]+",$',
    '^\s*\["\w+"\] = \{$', '^\s*\w+ = \{$'
)

$files = if ($File) { @(Split-Path $File -Leaf) } else {
    Get-Content -LiteralPath (Join-Path $AddonDir 'FiresideTales.toc') |
        Where-Object { $_ -match '\.lua$' -and $_ -notmatch '^(StoryData|Core|StoryMenu|TellerBar|Import|MinimapButton|Campfire|Seasons)\.lua$' -and (Test-Path -LiteralPath (Join-Path $AddonDir $_)) }
}

# Macs can treat file names as case-sensitive, so a .toc entry must match exactly.
$actualNames = @(Get-ChildItem -LiteralPath $AddonDir -File | ForEach-Object Name)
foreach ($entry in Get-Content -LiteralPath (Join-Path $AddonDir 'FiresideTales.toc') | Where-Object { $_ -match '\.lua$' }) {
    if ($entry -match '[\\/]') { $problems.Add("FiresideTales.toc: '$entry' uses a path separator") }
    $match = $actualNames | Where-Object { $_ -ieq $entry }
    if ($match -and $match -cne $entry) { $problems.Add("FiresideTales.toc: '$entry' doesn't match the file's capitalization: $match") }
}

$grandTotal = 0
foreach ($name in $files) {
    $depth = 0; $n = 0; $stories = 0; $total = 0; $seen = @{}
    $story = $null
    function Close-Story {
        if (-not $story) { return }
        if (-not $story.Mood) { $problems.Add("$name`: '$($story.Title)' has no mood") }
        if ($story.Lines -lt 3 -or $story.Lines -gt 8) { $problems.Add("$name`: '$($story.Title)' has $($story.Lines) lines (want 3-8)") }
        if ($story.Emotes -lt 1) { $problems.Add("$name`: '$($story.Title)' has no emote") }
        if ($story.Says -lt 1) { $problems.Add("$name`: '$($story.Title)' has no spoken line") }
        if ($name -eq $TargetFile -and $story.Targets -lt 1) { $problems.Add("$name`: '$($story.Title)' never uses {target}") }
        if ($name -ne $TargetFile -and $story.Targets -gt 0) { $problems.Add("$name`: '$($story.Title)' uses {target} outside $TargetFile") }
        if ([math]::Round($story.Seconds) -gt $MaxSeconds) { $problems.Add("$name`: '$($story.Title)' takes about $([math]::Round($story.Seconds)) seconds (limit $MaxSeconds)") }
    }
    foreach ($row in Get-Content -LiteralPath (Join-Path $AddonDir $name) -Encoding utf8) {
        $n++
        $m = [regex]::Match($row, $lineRow)
        if ($m.Success) {
            $kind = $m.Groups[1].Value; $text = $m.Groups[2].Value
            $total++
            if ($story) {
                $story.Lines++
                if ($kind -eq 'emote') { $story.Emotes++ } else { $story.Says++ }
                if ($text.Contains('{target}')) { $story.Targets++ }
            }
            $bytes = $utf8.GetByteCount($text.Replace('{target}', $TargetRoom))
            # The same read cue TellerBar.lua shows: 3 seconds plus 1 per 20 bytes, from 4 to 14.
            if ($story) { $story.Seconds += [math]::Max(4, [math]::Min(14, 3 + $bytes / 20)) }
            if ($bytes -gt $MaxBytes) { $problems.Add("$name`:$n is $bytes bytes (limit $MaxBytes)") }
            if ($text.Replace('{target}', '') -match '[|{}]|[^\x20-\x7E]') { $problems.Add("$name`:$n has an unsafe character: $text") }
            if ($kind -eq 'emote' -and $text -cmatch '^[A-Z]') { $problems.Add("$name`:$n emote starts with a capital: $text") }
            continue
        }
        if ($row -match '^\s*title = "([^"\\]+)",$') {
            Close-Story
            $title = $Matches[1]
            $story = [pscustomobject]@{ Title = $title; Mood = $null; Lines = 0; Emotes = 0; Says = 0; Targets = 0; Seconds = 0.0 }
            $stories++
            continue
        }
        if ($row -match '^\s*mood = "(\w+)",$') {
            if ($Matches[1] -notin $Moods) { $problems.Add("$name`:$n unknown mood '$($Matches[1])'") }
            if ($story) { $story.Mood = $Matches[1] }
            continue
        }
        if (-not ($structural | Where-Object { $row -match $_ })) { $problems.Add("$name`:$n unrecognized layout: $row"); continue }
        if ($row -notmatch '^\s*--') {
            $depth += ([regex]::Matches($row, '\{')).Count - ([regex]::Matches($row, '\}')).Count
        }
    }
    Close-Story
    if ($depth -ne 0) { $problems.Add("$name has unbalanced braces ($depth)") }
    $grandTotal += $stories
    '{0}: {1} stories, {2} lines' -f $name, $stories, $total
}

# The same title twice in one menu would be confusing, so check them per list.
$groups = @{}
foreach ($name in $files) {
    $key = 'unset'
    foreach ($row in Get-Content -LiteralPath (Join-Path $AddonDir $name) -Encoding utf8) {
        if ($row -match '^ns\.AddStories\("(\w+)", "?([\w'' -]+)"?, \{$') { $key = "$($Matches[1])/$($Matches[2])" }
        elseif ($row -match '^ns\.Stories = \{$') { $key = 'shared/nil' }
        elseif ($row -match '^\t\["?(\w+)"?\] = \{$' -or $row -match '^\t(\w+) = \{$') { $key = "keyed/$($Matches[1])" }
        elseif ($row -match '^\s*title = "([^"\\]+)",$') {
            $normal = $key -replace '^(character|race|class)/', 'keyed/'
            if (-not $groups[$normal]) { $groups[$normal] = @{} }
            if ($groups[$normal][$Matches[1]]) { $problems.Add("Duplicate title '$($Matches[1])' in $normal") }
            $groups[$normal][$Matches[1]] = $true
        }
    }
}

"Total: $grandTotal stories"
if ($problems.Count) {
    "PROBLEMS: $($problems.Count)"
    $problems
    exit 1
}
'All checks passed.'
