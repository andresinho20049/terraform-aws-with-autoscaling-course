# Projeto de Estudo Terraform AWS Cloud Solutions Architect
Este projeto tem como objetivo principal o estudo e a prática da criação de infraestrutura como código (IaC) utilizando Terraform para provisionar recursos na Amazon Web Services (AWS). O foco é aprofundar o conhecimento em serviços AWS essenciais para a certificação AWS Solutions Architect, garantindo que a infraestrutura seja escalável, replicável e bem organizada.

## Estrutura do Projeto

O projeto é estruturado em módulos para promover a modularidade, reusabilidade e escalabilidade. Variáveis de ambiente e segredos serão utilizados para gerenciar configurações sensíveis e específicas de cada ambiente.

Para suportar **múltiplos ambientes** (como `dev`, `prod`, `staging`), o projeto utiliza uma estrutura de pastas para arquivos `.tfvars`:

```
.
├── .env                    
├── .env.example            
├── README.md               
├── README.pt-br.md         
├── .gitignore              
│
├── src/                    
│
├── packer/                 
│   ├── README.md           
│   ├── envs/               
│   │   ├── dev/
│   │   │   └── dev.pkrvars.hcl
│   │   ├── prod/
│   │   │   └── prod.pkrvars.hcl
│   │   └── staging/
│   │       └── staging.pkrvars.hcl
│   │
│   ├── ami-templates/      
│   │   ├── nginx-webserver/ 
│   │   │   ├── build.pkr.hcl     
│   │   │   ├── source.pkr.hcl    
│   │   │   └── variables.pkr.hcl 
│   │   │   └── scripts/          
│   │   │       └── install_nginx.sh 
│   │   │
│   │   └── my-app-worker/  
│   │       ├── ...
│   │
│   └── output_ami_ids.tfvars 
│
├── infla/                  
│   ├── main.tf             
│   ├── variable.tf         
│   ├── provider.tf         
│   ├── output.tf           
│   ├── backend.tf          
│   │
│   ├── modules/            
│   │   ├── vpc/
│   │   ├── alb/
│   │   └── ...             
│   │
│   └── envs/               
│       ├── dev/
│       │   |── terraform.tfvars 
│       │   └── ...
│       ├── prod/
│       │   └── terraform.tfvars 
│       └── staging/
│           └── terraform.tfvars
│
└── scripts/                
```

Cada pasta de ambiente (`dev`, `prod`, `staging`, etc.) contém um arquivo `terraform.tfvars` com configurações específicas para aquele ambiente, como blocos CIDR de VPC, IDs de AMI e tipos de instância.

## Recursos Provisionados

A infraestrutura provisionada por este projeto abtangerá os seguintes componentes:

### Módulo `vpc-module`

Responsável por criar a rede virtual na AWS, incluindo:

* **VPC (Virtual Private Cloud):** Rede isolada para a sua infraestrutura.
    * **Primeira Rede:** `10.0.0.0/16`
        * **Subnet Pública AZa:** `10.0.1.0/24`
        * **Subnet Privada AZa:** `10.0.2.0/24`
        * **Subnet Pública AZb:** `10.0.3.0/24`
        * **Subnet Privada AZb:** `10.0.4.0/24`
    * **Segunda Rede (para peering multi-região):** `10.1.0.0/16`
        * **Subnet Pública AZa:** `10.1.1.0/24`
        * **Subnet Privada AZa:** `10.1.2.0/24`
        * **Subnet Pública AZb:** `10.1.3.0/24`
        * **Subnet Privada AZb:** `10.1.4.0/24`
* **Subnets:** Divididas em subnets públicas e privadas em diferentes Availability Zones (AZa, AZb).
* **Tabelas de Rota (Route Tables):**
    * Uma tabela de rota pública para o tráfego de entrada e saída da internet.
    * Uma tabela de rota privada para o tráfego interno e acesso a serviços AWS.
* **Internet Gateway (IGW):** Permite a comunicação entre a VPC e a internet.
    * O IGW estará vinculado à tabela de rota pública.
* **Security Groups:**
    * **Público:** Permitindo acesso SSH (porta 22) e HTTP (porta 80) de qualquer IP (`0.0.0.0/0`).
    * **Privado:** Permitindo acesso SSH (porta 22) apenas das subnets internas da VPC.

### Módulo `loadbalancer-module`

Responsável por configurar o balanceamento de carga e a escalabilidade automática:

* **Application Load Balancer (ALB):** Distribui o tráfego de entrada entre múltiplas instâncias.
* **Target Group:** Grupo de instâncias EC2 que o ALB direcionará o tráfego.
* **Launch Template:** Define a configuração de instâncias EC2 a serem lançadas.
* **Auto Scaling Group (ASG):** Garante que um número específico de instâncias EC2 esteja sempre em execução, escalando automaticamente para cima ou para baixo conforme a demanda.

### `main.tf`

O arquivo `main.tf` na raiz do projeto orquestrará a chamada dos módulos:

* **Provider AWS:** Configuração do provedor AWS.
* Chamadas dos módulos `vpc-module` e `loadbalancer-module`.

## Convenção de Nomenclatura

Os recursos AWS seguirão um padrão de nomenclatura consistente:

`$username.$region.$resource-name.$name`

