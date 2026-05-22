# _snapshot.ps1 - Backup config files, keep last 15
$scriptDir = Split-Path -Parent $PSCommandPath
$scriptDir = Split-Path $scriptDir -Parent  # scripts/ -> root
if (-not $scriptDir) { $scriptDir = "$env:USERPROFILE\ai-learning" }
$snapDir = Join-Path $scriptDir "_snapshots"
$maxKeep = 15
if (-not (Test-Path $snapDir)) { New-Item -ItemType Directory -Path $snapDir -Force | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Write-Host "[SNAP] $timestamp" -ForegroundColor Cyan

$files = @(
    @{src="progress.json"; prefix="progress_"; ext="json"},
    @{src="pending_tasks.json"; prefix="pending_"; ext="json"},
    @{src="current_session.md"; prefix="session_"; ext="md"},
    @{src="weekly_plan.json"; prefix="weekly_"; ext="json"}
)

$usedPrefixes = @()

foreach ($f in $files) {
    $srcPath = Join-Path $scriptDir $f.src
    if (Test-Path $srcPath) {
        $dstName = "$($f.prefix)$timestamp.$($f.ext)"
        $dstPath = Join-Path $snapDir $dstName
        Copy-Item -Path $srcPath -Destination $dstPath -Force
        Write-Host "  OK $($f.src)" -ForegroundColor Green
        $usedPrefixes += $f.prefix
    } else {
        Write-Host "  -- $($f.src) (not found)" -ForegroundColor DarkGray
    }
}

# Auto-clean: keep only last $maxKeep snapshots per prefix
$cleaned = 0
foreach ($prefix in ($usedPrefixes | Select-Object -Unique)) {
    $snaps = @(Get-ChildItem $snapDir -Filter "$prefix*" | Sort-Object Name -Descending)
    if ($snaps.Count -gt $maxKeep) {
        $toDelete = $snaps[$maxKeep..($snaps.Count - 1)]
        foreach ($d in $toDelete) {
            Remove-Item -Path $d.FullName -Force
            $cleaned++
        }
    }
}
if ($cleaned -gt 0) {
    Write-Host "  Cleaned $cleaned old snapshots (max $maxKeep per file)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "[DONE]" -ForegroundColor Green
$snapCount = @(Get-ChildItem $snapDir).Count
$sizeKB = [math]::Round((Get-ChildItem -Recurse $snapDir | Measure-Object -Property Length -Sum).Sum / 1KB, 2)
Write-Host "       $snapCount files, $sizeKB KB" -ForegroundColor DarkGray
