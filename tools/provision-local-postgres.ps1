param([string]$EnvFile = 'apps/api/.env')
$ErrorActionPreference = 'Stop'

# Credentials stay in the ignored environment file and child environment/stdin.
$taskConfig = @{}
foreach ($taskLine in Get-Content -LiteralPath $EnvFile) {
  if ($taskLine -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') {
    $taskConfig[$Matches[1]] = $Matches[2].Trim('"').Trim("'")
  }
}
if ($env:POSTGRES_ADMIN_URL) { $taskConfig['POSTGRES_ADMIN_URL'] = $env:POSTGRES_ADMIN_URL }
if (!$taskConfig['DATABASE_URL'] -or !$taskConfig['POSTGRES_ADMIN_URL']) {
  throw 'Configure DATABASE_URL and POSTGRES_ADMIN_URL in the ignored API environment file.'
}
$taskApp = [uri]$taskConfig['DATABASE_URL']
$taskAdmin = [uri]$taskConfig['POSTGRES_ADMIN_URL']
foreach ($taskConnection in @($taskApp, $taskAdmin)) {
  if ($taskConnection.Host -notin @('localhost', '127.0.0.1', '::1')) {
    throw 'This provisioning helper accepts local PostgreSQL connections only.'
  }
}
if ($taskApp.Port -ne $taskAdmin.Port -or $taskApp.Port -le 0) {
  throw 'Both local connection URLs must specify the same explicit port.'
}
$taskAppAuth = $taskApp.UserInfo.Split(':', 2)
$taskAdminAuth = $taskAdmin.UserInfo.Split(':', 2)
if ($taskAppAuth.Length -ne 2 -or $taskAdminAuth.Length -ne 2) {
  throw 'Both connection URLs must include a username and password.'
}
$taskRole = [uri]::UnescapeDataString($taskAppAuth[0])
$taskPassword = [uri]::UnescapeDataString($taskAppAuth[1])
$taskDatabase = $taskApp.AbsolutePath.TrimStart('/')
$taskTestDatabase = 'supplybiz_service_area_test'
if ($taskRole -notmatch '^supplybiz_[a-z0-9_]+$' -or $taskDatabase -notmatch '^supplybiz(?:_[a-z0-9_]+)?$') {
  throw 'Expected a Supply Biz application role and database name.'
}
$taskPsql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
if (!(Test-Path -LiteralPath $taskPsql)) { throw 'PostgreSQL 18 psql executable is unavailable.' }
function Invoke-LocalSql([string]$Database, [string]$Sql) {
  $taskStart = New-Object System.Diagnostics.ProcessStartInfo
  $taskStart.FileName = $taskPsql
  $taskStart.Arguments = "-X -w -v ON_ERROR_STOP=1 -h localhost -p $($taskAdmin.Port) -U $([uri]::UnescapeDataString($taskAdminAuth[0])) -d $Database -At"
  $taskStart.UseShellExecute = $false
  $taskStart.CreateNoWindow = $true
  $taskStart.RedirectStandardInput = $true
  $taskStart.RedirectStandardOutput = $true
  $taskStart.RedirectStandardError = $true
  $taskStart.EnvironmentVariables['PGPASSWORD'] = [uri]::UnescapeDataString($taskAdminAuth[1])
  $taskProcess = [System.Diagnostics.Process]::Start($taskStart)
  $taskProcess.StandardInput.WriteLine($Sql)
  $taskProcess.StandardInput.Close()
  $taskResult = $taskProcess.StandardOutput.ReadToEnd()
  $taskFailure = $taskProcess.StandardError.ReadToEnd()
  $taskProcess.WaitForExit()
  if ($taskProcess.ExitCode -ne 0) {
    # SQL errors can echo statements. Never emit the SQL or raw stderr here.
    if ($taskFailure -match 'authentication failed|no password supplied') { throw 'PostgreSQL administrator authentication failed.' }
    if ($taskFailure -match 'extension.*postgis.*not available') { throw 'Install the PostGIS extension files for PostgreSQL 18, then rerun.' }
    throw 'PostgreSQL provisioning failed; inspect the local server using the administrator account.'
  }
  return $taskResult.Trim()
}
$taskAdminDatabase = $taskAdmin.AbsolutePath.TrimStart('/')
if ($taskAdminDatabase -notmatch '^[a-zA-Z0-9_]+$' -or $taskAdminAuth[0] -notmatch '^[a-zA-Z0-9_]+$') {
  throw 'Administrator database and role must use simple PostgreSQL identifiers.'
}
$taskExists = Invoke-LocalSql $taskAdminDatabase "SELECT 1 FROM pg_roles WHERE rolname = '$taskRole';"
if ($taskExists -ne '1') {
  $taskQuotedPassword = $taskPassword.Replace("'", "''")
  $null = Invoke-LocalSql $taskAdminDatabase "SET standard_conforming_strings = on; CREATE ROLE $taskRole LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD '$taskQuotedPassword';"
  Write-Output 'Created the application login role.'
} else { Write-Output 'Application role already exists; its password and permissions were preserved.' }
foreach ($taskName in @($taskDatabase, $taskTestDatabase) | Select-Object -Unique) {
  $taskExists = Invoke-LocalSql $taskAdminDatabase "SELECT 1 FROM pg_database WHERE datname = '$taskName';"
  if ($taskExists -ne '1') {
    $null = Invoke-LocalSql $taskAdminDatabase "CREATE DATABASE $taskName OWNER $taskRole;"
    Write-Output "Created database $taskName."
  } else { Write-Output "Database $taskName already exists; ownership and contents were preserved." }
}
foreach ($taskName in @($taskDatabase, $taskTestDatabase) | Select-Object -Unique) {
  $null = Invoke-LocalSql $taskName 'CREATE EXTENSION IF NOT EXISTS postgis;'
  Write-Output "PostGIS enabled in $taskName."
}
Write-Output 'Local provisioning complete. Apply migrations separately; use supplybiz_service_area_test for task checks.'
