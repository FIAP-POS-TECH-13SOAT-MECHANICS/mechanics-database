param (
    [Parameter(Mandatory)]
    [ValidateSet("relational", "no-sql")]
    [string]$dbType,
    [Parameter(Mandatory)]
    [string]$serviceName,
    [Parameter(Mandatory)]
    [ValidateSet("dev", "stg", "prod", "")]
    [string]$environment)
Write-Host -ForegroundColor Yellow "Updating database for service '$serviceName' in environment '$environment'..."
$bucketName = "fiap-mechanics-tf-$(aws sts get-access-key-info --access-key-id $(aws configure get aws_access_key_id) --query Account --output text)"

terraform -chdir="./$dbType/$serviceName" init -backend-config="bucket=$bucketName" -backend-config="key=$dbType-$serviceName-$environment.tfstate" -reconfigure
if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" } 

terraform -chdir="./$dbType/$serviceName" apply -var="environment=$environment" -auto-approve
if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" } 

Write-Host
Write-Host -ForegroundColor Green "Database for service '$serviceName' ($dbType) in environment '$environment' has been applied."
