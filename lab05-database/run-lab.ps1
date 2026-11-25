$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
Push-Location $PSScriptRoot

function Invoke-Docker {
    param([string[]]$Arguments)
    & docker @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker exited with code $LASTEXITCODE."
    }
}

function Invoke-LabSql {
    param([string]$File, [string]$Database = 'library_lab05')
    Invoke-Docker -Arguments @(
        'compose', 'exec', '-T', 'postgres',
        'psql', '-X', '-v', 'ON_ERROR_STOP=1', '-P', 'pager=off',
        '-U', 'lab05', '-d', $Database, '-f', "/tmp/lab05-sql/$File"
    )
}

function Save-Check {
    param([string]$Name, [scriptblock]$Run)
    $path = Join-Path (Get-Location) "docs/evidence/$Name.txt"
    & $Run | Tee-Object -Variable lines | Write-Output
    [IO.File]::WriteAllLines($path, [string[]]$lines, [Text.UTF8Encoding]::new($false))
}

function Confirm-Rejection {
    param([string]$User, [string]$Sql, [string]$Expected, [string]$Evidence)
    $ErrorActionPreference = 'Continue'
    $arguments = @('compose', 'exec', '-T', 'postgres', 'psql', '-X',
        '-v', 'ON_ERROR_STOP=1', '-v', 'VERBOSITY=verbose', '-U', $User, '-d', 'library_lab05', '-c', $Sql)
    $output = & docker @arguments 2>&1
    $code = $LASTEXITCODE
    $lines = @("User: $User", "SQL: $Sql") + @($output | ForEach-Object { "$_" })
    if ($code -eq 0 -or (($lines -join ' ') -notmatch $Expected)) {
        throw "Expected PostgreSQL error $Expected. $($lines -join ' ')"
    }
    $path = Join-Path (Get-Location) "docs/evidence/$Evidence.txt"
    [IO.File]::WriteAllLines($path, [string[]]$lines, [Text.UTF8Encoding]::new($false))
    $lines
}

try {
    Invoke-Docker -Arguments @('compose', 'up', '-d', '--wait')

    $existing = Invoke-Docker -Arguments @(
        'compose', 'exec', '-T', 'postgres', 'psql', '-XAt', '-U', 'lab05',
        '-d', 'library_lab05', '-c', "SELECT to_regclass('public.books') IS NOT NULL"
    )
    if ($existing -eq 't') {
        throw 'The database already contains tables. Use a fresh volume for a new experiment.'
    }

    Invoke-Docker -Arguments @('compose', 'cp', 'sql', 'postgres:/tmp/lab05-sql')
    Invoke-Docker -Arguments @(
        'compose', 'exec', '-T', 'postgres', 'psql', '-X', '-v', 'ON_ERROR_STOP=1',
        '--single-transaction', '-U', 'lab05', '-d', 'library_lab05',
        '-f', '/tmp/lab05-sql/initialize.sql'
    )

    Save-Check '01-test-data' { Invoke-LabSql '00_benchmark_data.sql' }
    Save-Check '02-plans-before' {
        foreach ($sample in 1..3) { "Sample $sample"; Invoke-LabSql '01_benchmark.sql' }
    }
    Invoke-LabSql '02_indexes.sql'
    Save-Check '03-plans-after' {
        foreach ($sample in 1..3) { "Sample $sample"; Invoke-LabSql '01_benchmark.sql' }
    }

    Invoke-LabSql '03_level1.sql'
    Save-Check '04-views-and-simple-audit' { Invoke-LabSql '04_level1_check.sql' }
    Save-Check '05-viewer-read' {
        Invoke-Docker -Arguments @(
            'compose', 'exec', '-T', 'postgres', 'psql', '-X', '-U', 'lab05_viewer',
            '-d', 'library_lab05', '-c',
            'SELECT current_user, book_id, title FROM books ORDER BY book_id LIMIT 3'
        )
    }
    Confirm-Rejection -User 'lab05_viewer' -Sql 'UPDATE books SET title = title WHERE book_id = 1' -Expected '42501' -Evidence '06-viewer-write-rejected'

    Invoke-LabSql '05_level2.sql'
    Save-Check '07-partial-before' { Invoke-LabSql '06_partial_benchmark.sql' }
    Invoke-LabSql '07_partial_indexes.sql'
    Save-Check '08-partial-after' { Invoke-LabSql '06_partial_benchmark.sql' }
    Save-Check '09-rule-and-audit' { Invoke-LabSql '08_level2_check.sql' }
    Confirm-Rejection -User 'lab05' -Sql "INSERT INTO readers (full_name, email) VALUES ('Validation test', 'invalid-email')" -Expected '23514' -Evidence '10-invalid-email'

    Invoke-Docker -Arguments @(
        'compose', 'exec', '-T', 'postgres', 'psql', '-X', '-v', 'ON_ERROR_STOP=1',
        '-U', 'lab05', '-d', 'library_lab05', '-c', 'CREATE EXTENSION pg_stat_statements'
    )
    Invoke-LabSql '09_level3.sql'
    Save-Check '11-level3' { Invoke-LabSql '10_level3_check.sql' }
    Confirm-Rejection -User 'lab05_viewer' -Sql 'CALL lab05_maintain_database()' -Expected '42501' -Evidence '11b-maintenance-rejected'
    Invoke-LabSql '01_benchmark.sql' | Out-Null
    Invoke-LabSql '06_partial_benchmark.sql' | Out-Null
    Save-Check '12-monitoring' { Invoke-LabSql '11_monitor.sql' }

    New-Item -ItemType Directory -Force -Path backups | Out-Null
    Save-Check '13-backup-and-restore' {
        'pg_dump -Fc -U lab05 -d library_lab05 -f /tmp/library_lab05.dump'
        Invoke-Docker -Arguments @(
            'compose', 'exec', '-T', 'postgres', 'pg_dump', '-Fc', '-U', 'lab05',
            '-d', 'library_lab05', '-f', '/tmp/library_lab05.dump'
        )
        Invoke-Docker -Arguments @('compose', 'cp', 'postgres:/tmp/library_lab05.dump', 'backups/library_lab05.dump')
        "Backup size: $((Get-Item -LiteralPath 'backups/library_lab05.dump').Length) bytes"
        'createdb -U lab05 library_lab05_restore'
        Invoke-Docker -Arguments @('compose', 'exec', '-T', 'postgres', 'createdb', '-U', 'lab05', 'library_lab05_restore')
        'pg_restore --exit-on-error -U lab05 -d library_lab05_restore /tmp/library_lab05.dump'
        Invoke-Docker -Arguments @(
            'compose', 'exec', '-T', 'postgres', 'pg_restore', '--exit-on-error',
            '-U', 'lab05', '-d', 'library_lab05_restore', '/tmp/library_lab05.dump'
        )
        Invoke-Docker -Arguments @(
            'compose', 'exec', '-T', 'postgres', 'psql', '-X', '-v', 'ON_ERROR_STOP=1',
            '-U', 'lab05', '-d', 'library_lab05_restore',
            '-c', 'REVOKE CONNECT ON DATABASE library_lab05_restore FROM PUBLIC; GRANT CONNECT ON DATABASE library_lab05_restore TO lab05_viewer, lab05_user'
        )
        Invoke-LabSql '12_restore_check.sql' 'library_lab05_restore'
    }
}
finally {
    Pop-Location
}
