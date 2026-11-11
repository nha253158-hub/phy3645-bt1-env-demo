# Demo 3 - Virtual machine with VirtualBox (fully scripted with VBoxManage):
#   create a small VM (Alpine Linux live ISO, 512 MB RAM, 1 vCPU, 2 GB virtual disk),
#   boot it, type commands into its console, save a screenshot of the console,
#   compare with the Windows host, then power the VM off.
. "$PSScriptRoot\common.ps1"
Start-Log '3_vm.log'

$vbox = Find-Exe @("$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe", 'VBoxManage')
if (-not $vbox) {
    Write-Section 'VirtualBox not found -> installing with winget'
    $winget = (Get-Command winget -ErrorAction SilentlyContinue).Source
    if ($winget) { Run 'winget install -e --id Oracle.VirtualBox' $winget @('install', '-e', '--id', 'Oracle.VirtualBox', '--accept-package-agreements', '--accept-source-agreements') }
    $vbox = Find-Exe @("$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe")
    if (-not $vbox) { Write-Log 'Install VirtualBox, then run run_3_vm.bat again.' 'Yellow'; exit 0 }
}

$vm      = 'phy3645-alpine'
$vmDir   = Join-Path $HOME 'VirtualBox VMs'
$isoDir  = Join-Path $vmDir 'iso'
$shotDir = Join-Path $Root '07-vm'
New-Item -ItemType Directory -Force -Path $isoDir, $shotDir | Out-Null

# ---------------------------------------------------------------------------
Write-Section 'Host machine (Windows, physical)'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
Write-Log "OS      : $($os.Caption) (build $($os.BuildNumber))"
Write-Log "CPU     : $($cpu.Name.Trim()) - $($cs.NumberOfLogicalProcessors) logical processors"
Write-Log "RAM     : $([math]::Round($cs.TotalPhysicalMemory / 1GB, 1)) GB"

Write-Section 'VirtualBox = type-2 hypervisor'
Run 'VBoxManage --version' $vbox @('--version')
Run 'VBoxManage list vms' $vbox @('list', 'vms')

# ---------------------------------------------------------------------------
Write-Section "Create VM '$vm' (virtual hardware)"
$null = Capture $vbox @('showvminfo', $vm)
if ($script:Code -ne 0) {
    # Alpine "virt" ISO: ~60 MB, boots to a live shell, no installation needed.
    $base = 'https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64'
    $isoName = $null
    try {
        $yaml = (Invoke-WebRequest -UseBasicParsing -Uri "$base/latest-releases.yaml").Content
        $isoName = [regex]::Match($yaml, 'alpine-virt-[0-9.]+-x86_64\.iso').Value
    } catch { }
    if (-not $isoName) { $isoName = 'alpine-virt-3.22.2-x86_64.iso'; $base = 'https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86_64' }
    $iso = Join-Path $isoDir $isoName
    if (-not (Test-Path $iso)) {
        Write-Log "downloading $isoName ..." 'Yellow'
        Invoke-WebRequest -UseBasicParsing -Uri "$base/$isoName" -OutFile $iso
    }
    $vdi = Join-Path $vmDir "$vm\$vm.vdi"
    Run "VBoxManage createvm --name $vm --ostype Linux_64 --register" $vbox @('createvm', '--name', $vm, '--ostype', 'Linux_64', '--register')
    Run "VBoxManage modifyvm $vm --memory 512 --cpus 1 --nic1 nat --graphicscontroller vmsvga --vram 16" $vbox @('modifyvm', $vm, '--memory', '512', '--cpus', '1', '--nic1', 'nat', '--graphicscontroller', 'vmsvga', '--vram', '16', '--boot1', 'dvd', '--boot2', 'disk', '--audio-enabled', 'off')
    Run "VBoxManage createmedium disk --filename $vm.vdi --size 2048" $vbox @('createmedium', 'disk', '--filename', $vdi, '--size', '2048')
    Run "VBoxManage storagectl $vm --name SATA --add sata" $vbox @('storagectl', $vm, '--name', 'SATA', '--add', 'sata')
    Run "VBoxManage storageattach $vm ... --type hdd --medium $vm.vdi" $vbox @('storageattach', $vm, '--storagectl', 'SATA', '--port', '0', '--device', '0', '--type', 'hdd', '--medium', $vdi)
    Run "VBoxManage storageattach $vm ... --type dvddrive --medium $isoName" $vbox @('storageattach', $vm, '--storagectl', 'SATA', '--port', '1', '--device', '0', '--type', 'dvddrive', '--medium', $iso)
}
Write-Log ''
Write-Log "> VBoxManage showvminfo $vm --machinereadable   (filtered)" 'Cyan'
foreach ($l in (Capture $vbox @('showvminfo', $vm, '--machinereadable'))) {
    if ($l -match '^(name|ostype|memory|cpus|VMState|firmware|nic1|graphicscontroller|vram)=' -or $l -match '\.(vdi|iso)"$') { Write-Log $l }
}

# ---------------------------------------------------------------------------
Write-Section 'Boot the VM and run commands INSIDE it'
$running = (Capture $vbox @('list', 'runningvms')) -match [regex]::Escape("`"$vm`"")
if (-not $running) {
    Run "VBoxManage startvm $vm --type headless" $vbox @('startvm', $vm, '--type', 'headless')
    Write-Log 'waiting 75 s for Alpine to boot...' 'Yellow'
    Start-Sleep -Seconds 75
}

function Send-Line([string]$text) {
    $null = Capture $vbox @('controlvm', $vm, 'keyboardputstring', $text)
    $null = Capture $vbox @('controlvm', $vm, 'keyboardputscancode', '1c', '9c')   # Enter
    Start-Sleep -Seconds 2
}
Send-Line 'root'        # Alpine live ISO: user root, no password
Start-Sleep -Seconds 3
$guestCmd = 'clear; uname -a; head -3 /etc/os-release; echo CPUs: $(nproc); free -m; fdisk -l /dev/sda | head -1; dmesg | grep -m1 -i hypervisor'
Write-Log ''
Write-Log "> (typed into the VM console)  $guestCmd" 'Cyan'
Send-Line $guestCmd
Start-Sleep -Seconds 3
$png = Join-Path $shotDir 'vm_console.png'
Run "VBoxManage controlvm $vm screenshotpng 07-vm\vm_console.png" $vbox @('controlvm', $vm, 'screenshotpng', $png)

# ---------------------------------------------------------------------------
Write-Section 'Power off the VM'
Run "VBoxManage controlvm $vm poweroff" $vbox @('controlvm', $vm, 'poweroff')
Start-Sleep -Seconds 3
Run 'VBoxManage list vms' $vbox @('list', 'vms')

Write-Section 'DONE'
Write-Log 'Screenshot of the VM console: 07-vm\vm_console.png'
Write-Log 'Log saved to logs\3_vm.log'
