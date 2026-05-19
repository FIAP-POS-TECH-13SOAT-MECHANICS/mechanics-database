# Scripts para deploy

1. Certifique-se de ter instalado as ferramentas necessárias:
   - AWS CLI
   - Terraform
2. Configure suas credenciais na AWS:
   - Usando AWS CLI: `aws configure`; ou,
   - Colando no arquivo de configuração (se já existir): `notepad $ENV:USERPROFILE\.aws\credentials`;
3. Utilize o script `initialize-database.ps1` para subir o ambiente na AWS.

O exemplo abaixo mostra como subir o ambiente para o serviço WorkOrders no ambiente STG:

```powershell
.\scripts\initialize-database.ps1 relational work-orders stg
```

O comando abaixo destrói todas as bases de dados no ambiente DEV:

```powershell
.\scripts\invoke-terraform.ps1 dev -destroy
```

Os scripts são idempotentes, isto é, podem ser executados múltiplas vezes.

## SonarQube (SQL Server)

Para provisionar a instância RDS dedicada do SonarQube:

```powershell
.\scripts\initialize-database.ps1 relational sonarqube dev
```

O workflow de CI/CD deste repositório executa automaticamente o bootstrap do database do SonarQube
logo após o `terraform apply` do serviço `relational/sonarqube`.

Esse bootstrap cria/configura o database do SonarQube na instância SQL Server
(collation e `READ_COMMITTED_SNAPSHOT`) usando as credenciais da secret gerada pelo Terraform.

Para execução local/manual (reprocessamento):

```powershell
.\scripts\bootstrap-sonarqube-sqlserver.ps1 `
  -environment dev `
  -serviceName sonarqube `
  -databaseName sonarqube
```

Opcionalmente, é possível sobrescrever `-serverInstance`, `-adminUser` e `-adminPassword` manualmente.

Observação:

- O módulo `relational/sonarqube` expõe `db_secret_name` em `outputs.tf`.
- Esse output é consumido pela camada `sonarqube` do repositório `mechanics-infra` via `terraform_remote_state`.

## Permissão de execução de scripts

No Windows, a execução de scripts do Powershell vem desabilitada por padrão.

Para habilitar, abra um terminal como administrador e utilize o comando [Set-ExecutionPolicy](https://learn.microsoft.com/pt-br/powershell/module/microsoft.powershell.security/set-executionpolicy):

```powershell
Set-ExecutionPolicy Unrestricted
```
