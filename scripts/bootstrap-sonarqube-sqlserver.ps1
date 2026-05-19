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
    $parts = @{}

    foreach ($segment in ($connectionString -split ";")) {
        if ([string]::IsNullOrWhiteSpace($segment)) {
            continue
        }

        $separatorIndex = $segment.IndexOf("=")
        if ($separatorIndex -lt 1) {
            continue
        }

        $key = $segment.Substring(0, $separatorIndex).Trim().ToLowerInvariant()
        $value = $segment.Substring($separatorIndex + 1).Trim()
        $parts[$key] = $value
    }

    $server = if ($parts.ContainsKey("server")) { $parts["server"] } elseif ($parts.ContainsKey("data source")) { $parts["data source"] } else { "" }
    $userId = if ($parts.ContainsKey("user id")) { $parts["user id"] } elseif ($parts.ContainsKey("uid")) { $parts["uid"] } else { "" }
    $password = if ($parts.ContainsKey("password")) { $parts["password"] } elseif ($parts.ContainsKey("pwd")) { $parts["pwd"] } else { "" }

    return @{
        Server   = [string]$server
        UserId   = [string]$userId
        Password = [string]$password
    }
}

function Get-SqlcmdExecutor {
    $nativeSqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
    if ($null -ne $nativeSqlcmd) {
        return @{
            Kind    = "native"
            Command = $nativeSqlcmd.Source
        }
    }

    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if ($null -eq $docker) {
        throw "sqlcmd nao encontrado. Instale SQL Server Command Line Utilities ou Docker."
    }

    Write-Host -ForegroundColor Yellow "sqlcmd nao encontrado localmente. Usando container mcr.microsoft.com/mssql-tools."

    return @{
        Kind    = "docker"
        Command = $docker.Source
    }
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

    if ([string]::IsNullOrWhiteSpace($serverInstance)) {
        throw "Nao foi possivel extrair 'Server' da connection string da secret '$dbSecretName'."
    }
    if ([string]::IsNullOrWhiteSpace($adminUser)) {
        throw "Nao foi possivel extrair 'User Id' da connection string da secret '$dbSecretName'."
    }
    if ([string]::IsNullOrWhiteSpace($adminPassword)) {
        throw "Nao foi possivel extrair 'Password' da connection string da secret '$dbSecretName'."
    }
}

$sqlFile = Join-Path $PSScriptRoot "sql/bootstrap-sonarqube.sql"
if (-not (Test-Path $sqlFile)) {
    throw "Script SQL nao encontrado em '$sqlFile'."
}

Write-Host -ForegroundColor Yellow "Aplicando bootstrap SonarQube em SQL Server..."

${commonSqlArgs} = @(
    "-S", $serverInstance,
    "-U", $adminUser,
    "-P", $adminPassword,
    "-d", "master",
    "-b",
    "-v", "DB_NAME=$databaseName",
    "-v", "DB_COLLATION=$databaseCollation"
)

if (-not [string]::IsNullOrWhiteSpace($sonarPassword)) {
    $commonSqlArgs += @(
        "-v", "SONAR_LOGIN=$sonarLogin",
        "-v", "SONAR_PASSWORD=$sonarPassword"
    )
}

${executor} = Get-SqlcmdExecutor

if ($executor.Kind -eq "native") {
    $sqlArgs = $commonSqlArgs + @("-i", $sqlFile)

    & $executor.Command @sqlArgs
} else {
    $sqlFileName = Split-Path -Leaf $sqlFile
    $sqlDirectory = Split-Path -Parent $sqlFile
    $mountedSqlFile = "/sql/$sqlFileName"

    $dockerSqlCmdCandidates = @(
        "/opt/mssql-tools18/bin/sqlcmd",
        "/opt/mssql-tools/bin/sqlcmd"
    )

    $dockerCommand = "set -e; "
    $dockerCommand += "if [ -x {0} ]; then SQLCMD={0}; elif [ -x {1} ]; then SQLCMD={1}; else echo 'sqlcmd nao encontrado no container'; exit 1; fi; " -f $dockerSqlCmdCandidates[0], $dockerSqlCmdCandidates[1]
    $dockerCommand += "`"$`SQLCMD`" "
    $dockerCommand += ($commonSqlArgs + @("-i", $mountedSqlFile) | ForEach-Object { "'" + ($_ -replace "'", "'\\''") + "'" }) -join " "

    $dockerArgs = @(
        "run",
        "--rm",
        "-v", "${sqlDirectory}:/sql:ro",
        "mcr.microsoft.com/mssql-tools",
        "bash",
        "-lc",
        $dockerCommand
    )

    & $executor.Command @dockerArgs
}

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao executar bootstrap do SonarQube no SQL Server."
}

Write-Host
Write-Host -ForegroundColor Green "Bootstrap do SonarQube concluido."