* `$username`: Seu nome de usuário ou identificador.
* `$region`: A região AWS onde o recurso está sendo provisionado (ex: `us-east-1`).
* `$resource-name`: O tipo de recurso (ex: `vpc`, `subnet`, `alb`).
* `$name`: Um nome descritivo para o recurso.

**Exemplo:** `andresinho20049.us-east-1.vpc.my-vpc`

## Tags nos Recursos

Todos os recursos provisionados incluirão as seguintes tags para melhor organização e rastreabilidade:

* `environment`: `$env` (Ex: `dev`, `prod`, `staging`)
* `project`: `$project` (Nome do projeto, ex: `estudo-terraform`)
* `region`: `$region` (Região AWS)

## Backend S3 e Workspaces

Para gerenciar o estado do Terraform de forma segura e colaborativa, será utilizado um backend S3 com DynamoDB para bloqueio de estado. Além disso, serão usados workspaces para isolar ambientes (desenvolvimento, produção, etc.).

### Gerenciamento de Workspaces

Para alternar ou criar workspaces, utilize:

```bash
terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
```

Isso garante que o estado do Terraform seja armazenado separadamente para cada ambiente (e.g., `dev`, `prod`).

## Requisitos

* Terraform CLI instalado.
* Packer CLI instalado
* Credenciais AWS configuradas (via variáveis de ambiente, arquivo de credenciais, ou perfil AWS).
* Bucket S3 configurado para o backend de estado.
* Tabela DynamoDB configurada para o bloqueio de estado.

## Como Usar
### 1. Preparando o Ambiente
1. **Clone o Repositório:**
    ```bash
    git clone https://github.com/andresinho20049/terraform-aws-with-autoscaling-course
    cd terraform-aws-with-autoscaling-course
    ```

2. **Renomeie o arquivo `.env.example` para `.env`:**
    Este arquivo conterá as variáveis ​​de ambiente necessárias para o backend do Terraform e outras configurações globais.
    > Lembre-se de substituir os valores de exemplo pelos seus próprios.

3. **Carregue as Variáveis ​​de Ambiente:**
    Antes de executar qualquer comando do Terraform, carregue as variáveis ​​do arquivo `.env` na sua sessão de shell.

    ```bash
    source .env
    ```

### 2. Executando o Packer

1. **Construindo a AMI com o Packer:**
    Navegue até o diretório de modelos do Packer e construa a AMI para o seu ambiente. Isso criará a imagem de máquina necessária para suas instâncias EC2.

    ```bash
    cd packer/ami-templates/nginx-webserver/
    packer init .
    packer build \
        -var-file="../../envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl" .
    
    # Navigate back to the 'infla' directory for Terraform commands
    cd ../../../infla 
    ```

### 3. Executando o Terraform

1. **Inicializar o Terraform:**
    Este comando configura o backend S3 para o gerenciamento de estado do Terraform.

    > verifique se o seu diretório atual é `infra`

    ```bash
    terraform init \
        -backend-config="bucket=$TF_BACKEND_BUCKET" \
        -backend-config="key=$TF_BACKEND_KEY" \
        -backend-config="region=$TF_BACKEND_REGION" \
        -backend-config="dynamodb_table=$TF_AWS_LOCK_DYNAMODB_TABLE"
    ```

2. **Selecionar ou Criar Espaço de Trabalho:**
    Defina o ambiente para o qual deseja provisionar a infraestrutura. Certifique-se de que o valor de `$ENVIRONMENT` corresponda a uma das pastas em `envs/`.

    ```bash
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    ```

3. **Planejar Infraestrutura:**
    Este comando gera um plano de execução, mostrando quais recursos serão criados, modificados ou destruídos. Ele utiliza o arquivo `.tfvars` específico para o ambiente selecionado.

    ```bash
    mkdir -p plan
    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$TF_BACKEND_KEY" \
        -var="key_name=$SSH_KEY_NAME" \
        -out="./plan/$ENVIRONMENT.plan"
    ```

4. **Aplicar Infraestrutura:**
    Execute o plano gerado para provisionar os recursos na AWS.

    ```bash
    terraform apply "./plan/$ENVIRONMENT.plan"
    ```

5. **Destruir Infraestrutura (quando não for mais necessária):**
    Para remover todos os recursos provisionados, use o comando `destroy`.

    ```bash
    terraform destruir \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="nome_de_usuário_da_conta=$USERNAME" \
        -var="projeto=$TF_BACKEND_KEY" \
        -var="nome_da_chave=$SSH_KEY_NAME"
    ```

## Multi-Regiões e Peering
O projeto está preparado para provisionar recursos em multi-regiões e realizar peering de VPCs. As redes `10.0.0.0/16` e `10.1.0.0/16` são exemplos de blocos CIDR distintos que podem ser usados para VPCs em diferentes regiões para facilitar a configuração de peering. A implementação do peering de fato será adicionada em uma fase posterior, mas a base para isso está presente na definição dos blocos de rede e nas variáveis de ambiente.

## ©️ Copyright
**Developed by** [Andresinho20049](https://andresinho20049.com.br/) \
**Project**: *AWS Cloud Solutions Architect Study Project* \
**Description**: \
This project provides a foundational AWS infrastructure for learning and preparing for the AWS Cloud Solutions Architect certification. It focuses on modularity, scalability, and best practices for Infrastructure as Code (IaC) with Terraform, including multi-environment support and VPC peering capabilities.