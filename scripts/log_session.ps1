# log_session.ps1 - Quick session logger
[CmdletBinding()]
param()

$scriptDir = Split-Path -Parent $PSCommandPath
$scriptDir = Split-Path $scriptDir -Parent  # scripts/ -> root
if (-not $scriptDir) { $scriptDir = "." }

$progressPath = Join-Path $scriptDir "progress.json"
$journalDir = Join-Path $scriptDir "journal"
if (-not (Test-Path $journalDir)) { New-Item -ItemType Directory -Path $journalDir -Force | Out-Null }

$L = @{
    'title' = 'Quick Session Logger'
    'topicPrompt' = 'Topic'
    'durationPrompt' = 'Duration (minutes)'
    'notePrompt' = 'Notes (optional)'
    'clearPrompt' = 'Anything unclear? (optional)'
    'recorded' = 'Session recorded!'
    'journalWritten' = 'Journal written to'
    'progressUpdated' = 'Progress updated'
    'selectStage' = 'Select stage'
    'cancelled' = 'Cancelled'
}

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  $($L.title)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Read progress
$progress = Get-Content $progressPath -Raw -Encoding UTF8 | ConvertFrom-Json

# --- Select stage ---
$stages = @()
$i = 0
foreach ($key in $progress.stages.PSObject.Properties.Name) {
    $s = $progress.stages.$key
    if ($s.status -eq 'not_started' -or $s.status -eq 'completed') { continue }
    $stages += @{ key = $key; name = $s.name; index = $i }
    $isHigh = ($s.priority -eq 'highest')
    Write-Host "  [$i] $($s.name)" -ForegroundColor $(if ($isHigh) { 'Yellow' } else { 'White' })
    $i++
    if ($s.sub_items) {
        foreach ($subKey in $s.sub_items.PSObject.Properties.Name) {
            $sub = $s.sub_items.$subKey
            if ($sub.status -ne 'in_progress') { continue }
            $stages += @{ key = $subKey; name = $sub.name; index = $i; parent = $key }
            Write-Host "  [$i] -- $($sub.name)" -ForegroundColor 'Green'
            $i++
        }
    }
}
Write-Host ""

$selStr = Read-Host "  $($L.selectStage) [0-$($stages.Count-1)]"
$sel = 0
if ([int]::TryParse($selStr, [ref]$sel) -and $sel -ge 0 -and $sel -lt $stages.Count) {
    $selected = $stages[$sel]
} else {
    Write-Host "  $($L.cancelled)" -ForegroundColor Red
    Read-Host "[Press Enter]"
    exit
}

# --- Topic ---
$topic = Read-Host "  $($L.topicPrompt)"

# --- Duration ---
$durStr = Read-Host "  $($L.durationPrompt)"
$duration = 0
if (-not [int]::TryParse($durStr, [ref]$duration)) { $duration = 0 }

# --- Notes ---
Write-Host "  $($L.notePrompt) (Ctrl+C to skip)" -ForegroundColor DarkGray
$notes = Read-Host "  >>"
if (-not $notes) { $notes = "-" }

# --- Pain points ---
Write-Host "  $($L.clearPrompt) (Ctrl+C to skip)" -ForegroundColor DarkGray
$painPoints = Read-Host "  >>"

# --- Write journal ---
$today = Get-Date
$dateStr = $today.ToString("yyyy-MM-dd")
$timeStr = $today.ToString("HH:mm")

$journalContent = @"
## $dateStr $timeStr - $topic

**Stage:** $($selected.name)
**Duration:** $($duration) min
**Notes:** $notes
"@
if ($painPoints) { $journalContent += "`n**Unclear:** $painPoints" }
$journalContent += "`n`n---`n"

$journalPath = Join-Path $journalDir "$dateStr.md"
if (Test-Path $journalPath) {
    $existing = Get-Content $journalPath -Raw -Encoding UTF8
    $journalContent = $existing.TrimEnd() + "`n`n" + $journalContent
}
$journalContent | Out-File -FilePath $journalPath -Encoding UTF8
Write-Host "  [$($L.journalWritten)] $dateStr.md" -ForegroundColor Green

# --- Update progress ---
if ($selected.ContainsKey('parent')) {
    $subKey = $selected.key
    $parentKey = $selected.parent
    $currentVal = [int]$progress.stages.$parentKey.sub_items.$subKey.progress
    $targetVal = [int]$progress.stages.$parentKey.sub_items.$subKey.target
    $newVal = [math]::Min($currentVal + 1, $targetVal)
    $progress.stages.$parentKey.sub_items.$subKey.progress = $newVal
} else {
    $currentVal = [int]$progress.stages.($selected.key).progress
    $targetVal = [int]$progress.stages.($selected.key).target
    $newVal = [math]::Min($currentVal + 1, $targetVal)
    $progress.stages.($selected.key).progress = $newVal
}
$progress.last_updated = $dateStr
$progress.session_count = [int]$progress.session_count + 1

$progress | ConvertTo-Json -Depth 10 | Out-File -FilePath $progressPath -Encoding UTF8
Write-Host "  [$($L.progressUpdated)] $($selected.name): $currentVal -> $newVal" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  $($L.recorded)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Read-Host "[Press Enter]"
