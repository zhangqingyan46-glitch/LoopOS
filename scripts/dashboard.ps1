# dashboard.ps1 - Learning Dashboard
[CmdletBinding()]
param()

$scriptDir = Split-Path -Parent $PSCommandPath
$scriptDir = Split-Path $scriptDir -Parent  # scripts/ -> root
if (-not $scriptDir) { $scriptDir = "." }

$journalDir = Join-Path $scriptDir "journal"

# --- English strings ---
$L = @{
    'dayNames' = @('Mon','Tue','Wed','Thu','Fri','Sat','Sun')
    'todayPlan' = "Today's Plan"
    'progress' = 'Progress'
    'scoreRating' = 'Rating'
    'pending' = 'Pending'
    'studiedToday' = 'Studied today'
    'streakNone' = 'No streak'
    'streakDays' = 'Streak'
    'days' = 'd'
    'lastStudy' = 'Last'
    'today' = 'today'
    'daysAgo' = 'd ago'
    'never' = 'Never studied'
    'noPlan' = "No plan yet. Say `"Start today's learning`""
    'thisWeek' = 'This week'
    'hint' = 'Start a conversation with AI'
    'priority' = 'Priority'
    'moreItems' = 'more'
    'items' = 'items'
    'expectedProgress' = 'Progress vs expected'
    'ahead' = 'ahead'
    'behind' = 'behind'
    'onTrack' = 'on track'
    'selectSection' = 'Select a section'
    'menuExit' = 'Exit'
    'planWritten' = 'Plan written to current_session.md'
    'startHint' = "Now say `"Start today's learning`" to begin"
    'inputPrompt' = 'Type a number and press Enter'
    'grades' = @{
        'A'='Excellent'
        'B+'='Good'
        'B'='Decent'
        'C+'='Fair'
        'C'='Needs work'
        'D'='At risk'
        'F'='Critical'
    }
}

# --- Helpers ---

function Get-DayShort {
    param([System.DayOfWeek]$day)
    $idx = [int]$day
    if ($idx -eq 0) { $idx = 6 } else { $idx-- }
    return $L.dayNames[$idx]
}

function Get-ProgressBar {
    param([int]$p, [int]$t, [int]$w = 11)
    if ($t -eq 0) { return ("." * $w) + "  0/0" }
    $filled = [math]::Min([math]::Floor($p / $t * $w), $w)
    $empty = $w - $filled
    return ("#" * $filled) + ("." * $empty) + ("  $p/$t")
}

function Test-JournalDate {
    param([string]$d)
    $p = Join-Path $journalDir "$d.md"
    return (Test-Path $p -PathType Leaf)
}

# --- Read data files ---

function Read-JsonFile {
    param([string]$path)
    if (-not (Test-Path $path -PathType Leaf)) { return $null }
    try {
        $raw = Get-Content -Path $path -Raw -Encoding UTF8
        return ($raw | ConvertFrom-Json)
    } catch { return $null }
}

$progress   = Read-JsonFile (Join-Path $scriptDir "progress.json")
$pending    = Read-JsonFile (Join-Path $scriptDir "pending_tasks.json")
$weekly     = Read-JsonFile (Join-Path $scriptDir "weekly_plan.json")

$sessionPlan = ""
$sessionPath = Join-Path $scriptDir "current_session.md"
if (Test-Path $sessionPath -PathType Leaf) {
    $sessionPlan = Get-Content -Path $sessionPath -Raw -Encoding UTF8
}

if (-not $progress) {
    Write-Host "[ERROR] Cannot read progress.json" -ForegroundColor Red
    Read-Host "[Press Enter]"
    exit 1
}

# --- Date math ---

$today = Get-Date
$dateStr = $today.ToString("yyyy-MM-dd")
$dayShort = Get-DayShort $today.DayOfWeek

$mon = $today.AddDays(-([int]$today.DayOfWeek - 1)).Date
$weekDays = @(0..6 | ForEach-Object { $mon.AddDays($_).ToString("yyyy-MM-dd") })
$weekDayShort = @(0..6 | ForEach-Object { Get-DayShort ([System.DayOfWeek]$_ ) })

# --- Scoring ---

$streak = 0
$checkDate = $today.AddDays(-1)
while (Test-JournalDate $checkDate.ToString("yyyy-MM-dd")) {
    $streak++
    $checkDate = $checkDate.AddDays(-1)
}
if ($streak -eq 0 -and $progress.last_updated) {
    $checkDate = $today.AddDays(-1)
    $progDate = $progress.last_updated
    if ($checkDate.ToString("yyyy-MM-dd") -eq $progDate) { $streak = 1 }
}

