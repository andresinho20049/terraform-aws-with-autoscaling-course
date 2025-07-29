# Projeto: Infraestrutura AWS com Terraform – Estudo e Automação

Este repositório é um estudo prático e automatizado de provisionamento de infraestrutura AWS usando Terraform, Packer e Shell Script. O objetivo é criar um ambiente escalável, seguro e de fácil manutenção, focado em boas práticas para projetos reais e preparação para certificações AWS.

## Visão Geral do Caso de Uso

O projeto simula um cenário de aplicação web escalável, com múltiplos ambientes (dev, prod, staging), deploy automatizado de conteúdo estático via EFS, e ciclo de vida seguro para bastion host. O fluxo principal é:

1. **Construção de AMI customizada** com Packer (NGINX, dependências, etc).
2. **Provisionamento de infraestrutura** (VPC, EFS, ALB, ASG, Bastion) via Terraform.
3. **Atualização de conteúdo** no EFS de forma centralizada e segura, refletindo em todas as instâncias do ASG.
4. **Automação total** via script `run.sh`, que orquestra todas as etapas, incluindo ciclo de vida do bastion host.

## Principais Componentes

- **VPC Modular**: Subnets públicas/privadas, roteamento, security groups segmentados.
- **EFS**: Armazenamento compartilhado para conteúdo web, montado em todas as instâncias do ASG.
- **ALB & ASG**: Balanceamento de carga e escalabilidade automática.
- **Bastion Host Temporário**: Criado sob demanda para operações administrativas (ex: atualização de arquivos no EFS), destruído automaticamente após uso.
- **Automação via `run.sh`**: Um único ponto de entrada para build, deploy, atualização de conteúdo e teardown.

## Estrutura do Projeto

O projeto é estruturado em módulos para promover a modularidade, reusabilidade e escalabilidade. Variáveis de ambiente e segredos serão utilizados para gerenciar configurações sensíveis e específicas de cada ambiente.

Para suportar **múltiplos ambientes** (como `dev`, `prod`, `staging`), o projeto utiliza uma estrutura de pastas para arquivos `.tfvars`:

```
.
├── src/                    
│   └── index.html          # Exemplo de arquivo que pode ser atualizado no EFS
│
├── packer/       
│   ├── ami-templates/      
│   │   ├── nginx-webserver/ 
│   │   │   ├── build.pkr.hcl    
│   │   │   ├── nginx-ami.pkr.hcl     
│   │   │   ├── source.pkr.hcl    
│   │   │   └── variables.pkr.hcl 
│   │   │
│   │   └── another-app-worker/  
│   │       ├── ...           
│   │
│   ├── envs/               
│   │   ├── dev/
│   │   │   └── dev.pkrvars.hcl
│   │   ├── prod/
│   │   │   └── prod.pkrvars.hcl
│   │   └── staging/
│   │       └── staging.pkrvars.hcl
│   │          
│   ├── README.md          
│   └── README.pt-br.md
│
├── infra/                  
│   ├── main.tf             
│   ├── variables.tf         
│   ├── provider.tf         
│   ├── outputs.tf           
│   ├── backend.tf          
│   │
│   ├── modules/            
│   │   ├── vpc/            # Módulo Virtual Private Cloud
│   │   ├── efs/            # Módulo Elastic File System
│   │   ├── alb/            # Módulo Application Load Balancer
│   │   └── bhc/            # Módulo Bastion Host Controller
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
├── scripts/                
│   ├── efs_actions.sh
│   ├── packer_actions.sh
│   ├── terraform_actions.sh
│   └── utils.sh
│
├── .env                    
├── .env.example          
├── .gitignore          
├── README.md               
├── README.pt-br.md        
├── run.sh               
```

Cada pasta de ambiente (`dev`, `prod`, `staging`, etc.) contém um arquivo `terraform.tfvars` com configurações específicas para aquele ambiente, como blocos CIDR de VPC, IDs de AMI e tipos de instância.

## Recursos Provisionados

A infraestrutura provisionada por este projeto abrange os seguintes componentes:

### Módulo `vpc` (chamado como `main_vpc`)

