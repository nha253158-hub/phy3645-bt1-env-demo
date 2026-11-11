# Commit everything and push to GitHub.
param([string]$Remote = '')
. "$PSScriptRoot\common.ps1"
Start-Log '5_git_push.log'

$git = Find-Exe @('git', "$env:ProgramFiles\Git\cmd\git.exe")
if (-not $git) {
    $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source
    if ($winget) { Run 'winget install -e --id Git.Git' $winget @('install', '-e', '--id', 'Git.Git', '--accept-package-agreements', '--accept-source-agreements') }
    Write-Log 'Git installed - close this window and run run_5_push_github.bat again.' 'Yellow'
    exit 0
}
if (-not $Remote) {
    $cfg = Join-Path $Root 'scripts\remote.txt'
    if (Test-Path $cfg) { $Remote = (Get-Content $cfg | Select-Object -First 1).Trim() }
}

Run 'git --version' $git @('--version')
if (-not (Test-Path (Join-Path $Root '.git'))) { Run 'git init -b main' $git @('init', '-b', 'main') }

$name = Capture $git @('config', 'user.name')
if (-not $name) { Write-Log 'git user.name is not set: run  git config --global user.name "Your Name"  and  git config --global user.email "you@example.com"' 'Red'; exit 1 }

Run 'git add -A' $git @('add', '-A')
Run 'git status --short' $git @('status', '--short')
$null = Capture $git @('rev-parse', '--verify', 'HEAD')
if ($script:Code -eq 0) { $msg = 'Cap nhat bai tap 1: README, log, du lieu mau' }
else { $msg = 'Bai tap 1: venv, virtualenv, uv, pyenv, conda, Docker, VM + Phan 2 RDBMS' }
Run "git commit -m `"$msg`"" $git @('commit', '-q', '-m', $msg)
Run 'git branch -M main' $git @('branch', '-M', 'main')

if ($Remote) {
    $remotes = Capture $git @('remote')
    if ($remotes -contains 'origin') { Run "git remote set-url origin $Remote" $git @('remote', 'set-url', 'origin', $Remote) }
    else { Run "git remote add origin $Remote" $git @('remote', 'add', 'origin', $Remote) }
    Run 'git push -u origin main' $git @('push', '-u', 'origin', 'main')
} else {
    Write-Log 'No remote URL (scripts\remote.txt is empty) - committed locally only.' 'Yellow'
}
Run 'git log --oneline -5' $git @('log', '--oneline', '-5')

Write-Section 'DONE'
