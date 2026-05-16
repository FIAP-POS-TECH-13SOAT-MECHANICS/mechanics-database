param (
    [Parameter(Mandatory)]
    [ValidateSet("dev", "stg", "prod")]
    [string]$environment,
    [switch]$destroy
)

$action = if ($destroy) { "destroy" } else { "apply" }
$bucketName = "fiap-mechanics-tf-$(aws sts get-access-key-info --access-key-id $(aws configure get aws_access_key_id) --query Account --output text)"

$projects = @()
foreach ($dbType in @("relational", "no-sql")) {
    if (Test-Path "./$dbType") {
        Get-ChildItem -Path "./$dbType" -Directory | ForEach-Object {
            $projects += @{ DbType = $dbType; ServiceName = $_.Name }
        }
    }
}

Write-Host -ForegroundColor Yellow "Found $($projects.Count) project(s). Running $action command for databases in environment '$environment'..."
Write-Host

$jobs = @()
foreach ($project in $projects) {
    $dbType = $project.DbType
    $svcName = $project.ServiceName
    $workingDir = (Resolve-Path "./$dbType/$svcName").Path

    $jobs += Start-Job -Name "$dbType/$svcName" -ScriptBlock {
        param($workingDir, $bucketName, $dbType, $svcName, $environment, $action)

        Write-Output ">>> terraform init"
        terraform -chdir="$workingDir" init `
            -backend-config="bucket=$bucketName" `
            -backend-config="key=$dbType-$svcName-$environment.tfstate" `
            -reconfigure 2>&1 | ForEach-Object { Write-Output $_.ToString() }

        if ($LASTEXITCODE -ne 0) {
            Write-Output "ERROR: terraform init failed (exit $LASTEXITCODE)"
            return
        }

        Write-Output ">>> terraform $action"
        terraform -chdir="$workingDir" $action `
            -var="environment=$environment" `
            -auto-approve 2>&1 | ForEach-Object { Write-Output $_.ToString() }

        if ($LASTEXITCODE -ne 0) {
            Write-Output "ERROR: terraform $action failed (exit $LASTEXITCODE)"
            return
        }

        Write-Output "DONE"
    } -ArgumentList $workingDir, $bucketName, $dbType, $svcName, $environment, $action
}

$printedLines = @{}
$jobs | ForEach-Object { $printedLines[$_.Name] = 0 }

while ($true) {
    Start-Sleep -Seconds 2

    foreach ($job in $jobs) {
        $label = "[$($job.Name)]"
        $output = Receive-Job -Job $job -Keep

        $newLines = $output | Select-Object -Skip $printedLines[$job.Name]
        foreach ($line in $newLines) {
            Write-Host "$label $line"
        }
        $printedLines[$job.Name] += @($newLines).Count
    }

    $allDone = ($jobs | Where-Object { $_.State -in @("Running", "NotStarted") }).Count -eq 0
    if ($allDone) { break }
}

foreach ($job in $jobs) {
    $label = "[$($job.Name)]"
    $output = Receive-Job -Job $job -Keep
    $newLines = $output | Select-Object -Skip $printedLines[$job.Name]
    foreach ($line in $newLines) {
        Write-Host "$label $line"
    }
}

Write-Host

$succeeded = $jobs | Where-Object { $_.State -eq "Completed" }
Write-Host -ForegroundColor Yellow "Execution finished. $($succeeded.Count) jobs completed."

foreach ($job in $jobs) {
    $isSuccess = $job.State -eq "Completed" -and $job.ChildJobs[0].Output -contains "DONE"

    if ($isSuccess) {
        Write-Host -ForegroundColor Green $job.Name
    } else {
        Write-Host -ForegroundColor Red   "$($job.Name) (ERROR)"
    }
}
$jobs | Remove-Job