# RacoDesk - development environment check (PowerShell)
# Usage (from the repository root):  powershell -ExecutionPolicy Bypass -File scripts/check-env.ps1
# It only reads versions; it does not install or change anything.

$missing = 0

function Test-Tool {
    param([string]$Name, [string]$Command, [string[]]$VersionArgs)
    $found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $found) {
        Write-Host ("[ MISSING ] {0}" -f $Name) -ForegroundColor Red
        $script:missing++
        return
    }
    $version = (& $Command @VersionArgs 2>&1 | Select-Object -First 1)
    Write-Host ("[   OK    ] {0}: {1}" -f $Name, $version) -ForegroundColor Green
}

Write-Host "RacoDesk - environment check"
Write-Host "----------------------------"

Test-Tool "Git"        "git"      @("--version")
Test-Tool "VS Code"    "code"     @("--version")
Test-Tool "PHP"        "php"      @("--version")
Test-Tool "Composer"   "composer" @("--version")
Test-Tool "Node.js"    "node"     @("--version")
Test-Tool "npm"        "npm"      @("--version")
Test-Tool "PostgreSQL" "psql"     @("--version")
Test-Tool "Java (JDK)" "java"     @("-version")

# PHP extensions needed by Laravel + PostgreSQL
if (Get-Command php -ErrorAction SilentlyContinue) {
    $modules = (php -m) -join " "
    foreach ($ext in @("pdo_pgsql", "mbstring", "openssl", "fileinfo", "curl")) {
        if ($modules -match $ext) {
            Write-Host ("[   OK    ] PHP extension {0}" -f $ext) -ForegroundColor Green
        } else {
            Write-Host ("[ MISSING ] PHP extension {0} (enable it in php.ini)" -f $ext) -ForegroundColor Red
            $missing++
        }
    }
}

# Android SDK
if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
    Write-Host ("[   OK    ] ANDROID_HOME: {0}" -f $env:ANDROID_HOME) -ForegroundColor Green
} else {
    Write-Host "[ MISSING ] ANDROID_HOME is not set (install Android Studio and set the variable)" -ForegroundColor Red
    $missing++
}
Test-Tool "adb (Android platform-tools)" "adb" @("--version")

# Git identity
$gitName  = git config user.name 2>$null
$gitEmail = git config user.email 2>$null
if ($gitName -and $gitEmail) {
    Write-Host ("[   OK    ] Git identity: {0} <{1}>" -f $gitName, $gitEmail) -ForegroundColor Green
} else {
    Write-Host "[ MISSING ] Git identity (git config user.name / user.email)" -ForegroundColor Red
    $missing++
}

Write-Host "----------------------------"
if ($missing -eq 0) {
    Write-Host "Everything is ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host ("{0} item(s) missing. See docs/dev-setup.md" -f $missing) -ForegroundColor Yellow
    exit 1
}
