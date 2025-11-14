param(
    [string]$OutputPath = "stage1-report.txt"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Figure out project root (parent of tools folder)
$scriptPath  = $MyInvocation.MyCommand.Path
$toolsDir    = Split-Path -Parent $scriptPath
$projectRoot = Split-Path -Parent $toolsDir

Set-Location $projectRoot

$reportLines = @()
$reportLines += "=== My Joe – Stage 1 Verification Report ==="
$reportLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ssK')"
$reportLines += "Project root: $projectRoot"
$reportLines += ""

# --- Check .git directory ---
$gitDir = Join-Path $projectRoot ".git"
if (Test-Path $gitDir) {
    $reportLines += "[OK] .git directory found at: $gitDir"
} else {
    $reportLines += "[FAIL] .git directory NOT found at expected location."
}

# --- Check current branch ---
try {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $reportLines += "Current Git branch: $currentBranch"
    if ($currentBranch -eq "main") {
        $reportLines += "[OK] Current branch is 'main'."
    } else {
        $reportLines += "[WARN] Current branch is not 'main'."
    }
} catch {
    $reportLines += "[FAIL] Unable to determine current Git branch."
    $reportLines += "Error: $($_.Exception.Message)"
}

# --- Check origin remote URL ---
try {
    $originUrl = git remote get-url origin 2>$null
} catch {
    $originUrl = $null
}

if (-not $originUrl) {
    $reportLines += "[FAIL] No 'origin' remote configured."
} else {
    $reportLines += "Origin remote URL: $originUrl"
    $expectedUrl = "https://github.com/Pozzers/myjoe-app.git"

    if ($originUrl -eq $expectedUrl) {
        $reportLines += "[OK] Origin matches expected GitHub repo URL."
    } else {
        $reportLines += "[WARN] Origin does not match expected GitHub repo."
        $reportLines += "       Expected: $expectedUrl"
        $reportLines += "       Actual:   $originUrl"
    }
}

# --- Check working tree is clean ---
try {
    $gitStatus = git status --porcelain
    if ([string]::IsNullOrWhiteSpace($gitStatus)) {
        $reportLines += "[OK] Working tree is clean (no uncommitted changes)."
    } else {
        $reportLines += "[WARN] Working tree has uncommitted changes:"
        $reportLines += $gitStatus
    }
} catch {
    $reportLines += "[FAIL] Unable to run 'git status --porcelain'."
    $reportLines += "Error: $($_.Exception.Message)"
}

# --- Check Stage 1 handover file and staging URL ---
$handoverPath = Join-Path $projectRoot "docs\stage1-handover.md"
if (Test-Path $handoverPath) {
    $reportLines += "[OK] Stage 1 handover file found: $handoverPath"

    try {
        $content     = Get-Content $handoverPath
        $stagingLine = $content | Where-Object { $_ -match '^Staging URL:' }

        if ($stagingLine) {
            $stagingUrl = ($stagingLine -replace '^Staging URL:\s*', '').Trim()
            if ($stagingUrl) {
                $reportLines += "Staging URL from handover: $stagingUrl"

                try {
                    $response = Invoke-WebRequest -Uri $stagingUrl -Method Head -TimeoutSec 10 -UseBasicParsing
                    $reportLines += "[OK] Staging URL reachable (HTTP $($response.StatusCode))."
                } catch {
                    $reportLines += "[WARN] Could not reach staging URL."
                    $reportLines += "Error: $($_.Exception.Message)"
                }
            } else {
                $reportLines += "[WARN] 'Staging URL:' line found but empty. Update docs\stage1-handover.md."
            }
        } else {
            $reportLines += "[WARN] No line starting with 'Staging URL:' found in docs\stage1-handover.md."
        }
    } catch {
        $reportLines += "[FAIL] Error reading Stage 1 handover file."
        $reportLines += "Error: $($_.Exception.Message)"
    }
} else {
    $reportLines += "[FAIL] Stage 1 handover file missing at docs\stage1-handover.md."
}

# --- Write report to disk ---
$fullOutputPath = Join-Path $projectRoot $OutputPath
$reportLines | Set-Content -Encoding UTF8 $fullOutputPath

Write-Host "Stage 1 verification complete. Report written to $fullOutputPath"