Responsável por criar a rede virtual na AWS, incluindo:

  * **VPC (Virtual Private Cloud):** Rede isolada para a sua infraestrutura.
      * **Primeira Rede:** `10.0.0.0/16`
          * **Subnet Pública AZa:** `10.0.1.0/24`
          * **Subnet Privada AZa:** `10.0.2.0/24`
          * **Subnet Pública AZb:** `10.0.3.0/24`
          * **Subnet Privada AZb:** `10.0.4.0/24`
      * **Segunda Rede (para peering multi-região):** `10.1.0.0/16` > Optional
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
      * **Público:** Permitindo acesso HTTP (porta 80) de qualquer IP (`0.0.0.0/0`).
      * **Privado:** Permitindo acesso SSH (porta 22) apenas das subnets internas da VPC.
      * **Bastion:** Security Group específico para o bastion host, permitindo SSH de IPs controlados e acesso ao EFS.
      * **EFS:** Security Group para o EFS, permitindo tráfego NFS das instâncias da aplicação e do bastion host.

### Módulo `efs`

Responsável por provisionar o Amazon Elastic File System (EFS), um sistema de arquivos distribuído e escalável.

  * **File System EFS:** Um ponto centralizado para armazenar dados que podem ser compartilhados entre múltiplas instâncias EC2. Isso é essencial para aplicações que necessitam de um armazenamento comum e persistente, como servidores web que servem conteúdo estático. As instâncias do Auto Scaling Group montarão este EFS, garantindo que todas as réplicas da sua aplicação acessem os mesmos arquivos.
  * **Mount Targets:** Pontos de acesso dentro das subnets privadas da VPC, permitindo que as instâncias EC2 montem o EFS.
  * **Security Group:** Conforme mencionado na VPC, um SG dedicado ao EFS para controlar o acesso NFS.

### Módulo `alb` (chamado como `web_alb`)

Responsável por configurar o balanceamento de carga e a escalabilidade automática para sua aplicação web.

  * **Application Load Balancer (ALB):** Distribui o tráfego de entrada HTTP/HTTPS entre as instâncias da aplicação.
  * **Target Group:** Agrupa as instâncias EC2 que recebem o tráfego do ALB.
  * **Launch Template:** Define as configurações para as instâncias EC2 que serão lançadas, incluindo o tipo de instância, AMI, chave SSH e o script de `user_data` para montar o EFS.
  * **Auto Scaling Group (ASG):** Garante que um número específico de instâncias EC2 esteja sempre em execução, escalando automaticamente para cima ou para baixo conforme a demanda, proporcionando alta disponibilidade e resiliência.

### Módulo `bhc` (Bastion Host Configuration, chamado como `bastion_host`)

Responsável pela provisão de um bastion host seguro e temporário.

  * **Instância EC2 Bastion Host:** Uma máquina virtual que pode ser criada e destruída sob demanda. Ela serve como um ponto de acesso seguro para a rede privada, permitindo que operações de gerenciamento (como a atualização de arquivos no EFS) sejam realizadas sem expor as instâncias da aplicação diretamente à internet.
  * **Configuração Efêmera:** O bastion host é configurado para ter todos os recursos necessários (AMI baseada em Amazon Linux 2, montagem automática do EFS em `/mnt/efs`, e permissões IAM apropriadas via perfil de instância).
  * **Controle de Acesso:** O Security Group do bastion é rigorosamente configurado para permitir acesso SSH apenas de IPs confiáveis e acesso NFS ao EFS. O uso de SSM (AWS Systems Manager) é priorizado para acesso e execução de comandos, eliminando a necessidade de abrir portas SSH publicamente.
  * **Otimização de Custos e Segurança:** Sendo temporário e ativado sob demanda, o bastion host minimiza os custos e reduz a superfície de ataque, pois não está ativo 24/7.

## Abordagem de Construção de AMI e Gerenciamento de Conteúdo

