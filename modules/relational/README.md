# Banco de dados relacional (database)

Sobe uma instância no RDS.

## Banco de dados ([`db.tf`](./db.tf))

Define uma instância RDS do Microsoft SQL Server.
A instância utiliza `db.t3.small` (2 vCPU e 2GB de memória), que é a configuração mínima recomendada para versão Express.

Também define sub-redes e grupos de segurança.
O acesso pode ser público ou privado, dependendo do ambiente utilizado.

O nome de usuário e senha são gerados pelo Terraform.
Isso facilita a criação dos secrets e outputs (só são exibidos se for público).

## Credenciais de acesso ([`credentials.tf`](./credentials.tf))

Gera um usuário e senha aleatórios usando o módulo Random do Terraform.

## Secrets Manager ([`secrets.tf`](./secrets.tf))

Armazena as credenciais geradas seguindo o padrão `fiap-mechanics-ENV-database`.
A connectionString é salva no formato do SQL Server com a chave `value`.

## Arquivos de configuração do ambiente

Os demais arquivos definem variáveis, outputs e geração de senhas.

- [`data.tf`](./data.tf)
  - Busca states de outras camadas.
- [`outputs.tf`](./outputs.tf)
  - Sempre exibe o ambiente.
  - Exibe o nome da secret onde as credenciais foram salvas.
  - Se o ambiente for público, expõe a connectionString.
- [`vars.tf`](./vars.tf)
  - Define valores utilizados em todo o projeto.
  - `environment`: define o ambiente, que pode ser `dev`, `stg` ou `prod`.
  - `service_name`: nome do serviço que utilizará o banco de dados.
  - `database_name`: nome do banco de dados (se não informado, utiliza `mechanics-SERVICE`).
  - `db_engine_version`: versão do banco de dados. Padrão é `15.00`.
  - `db_instance_class`: classe da instância RDS. Padrão é `db.t3.small`.
- [`providers.tf`](./providers.tf)
  - O projeto utiliza o pacote de AWS e o gerador de senhas oficiais da HashiCorp.
