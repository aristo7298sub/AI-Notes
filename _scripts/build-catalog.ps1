<#
.SYNOPSIS
    Scan all articles' YAML frontmatter and auto-generate README.md catalog.
.EXAMPLE
    .\_scripts\build-catalog.ps1
#>

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$contentDirs = @(
    'deep-dives', 'commentaries', 'insights',
    'learning-notes/papers', 'learning-notes/courses', 'learning-notes/books',
    'tool-guides', 'projects'
)

$categoryLabels = @{
    'deep-dive'     = 'Deep Dives'
    'commentary'    = 'Commentaries'
    'insight'       = 'Insights'
    'learning-note' = 'Learning Notes'
    'tool-guide'    = 'Tool Guides'
    'project'       = 'Projects'
}

function Parse-Frontmatter {
    param([string]$FilePath)

    $content = Get-Content $FilePath -Raw -Encoding UTF8
    if ($content -notmatch '(?s)^---\r?\n(.+?)\r?\n---') { return $null }

    $yaml = $Matches[1]
    $meta = @{
        FilePath = $FilePath
        RelPath  = ($FilePath.Substring($root.Length + 1)) -replace '\\', '/'
    }

    foreach ($line in ($yaml -split '\r?\n')) {
        if ($line -match '^(\w[\w-]*):\s*(.+)$') {
            $key = $Matches[1]
            $val = $Matches[2].Trim().Trim('"').Trim("'")

            if ($key -eq 'tags') {
                $val = $val -replace '^\[|\]$', ''
                $meta[$key] = @($val -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
            } else {
                $meta[$key] = $val
            }
        }
    }
    return $meta
}

# Collect all articles
$articles = @()
foreach ($dir in $contentDirs) {
    $fullDir = Join-Path $root $dir
    if (-not (Test-Path $fullDir)) { continue }

    Get-ChildItem $fullDir -Filter '*.md' -File | ForEach-Object {
        $meta = Parse-Frontmatter $_.FullName
        if ($meta) { $articles += $meta }
    }
}

Write-Host ('Found {0} articles' -f $articles.Count) -ForegroundColor Cyan

# --- Build catalog ---
$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add('## Article Index')
$lines.Add('')
$lines.Add(('> Run ``.\_scripts\build-catalog.ps1`` to update. Last updated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm')))
$lines.Add('')
$lines.Add(('Total: **{0}** articles.' -f $articles.Count))
$lines.Add('')

# By category
$lines.Add('### By Category')
$lines.Add('')

$grouped = $articles | Group-Object { $_.category } | Sort-Object Name
foreach ($group in $grouped) {
    $label = $group.Name
    if ($categoryLabels.ContainsKey($group.Name)) { $label = $categoryLabels[$group.Name] }
    $lines.Add(('#### {0} ({1})' -f $label, $group.Count))
    $lines.Add('')

    $sorted = $group.Group | Sort-Object { $_.date } -Descending
    foreach ($a in $sorted) {
        $t = $a.title
        if (-not $t) { $t = [System.IO.Path]::GetFileNameWithoutExtension($a.FilePath) }
        $d = ''
        if ($a.date) { $d = ' -- {0}' -f $a.date }
        $lines.Add(('- [{0}]({1}){2}' -f $t, $a.RelPath, $d))
    }
    $lines.Add('')
}

# By tag
$lines.Add('### By Tag')
$lines.Add('')

$allTags = @{}
foreach ($a in $articles) {
    if ($a.tags) {
        foreach ($tag in $a.tags) {
            if (-not $allTags.ContainsKey($tag)) { $allTags[$tag] = [System.Collections.Generic.List[object]]::new() }
            $allTags[$tag].Add($a)
        }
    }
}

foreach ($tag in ($allTags.Keys | Sort-Object)) {
    $linkList = @()
    foreach ($a in $allTags[$tag]) {
        $t = $a.title
        if (-not $t) { $t = [System.IO.Path]::GetFileNameWithoutExtension($a.FilePath) }
        $linkList += ('[{0}]({1})' -f $t, $a.RelPath)
    }
    $links = $linkList -join ' | '
    $lines.Add(('**`{0}`**: {1}' -f $tag, $links))
    $lines.Add('')
}

# By timeline
$lines.Add('### Timeline')
$lines.Add('')

$byDate = $articles | Where-Object { $_.date } | Sort-Object { $_.date } -Descending
foreach ($a in $byDate) {
    $t = $a.title
    if (-not $t) { $t = [System.IO.Path]::GetFileNameWithoutExtension($a.FilePath) }
    $catLabel = $a.category
    if ($categoryLabels.ContainsKey($a.category)) { $catLabel = $categoryLabels[$a.category] }
    $lines.Add(('- **{0}** [{1}]({2}) `{3}`' -f $a.date, $t, $a.RelPath, $catLabel))
}

$catalogContent = $lines -join "`n"

# --- Update README.md ---
$readmePath = Join-Path $root 'README.md'
$readme = Get-Content $readmePath -Raw -Encoding UTF8

$startMarker = '<!-- AUTO-GENERATED CATALOG START -->'
$endMarker   = '<!-- AUTO-GENERATED CATALOG END -->'

$startIdx = $readme.IndexOf($startMarker)
$endIdx   = $readme.IndexOf($endMarker)

if ($startIdx -ge 0 -and $endIdx -ge 0) {
    $before = $readme.Substring(0, $startIdx + $startMarker.Length)
    $after  = $readme.Substring($endIdx)
    $newReadme = $before + "`n`n" + $catalogContent + "`n`n" + $after
    [System.IO.File]::WriteAllText($readmePath, $newReadme, [System.Text.Encoding]::UTF8)
} else {
    Write-Host 'WARNING: AUTO-GENERATED CATALOG markers not found in README.md' -ForegroundColor Yellow
    exit 1
}

Write-Host 'README.md catalog updated successfully.' -ForegroundColor Green