$studiedToday = Test-JournalDate $dateStr
if (-not $studiedToday -and $progress.last_updated -eq $dateStr) {
    $studiedToday = $true
}

$weekAttendance = @()
for ($i = 0; $i -lt 7; $i++) {
    $weekAttendance += Test-JournalDate $weekDays[$i]
}
if ($progress.last_updated) {
    for ($i = 0; $i -lt 7; $i++) {
        if ($weekDays[$i] -eq $progress.last_updated) { $weekAttendance[$i] = $true }
    }
}

$pendingCount = 0
$highPending = 0
if ($pending -and $pending.tasks) {
    foreach ($t in $pending.tasks) {
        if ($t.status -ne "pending") { continue }
        $pendingCount++
        if ($t.stage_id -eq "0") { $highPending++ }
    }
}

$lastStudyDate = ""
for ($i = 1; $i -le 14; $i++) {
    $d = $today.AddDays(-$i).ToString("yyyy-MM-dd")
    if (Test-JournalDate $d) { $lastStudyDate = $d; break }
}
if ($progress.last_updated) {
    $progDate = $progress.last_updated
    if ($lastStudyDate -eq "" -or $progDate -gt $lastStudyDate) {
        $lastStudyDate = $progDate
    }
}
$lastStudyDays = 99
if ($lastStudyDate -ne "") {
    $d = [datetime]::ParseExact($lastStudyDate, "yyyy-MM-dd", $null)
    $lastStudyDays = ($today - $d).Days
}

$score = 60
if ($studiedToday) { $score += 15 } elseif ($streak -gt 0) { $score += 8 }
if ($streak -ge 3) { $score += 7 }
if ($lastStudyDays -le 1) { $score += 5 } elseif ($lastStudyDays -le 3) { $score += 2 }
else { $score -= 10 * [math]::Min($lastStudyDays - 3, 5) }
$score -= $highPending * 6
$score -= ($pendingCount - $highPending) * 3
$score = [math]::Max(0, [math]::Min(100, [math]::Round($score)))

$grade = 'F'
if ($score -ge 90) { $grade = 'A' }
elseif ($score -ge 80) { $grade = 'B+' }
elseif ($score -ge 70) { $grade = 'B' }
elseif ($score -ge 60) { $grade = 'C+' }
elseif ($score -ge 50) { $grade = 'C' }
elseif ($score -ge 35) { $grade = 'D' }
$gradeDesc = $L.grades[$grade]

# --- Expected progress ---
$startDate = [datetime]::ParseExact($progress.start_date, "yyyy-MM-dd", $null)
$daysElapsed = [math]::Max(0, ($today - $startDate).Days)

$stageWeeks = @{}
if ($progress.stages) {
    foreach ($key in $progress.stages.PSObject.Properties.Name) {
        $s = $progress.stages.$key
        if ($s.target -gt 0) { $stageWeeks[$key] = [math]::Max(4, [math]::Ceiling([int]$s.target / 2)) }
    }
    foreach ($key in $progress.stages.PSObject.Properties.Name) {
        $s = $progress.stages.$key
        if ($s.sub_items) {
            foreach ($k in $s.sub_items.PSObject.Properties.Name) {
                $sub = $s.sub_items.$k
                if ($sub.target -gt 0) { $stageWeeks[$k] = [math]::Max(4, [math]::Ceiling([int]$sub.target / 2)) }
            }
        }
    }
}

# --- Extract tasks from current_session.md ---
$todaySchedule = @()
if ($sessionPlan -match [regex]::Escape($dateStr)) {
    $lines = $sessionPlan -split "`r?`n"
    foreach ($line in $lines) {
        if ($line -match '^\s*[-*]\s*\[([ x])\]\s*(.+)$') {
            $text = $matches[2].Trim()
            $done = ($matches[1] -eq 'x')
            $todaySchedule += @{ text = $text; done = $done }
        }
    }
}

# --- Stage progress ---
$stages = @()

