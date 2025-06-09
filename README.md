# Terraform AWS Cloud Solutions Architect Study Project
This project aims to study and practice Infrastructure as Code (IaC) using Terraform to provision resources on Amazon Web Services (AWS). The focus is to deepen knowledge of essential AWS services for the AWS Solutions Architect certification, ensuring that the infrastructure is scalable, replicable, and well-organized.

## Project Structure

The project is structured into **modules** to promote modularity, reusability, and scalability. Environment variables and secrets will be used to manage sensitive and environment-specific configurations.

To support **multiple environments** (such as `dev`, `prod`, `staging`), the project uses a folder structure for `.tfvars` files:

```
.env
infla/
├── main.tf
├── modules/
│   ├── vpc/
│   └── alb/
└── envs/
    ├── dev/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
    └── staging/
        └── terraform.tfvars
```

Each environment folder (`dev`, `prod`, `staging`, etc.) contains a `terraform.tfvars` file with specific configurations for that environment, such as VPC CIDR blocks, AMI IDs, and instance types.


## Provisioned Resources

The infrastructure provisioned by this project will include the following components:

### `vpc-module`

Responsible for creating the virtual network in AWS, including:

* **VPC (Virtual Private Cloud):** An isolated network for your infrastructure.
    * **First Network:** `10.0.0.0/16`
        * **Public Subnet AZa:** `10.0.1.0/24`
        * **Private Subnet AZa:** `10.0.2.0/24`
        * **Public Subnet AZb:** `10.0.3.0/24`
        * **Private Subnet AZb:** `100.0.4.0/24`
    * **Second Network (for multi-region peering):** `10.1.0.0/16`
        * **Public Subnet AZa:** `10.1.1.0/24`
        * **Private Subnet AZa:** `10.1.2.0/24`
        * **Public Subnet AZb:** `10.1.3.0/24`
        * **Private Subnet AZb:** `10.1.4.0/24`
* **Subnets:** Divided into public and private subnets across different Availability Zones (AZa, AZb).
* **Route Tables:**
    * A public route table for inbound and outbound internet traffic.
    * A private route table for internal traffic and access to AWS services.
* **Internet Gateway (IGW):** Enables communication between the VPC and the internet.
    * The IGW will be associated with the public route table.
* **Security Groups:**
    * **Public:** Allows SSH (port 22) and HTTP (port 80) access from any IP (`0.0.0.0/0`).
    * **Private:** Allows SSH (port 22) access only from internal subnets within the VPC.

### `loadbalancer-module`

Responsible for configuring load balancing and automatic scaling:

* **Application Load Balancer (ALB):** Distributes incoming traffic across multiple instances.
* **Target Group:** A group of EC2 instances to which the ALB will direct traffic.
* **Launch Template:** Defines the configuration for EC2 instances to be launched.
    * The **AMI (`aws linux2`)** and other instance configurations will be defined via `tfvars` files.
* **Auto Scaling Group (ASG):** Ensures a specified number of EC2 instances are always running, scaling automatically up or down based on demand.

### `main.tf`
The `main.tf` file at the root of the project will orchestrate the calls to the modules:

* **AWS Provider:** Configuration for the AWS provider.
* Calls to `vpc-module` and `loadbalancer-module`.

## Naming Convention

AWS resources will follow a consistent naming standard:

`$username.$region.$resource-name.$name`

* `$username`: Your username or identifier.
* `$region`: The AWS region where the resource is being provisioned (e.g., `us-east-1`).
* `$resource-name`: The resource type (e.g., `vpc`, `subnet`, `alb`).
* `$name`: A descriptive name for the resource.

**Example:** `andresinho20049.us-east-1.vpc.my-vpc`

## Resource Tagging

All provisioned resources will include the following tags for better organization and traceability:

* `environment`: `$env` (e.g., `dev`, `prod`, `staging`)
* `project`: `$project` (Project name, e.g., `terraform-study`)
* `region`: `$region` (AWS Region)

## S3 Backend and Workspaces

To manage Terraform state securely and collaboratively, an S3 backend with DynamoDB for state locking will be used. Additionally, **workspaces** will be utilized to isolate environments (development, production, etc.).

### Workspace Management

To switch or create workspaces, use:

```bash
terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
```

This ensures that the Terraform state is stored separately for each environment (e.g., `dev`, `prod`).

## Requirements

* Terraform CLI installed.
* AWS credentials configured (via environment variables, credentials file, or AWS profile).
* S3 bucket configured for the state backend.
* DynamoDB table configured for state locking.

## How to Use
### 1. Preparing the Environment

1. **Clone the Repository:**
    ```bash
    git clone https://github.com/andresinho20049/terraform-aws-with-autoscaling-course
    cd terraform-aws-with-autoscaling-course
    ```

2. **Rename the `.env.example` file to `.env`:**
    This file will contain the environment variables needed for the Terraform backend and other global configurations.
    > Remember to Replace the example values ​​with your own

### 2. Running Terraform

1. **Load the Environment Variables:**
    Before running any Terraform commands, load the variables from the `.env` file into your shell session and then enter the `infla` folder.

    ```bash
    source .env
    cd infla
    ```

2. **Initialize Terraform:**
    This command configures the S3 backend for Terraform state management.

    ```bash
    terraform init \
        -backend-config="bucket=$TF_BACKEND_BUCKET" \
        -backend-config="key=$TF_BACKEND_KEY" \
        -backend-config="region=$TF_BACKEND_REGION" \
        -backend-config="dynamodb_table=$TF_AWS_LOCK_DYNAMODB_TABLE"
    ```

3. **Select or Create Workspace:**
    Define the environment for which you want to provision infrastructure. Make sure the value of `$ENVIRONMENT` matches one of the folders in `envs/`.

    ```bash
    terraform workspace select $ENVIRONMENT || terraform workspace new $ENVIRONMENT
    ```

4. **Plan Infrastructure:**
    This command generates an execution plan, showing which resources will be created, modified, or destroyed. It uses the `.tfvars` file specific to the selected environment.

    ```bash
    terraform plan \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$TF_BACKEND_KEY" \
        -out="$ENVIRONMENT.plan"
    ```

5. **Apply Infrastructure:**
    Execute the generated plan to provision the resources in AWS.

    ```bash
    terraform apply "$ENVIRONMENT.plan"
    ```

6. **Destroy Infrastructure (when no longer needed):**
To remove all provisioned resources, use the `destroy` command. **Caution:** This is irreversible!

    ```bash
    terraform destroy \
        -var-file="./envs/$ENVIRONMENT/terraform.tfvars" \
        -var="account_username=$USERNAME" \
        -var="project=$TF_BACKEND_KEY"
    ```

## Multi-Region and Peering
The project is prepared to provision resources in multiple regions and perform VPC peering. The `10.0.0.0/16` and `10.1.0.0/16` networks are examples of distinct CIDR blocks that can be used for VPCs in different regions to facilitate peering configuration. The actual peering implementation will be added in a later phase, but the foundation for it is present in the network block definition and environment variables.

## ©️ Copyright
**Developed by** [Andresinho20049](https://andresinho20049.com.br/) \
**Project**: *AWS Cloud Solutions Architect Study Project* \
**Description**: \
This project provides a foundational AWS infrastructure for learning and preparing for the AWS Cloud Solutions Architect certification. It focuses on modularity, scalability, and best practices for Infrastructure as Code (IaC) with Terraform, including multi-environment support and VPC peering capabilities.