Este projeto adota uma abordagem robusta para a gestão de imagens de máquinas e conteúdo da aplicação:

  * **AMI Otimizada com Packer:** Utilizamos o **Packer** para construir imagens de máquina (AMIs) personalizadas. Essa AMI pré-instala serviços essenciais como o NGINX, `amazon-efs-utils` e outras dependências, além de garantir que os pacotes do sistema estejam atualizados. Ao invés de instalar tudo no `user_data` de cada instância nova, a AMI já vem pronta, o que acelera o tempo de boot das instâncias e as torna mais consistentes e seguras, especialmente para instâncias em subnets privadas que não possuem acesso direto à internet.
  * **EFS como Servidor de Arquivos Distribuído:** O **Amazon EFS** é empregado como um sistema de arquivos de rede (NFS) totalmente gerenciado. Isso significa que o conteúdo web (HTML, CSS, JS, imagens) é armazenado em uma única fonte de verdade centralizada no EFS. Quando um arquivo é atualizado no EFS (por exemplo, via bastion host), essa alteração é **imediatamente refletida** em todas as instâncias EC2 do Auto Scaling Group que estão montando o mesmo EFS. Isso elimina a necessidade de sincronizar arquivos individualmente em cada servidor, simplificando a implantação de conteúdo e garantindo a consistência.
  * **Bastion Host para Operações Seguras:** A atualização do conteúdo no EFS ou outras tarefas de gerenciamento são realizadas de forma segura através do **bastion host temporário**. Este bastion é criado com **Security Groups e perfis IAM apropriados**, garantindo que apenas o tráfego e as permissões necessárias sejam concedidos durante o tempo de vida da operação. Isso mantém suas instâncias de aplicação em subnets privadas, protegidas de acesso direto.

## Convenção de Nomenclatura

Os recursos AWS seguirão um padrão de nomenclatura consistente:

`$username.$region.$resource-name.$name.$enviroment`

  * `$username`: Seu nome de usuário ou identificador.
  * `$region`: A região AWS onde o recurso está sendo provisionado (ex: `us-east-1`).
  * `$resource-name`: O tipo de recurso (ex: `vpc`, `subnet`, `alb`).
  * `$name`: Um nome descritivo para o recurso.
  * `$enviroment`: O ambiente onde o recurso está sendo provisionado (ex: `dev`).

**Exemplo:** `andresinho20049.us-east-1.vpc.my-vpc.dev`

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

  * **Terraform CLI** instalado.
  * **Packer CLI** instalado.
  * **AWS CLI** configurado com credenciais.
  * Bucket S3 configurado para o backend de estado.
  * Tabela DynamoDB configurada para o bloqueio de estado.

## Como Usar

Este projeto oferece duas formas principais de interagir com a infraestrutura: executando os comandos **manualmente** (para maior controle e depuração) ou utilizando o **script `run.sh`** (para automação e conveniência).

### 1\. Preparando o Ambiente (Ambas as Abordagens)

Independentemente da abordagem escolhida, os passos iniciais são os mesmos.

1.  **Clone o Repositório:**

    ```bash
    git clone https://github.com/andresinho20049/terraform-aws-with-autoscaling-course
    cd terraform-aws-with-autoscaling-course
    ```

2.  **Renomeie o arquivo `.env.example` para `.env`:**
    Este arquivo conterá as **variáveis de ambiente** necessárias para o backend do Terraform e outras configurações globais.

    ```bash
    cp .env.example .env
    ```

    > Lembre-se de **substituir os valores de exemplo pelos seus próprios**.

3.  **Carregue as Variáveis de Ambiente:**
    Antes de executar qualquer comando do Packer, Terraform ou `run.sh`, carregue as variáveis do arquivo `.env` na sua sessão de shell.

    ```bash
    source .env
    ```

