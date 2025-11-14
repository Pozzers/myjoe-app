Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$reportLines = @()
$reportLines += "=== My Joe - Stage 0 Verification Report (v3) ==="
$reportLines += "Generated: $([DateTime]::UtcNow.ToString('s'))"
$reportLines += ""

function Add-Section {
    param([string]$title)
    $script:reportLines += ""
    $script:reportLines += "### $title"
}

Add-Section "Environment"

# Node.js
try {
    $nodeVersion = node -p "process.versions.node"
    $reportLines += "Node.js version: $nodeVersion"

    $parts = $nodeVersion.Split(".")
    if ($parts.Length -ge 2) {
        $major = [int]$parts[0]
        $minor = [int]$parts[1]

        if ($major -lt 20 -or ($major -eq 20 -and $minor -lt 9)) {
            $reportLines += "WARNING: Node.js version is below 20.9, which is the minimum required by modern Next.js."
        } else {
            $reportLines += "OK: Node.js version meets or exceeds the Next.js minimum (20.9+)."
        }
    } else {
        $reportLines += "WARN: Could not parse Node.js version string."
    }
}
catch {
    $reportLines += "ERROR: Node.js is not available on PATH. $_"
}

# npm
try {
    $npmVersion = npm -v
    $reportLines += "npm version: $npmVersion"
}
catch {
    $reportLines += "ERROR: npm is not available on PATH. $_"
}

# Git
try {
    $gitVersion = git --version
    $reportLines += "Git version: $gitVersion"
}
catch {
    $reportLines += "ERROR: Git is not available on PATH. $_"
}

Add-Section "Project structure"

# Work out project root as the parent of this script's folder (tools\)
try {
    $projectPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $reportLines += "Project root: $projectPath"
}
catch {
    $reportLines += "ERROR: Could not determine project root from script location. $_"
    $projectPath = $null
}

if (-not $projectPath) {
    $reportLines += "ABORT: No project path available, skipping further checks."
}
else {
    if (-not (Test-Path $projectPath)) {
        $reportLines += "ERROR: Project folder not found at $projectPath."
    }
    else {
        $reportLines += "OK: Project folder exists."

        # Simple key files that should exist
        $singleKeyFiles = @(
            "package.json",
            "tsconfig.json"
        )

        foreach ($rel in $singleKeyFiles) {
            $full = Join-Path $projectPath $rel
            if (Test-Path $full) {
                $reportLines += "OK: Found $rel"
                try {
                    $hash = Get-FileHash -Path $full -Algorithm SHA256
                    $reportLines += "HASH ($rel): $($hash.Hash)"
                }
                catch {
                    $reportLines += "WARN: Could not compute hash for $rel - $($_.Exception.Message)"
                }
            }
            else {
                $reportLines += "MISSING: $rel"
            }
        }

        # app entry files, supporting both app/ and src/app/ layouts
        $entryFileGroups = @(
            @{
                Name  = "Root layout (layout.tsx)";
                Paths = @("app\layout.tsx", "src\app\layout.tsx")
            },
            @{
                Name  = "Root page (page.tsx)";
                Paths = @("app\page.tsx", "src\app\page.tsx")
            }
        )

        foreach ($group in $entryFileGroups) {
            $foundAny = $false
            foreach ($rel in $group.Paths) {
                $full = Join-Path $projectPath $rel
                if (Test-Path $full) {
                    if (-not $foundAny) {
                        $reportLines += "OK: Found $($group.Name) at $rel"
                    }
                    else {
                        $reportLines += "INFO: Additional location for $($group.Name) found at $rel"
                    }

                    $foundAny = $true
                    try {
                        $hash = Get-FileHash -Path $full -Algorithm SHA256
                        $reportLines += "HASH ($rel): $($hash.Hash)"
                    }
                    catch {
                        $reportLines += "WARN: Could not compute hash for $rel - $($_.Exception.Message)"
                    }
                }
            }

            if (-not $foundAny) {
                $reportLines += "MISSING: No layout/page file found for $($group.Name) in app\\ or src\\app\\."
            }
        }

        # Next.js config (any supported extension)
        $nextConfigCandidates = @(
            "next.config.mjs",
            "next.config.js",
            "next.config.ts",
            "next.config.mts",
            "next.config.cjs"
        )

        $foundNextConfig = $false
        foreach ($cfg in $nextConfigCandidates) {
            $fullCfg = Join-Path $projectPath $cfg
            if (Test-Path $fullCfg) {
                $foundNextConfig = $true
                $reportLines += "OK: Found Next.js config file: $cfg"
                try {
                    $hash = Get-FileHash -Path $fullCfg -Algorithm SHA256
                    $reportLines += "HASH ($cfg): $($hash.Hash)"
                }
                catch {
                    $reportLines += "WARN: Could not compute hash for $cfg - $($_.Exception.Message)"
                }
                break
            }
        }

        if (-not $foundNextConfig) {
            $reportLines += "MISSING: No next.config.* file found in project root."
        }

        # PostCSS config (for Tailwind)
        $postcssCandidates = @(
            "postcss.config.mjs",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.ts"
        )

        $foundPostcss = $false
        foreach ($cfg in $postcssCandidates) {
            $fullCfg = Join-Path $projectPath $cfg
            if (Test-Path $fullCfg) {
                $foundPostcss = $true
                $reportLines += "OK: Found PostCSS config file: $cfg"
                try {
                    $hash = Get-FileHash -Path $fullCfg -Algorithm SHA256
                    $reportLines += "HASH ($cfg): $($hash.Hash)"
                }
                catch {
                    $reportLines += "WARN: Could not compute hash for $cfg - $($_.Exception.Message)"
                }
                break
            }
        }

        if (-not $foundPostcss) {
            $reportLines += "INFO: No postcss.config.* file found. Next.js includes PostCSS by default, but Tailwind typically expects an explicit config."
        }
    }
}

