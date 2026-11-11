# Demo 2 - Docker containers on Windows (Docker Desktop, WSL2 backend)
. "$PSScriptRoot\common.ps1"
Start-Log '2_docker.log'
$env:WSL_UTF8 = '1'

$exe = Find-Exe @('docker', "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe")
if (-not $exe) {
    Write-Section 'Docker not found -> installing Docker Desktop with winget'
    $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source
    if ($winget) {
        Run 'winget install -e --id Docker.DockerDesktop' $winget @('install', '-e', '--id', 'Docker.DockerDesktop', '--accept-package-agreements', '--accept-source-agreements')
    } else {
        Write-Log 'winget not available. Download Docker Desktop: https://www.docker.com/products/docker-desktop/' 'Red'
    }
    Write-Log ''
    Write-Log 'NEXT: restart Windows if asked, open Docker Desktop once (accept terms, skip sign-in), then run run_2_docker.bat again.' 'Yellow'
    exit 0
}
$docker = Get-Docker
if (-not $docker) { exit 1 }

Write-Section 'Docker engine'
Run 'docker --version' $docker @('--version')
Run 'docker info --format "OS / kernel / CPU / RAM of the Docker host"' $docker @('info', '--format', 'OS={{.OperatingSystem}} | Kernel={{.KernelVersion}} | CPUs={{.NCPU}} | MemTotal={{.MemTotal}}')

Write-Section 'A. Build and run our own image (06-docker\Dockerfile)'
Show-File '06-docker\Dockerfile'
Run 'docker build -t phy3645-env-demo 06-docker' $docker @('build', '-t', 'phy3645-env-demo', '06-docker')
Run 'docker run --rm phy3645-env-demo' $docker @('run', '--rm', 'phy3645-env-demo')
Run 'docker images phy3645-env-demo' $docker @('images', 'phy3645-env-demo')

Write-Section 'B. Isolation: each container has its own userland, processes, hostname'
Run 'docker run --rm alpine cat /etc/os-release' $docker @('run', '--rm', 'alpine', 'cat', '/etc/os-release')
Run 'docker run --rm alpine ps' $docker @('run', '--rm', 'alpine', 'ps')
Run 'docker run --rm alpine hostname' $docker @('run', '--rm', 'alpine', 'hostname')

Write-Section 'C. ...but they all share ONE kernel (the Linux kernel of the WSL2 VM)'
Run 'ver   (Windows host)' $env:ComSpec @('/c', 'ver')
Run 'docker run --rm alpine uname -r' $docker @('run', '--rm', 'alpine', 'uname', '-r')
Run 'docker run --rm python:3.12-slim uname -r' $docker @('run', '--rm', 'python:3.12-slim', 'uname', '-r')
$wsl = "$env:windir\System32\wsl.exe"
if (Test-Path $wsl) {
    Run 'wsl -d docker-desktop uname -r   (the WSL2 VM itself)' $wsl @('-d', 'docker-desktop', 'uname', '-r')
    if ($script:Code -ne 0) { Run 'wsl uname -r   (the WSL2 VM itself)' $wsl @('uname', '-r') }
}

Write-Section 'D. Container lifecycle + port mapping (nginx web server)'
$null = Capture $docker @('rm', '-f', 'phy3645-web')
Run 'docker run -d --name phy3645-web -p 8080:80 nginx:alpine' $docker @('run', '-d', '--name', 'phy3645-web', '-p', '8080:80', 'nginx:alpine')
Start-Sleep -Seconds 3
Run 'docker ps' $docker @('ps')
Write-Log ''
Write-Log '> curl http://localhost:8080' 'Cyan'
try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:8080' -TimeoutSec 15
    $title = [regex]::Match($r.Content, '<title>(.*?)</title>').Groups[1].Value
    Write-Log "HTTP $($r.StatusCode)  title: $title"
} catch { Write-Log "request failed: $($_.Exception.Message)" 'Red' }
Run 'docker stop phy3645-web' $docker @('stop', 'phy3645-web')
Run 'docker rm phy3645-web' $docker @('rm', 'phy3645-web')
Run 'docker ps -a --filter name=phy3645' $docker @('ps', '-a', '--filter', 'name=phy3645')

Write-Section 'DONE'
Write-Log 'Log saved to logs\2_docker.log'
