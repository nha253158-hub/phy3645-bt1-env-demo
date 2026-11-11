# Shared helpers for the demo scripts (Windows PowerShell 5.1+).
# Every command and its output is printed on screen AND appended to a log file in logs\.

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar in PS 5.1
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
$env:PYTHONIOENCODING = 'utf-8'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'logs') | Out-Null
$script:Code = 0

function Start-Log([string]$name) {
    $script:Log = Join-Path $Root "logs\$name"
    $header = "# $name | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $env:COMPUTERNAME | $([Environment]::OSVersion.VersionString)"
    [IO.File]::WriteAllText($script:Log, $header + "`r`n")
    Write-Host $header -ForegroundColor Green
}

function Write-Log([string]$text, [string]$color = 'Gray') {
    Write-Host $text -ForegroundColor $color
    [IO.File]::AppendAllText($script:Log, $text + "`r`n")
}

function Write-Section([string]$title) {
    Write-Log ''
    Write-Log ('=' * 70) 'Yellow'
    Write-Log "== $title" 'Yellow'
    Write-Log ('=' * 70) 'Yellow'
}

# Run a native program, log "> <shown>" followed by its stdout+stderr.
# Exit code is left in $script:Code.
function Run([string]$shown, [string]$exe, [string[]]$argv = @()) {
    Write-Log ''
    Write-Log "> $shown" 'Cyan'
    $out = & $exe @argv 2>&1 | ForEach-Object { "$_" }
    $script:Code = $LASTEXITCODE
    foreach ($line in $out) { Write-Log $line }
    if ($script:Code -ne 0) { Write-Log "[exit code $($script:Code)]" 'Red' }
}

# Same as Run but returns the output lines instead of logging them (for files / variables).
function Capture([string]$exe, [string[]]$argv = @()) {
    $out = & $exe @argv 2>$null | ForEach-Object { "$_" }
    $script:Code = $LASTEXITCODE
    return $out
}

function Find-Exe([string[]]$candidates) {
    foreach ($c in $candidates) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        if (($c -match '[\\/]') -and (Test-Path $c)) { return (Resolve-Path $c).Path }
        $cmd = Get-Command $c -CommandType Application -ErrorAction SilentlyContinue |
            Where-Object { $_.Source -notlike '*WindowsApps*' } | Select-Object -First 1
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Show-File([string]$path) {
    Write-Log ''
    Write-Log "> type $path" 'Cyan'
    foreach ($l in (Get-Content (Join-Path $Root $path))) { Write-Log $l }
}

function Write-Utf8File([string]$path, [string[]]$lines) {
    $full = Join-Path $Root $path
    [IO.File]::WriteAllLines($full, $lines, (New-Object System.Text.UTF8Encoding $false))
}

# Find docker.exe and make sure the engine is running (starts Docker Desktop if needed).
# Returns the path to docker.exe, or $null if Docker is missing / not running.
function Get-Docker {
    $docker = Find-Exe @('docker', "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe")
    if (-not $docker) { return $null }
    $null = Capture $docker @('info')
    if ($script:Code -ne 0) {
        $dd = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dd) {
            Write-Log 'Starting Docker Desktop and waiting for the engine (max ~3 min)...' 'Yellow'
            Start-Process $dd
        }
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Seconds 3
            $null = Capture $docker @('info')
            if ($script:Code -eq 0) { break }
        }
    }
    if ($script:Code -ne 0) {
        Write-Log 'Docker engine is not running. Open Docker Desktop, wait for "Engine running", then rerun.' 'Red'
        return $null
    }
    return $docker
}
