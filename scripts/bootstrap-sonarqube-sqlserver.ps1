param (
    [Parameter(Mandatory)]
    [ValidateSet("dev", "stg", "prod")]
    [string]$environment,
    [string]$serviceName = "sonarqube",
    [string]$databaseName = "sonarqube",
    [string]$databaseCollation = "Latin1_General_CS_AS",
    [string]$sonarLogin = "sonarqube",
    [string]$sonarPassword = "",
    [string]$dbSecretName = "",
    [string]$serverInstance = "",
    [string]$adminUser = "",
    [string]$adminPassword = ""
)

function Parse-ConnectionString([string]$connectionString) {
    $builder = New-Object System.Data.Common.DbConnectionStringBuilder
    $builder.ConnectionString = $connectionString

    return @{
        Server   = [string]$builder["Server"]
        UserId   = [string]$builder["User Id"]
        Password = [string]$builder["Password"]
    }
}

$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if ($null -eq $sqlcmd) {
    throw "sqlcmd nao encontrado. Instale o SQL Server Command Line Utilities."
}

if ([string]::IsNullOrWhiteSpace($serverInstance) -or [string]::IsNullOrWhiteSpace($adminUser) -or [string]::IsNullOrWhiteSpace($adminPassword)) {
    if ([string]::IsNullOrWhiteSpace($dbSecretName)) {
        $dbSecretName = "$serviceName-$environment-database"
    }

    Write-Host -ForegroundColor Yellow "Lendo credenciais da secret '$dbSecretName'..."
    $secretRaw = aws secretsmanager get-secret-value --secret-id $dbSecretName --query SecretString --output text
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($secretRaw)) {
        throw "Falha ao ler secret '$dbSecretName'."
    }

    $secret = $secretRaw | ConvertFrom-Json
    $connectionString = [string]$secret.value
    if ([string]::IsNullOrWhiteSpace($connectionString)) {
        throw "Secret '$dbSecretName' nao possui a chave 'value' com connection string."
    }

    $parts = Parse-ConnectionString -connectionString $connectionString
    $serverInstance = $parts.Server
    $adminUser = $parts.UserId
    $adminPassword = $parts.Password
}

$sqlFile = Join-Path $PSScriptRoot "sql/bootstrap-sonarqube.sql"
if (-not (Test-Path $sqlFile)) {
    throw "Script SQL nao encontrado em '$sqlFile'."
}

Write-Host -ForegroundColor Yellow "Aplicando bootstrap SonarQube em SQL Server..."

$sqlArgs = @(
    "-S", $serverInstance,
    "-U", $adminUser,
    "-P", $adminPassword,
    "-d", "master",
    "-b",
    "-i", $sqlFile,
    "-v", "DB_NAME=$databaseName",
    "-v", "DB_COLLATION=$databaseCollation",
    "-v", "SONAR_LOGIN=$sonarLogin",
    "-v", "SONAR_PASSWORD=$sonarPassword"
)

& $sqlcmd.Source @sqlArgs
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao executar bootstrap do SonarQube no SQL Server."
}

Write-Host
Write-Host -ForegroundColor Green "Bootstrap do SonarQube concluido."
