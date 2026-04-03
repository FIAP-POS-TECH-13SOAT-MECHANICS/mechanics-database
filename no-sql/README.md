# Banco de dados não-relacional (no-sql)

Sobe uma tabela no DynamoDB.

## Instruções

Após criar a pasta com o nome do serviço, conforme as instruções [na raiz do repositório](../README.md), utilize o arquivo `main.tf` para definir os índices necessários:

```terraform
module "database" {
  source = "./base"

  environment  = var.environment
  service_name = "new-product"

  global_secondary_indexes = [
    {
      name = "customerId-index"
      key_schema = [
        { attribute_name = "customerId", key_type = "HASH" },
        { attribute_name = "expirationDate", key_type = "RANGE" }
      ]
    }
  ]
}
```
