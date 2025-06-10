# Packer - Gerenciamento de AMIs

Este diretório contém todas as definições e configurações do Packer para a criação de imagens de máquina da Amazon (AMIs) personalizadas para este projeto. O objetivo é criar AMIs "pré-cozidas" com o software necessário já instalado, garantindo builds mais rápidos e consistentes para suas instâncias EC2, além de reduzir dependências de conectividade externa durante o boot da instância.


## 1. Estrutura do Diretório
```
packer/
├── README.md
├── envs/
│   ├── dev/
│   │   └── dev.pkrvars.hcl
│   ├── prod/
│   │   └── prod.pkrvars.hcl
│   └── staging/
│       └── staging.pkrvars.hcl
│
├── ami-templates/          
│   └── nginx-webserver/    
│       ├── build.pkr.hcl     # Define os provisioners (o que será instalado/configurado).
│       ├── source.pkr.hcl    # Define o builder (base AMI, região, tipo de instância, etc.).
│       └── variables.pkr.hcl # Variáveis específicas para este template de AMI.
│       └── scripts/          # Scripts locais que são copiados/executados pelos provisioners.
│           └── install_nginx.sh
│
└── output_ami_ids.tfvars
```


## 2. Pré-requisitos

Para trabalhar com o Packer neste projeto, você precisará ter o seguinte instalado e configurado em sua máquina:

* **Packer CLI:** Instale o Packer v1.8.0 ou superior (ou a versão especificada em `packer {}` nos templates).
* **AWS CLI:** Configure suas credenciais da AWS (ID da chave de acesso, chave de acesso secreta e região padrão) usando `aws configure`.
* **Permissões IAM:** O usuário ou role IAM que o Packer usa precisa de permissões para:
    * `ec2:RunInstances`, `ec2:TerminateInstances`, `ec2:CreateImage`, `ec2:DeregisterImage`, `ec2:DeleteSnapshot`, `ec2:CreateSnapshot`, `ec2:DescribeImages`, `ec2:DescribeInstances`, `ec2:DescribeSnapshots`, `ec2:DescribeSecurityGroups`, `ec2:CreateSecurityGroup`, `ec2:AuthorizeSecurityGroupIngress`, `ec2:RevokeSecurityGroupIngress`, `ec2:DeleteSecurityGroup`.
    * `iam:PassRole` (se o Launch Template do Packer usar um perfil de instância).

## 3. Como Construir uma AMI

Siga os passos abaixo para construir uma AMI para um ambiente específico.

**3.1. Navegue até o Diretório do Template da AMI:**

Primeiro, navegue até o diretório do template da AMI que você deseja construir. Por exemplo, para a AMI do Nginx:

```bash
cd packer/ami-templates/nginx-webserver/
```

**3.2. Inicialize o Packer:**

Execute este comando uma vez para baixar os plugins necessários do Packer:

```bash
packer init .
```

**3.3. Valide o Template (Opcional, mas Recomendado):**

Verifique se a sintaxe do seu template está correta:

```bash
packer validate -var-file="../../envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl" .
```

**3.4. Construa a AMI para um Ambiente Específico:**

Use o argumento `-var-file` para carregar as variáveis de ambiente corretas.

```bash
packer build -var-file="../../envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl" .
```

Após a execução bem-sucedida, o Packer imprimirá o ID da AMI recém-criada no console.

## 4. Convenção de Nomes das AMIs

As AMIs criadas por este projeto seguem a convenção de nomenclatura:

`[ami_name_base_prefix]-[environment]-[YYYYMMDDHHMM]`

* `ami_name_base_prefix`: Definido em `variables.pkr.hcl` (ex: `nginx-webserver-amzn2`).
* `environment`: O ambiente para o qual a AMI foi construída (ex: `dev`, `prod`, `staging`).
* `YYYYMMDDHHMM`: Carimbo de data/hora (ano, mês, dia, hora, minuto) da criação da AMI, garantindo unicidade.

Exemplo: `nginx-webserver-amzn2-dev-202506092230`

## 5. Integração com Terraform

Após a construção de uma AMI bem-sucedida, o `ami_id` gerado pelo Packer será consumido pela configuração do Terraform.

A melhor prática é que seu Terraform use um bloco `data "aws_ami"` para buscar a AMI mais recente com base em seu nome e tags do ambiente, garantindo que a infraestrutura sempre implante a versão mais atual da sua aplicação.

Exemplo de como o Terraform pode buscar a AMI:

```hcl
data "aws_ami" "nginx_webserver" {
  most_recent = true
  owners      = ["self"] # Busca AMIs criadas na sua própria conta

  filter {
    name   = "name"
    # O nome da AMI que você busca
    values = ["${var.ami_name_base_prefix_terraform}-${var.environment}-*"]
  }

  tags = {
    ManagedBy   = "Packer"
    Environment = var.environment # Filtra também pela tag de ambiente
  }
}

# Em seguida, você passaria este ID para o seu Launch Template/ASG:
module "web_alb" {
  source = "./modules/alb"
  # ...
  ami_id = data.aws_ami.nginx_webserver.id
  # ...
}
```

## 6. Considerações e Boas Práticas
* **Custos:** O Packer lançará uma instância EC2 temporária (usando o `instance_type` definido, como `t2.micro`) durante o processo de build. Esta instância é encerrada automaticamente após a criação da AMI. Certifique-se de que os tipos de instância escolhidos para o build sejam elegíveis para o Free Tier, se aplicável.
* **Segurança:** Garanta que as credenciais da AWS usadas pelo Packer (IAM User/Role) tenham apenas as permissões mínimas necessárias para executar o processo de build da AMI.
* **Reconstrução de AMIs:** Reconstrua suas AMIs regularmente para incluir atualizações de segurança do SO e patches de software.
* **Versionamento:** O carimbo de data/hora no nome da AMI serve como um versionamento básico. Para um versionamento mais robusto, considere usar tags personalizadas ou ferramentas de CI/CD que gerenciem números de versão.
* **Depuração:** Se um build do Packer falhar, a instância temporária pode não ser encerrada imediatamente, permitindo que você faça SSH nela para depurar o problema. Verifique os logs do Packer para obter o ID da instância temporária.