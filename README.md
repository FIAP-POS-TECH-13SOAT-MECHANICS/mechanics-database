# Mechanics Database

Provisiona a infraestrutura de um banco de dados relacional usando Terraform.

## Definição do ambiente

- Banco de dados: MSSQL 2025
- Instância: RDS `db.t3.small`
- Credenciais de acesso: AWS Secrets Manager

## Provisionamento da infraestrutura

Para executar localmente, primeiro suba a camada `shared` disponível no [repositório de infraestrutura](https://github.com/FIAP-POS-TECH-13SOAT-MECHANICS/mechanics-infra).
Essa camada cria as configurações de rede necessárias para o ambiente.
Consulta a documentação do repositório para instruções de configuração e ferramentas necessárias.

Clone o repositório e execute o script de inicialização:

```powershell
git clone https://github.com/FIAP-POS-TECH-13SOAT-MECHANICS/mechanics-infra.git
cd mechanics-infra
./scripts/initialize-layer.ps1 shared
```

Após a conclusão, execute os comandos abaixo na raiz do repositório:

```powershell
$environment = "dev"
$bucketName = "fiap-mechanics-tf-$(aws sts get-access-key-info --access-key-id $(aws configure get aws_access_key_id) --query Account --output text)"

terraform -chdir="./infra" init -backend-config="bucket=$bucketName" -backend-config="key=database-$environment.tfstate" -reconfigure
terraform -chdir="./infra" apply -var="environment=$environment"
```

Esse processo também está disponível no [script](./scripts/README.md):

```powershell
.\scripts\initialize-database.ps1 dev
```

## Pipeline de CI/CD

Ao fazer alterações nas branches `main`, `release` ou `develop`, é disparada a pipeline [CI/CD](./.github/workflows/ci-cd.yml).

A pipeline executa os seguintes passos:

1. Identifica o nome do ambiente a partir da branch
   - `main` => `prod`
   - `release` => `stg`
   - `develop` => `dev`
2. Provisiona a camada `shared` do ambiente correspondente
3. Provisiona o banco de dados
