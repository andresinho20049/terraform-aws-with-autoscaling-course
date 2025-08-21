# 🚀 AWS Infrastructure with Terraform – Study & Automation
[![pt-br](https://img.shields.io/badge/lang-pt--br-green.svg)](/README.pt-br.md)

This repository is a practical and automated study of AWS infrastructure provisioning using Terraform, Packer, and Shell Script. The goal is to create a scalable, secure, and maintainable environment, focusing on best practices for real-world projects and AWS certification preparation.

## 🔛 Use Case Overview

The project simulates a scalable web application scenario, with multiple environments (dev, prod, staging), automated deployment of static content via EFS, and a secure bastion host lifecycle. The main flow is:

1. **Custom AMI build** with Packer (NGINX, dependencies, etc).
2. **Infrastructure provisioning** (VPC, EFS, ALB, ASG, Bastion) via Terraform.
3. **Centralized content update** on EFS, instantly reflected on all ASG instances.
4. **Full automation** via the `run.sh` script, orchestrating all steps, including bastion host lifecycle.

## 🔑 Key Components

- **Modular VPC**: Public/private subnets, routing, segmented security groups.
- **EFS**: Shared storage for web content, mounted on all ASG instances.
- **ALB & ASG**: Load balancing and auto-scaling.
- **Ephemeral Bastion Host**: Created on demand for admin operations (e.g., EFS updates), automatically destroyed after use.
- **Automation via `run.sh`**: A single entry point for build, deploy, content update, and teardown.

## 🚧 Project Structure

The project is structured into modules to promote modularity, reusability, and scalability. Environment variables and secrets will be used to manage sensitive and environment-specific configurations.

To support **multiple environments** (such as `dev`, `prod`, `staging`), the project uses a folder structure for `.tfvars` files:

```
.
├── src/
│   └── index.html          # Example file that can be updated on EFS
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
│   │   │   └── prod.pkrvars.h│cl
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
│   │   ├── vpc/            # Virtual Private Cloud Module
│   │   ├── efs/            # Elastic File System Module
│   │   ├── alb/            # Application Load Balancer Module
│   │   └── bhc/            # Bastion Host Controller Module
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

Each environment folder (`dev`, `prod`, `staging`, etc.) contains a `terraform.tfvars` file with specific configurations for that environment, such as VPC CIDR blocks, AMI IDs, and instance types.

## ☁️ Provisioned Resources

The infrastructure provisioned by this project covers the following components:

![Diagram](/assets/terraform-aws-with-autoscaling-course.drawio.svg)

### `vpc` Module (named as `main_vpc`)

Responsible for creating the virtual network in AWS, including:

  * **VPC (Virtual Private Cloud):** Isolated network for your infrastructure.
      * **First Network:** `10.0.0.0/16`
          * **Public Subnet AZa:** `10.0.1.0/24`
          * **Private Subnet AZa:** `10.0.2.0/24`
          * **Public Subnet AZb:** `10.0.3.0/24`
          * **Private Subnet AZb:** `10.0.4.0/24`
      * **Second Network (for multi-region peering):** `10.1.0.0/16` > Optional
          * **Public Subnet AZa:** `10.1.1.0/24`
          * **Private Subnet AZa:** `10.1.2.0/24`
          * **Public Subnet AZb:** `10.1.3.0/24`
          * **Private Subnet AZb:** `10.1.4.0/24`
  * **Subnets:** Divided into public and private subnets across different Availability Zones (AZa, AZb).
  * **Route Tables:**
      * A public route table for internet inbound and outbound traffic.
      * A private route table for internal traffic and AWS service access.
  * **Internet Gateway (IGW):** Enables communication between the VPC and the internet.
      * The IGW will be associated with the public route table.
  * **Security Groups:**
      * **Public:** Allowing HTTP access (port 80) from any IP (`0.0.0.0/0`).
      * **Private:** Allowing SSH access (port 22) only from internal VPC subnets.
      * **Bastion:** Specific Security Group for the bastion host, allowing SSH from controlled IPs and EFS access.
      * **EFS:** Security Group for EFS, allowing NFS traffic from application instances and the bastion host.

### `efs` Module

Responsible for provisioning Amazon Elastic File System (EFS), a distributed and scalable file system.

  * **EFS File System:** A centralized point for storing data that can be shared across multiple EC2 instances. This is essential for applications that require common and persistent storage, such as web servers serving static content. Auto Scaling Group instances will mount this EFS, ensuring all application replicas access the same files.
  * **Mount Targets:** Access points within the private subnets of the VPC, allowing EC2 instances to mount EFS.
  * **Security Group:** As mentioned in the VPC, a dedicated SG for EFS to control NFS access.

### `alb` Module (named as `web_alb`)

Responsible for configuring load balancing and auto-scaling for your web application.

  * **Application Load Balancer (ALB):** Distributes inbound HTTP/HTTPS traffic among application instances.
  * **Target Group:** Groups the EC2 instances that receive traffic from the ALB.
  * **Launch Template:** Defines the configurations for the EC2 instances to be launched, including instance type, AMI, SSH key, and `user_data` script for mounting EFS.
  * **Auto Scaling Group (ASG):** Ensures a specific number of EC2 instances are always running, scaling up or down automatically based on demand, providing high availability and resilience.

### `bhc` Module (Bastion Host Configuration, named as `bastion_host`)

Responsible for provisioning a secure and temporary bastion host.

  * **EC2 Bastion Host Instance:** A virtual machine that can be created and destroyed on demand. It serves as a secure access point to the private network, allowing management operations (such as updating files on EFS) to be performed without exposing application instances directly to the internet.
  * **Ephemeral Configuration:** The bastion host is configured with all necessary resources (Amazon Linux 2 based AMI, automatic EFS mounting at `/mnt/efs`, and appropriate IAM permissions via instance profile).
  * **Access Control:** The bastion's Security Group is strictly configured to allow SSH access only from trusted IPs and NFS access to EFS. The use of SSM (AWS Systems Manager) is prioritized for access and command execution, eliminating the need to publicly open SSH ports.
  * **Cost and Security Optimization:** Being temporary and activated on demand, the bastion host minimizes costs and reduces the attack surface, as it is not active 24/7.

## 〰️ AMI Build Approach and Content Management

This project adopts a robust approach for managing machine images and application content:

  * **Optimized AMI with Packer:** We use **Packer** to build custom machine images (AMIs). This AMI pre-installs essential services like NGINX, `amazon-efs-utils`, and other dependencies, in addition to ensuring system packages are updated. Instead of installing everything in the `user_data` of each new instance, the AMI comes ready, which speeds up instance boot time and makes them more consistent and secure, especially for instances in private subnets that do not have direct internet access.
  * **EFS as a Distributed File Server:** **Amazon EFS** is employed as a fully managed network file system (NFS). This means web content (HTML, CSS, JS, images) is stored in a single, centralized source of truth on EFS. When a file is updated on EFS (e.g., via the bastion host), this change is **immediately reflected** across all EC2 instances in the Auto Scaling Group that are mounting the same EFS. This eliminates the need to individually synchronize files on each server, simplifying content deployment and ensuring consistency.
  * **Bastion Host for Secure Operations:** Updating content on EFS or other management tasks are performed securely through the **temporary bastion host**. This bastion is created with **appropriate Security Groups and IAM profiles**, ensuring that only necessary traffic and permissions are granted during the operation's lifespan. This keeps your application instances in private subnets, protected from direct access.

## 💱 Naming Convention

AWS resources will follow a consistent naming pattern:

`$username.$region.$resource-name.$name.$environment`

  * `$username`: Your username or identifier.
  * `$region`: The AWS region where the resource is being provisioned (e.g., `us-east-1`).
  * `$resource-name`: The type of resource (e.g., `vpc`, `subnet`, `alb`).
  * `$name`: A descriptive name for the resource.
  * `$environment`: The environment where the resource is being provisioned (e.g., `dev`).

**Example:** `andresinho20049.us-east-1.vpc.my-vpc.dev`

## ®️ Resource Tags

All provisioned resources will include the following tags for better organization and traceability:

  * `environment`: `$env` (Ex: `dev`, `prod`, `staging`)
  * `project`: `$project` (Project name, ex: `terraform-study`)
  * `region`: `$region` (AWS Region)

## 💻 S3 Backend and Workspaces

To manage Terraform state securely and collaboratively, an S3 backend with DynamoDB for state locking will be used. Additionally, workspaces will be employed to isolate environments (development, production, etc.).

### Workspace Management

To switch or create workspaces, use:

```bash
terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
```

This ensures that the Terraform state is stored separately for each environment (e.g., `dev`, `prod`).

## ✳️ Requirements

  * **Terraform CLI** installed.
  * **Packer CLI** installed.
  * **AWS CLI** configured with credentials.
  * S3 bucket configured for state backend.
  * DynamoDB table configured for state locking.


## ⁉️ How to Use

This project offers two main ways to interact with the infrastructure: by executing commands **manually** (for greater control and debugging) or by using the **`run.sh` script** (for automation and convenience).

### 🔺 1\. Preparing the Environment (Both Approaches)

Regardless of the chosen approach, the initial steps are the same.

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/andresinho20049/terraform-aws-with-autoscaling-course
    cd terraform-aws-with-autoscaling-course
    ```

2.  **Rename the `.env.example` file to `.env`:**
    This file will contain the **environment variables** necessary for the Terraform backend and other global configurations.

    ```bash
    cp .env.example .env
    ```

    > Remember to **replace the example values with your own**.

3.  **Load Environment Variables:**
    Before running any Packer, Terraform, or `run.sh` commands, load the variables from the `.env` file into your shell session.

    ```bash
    source .env
    ```

### Choose Your Approach:

  * [**Manual Approach (Step-by-Step)**](#2-manual-approach-step-by-step)
  * [**Automated Approach (Using `run.sh`)**](#3-automated-approach-using-runsh)

### 🔹 2\. Manual Approach (Step-by-Step)

Follow these steps if you prefer to execute Packer, Terraform, and AWS CLI commands manually for greater control and debugging.

<details> 
<summary>
    👀 See Example
</summary>

<content>


#### a. Running Packer

1.  **Navigate to the Packer directory:**
    ```bash
    cd packer/ami-templates/nginx-webserver/
    ```
2.  **Initialize Packer:**
    ```bash
    packer init .
    ```
3.  **Build the AMI with Packer:**
    ```bash
    packer build \
        -var-file="../../envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl" .
    ```

#### b. Running Terraform (After Packer)

1.  **Navigate back to the `infra` directory:**

    ```bash
    cd ../../../infra
    ```

2.  **Initialize Terraform:**
    This command configures the S3 backend for Terraform state management.

    ```bash
    terraform init \
        -backend-config="bucket=$TF_BACKEND_BUCKET" \
        -backend-config="key=$TF_BACKEND_KEY" \
        -backend-config="region=$TF_BACKEND_REGION" \
        -backend-config="dynamodb_table=$TF_AWS_LOCK_DYNAMODB_TABLE"
    ```

3.  **Select or Create Workspace:**
    Define the environment for which you want to provision the infrastructure. Make sure the value of `$ENVIRONMENT` matches one of the folders in `envs/`.

    ```bash
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    ```

4.  **Plan Infrastructure:**
    This command generates an execution plan, showing which resources will be created, modified, or destroyed. It uses the specific `.tfvars` file for the selected environment.

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

    > **Note:** The `-var="create_bastion_host=false"` ensures that the bastion host is **not** created by default during the main infrastructure `apply`.

5.  **Apply Infrastructure:**
    Execute the generated plan to provision resources in AWS.

    ```bash
    terraform apply "./plan/$ENVIRONMENT.plan"
    ```

#### c. Managing the Bastion Host and EFS Manually

1.  **Create the Bastion Host:**
    Navigate to the `infra` directory and apply Terraform to create the bastion.

    ```bash
    cd infra # If you're not already in the infra directory
    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=true" \
        -out="./plan/$ENVIRONMENT.bastion.plan"
    terraform apply "./plan/$ENVIRONMENT.bastion.plan"
    ```

    **Get the Bastion Instance ID:**

    ```bash
    terraform output -raw bastion_instance_id
    # Example output: i-0abcdef1234567890
    ```

    > Save this ID, you'll need it.

#### d. Update Content on EFS (Manual Step-by-Step Process)

For those who want to understand or execute the process of updating a file on EFS manually, without using the `run.sh` script, follow the detailed steps below. This method uses a **temporary S3 bucket** as an intermediary for file transfer, ensuring security and efficiency through AWS Systems Manager (SSM).

We assume the **bastion host is already running** and that the **EFS is mounted at `/mnt/efs`** on your instances, with your website content in `/mnt/efs/<PROJECT_NAME>/html/`.

1.  **Upload Local File to a Temporary S3 Bucket**
    Before updating EFS, let's upload the file to a temporary S3 bucket.

    ```bash
    LOCAL_FILE="./src/index.html" # Change this to your local file path

    # Crie um nome para o bucket S3 temporário e uma chave única para o arquivo
    S3_TEMP_BUCKET="${USERNAME}.${TF_BACKEND_REGION}.s3.bhc-temp.${ENVIRONMENT}"
    S3_KEY="efs-temp/$(basename "$LOCAL_FILE")-$(date +%s)"

    aws s3 cp "$LOCAL_FILE" "s3://$S3_TEMP_BUCKET/$S3_KEY" --region "$AWS_REGION"
    ```

2. **Move the File from S3 to EFS on the Bastion Host and Adjust Permissions**

    Now, use `aws ssm send-command` to run commands on the bastion host. These commands will download the file from S3, move it to the correct EFS directory, and adjust its permissions and ownership.

    ```bash
    EFS_RELATIVE_PATH="html/index.html" # Adjust this to your EFS file path

    # Full EFS file path
    EFS_MOUNT_POINT_ON_EC2="/mnt/efs"
    EFS_TARGET_FULL_PATH="${EFS_MOUNT_POINT_ON_EC2}/${PROJECT_NAME}/${EFS_RELATIVE_PATH}"
    LOCAL_FILE_BASENAME="$(basename "$LOCAL_FILE")"

    # Construct the remote command string, escaping internal double quotes for JSON. REMOTE_COMMANDS="sudo mkdir -p \\\"$(dirname "$EFS_TARGET_FULL_PATH")\\\"; \\ 
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

3. **Trigger an Instance Refresh on the Auto Scaling Group (Crucial for Deployment)**

    For instances in your Auto Scaling Group to start serving the updated content, you need to trigger an instance refresh. This ensures that new instances (with the latest EFS content, since it is a shared file system) are launched and old ones are gradually removed.

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

4.  **Destroy the Bastion Host:**

    When you no longer need the bastion host, remove it by **applying Terraform with `create_bastion_host` set to `false`**. This avoids tearing down your entire infrastructure.

    ```bash
    cd infra # If you're not already in the infra directory

    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=false" \
        -out="./plan/$ENVIRONMENT.destroy_bastion.plan"

    terraform apply "./plan/$ENVIRONMENT.destroy_bastion.plan"
    ```

#### d. Destroy Complete Infrastructure (Manual)

1.  **Navigate to the `infra` directory:**
    ```bash
    cd infra
    ```
2.  **Destroy the infrastructure:**
    ```bash
    terraform destroy \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$PROJECT_NAME" \
        -var="key_name=$SSH_KEY_NAME" \
        -var="create_bastion_host=false" # Ensures the bastion (if exists) is considered for destruction
    ```

</content>

</details>

### 🔸 3\. Automated Approach (Using `run.sh`)

The `run.sh` script centralizes and automates operations, making them simpler and less error-prone.

<details> 
<summary>
    👀 See Example
</summary>

<content>

1. **Grant Execute Permissions to Scripts**

    Ensure that the main script and helper scripts have execute permissions.

    ```bash
    chmod +x run.sh scripts/*.sh
    ```

2. **Full provisioning (build AMI + infrastructure):**
   ```bash
   ./run.sh apply
   ```

3. **Update content on EFS (reflected on all instances):**
   ```bash
   ./run.sh update-efs-file src/index.html html/index.html
   # Or for entire directories:
   ./run.sh update-efs-file src/ html/
   ```
   > The script creates the bastion if needed, uploads securely via temporary S3, executes remote commands via SSM, and destroys the bastion at the end.

4. **Destroy infrastructure:**
   ```bash
   ./run.sh destroy
   ```

</content>

</details>

## 💥 Best Practices & Highlights

- **Secure bastion lifecycle**: No open SSH ports, uses SSM, destroys host after use.
- **End-to-end automation**: From AMI build to content deploy, all via a single script.
- **Multi-environment**: Clear separation via workspaces and `.tfvars` files.
- **Idempotency & consistency**: Content updates are reflected on all instances without manual deploys.
- **Ready for multi-region & peering**: Network structure prepared for expansion.

## ©️ Copyright
**Developed by** [Andresinho20049](https://andresinho20049.com.br/) \
**Project**: *AWS Infrastructure with Terraform – Study & Automation* \
**Description**: \
This project offers a practical and automated study of AWS infrastructure provisioning using Terraform, Packer, and Shell Script. It creates a scalable, secure, and easy-to-maintain environment, focusing on best practices and preparing for AWS certifications. It simulates a web application with multiple environments (dev, prod, staging), including the creation of a custom AMI with Packer, provisioning of VPC, EFS, ALB, and ASG via Terraform, and full automation via the run.sh script.