if ($progress.stages) {
    foreach ($key in $progress.stages.PSObject.Properties.Name) {
        $s = $progress.stages.$key
        if ($s.status -eq 'not_started' -or $s.status -eq 'completed') { continue }
        $weeks = if ($stageWeeks.ContainsKey($key)) { $stageWeeks[$key] } else { 10 }
        $exp = if ($weeks -gt 0) { [math]::Round($daysElapsed / ($weeks * 7) * [int]$s.target, 1) } else { 0 }
        $gap = [math]::Round([int]$s.progress - $exp, 1)
        $isHigh = ($s.priority -eq 'highest')
        $clr = if ($isHigh) { 'Yellow' } else { 'Cyan' }
        $stages += @{ label = $s.name; id = $key; p = [int]$s.progress; t = [int]$s.target; gap = $gap; color = $clr }
        if ($s.sub_items) {
            foreach ($subKey in $s.sub_items.PSObject.Properties.Name) {
                $sub = $s.sub_items.$subKey
                if ($sub.status -eq 'dropped' -or $sub.status -eq 'deferred') { continue }
                $clr = if ($sub.status -eq 'in_progress') { 'Green' } else { 'DarkGray' }
                $weeks = if ($stageWeeks.ContainsKey($subKey)) { $stageWeeks[$subKey] } else { 10 }
                $exp = if ($weeks -gt 0) { [math]::Round($daysElapsed / ($weeks * 7) * [int]$sub.target, 1) } else { 0 }
                $gap = [math]::Round([int]$sub.progress - $exp, 1)
                $shortLabel = $sub.name
                $maxLabelLen = 25
                if ($shortLabel.Length -gt $maxLabelLen) { $shortLabel = $shortLabel.Substring(0, $maxLabelLen - 2) + '..' }
                $stages += @{ label = $shortLabel; id = $subKey; p = [int]$sub.progress; t = [int]$sub.target; gap = $gap; color = $clr }
            }
        }
    }
}

# Build menu items dynamically
$menuItems = @()
$menuIdx = 1
if ($progress.stages) {
    foreach ($key in $progress.stages.PSObject.Properties.Name) {
        $s = $progress.stages.$key
        if ($s.status -eq 'not_started') { continue }
        $menuItems += @{ id = $menuIdx; label = $s.name; topic = $key }
        $menuIdx++
    }
}

# --- Suggestion ---
$suggestion = $L.studiedToday
if ($pendingCount -gt 0 -and $pending -and $pending.tasks) {
    $first = $pending.tasks | Where-Object { $_.status -eq 'pending' } | Select-Object -First 1
    if ($first) { $suggestion = "$($L.priority): $($first.topic)" }
}

# ================================================
#  RENDER
# ================================================

Clear-Host
$W = 56
$rule = '=' * $W
$rule2 = '-' * $W

$title = "  [~] AI Learning OS  $dateStr ($dayShort)  "
Write-Host "+$rule+" -ForegroundColor Cyan
Write-Host "|$title|" -ForegroundColor Cyan

Write-Host "|$rule2|" -ForegroundColor Cyan
Write-Host ("|  >> $($L.todayPlan)") -ForegroundColor White
if ($todaySchedule.Count -gt 0) {
    foreach ($task in $todaySchedule) {
        $mark = if ($task.done) { '[V]' } else { '[ ]' }
        $disp = "     $mark $($task.text)"
        if ($disp.Length -gt $W) { $disp = $disp.Substring(0, $W-2) + '..' }
        Write-Host ("|" + $disp + (" " * ($W - $disp.Length)) + "|")
    }
} else {
    $msg = "     ($($L.noPlan))"
    Write-Host ("|" + $msg + (" " * ($W - $msg.Length)) + "|") -ForegroundColor DarkGray
}
Write-Host ("|" + (" " * $W) + "|")

Write-Host ("|  >> $($L.progress)") -ForegroundColor White
foreach ($s in $stages) {
    $bar = Get-ProgressBar $s.p $s.t 11
    $gapFlag = ""
    $gapColor = "DarkGray"
    if ($s.gap -gt 0.5) { $gapFlag = "+$($s.gap)"; $gapColor = "Green" }
    elseif ($s.gap -lt -0.5) { $gapFlag = "$($s.gap)"; $gapColor = "Red" }
    elseif ($s.t -gt 0) { $gapFlag = "0"; $gapColor = "DarkGray" }
    $maxLabelLen = 22
    $label = $s.label
    if ($label.Length -gt $maxLabelLen) { $label = $label.Substring(0, $maxLabelLen - 2) + '..' }
    $line = "    $label  $bar"
    if ($line.Length -gt ($W - 7)) { $line = $line.Substring(0, $W - 10) }
    $gapDisp = " [$gapFlag]"
    $pad = [math]::Max(1, $W - $line.Length - $gapDisp.Length)
    $line2 = $line + (" " * $pad) + $gapDisp
    if ($line2.Length -gt $W) { $line2 = $line2.Substring(0, $W) }
    $clr = $s.color
    Write-Host ("|" + $line2 + (" " * [math]::Max(0, $W - $line2.Length)) + "|") -ForegroundColor $clr
}
Write-Host ("|" + (" " * $W) + "|")