### Escolha Sua Abordagem:

  * [**Abordagem Manual (Passo a Passo)**](#2-abordagem-manual-passo-a-passo)
  * [**Abordagem Automatizada (Usando `run.sh`)**](#3-abordagem-automatizada-usando-runsh)

### 2\. Abordagem Manual (Passo a Passo)

Siga estes passos se preferir executar os comandos do Packer, Terraform e AWS CLI manualmente para maior controle e depuração.

<details> 
<summary>
:eyes: Veja Exemplo
</summary>

<content>

#### a. Executando o Packer

1.  **Navegue até o diretório do Packer:**
    ```bash
    cd packer/ami-templates/nginx-webserver/
    ```
2.  **Inicialize o Packer:**
    ```bash
    packer init .
    ```
3.  **Construa a AMI com o Packer:**
    ```bash
    packer build \
        -var-file="../../envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl" .
    ```

#### b. Executando o Terraform (Após o Packer)

1.  **Navegue de volta para o diretório `infra`:**

    ```bash
    cd ../../../infra 
    ```

2.  **Inicialize o Terraform:**
    Este comando configura o backend S3 para o gerenciamento de estado do Terraform.

    ```bash
    terraform init \
        -backend-config="bucket=$TF_BACKEND_BUCKET" \
        -backend-config="key=$TF_BACKEND_KEY" \
        -backend-config="region=$TF_BACKEND_REGION" \
        -backend-config="dynamodb_table=$TF_AWS_LOCK_DYNAMODB_TABLE"
    ```

3.  **Selecionar ou Criar Espaço de Trabalho:**
    Defina o ambiente para o qual deseja provisionar a infraestrutura. Certifique-se de que o valor de `$ENVIRONMENT` corresponda a uma das pastas em `envs/`.

    ```bash
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    ```

4.  **Planejar Infraestrutura:**
    Este comando gera um plano de execução, mostrando quais recursos serão criados, modificados ou destruídos. Ele utiliza o arquivo `.tfvars` específico para o ambiente selecionado.

    ```bash
    mkdir -p plan
    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=false" \
        -out="./plan/$ENVIRONMENT.plan"
    ```

    > **Observação:** O `-var="create_bastion_host=false"` garante que o bastion host **não** seja criado por padrão durante o `apply` da infraestrutura principal.

5.  **Aplicar Infraestrutura:**
    Execute o plano gerado para provisionar os recursos na AWS.

    ```bash
    terraform apply "./plan/$ENVIRONMENT.plan"
    ```

#### c. Gerenciando o Bastion Host e EFS Manualmente

1.  **Criar o Bastion Host:**
    Navegue até o diretório `infra` e aplique o Terraform para criar o bastion.

    ```bash
    cd infra # Se você não estiver já no diretório infra
    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=true" \
        -out="./plan/$ENVIRONMENT.bastion.plan"
    terraform apply "./plan/$ENVIRONMENT.bastion.plan"
    ```

    **Obtenha o ID da Instância do Bastion:**

    ```bash
    terraform output -raw bastion_instance_id
    # Exemplo de saída: i-0abcdef1234567890
    ```

    > Guarde este ID, você precisará dele.

#### d. Atualizar Conteúdo no EFS (Processo Manual Passo a Passo)
Para quem deseja entender ou executar o processo de atualização de um arquivo no EFS manualmente, sem utilizar o script `run.sh`, siga os passos detalhados abaixo. Este método utiliza um **bucket S3 temporário** como intermediário para a transferência do arquivo, garantindo segurança e eficiência através do AWS Systems Manager (SSM).

Assumiremos que o **bastion host já está em execução** e que o **EFS está montado em `/mnt/efs`** nas suas instâncias, com o conteúdo do seu site em `/mnt/efs/<PROJECT_NAME>/html/`.

1. **Subir arquivo local no bucket S3 temporário**
    Antes de atualizar o EFS, vamos subir o arquivo num bucket S3 temporário.

    ```bash
    LOCAL_FILE="./src/index.html" # Ajuste para o caminho do seu arquivo local

    # Crie um nome para o bucket S3 temporário e uma chave única para o arquivo
    S3_TEMP_BUCKET="${USERNAME}.${TF_BACKEND_REGION}.s3.bhc-temp.${ENVIRONMENT}"
    S3_KEY="efs-temp/$(basename "$LOCAL_FILE")-$(date +%s)"

    aws s3 cp "$LOCAL_FILE" "s3://$S3_TEMP_BUCKET/$S3_KEY" --region "$AWS_REGION"
    ```

2. **Mova o Arquivo do S3 para o EFS no Bastion Host e Ajuste Permissões**

    Agora, use `aws ssm send-command` para executar comandos no bastion host. Esses comandos baixarão o arquivo do S3, o moverão para o diretório EFS correto e ajustarão suas permissões e propriedade.

    ```bash
    EFS_RELATIVE_PATH="html/index.html" # Ajuste para o caminho do seu arquivo no EFS

    # Caminho completo do arquivo no EFS
    EFS_MOUNT_POINT_ON_EC2="/mnt/efs"
    EFS_TARGET_FULL_PATH="${EFS_MOUNT_POINT_ON_EC2}/${PROJECT_NAME}/${EFS_RELATIVE_PATH}"
    LOCAL_FILE_BASENAME="$(basename "$LOCAL_FILE")"

    # Construa a string de comandos remotos, escapando aspas duplas internas para JSON.
    REMOTE_COMMANDS="sudo mkdir -p \\\"$(dirname "$EFS_TARGET_FULL_PATH")\\\"; \\
        aws s3 cp \\\"s3://$s3_temp_bucket/$s3_key\\\" \\\"/tmp/$(basename "$local_file_full_path")\\\"; \\
        sudo mv \\\"/tmp/$(basename "$local_file_full_path")\\\" \\\"$EFS_TARGET_FULL_PATH\\\"; \\
        aws s3 rm \\\"s3://$s3_temp_bucket/$s3_key\\\""

    aws ssm send-command \
        --instance-ids "$BASTION_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$REMOTE_COMMANDS\"]" \
        --region "$region" \
        --output text
    ```

3. **Dispare um Instance Refresh no Auto Scaling Group (Crucial para Implantação)**

    Para que as instâncias no seu Auto Scaling Group passem a servir o conteúdo atualizado, você precisa disparar um "instance refresh". Isso garante que novas instâncias (com o conteúdo mais recente do EFS, já que ele é um sistema de arquivos compartilhado) sejam lançadas e as antigas sejam removidas gradualmente.

    ```bash
    cd infra
    ASG_NAME=$(terraform output -raw asg_name) # Certifique-se de que este output existe
    cd ..

    echo "Iniciando Instance Refresh para o Auto Scaling Group: $ASG_NAME"

    aws autoscaling start-instance-refresh \
        --auto-scaling-group-name "$ASG_NAME" \
        --region "$AWS_REGION" \
        --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 180}'

    if [ $? -ne 0 ]; then
        echo "Aviso: Falha ao iniciar o instance refresh para o ASG '$ASG_NAME'. Verifique o console AWS para detalhes."
    else
        echo "Instance refresh iniciado com sucesso para '$ASG_NAME'. Novas instâncias serão provisionadas para servir o conteúdo atualizado."
    fi
    ``` 

4.  **Destruir o Bastion Host:**

    Quando você não precisar mais do Bastion Host, remova-o **aplicando o Terraform com `create_bastion_host` definido como `false`**. Isso evita a desmontagem de toda a sua infraestrutura.

    ```bash
    cd infra # Se você ainda não estiver no diretório infra

    terraform plan \
    -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
    -var="account_username=$USERNAME" \
    -var="project=$PROJECT_NAME" \
    -var="key_name=$SSH_KEY_NAME" \
    -var="create_bastion_host=false" \
    -out="./plan/$ENVIRONMENT.destroy_bastion.plan"

    terraform apply "./plan/$ENVIRONMENT.destroy_bastion.plan"
    ```

#### d. Destruir Infraestrutura Completa (Manual)

1.  **Navegue para o diretório `infra`:**
    ```bash
    cd infra
    ```
2.  **Destrua a infraestrutura:**
    ```bash
    terraform destroy \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=false" # Garante que o bastion (se existir) seja considerado para destruição
    ```

</content>

</details>

### 3\. Abordagem Automatizada (Usando `run.sh`)

O script `run.sh` centraliza e automatiza as operações, tornando-as mais simples e menos propensas a erros.

<details> 
<summary>
:eyes: Veja Exemplo
</summary>

<content>

1. **Conceda Permissões de Execução aos Scripts**

    Certifique-se de que o script principal e os scripts auxiliares tenham permissões de execução.

    ```bash
    chmod +x run.sh scripts/*.sh
    ```

2. **Provisionamento completo (build AMI + infraestrutura):**
   ```bash
   ./run.sh apply
   ```

3. **Atualizar conteúdo no EFS (refletido em todas as instâncias):**
   ```bash
   ./run.sh update-efs-file src/index.html html/index.html
   # Ou para diretórios inteiros:
   ./run.sh update-efs-file src/ html/
   ```
   > O script cria o bastion se necessário, faz upload seguro via S3 temporário, executa comandos remotos via SSM, e destrói o bastion ao final.

4. **Destruir infraestrutura:**
   ```bash
   ./run.sh destroy
   ```

</content>

</details>

## Boas Práticas e Diferenciais

- **Ciclo de vida seguro do bastion**: Não deixa portas SSH abertas, usa SSM, e destrói o host após uso.
- **Automação ponta-a-ponta**: Do build da AMI ao deploy do conteúdo, tudo via um único script.
- **Multi-ambiente**: Separação clara de ambientes via workspaces e arquivos `.tfvars`.
- **Idempotência e consistência**: Atualizações de conteúdo são refletidas em todas as instâncias sem necessidade de deploy manual em cada uma.
- **Pronto para multi-região e peering**: Estrutura de rede preparada para expansão.

**Autor:** [Andresinho20049](https://andresinho20049.com.br/)  
**Projeto:** AWS Cloud Solutions Architect Study Project