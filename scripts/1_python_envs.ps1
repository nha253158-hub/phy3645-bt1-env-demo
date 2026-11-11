# Demo 1 - Python environment managers on Windows:
#   venv, virtualenv, uv, pyenv-win, conda
# The same file demo_app\check_env.py is run inside every environment so the
# results (interpreter path, Python version, requests version) can be compared.

. "$PSScriptRoot\common.ps1"
Start-Log '1_python_envs.log'
$check = 'demo_app\check_env.py'

# ---------------------------------------------------------------------------
Write-Section '0. System Python (no environment)'
$sysPy = $null
$pyLauncher = Find-Exe @('py')
if ($pyLauncher) {
    $sysPy = Capture $pyLauncher @('-3', '-c', 'import sys; print(sys.executable)') | Select-Object -Last 1
}
if (-not $sysPy) { $sysPy = Find-Exe @('python', "$HOME\miniconda3\python.exe", "$HOME\anaconda3\python.exe") }
if (-not $sysPy) { Write-Log 'No Python 3 found. Install Python first.' 'Red'; exit 1 }
Write-Log "system python = $sysPy"
Run 'python demo_app\check_env.py' $sysPy @($check)

# ---------------------------------------------------------------------------
Write-Section '1. venv (standard library)'
if (-not (Test-Path '01-venv\.venv\Scripts\python.exe')) {
    Run 'python -m venv 01-venv\.venv' $sysPy @('-m', 'venv', '01-venv\.venv')
}
$venvPy = Join-Path $Root '01-venv\.venv\Scripts\python.exe'
Run '01-venv\.venv\Scripts\activate   (then)   pip install requests==2.31.0' $venvPy @('-m', 'pip', 'install', '-q', '--disable-pip-version-check', 'requests==2.31.0')
Run 'python demo_app\check_env.py' $venvPy @($check)
Write-Utf8File '01-venv\requirements.txt' (Capture $venvPy @('-m', 'pip', 'freeze'))
Show-File '01-venv\requirements.txt'

# ---------------------------------------------------------------------------
Write-Section '2. virtualenv (third-party, superset of venv)'
Run 'pip install --user virtualenv' $sysPy @('-m', 'pip', 'install', '-q', '--user', '--disable-pip-version-check', 'virtualenv')
if ($script:Code -ne 0) {
    Run 'pip install virtualenv' $sysPy @('-m', 'pip', 'install', '-q', '--disable-pip-version-check', 'virtualenv')
}
Run 'virtualenv --version' $sysPy @('-m', 'virtualenv', '--version')
if (-not (Test-Path '02-virtualenv\.venv\Scripts\python.exe')) {
    Run 'virtualenv 02-virtualenv\.venv' $sysPy @('-m', 'virtualenv', '02-virtualenv\.venv')
}
$vePy = Join-Path $Root '02-virtualenv\.venv\Scripts\python.exe'
Run '02-virtualenv\.venv\Scripts\activate   (then)   pip install requests==2.28.2' $vePy @('-m', 'pip', 'install', '-q', '--disable-pip-version-check', 'requests==2.28.2')
Run 'python demo_app\check_env.py' $vePy @($check)
Write-Utf8File '02-virtualenv\requirements.txt' (Capture $vePy @('-m', 'pip', 'freeze'))
Show-File '02-virtualenv\requirements.txt'

# ---------------------------------------------------------------------------
Write-Section '3. uv (Astral, Rust): Python versions + venv + packages + lockfile'
$uv = Find-Exe @('uv', "$HOME\.local\bin\uv.exe", "$HOME\.cargo\bin\uv.exe")
if (-not $uv) {
    Write-Log ''
    Write-Log '> powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"' 'Cyan'
    $inst = powershell -NoProfile -ExecutionPolicy ByPass -Command 'irm https://astral.sh/uv/install.ps1 | iex' 2>&1 | ForEach-Object { "$_" }
    foreach ($l in $inst) { Write-Log $l }
    $uv = Find-Exe @("$HOME\.local\bin\uv.exe", "$HOME\.cargo\bin\uv.exe")
}
if (-not $uv) {
    Write-Log 'uv could not be installed - skipping uv demo' 'Red'
} else {
    Run 'uv --version' $uv @('--version')
    Push-Location (Join-Path $Root '03-uv')
    if (-not (Test-Path 'pyproject.toml')) {
        Run 'uv init --name uv-demo --python 3.11 --vcs none --no-readme' $uv @('init', '--name', 'uv-demo', '--python', '3.11', '--vcs', 'none', '--no-readme', '--no-workspace')
    }
    Run 'uv python install 3.11' $uv @('python', 'install', '3.11')
    Run 'uv add requests==2.32.3' $uv @('add', 'requests==2.32.3')
    Run 'uv run python ..\demo_app\check_env.py' $uv @('run', 'python', '..\demo_app\check_env.py')
    Run 'uv python list --only-installed' $uv @('python', 'list', '--only-installed')
    Pop-Location
    Show-File '03-uv\pyproject.toml'
}

