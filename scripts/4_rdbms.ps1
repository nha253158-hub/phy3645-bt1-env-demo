# Part 2 - RDBMS: PostgreSQL 17 and MySQL 8.4 running in Docker containers,
# then run the sample SQL scripts in part2-rdbms\.
. "$PSScriptRoot\common.ps1"
Start-Log '4_rdbms.log'

$docker = Get-Docker
if (-not $docker) { Write-Log 'Run run_2_docker.bat first (installs / starts Docker).' 'Red'; exit 1 }
$pw = 'phy3645'

function Get-FreePort([int]$preferred) {
    $p = $preferred
    while (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) { $p++ }
    return $p
}

function Start-Db([string]$name, [string]$image, [int]$port, [int]$innerPort, [string[]]$envArgs, [string]$volume) {
    $null = Capture $docker @('inspect', $name)
    if ($script:Code -eq 0) {
        Run "docker start $name" $docker @('start', $name)
    } else {
        $hostPort = Get-FreePort $port
        $argv = @('run', '-d', '--name', $name, '-p', "$($hostPort):$innerPort", '-v', $volume) + $envArgs + @($image)
        Run ("docker run -d --name $name -p $($hostPort):$innerPort -v $volume " + ($envArgs -join ' ') + " $image") $docker $argv
    }
}

function Wait-Ready([string]$what, [string[]]$probe) {
    Write-Log "waiting for $what to accept TCP connections..." 'Yellow'
    for ($i = 0; $i -lt 60; $i++) {
        $null = Capture $docker $probe
        if ($script:Code -eq 0) { Write-Log "$what is ready."; return }
        Start-Sleep -Seconds 2
    }
    Write-Log "$what did not become ready in time" 'Red'
}

# ---------------------------------------------------------------------------
Write-Section 'PostgreSQL 17 (container phy3645-pg)'
Start-Db 'phy3645-pg' 'postgres:17' 5432 5432 @('-e', "POSTGRES_PASSWORD=$pw") 'phy3645-pgdata:/var/lib/postgresql/data'
Wait-Ready 'PostgreSQL' @('exec', 'phy3645-pg', 'pg_isready', '-h', '127.0.0.1', '-U', 'postgres')
Run 'docker cp part2-rdbms\01_postgres.sql phy3645-pg:/tmp/' $docker @('cp', 'part2-rdbms\01_postgres.sql', 'phy3645-pg:/tmp/01_postgres.sql')
Run 'docker exec phy3645-pg psql -U postgres -e -f /tmp/01_postgres.sql' $docker @('exec', 'phy3645-pg', 'psql', '-U', 'postgres', '-e', '-f', '/tmp/01_postgres.sql')

# ---------------------------------------------------------------------------
Write-Section 'MySQL 8.4 LTS (container phy3645-mysql)'
Start-Db 'phy3645-mysql' 'mysql:8.4' 3306 3306 @('-e', "MYSQL_ROOT_PASSWORD=$pw") 'phy3645-mysqldata:/var/lib/mysql'
Wait-Ready 'MySQL' @('exec', '-e', "MYSQL_PWD=$pw", 'phy3645-mysql', 'mysqladmin', 'ping', '-h', '127.0.0.1', '-uroot', '--silent')
Run 'docker cp part2-rdbms\02_mysql.sql phy3645-mysql:/tmp/' $docker @('cp', 'part2-rdbms\02_mysql.sql', 'phy3645-mysql:/tmp/02_mysql.sql')
Run 'docker exec phy3645-mysql mysql -uroot -t -vvv -e "source /tmp/02_mysql.sql"' $docker @('exec', '-e', "MYSQL_PWD=$pw", 'phy3645-mysql', 'mysql', '-uroot', '--default-character-set=utf8mb4', '-t', '-vvv', '-e', 'source /tmp/02_mysql.sql')

Write-Section 'Containers'
Run 'docker ps --filter name=phy3645' $docker @('ps', '--filter', 'name=phy3645')
Write-Log ''
Write-Log 'Connect with a GUI (pgAdmin / DBeaver / MySQL Workbench): host=localhost, user=postgres or root, password=phy3645' 'Green'
Write-Log 'Interactive shells:  docker exec -it phy3645-pg psql -U postgres -d school' 'Green'
Write-Log '                     docker exec -it phy3645-mysql mysql -uroot -p school' 'Green'

Write-Section 'DONE'
Write-Log 'Log saved to logs\4_rdbms.log'