Add-Section "Dependencies (from package.json)"

if ($projectPath) {
    $packageJsonPath = Join-Path $projectPath "package.json"
    if (Test-Path $packageJsonPath) {
        try {
            $packageJsonRaw = Get-Content $packageJsonPath -Raw
            $packageJson = $packageJsonRaw | ConvertFrom-Json

            $deps = $packageJson.dependencies
            $devDeps = $packageJson.devDependencies

            $depNames = @()
            if ($deps) { $depNames += $deps.PSObject.Properties.Name }
            $devDepNames = @()
            if ($devDeps) { $devDepNames += $devDeps.PSObject.Properties.Name }

            $expectedRequired = @(
                "next",
                "react",
                "react-dom",
                "typescript",
                "tailwindcss",
                "@tailwindcss/postcss"
            )

            $expectedOptional = @(
                "postcss"
            )

            foreach ($name in $expectedRequired) {
                if ($depNames -contains $name -or $devDepNames -contains $name) {
                    $reportLines += "OK: Dependency present - $name"
                }
                else {
                    $reportLines += "WARN: Required dependency not found in package.json - $name"
                }
            }

            foreach ($name in $expectedOptional) {
                if ($depNames -contains $name -or $devDepNames -contains $name) {
                    $reportLines += "OK: Optional dependency present - $name"
                }
                else {
                    $reportLines += "INFO: Optional dependency not found in package.json - $name"
                }
            }
        }
        catch {
            $reportLines += "ERROR: Could not read or parse package.json - $($_.Exception.Message)"
        }
    }
    else {
        $reportLines += "ERROR: package.json not found at $packageJsonPath."
    }
}

Add-Section "npm run dev (dry run)"

if ($projectPath) {
    Push-Location $projectPath
    try {
        # Do not fully start the dev server; just check that the script exists and responds.
        $devOutput = npm run dev -- --help 2>&1 | Select-Object -First 10
        $reportLines += "OK: 'npm run dev -- --help' executed. First lines:"
        foreach ($line in $devOutput) {
            $reportLines += "  $line"
        }
    }
    catch {
        $reportLines += "ERROR: 'npm run dev -- --help' failed - $($_.Exception.Message)"
    }
    finally {
        Pop-Location
    }
}

if ($projectPath) {
    $reportPath = Join-Path $projectPath "stage0-report.txt"
    $reportLines | Set-Content -Path $reportPath -Encoding UTF8
    Write-Host "Stage 0 verification complete. Report written to $reportPath"
}
else {
    Write-Host "Stage 0 verification could not complete because the project path could not be determined."
}
