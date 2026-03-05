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

### Certificado TLS

O atributo `TrustServerCertificate=True;` foi removido para exigir validação da conexão ao RDS.
Isso implica que a connectionString não funcionará se o certificado não estiver registrado no ambiente d execução.

O certificado pode ser encontrado [na documentação da AWS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html#UsingWithRDS.SSL.CertificatesDownload) e deve ser adicionado ao container Docker ou instalado no ambiente local.

#### Instalação no container Docker

Para acessar a instância RDS de uma aplicação .Net, é possível baixar o certificado diretamente no container.

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# faz o build da aplicação
# ...
# baixa o certificado para uma pasta temporária
RUN curl -o /tmp/aws-rds-global.crt https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

FROM mcr.microsoft.com/dotnet/aspnet:8.0-noble-chiseled-extra AS final
# copia o certificado e registra a variável de ambiente
COPY --from=build /tmp/aws-rds-global.crt /usr/local/share/ca-certificates/aws-rds-global.crt
ENV SSL_CERT_FILE=/usr/local/share/ca-certificates/aws-rds-global.crt
# executa a aplicação normalmente
# ...
```

#### Instalação no Windows

Para acessar a partir de uma máquina Windows, é possível baixar e importar via PowerShell.

```powershell
Invoke-WebRequest "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -OutFile "$env:TEMP\aws-rds-global.crt"
Import-Certificate -FilePath "$env:TEMP\aws-rds-global.crt" -CertStoreLocation "Cert:\CurrentUser\Root"
```

Para ambientes de desenvolvimento, é recomendável manter o `TrustServerCertificate=True;` na connectionString para também poder acessar instâncias locais (rodando em Docker Compose, por exemplo).

## Arquivos de configuração do ambiente

Os demais arquivos definem variáveis, outputs e geração de senhas.

- [`backend`](./backend)
  - Referencia o Bucket S3 para persistência dos states.
- [`data.tf`](./data.tf)
  - Busca states de outras camadas.
- [`outputs.tf`](./outputs.tf)
  - Sempre exibe o ambiente (em todas as camadas).
  - Exibe o nome da secret onde as credenciais foram salvas.
  - Se o ambiente for público, expõe a connectionString.
- [`vars.tf`](./vars.tf)
  - Define valores utilizados em todo o projeto.
  - `environment`: define o ambiente, que pode ser `dev`, `stg` ou `prod`.
  - `db_engine_version`: versão do banco de dados. Padrão é `15.00`.
  - `db_instance_class`: classe da instância RDS. Padrão é `db.t3.small`.
- [`providers.tf`](./providers.tf)
  - O projeto utiliza o pacote de AWS e o gerador de senhas oficiais da HashiCorp.
