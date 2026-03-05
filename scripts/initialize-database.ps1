param (
    [Parameter(Mandatory)]
    [ValidateSet("dev", "stg", "prod", "")]
    [string]$environment)
Write-Host -ForegroundColor Yellow "Updating infrastructure in environment '$environment'..."
  
$bucketName = "fiap-mechanics-tf-$(aws sts get-access-key-info --access-key-id $(aws configure get aws_access_key_id) --query Account --output text)"
terraform -chdir="./infra" init -backend-config="bucket=$bucketName" -backend-config="key=database-$environment.tfstate" -reconfigure
if ($LASTEXITCODE -ne 0) { throw "Terraform init failed" } 

terraform -chdir="./infra" apply -var="environment=$environment" -auto-approve
if ($LASTEXITCODE -ne 0) { throw "Terraform apply failed" } 

Write-Host
Write-Host -ForegroundColor Green "Infrastructure for environment '$environment' has been applied."
