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

O comando abaixo destroy todas as bases de dados no ambiente DEV:

```powershell
.\scripts\invoke-terraform.ps1 dev -destroy
```

Os scripts são idempotentes, isto é, podem ser executados múltiplas vezes.

## Permissão de execução de scripts

No Windows, a execução de scripts do Powershell vem desabilitada por padrão.

Para habilitar, abra um terminal como administrador e utilize o comando [Set-ExecutionPolicy](https://learn.microsoft.com/pt-br/powershell/module/microsoft.powershell.security/set-executionpolicy):

```powershell
Set-ExecutionPolicy Unrestricted
```
