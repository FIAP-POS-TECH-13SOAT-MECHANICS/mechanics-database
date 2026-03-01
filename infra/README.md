# Infraestrutura

- [Recursos criados](#recursos-criados)
- [Criação via Terraform e Helm](#criação-via-terraform-e-helm)
- [Pipeline de CI/CD](#pipeline-de-cicd)
- [Acessando a aplicação](#acessando-a-aplicação)
- [Comandos úteis](#comandos-úteis)

A infraestrutura do projeto é definida em scripts [Terraform](https://developer.hashicorp.com/terraform).
Os arquivos foram separados por tipo de recurso (banco de dados, orquestração, secrets, rede, etc).

A implementação pode ser facilmente replicada para mais de um ambiente (desenvolvimento, homologação e produção), com recursos e credenciais totalmente isolados.

## Recursos criados

![Recursos criados](./../docs/images/infrastructure-dark.yaml.png)

Segue abaixo uma definição de cada recurso, agrupados pelo arquivo do Terraform.

### Back-end ([`backend.tf`](./backend.tf))

Armazena os states do Terraform utilizando S3.
Cada ambiente - dev, stg ou prod - possui seu próprio arquivo de state no bucket S3, que é versionado e criptografado.

O nome do bucket deve ser único na região `us-east-1` e deve ser passado por parâmetro.
Utilize o prefixo `fiap-mechanics-tf-` e o ID da conta AWS.
O back-end possui controle de concorrência (state locking), permitindo a execução segura dos scripts em pipelines de CI/CD.

### Registro de contêineres ([`cr.tf`](./cr.tf))

Define o repositório onde as imagens de contêineres são armazenadas.
O nome segue o padrão `fiap-mechanics-ENV-cr`.

Está configurado para não permitir tags repetidas (exceto `latest`), uma vez que é necessária uma tag diferente para fazer a implantação no cluster.

### Banco de dados ([`db.tf`](./db.tf))

Define uma instância RDS do Microsoft SQL Server.
A instância utiliza `db.t3.small` (2 vCPU e 2GB de memória), que é a configuração mínima recomendada para versão Express.

Também define sub-redes e grupos de segurança.
O acesso pode ser público ou privado, dependendo do ambiente utilizado.

O nome de usuário e senha são gerados pelo Terraform.
Isso facilita a criação dos secrets e outputs (só são exibidos se for público).

### Cluster Kubernetes ([`k8s.tf`](./k8s.tf))

Define um cluster EKS usando um node group de instâncias `medium`, iniciado com dois nodes.

O cluster utiliza uma sub-rede privada e busca as permissões da AWS Academy necessárias usando blocos `data`.

### Configuração de rede ([`network.tf`](./network.tf))

Define a estrutura de rede para o ambiente.
Cada ambiente roda na sua própria VPC, que é nomeada seguindo o padrão `fiap-mechanics-ENV-vpc`.

Alguns recursos requerem pelo menos duas zonas de disponibilidade, sendo portanto criadas duas sub-redes públicas e duas privadas.
Uma sub-rede pública é aquela que possui um internet gateway associada a ela, com as rotas devidamente configuradas.
Isso torna a sub-rede acessível a partir da internet, possuindo um IP público e podendo ser acessada de fora da VPC.

Para as sub-redes privadas, é necessário um serviço NAT (Network Address Translation) para que os recursos da rede interna possam acessar à internet - por exemplo, para baixar imagens do repositório ECR - sem ficarem expostos a conexões de fora da VPC. Utilizamos o serviço de NAT Gateway da AWS.

### Dependências externas ([`addons.tf](./addons.tf))

Instala (via Helm charts) as dependências do projeto no cluster EKS.

- Metrics Server: obtém métricas do sistema para permitir o funcionamento do HPA
- Nginx Ingress Controller: gera um Network Load Balancer para permitir acesso externo ao projeto
- External Secrets Operator (ESO): importa credenciais de acesso do Secrets Manager da AWS
- MailPit: servidor SMTP e cliente de e-mail para simular o envio de mensagens

#### Sobre o serviço de e-mail

Como não há um serviço de disparo de e-mail na AWS Academy (SES não está disponível), o projeto segue utilizando Mailpit para simular o envio de mensagens.
É executado utilizando um script Helm, com usuário e senha gerados pelo Terraform e armazenados no Secrets Manager da AWS.

O projeto já está configurado para acessar o servidor SMTP do Mailpit importando as senhas do Secrets Manager.
É possível acessar via port-forwarding mapeando os serviços do Mailpit.

| Recurso       | Serviço      | Porta | Comando                                             |
| ------------- | ------------ | ----- | --------------------------------------------------- |
| Cliente Web   | mailpit-http | 80    | `kubectl port-forward service/mailpit-http 8025:80` |
| Servidor SMTP | mailpit-smtp | 25    | `kubectl port-forward service/mailpit-smtp 1025:25` |

### Arquivos de configuração do ambiente

Os demais arquivos definem variáveis, outputs e geração de senhas.

- [`outputs.tf`](./outputs.tf)
  - Sempre exibe o ambiente e o repositório ECR.
  - Se o projeto for público, exibe também a connectionString do banco de dados e credenciais para envio de e-mails.
- [`passwords.tf`](./passwords.tf)
  - Nome de usuário e senha para banco de dados e serviço de envio de e-mails.
  - Utiliza `random_string` ao invés de `random_password` para facilitar o uso nas outputs.
- [`vars.tf`](./vars.tf)
  - Define valores utilizados em todo o projeto, como nome do projeto e região AWS.
  - `environment`: define o ambiente, que pode ser `dev`, `stg` ou `prod`.
  - `public_access`: permite sobreescrever o comportamento padrão de permitir acesso público somente se for `dev` ou `stg`.
- [`providers.tf`](./providers.tf)
  - O projeto utiliza o pacote de AWS, Helm e o gerador de senhas oficiais da HashiCorp.

## Criação via Terraform e Helm

Os scripts foram projetados para que o projeto rode em um ambiente da AWS Academy.
Antes de prosseguir, certifique-se de ter instalado as ferramentas necessárias e ter atualizado as credenciais da AWS.

O Helm do projeto executa as [migrações](../docs/migrations.md) e sobe dois pods do projeto, com escalonamento para até 10 réplicas.

### Processo de deploy

O processo pode ser definido em duas etapas: Criação do ambiente e deploy da aplicação.
Ambos podem ser executados através dos scripts Powershell da pasta [scripts](./../scripts/README.md).

Os comandos para cada passo (incluindo a instalação das ferramentas) estão nas seções seguintes.

#### Criação do ambiente

1. Crie um bucket no S3
2. Aplique os scripts do Terraform
3. Configure o kubectl com `aws eks update-kubeconfig`
4. Crie uma secret chamada `aws-credentials` no namespace `external-secrets`

#### Deploy da aplicação

1. Compile a imagem Docker
2. Faça login no repositório ECR gerado pelo Terraform
3. Faça upload para o repositório
4. Execute o helm para aplicar a nova imagem

### Instalação das ferramentas

Instale
o [Terraform](https://developer.hashicorp.com/terraform/install), [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
e [Helm](https://helm.sh/docs/intro/install/).
No Windows, é possível baixar via [WinGet](https://learn.microsoft.com/pt-br/windows/package-manager/winget/).

```cmd
winget install --id Hashicorp.Terraform
winget install --id Amazon.AWSCLI
winget install --id Helm.Helm
```

Reinicie o terminal após a instalação para atualizar a variável PATH.

### Configuração do AWS CLI

Com as ferramentas instaladas, acesse a [página de cursos na AWS Academy](https://awsacademy.instructure.com/courses),
inicie o laboratório e clique em "AWS Details" para copiar as credenciais de acesso.

Rode o comando abaixo para fazer login:

```cmd
aws configure
```

### Execução dos scripts

Primeiro crie um bucket no S3 para servir de backend pro Terraform.
Para garantir que o nome seja único, utilize o nome `fiap-mechanics-tf` e o ID da conta da AWS como sufixo, como no exemplo abaixo.

```powershell
$awsAccountId = aws sts get-access-key-info --access-key-id $(aws configure get aws_access_key_id) --query Account --output text
aws s3 mb s3://fiap-mechanics-tf-$awsAccountId --region us-east-1
```

Por padrão, será gerado um ambiente de desenvolvimento (dev).
O sistema permite o acesso público para o banco de dados e servidor SMTP em ambientes que não sejam de produção (prod).

No Powershell, adicione os seguintes parâmetros aos comandos do Terraform para alterar o ambiente ou a permissão de acesso:

```powershell
-var="environment=prod"    # dev, stg ou prod
-var="public_access=true"  # padrão é "true" quando environment != "prod"
```

Após a criação do Bucket, acesse a pasta `infra`.
Passe a chave do backend de acordo com o ambiente desejado (dev, stg ou prod) e aplique os scripts.

```powershell
terraform init -backend-config="bucket=fiap-mechanics-tf-$awsAccountId" -backend-config="key=dev.tfstate" -reconfigure
terraform apply
```

O processo leva de 10 a 15 minutos.
Serão exibidas algumas informações úteis sobre o ambiente.
Caso precise desses dados novamente, utilize o comando `terraform output`.

Para rodar o projeto com os serviços criados pelo Terraform, crie
um [arquivo de configuração local](./../docs/configuration.md) e use as informações exibidas no terminal. Observe que
várias dessas informações só são exibidas se o projeto estiver definido como público (`public_access = 'true'`).

Se quiser gerenciar outros ambientes, altere o state e reconfigure o Terraform.

```powershell
terraform init -backend-config="bucket=fiap-mechanics-tf-fulano" -backend-config="key=stg.tfstate" -reconfigure
terraform apply -var="environment=stg"
```

### Configuração do ambiente

Utilize o AWS CLI para baixar as configurações do cluster EKS no kubectl.
Ajuste o nome do cluster de acordo com o ambiente.

```powershell
aws eks update-kubeconfig --name fiap-mechanics-dev-cluster --region us-east-1
```

O External Secrets Operator (ESO) requer acesso ao Secets Manager da AWS.
O ideal seria utilizar IRSA (IAM Roles for Service Accounts) para evitar expor as credenciais da conta AWS, mas por limitações do ambiente AWS Academy não é possível usar essa abordagem.
Portanto, adicione uma secret com as credenciais para que o ESO acesse o Secrets Manager.

```powershell
kubectl create secret generic aws-credentials `
  --namespace external-secrets `
  --from-literal=access-key-id="$(aws configure get aws_access_key_id)" `
  --from-literal=secret-access-key="$(aws configure get aws_secret_access_key)" `
  --from-literal=session-token="$(aws configure get aws_session_token)"
```

### Upload de imagens para o ECR

Após a execução do script Terraform, copie o valor do campo `cr_repository_url` ou use o AWS CLI (exemplo abaixo).
Retorne à raiz do projeto para compilar a imagem Docker e fazer upload para o ECR:

```powershell
$repositoryUrl = aws ecr describe-repositories --repository-names fiap-mechanics-dev-cr --query "repositories[0].repositoryUri" --output text
$password = aws ecr get-login-password --region us-east-1
docker login --username AWS --password $password $repositoryUrl
docker build -t fiap-mechanics .
docker tag fiap-mechanics:latest "$($repositoryUrl):latest"
docker push "$($repositoryUrl):latest"
```

>Não foi utilizado login via `--password-stdin` para garantir compatibilidade com Windows PowerShell (legado)

Na raiz do repositório, execute o comando abaixo para instalar o Chart do projeto:

```powershell
helm upgrade --install --set image.repository=$repositoryUrl --set app.env=dev fiap-mechanics ./k8s
```

### Atualização (nova release)

Para atualizar o ambiente, é necessário recompilar a imagem Docker, subir no ECR utilizando outra tag e lançar uma nova release via Helm.

```powershell
docker build -t fiap-mechanics .
docker tag fiap-mechanics:latest "$($repositoryUrl):new-tag"
docker push "$($repositoryUrl):new-tag"

helm upgrade --set image.repository=$repositoryUrl --set image.tag="new-tag" --set app.env=dev fiap-mechanics ./k8s
```

## Pipeline de CI/CD

Ao fazer alterações nas branches `main`, `release` ou `develop`, é disparada a pipeline [CI/CD](./../.github/workflows/ci-cd.yml).
A rotina de testes também é executada ao abrir um PR para alguma dessas branches.

![Pipeline de deploy](./../docs/images/deploy.svg)

A pipeline executa os seguintes passos:
1. Executa os testes
2. Identifica o nome do ambiente a partir da branch
   - `main` => `prod`
   - `release` => `stg`
   - `develop` => `dev`
3. Gera e exporta o artefato (executável) do projeto
4. Atualiza o ambiente via Terraform
5. Compila a imagem Docker, sobe no ECR e publica no EKS

## Acessando a aplicação

Há duas opções: mapear a porta via `kubectl` ou pela rota pública gerada pelo Ingress Controller.

Para o cliente de e-mail, mapeie a porta para o serviço do Mailpit e acesse via [localhost](http://localhost:8025).

```powershell
kubectl port-forward service/mailpit-http 8025:80
```

### Mapeamento de porta

Utilize o seguinte comando para mapear a porta.

```powershell
kubectl port-forward service/fiap-mechanics 5000:5000
```

Acesse o Swagger pela URL [localhost:5000/swagger](http://localhost:5000/swagger) ou
teste a conexão pelo [localhost:5000/health](http://localhost:5000/health).
Observe que o Swagger não está disponível se o ambiente for `prod`.

### Ingress Controller

Com um Ingress Controller, são gerados URLs públicas para o serviço, de forma que seja possível acessar diretamente pelo navegador.
O projeto utiliza [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx), que cria um serviço do tipo `LoadBalancer` responsável por expor o cluster externamente.
A instalação é feita pelo Terraform.

Utilize o comando abaixo para obter a URL do Swagger:

```powershell
"http://$(kubectl get ingress fiap-mechanics -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/swagger"
```

Aguarde até o load balancer ser criado e o DNS ser propagado.
Esse processo pode levar vários minutos.

>Observe que a tag da imagem precisa ser diferente da anterior.

## Comandos úteis

Buscar a URL do repositório:

```powershell
$repositoryUrl = aws ecr describe-repositories --repository-names fiap-mechanics-dev-cr --query "repositories[0].repositoryUri" --output text
```

Remover charts antigos:

```powershell
helm uninstall fiap-mechanics
```

Remover secrets da AWS:

```powershell
aws secretsmanager delete-secret --secret-id fiap-mechanics-dev-database --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id fiap-mechanics-dev-email --force-delete-without-recovery

# remover todos
aws secretsmanager list-secrets --query "SecretList[].Name" | ConvertFrom-Json | ForEach-Object { aws secretsmanager delete-secret --secret-id $_ --force-delete-without-recovery }
```

Forçar sincronização das secrets:

```powershell
kubectl annotate externalsecret fiap-mechanics-database force-sync="$(New-Guid)" --overwrite
kubectl annotate externalsecret fiap-mechanics-email force-sync="$(New-Guid)" --overwrite
```

Adicionar manualmente as secrets (útil para execução local):

```powershell
kubectl create secret generic fiap-mechanics-database `
  --from-literal=connectionString="Server=fiap-mechanics-dev-db.000.us-east-1.rds.amazonaws.com,1433;Database=fiap-mechanics;User Id=xxx;Password=xxx;TrustServerCertificate=True;"
kubectl create secret generic fiap-mechanics-email `
  --from-literal=host="fiap-mechanics-dev-email-smtp-lb-000.elb.us-east-1.amazonaws.com" `
  --from-literal=port="1025" `
  --from-literal=userName="xxx@mechanics.com" `
  --from-literal=password="xxx"
```

Liberar lock travado no Terraform:

```powershell
# copie o lock-id da mensagem de erro
terraform force-unlock LOCK_ID
```

Excluir imagens do ECR (para permitir `terraform destroy`):

```powershell
aws ecr batch-delete-image --repository-name fiap-mechanics-dev-cr --image-ids (aws ecr list-images --repository-name fiap-mechanics-dev-cr --query "imageIds[].imageDigest" --no-paginate | ConvertFrom-Json | ForEach-Object { "imageDigest=$_" })
```
