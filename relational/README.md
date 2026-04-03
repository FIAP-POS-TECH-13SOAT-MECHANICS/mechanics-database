# Banco de dados relacional (database)

Sobe uma intância RDS.

## Instruções

Após criar a pasta com o nome do serviço, conforme as instruções [na raiz do repositório](../README.md), utilize o arquivo `main.tf` para definir o nome do serviço:

```terraform
module "database" {
  source = "./base"

  environment  = var.environment
  service_name = "new-product"
}
```

## Certificado TLS

O atributo `TrustServerCertificate=True;` foi removido para exigir validação da conexão ao RDS.
Isso implica que a connectionString não funcionará se o certificado não estiver registrado no ambiente d execução.

O certificado pode ser encontrado [na documentação da AWS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html#UsingWithRDS.SSL.CertificatesDownload) e deve ser adicionado ao container Docker ou instalado no ambiente local.

### Instalação no container Docker

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

### Instalação no Windows

Para acessar a partir de uma máquina Windows, é possível baixar e importar via PowerShell.

```powershell
Invoke-WebRequest "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" -OutFile "$env:TEMP\aws-rds-global.crt"
Import-Certificate -FilePath "$env:TEMP\aws-rds-global.crt" -CertStoreLocation "Cert:\CurrentUser\Root"
```

Para ambientes de desenvolvimento, é recomendável manter o `TrustServerCertificate=True;` na connectionString para também poder acessar instâncias locais (rodando em Docker Compose, por exemplo).