# ---------------------------------------------------------------------------
Write-Section '4. pyenv-win (several Python versions side by side)'
$pyenvHome = "$HOME\.pyenv\pyenv-win"
$pyenv = Find-Exe @("$pyenvHome\bin\pyenv.bat", 'pyenv')
if (-not $pyenv) {
    Write-Log ''
    Write-Log '> install pyenv-win with the official script install-pyenv-win.ps1' 'Cyan'
    $tmp = Join-Path $env:TEMP 'install-pyenv-win.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1' -OutFile $tmp
    $inst = powershell -NoProfile -ExecutionPolicy Bypass -File $tmp 2>&1 | ForEach-Object { "$_" }
    foreach ($l in $inst) { Write-Log $l }
    $pyenv = Find-Exe @("$pyenvHome\bin\pyenv.bat")
}
if (-not $pyenv) {
    Write-Log 'pyenv-win could not be installed - skipping pyenv demo' 'Red'
} else {
    $env:PYENV = "$pyenvHome\"; $env:PYENV_ROOT = "$pyenvHome\"; $env:PYENV_HOME = "$pyenvHome\"
    $env:Path = "$pyenvHome\bin;$pyenvHome\shims;$env:Path"
    Run 'pyenv --version' $pyenv @('--version')
    Push-Location (Join-Path $Root '04-pyenv')
    Run 'pyenv install -s 3.10.11' $pyenv @('install', '-s', '-q', '3.10.11')
    if (-not (Test-Path "$pyenvHome\versions\3.10.11\python.exe")) {
        Run 'pyenv update' $pyenv @('update')
        Run 'pyenv install -s 3.10.11' $pyenv @('install', '-s', '-q', '3.10.11')
    }
    Run 'pyenv local 3.10.11' $pyenv @('local', '3.10.11')
    Run 'pyenv versions' $pyenv @('versions')
    Run 'pyenv which python' $pyenv @('which', 'python')
    $pyenvPy = "$pyenvHome\versions\3.10.11\python.exe"
    Run 'python ..\demo_app\check_env.py   (python resolved by pyenv local)' $pyenvPy @('..\demo_app\check_env.py')
    Pop-Location
    Show-File '04-pyenv\.python-version'
}

# ---------------------------------------------------------------------------
Write-Section '5. conda (Miniconda): env + Python + non-Python packages'
$conda = Find-Exe @("$HOME\miniconda3\Scripts\conda.exe", "$HOME\anaconda3\Scripts\conda.exe", 'conda')
if (-not $conda) {
    Write-Log 'conda not found - install Miniconda and rerun' 'Red'
} else {
    $envName = 'phy3645-demo'
    Run 'conda --version' $conda @('--version')
    $exists = (Capture $conda @('env', 'list')) | Where-Object { $_ -match "^$envName\s" }
    if (-not $exists) {
        Run "conda create -n $envName -c conda-forge python=3.9 requests=2.27 -y" $conda @('create', '-n', $envName, '-c', 'conda-forge', '--override-channels', 'python=3.9', 'requests=2.27', '-y', '-q')
    }
    Run "conda run -n $envName python demo_app\check_env.py" $conda @('run', '-n', $envName, 'python', $check)
    Run 'conda env list' $conda @('env', 'list')
    $yml = Capture $conda @('env', 'export', '-n', $envName, '--from-history') | Where-Object { $_ -notmatch '^prefix:' }
    Write-Utf8File '05-conda\environment.yml' $yml
    Show-File '05-conda\environment.yml'
}

Write-Section 'DONE'
Write-Log "Log saved to logs\1_python_envs.log"