Write-Host ("|  >> $($L.scoreRating): $grade | $gradeDesc | Score: $score/100") -ForegroundColor White
$streakText = $L.streakNone
if ($studiedToday) { $streakText = $L.studiedToday }
elseif ($streak -gt 0) { $streakText = "$($L.streakDays) $streak $($L.days)" }
$lastText = $L.never
if ($lastStudyDays -le 1) { $lastText = $L.today }
elseif ($lastStudyDays -lt 99) { $lastText = "$lastStudyDays $($L.daysAgo)" }
$infoLine = "     $streakText  |  $($L.lastStudy): $lastText"
Write-Host ("|" + $infoLine + (" " * ($W - $infoLine.Length)) + "|")
Write-Host ("|" + (" " * $W) + "|")

$attLine = "     $($L.thisWeek): "
for ($i = 0; $i -lt 7; $i++) { $attLine += $weekDayShort[$i] + " " }
Write-Host ("|" + $attLine + (" " * ($W - $attLine.Length)) + "|")
$markLine = "             "
for ($i = 0; $i -lt 7; $i++) { $markLine += $(if ($weekAttendance[$i]) { "V " } else { "- " }) }
$attColor = if ($studiedToday) { 'Green' } else { 'DarkGray' }
Write-Host ("|" + $markLine + (" " * ($W - $markLine.Length)) + "|") -ForegroundColor $attColor
Write-Host ("|" + (" " * $W) + "|")

if ($pendingCount -gt 0 -and $pending -and $pending.tasks) {
    Write-Host ("|  >> $($L.pending) ($pendingCount $($L.items))") -ForegroundColor White
    $shown = 0
    foreach ($t in $pending.tasks) {
        if ($shown -ge 4) { break }
        if ($t.status -ne 'pending') { continue }
        $isHigh = ($t.stage_id -eq '0')
        $mark = if ($isHigh) { '!' } else { '.' }
        $disp = "    $mark $($t.topic)"
        if ($t.pain_points -and $t.pain_points.Length -gt 0) {
            $pp = $t.pain_points
            if ($pp.Length -gt 22) { $pp = $pp.Substring(0, 20) + '..' }
            $disp += " [$pp]"
        }
        if ($disp.Length -gt $W) { $disp = $disp.Substring(0, $W-2) + '..' }
        $clr = if ($isHigh) { 'Red' } else { 'Yellow' }
        Write-Host ("|" + $disp + (" " * ($W - $disp.Length)) + "|") -ForegroundColor $clr
        $shown++
    }
    if ($pendingCount -gt 4) {
        $more = "    ... $($L.moreItems) $($pendingCount - 4) $($L.items)"
        Write-Host ("|" + $more + (" " * ($W - $more.Length)) + "|") -ForegroundColor DarkGray
    }
    Write-Host ("|" + (" " * $W) + "|")
}

# --- Interactive selection menu ---
if ($menuItems.Count -gt 0) {
    Write-Host ("|  >> $($L.selectSection)") -ForegroundColor White
    $menuItems += @{ id = 0; label = $L.menuExit; topic = "" }
    foreach ($m in $menuItems) {
        $disp = "    [$($m.id)] $($m.label)"
        Write-Host ("|" + $disp + (" " * ($W - $disp.Length)) + "|")
    }
    Write-Host ("|" + (" " * $W) + "|")
}
Write-Host "+$rule+" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  $($L.inputPrompt)") -ForegroundColor Yellow

$selStr = Read-Host ">> "
$sel = -1
if ([int]::TryParse($selStr, [ref]$sel)) {
    $selected = $menuItems | Where-Object { $_.id -eq $sel } | Select-Object -First 1
    if ($selected -and $selected.id -ne 0) {
        $sessionContent = @"
# Session Plan - $dateStr ($dayShort)

## Today's Tasks ($($selected.topic))
- [ ] $($selected.topic)

## Reference
- Current progress: progress.json
- Weekly plan: weekly_plan.json
"@
        $sessionContent | Out-File -FilePath (Join-Path $scriptDir "current_session.md") -Encoding UTF8
        Clear-Host
        Write-Host ""
        Write-Host "  [+] $($L.planWritten)" -ForegroundColor Green
        Write-Host "  [+] $($L.startHint)" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "[Press Enter]"
        exit 0
    }
}
Write-Host "  $($L.menuExit)" -ForegroundColor DarkGray
Read-Host "[Press Enter]"
