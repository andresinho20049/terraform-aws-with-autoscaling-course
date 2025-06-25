#!/bin/bash

# --- Configuration ---
# Set -e: Exit immediately if a command exits with a non-zero status.
# Set -u: Treat unset variables as an error.
# Set -o pipefail: The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Define Project Root ---
SCRIPT_DIR=$(unset CDPATH && cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="${SCRIPT_DIR}" # Assuming the script is in the project root

echo "Project root detected at: ${PROJECT_ROOT}"

# Define script usage
usage() {
  echo "Usage: $0 [apply|destroy]"
  echo "  apply   - Builds AMI with Packer and applies Terraform infrastructure."
  echo "  destroy - Destroys Terraform infrastructure."
  exit 1
}

# Check if an argument is provided
if [ -z "${1:-}" ]; then
  usage
fi

ACTION="$1"

# --- 1. Environment Preparation ---
echo "--- 1. Preparing the Environment ---"

# Check for .env file and load variables
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo "Error: .env file not found. Please rename .env.example to .env and configure it."
  exit 1
fi
echo "Loading environment variables from .env..."
# Using 'set -a' to export all variables read from .env automatically
set -a
source "${PROJECT_ROOT}/.env"
set +a # Disable auto-export after sourcing

# Validate required environment variables
REQUIRED_VARS=("ENVIRONMENT" "TF_BACKEND_BUCKET" "TF_BACKEND_KEY" "TF_BACKEND_REGION" "TF_AWS_LOCK_DYNAMODB_TABLE" "USERNAME" "SSH_KEY_NAME")
for VAR_NAME in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR_NAME:-}" ]; then
    echo "Error: Required environment variable '$VAR_NAME' is not set in .env"
    exit 1
  fi
done

echo "Environment variables loaded successfully."

# --- 2. Packer Execution ---
if [ "$ACTION" == "apply" ]; then
  echo "--- 2. Executing Packer ---"

  PACKER_DIR="${PROJECT_ROOT}/packer/ami-templates/nginx-webserver"
  PACKER_VARS_FILE="${PROJECT_ROOT}/packer/envs/$ENVIRONMENT/$ENVIRONMENT.pkrvars.hcl"

  # Check if Packer directory exists
  if [ ! -d "$PACKER_DIR" ]; then
    echo "Error: Packer directory '$PACKER_DIR' not found. Please check your project structure."
    exit 1
  fi

  # Check if Packer variables file exists
  if [ ! -f "$PACKER_VARS_FILE" ]; then
    echo "Error: Packer variables file '$PACKER_VARS_FILE' not found for environment '$ENVIRONMENT'. Create it."
    exit 1
  fi

  echo "Navigating to Packer directory: $PACKER_DIR"
  # Change directory without pushing to stack, operate directly
  cd "$PACKER_DIR"

  echo "Initializing Packer..."
  packer init .

  echo "Building AMI with Packer for environment: $ENVIRONMENT"
  # Use full paths for var-file as we are now inside PACKER_DIR
  packer build \
      -var-file="${PACKER_VARS_FILE}" .

  # Navigate back to the project root after Packer is done
  cd "${PROJECT_ROOT}"
  echo "Packer execution completed. Navigated back to project root: ${PROJECT_ROOT}"
fi

# --- 3. Terraform Execution ---
echo "--- 3. Executing Terraform ---"

TERRAFORM_DIR="${PROJECT_ROOT}/infra"
TERRAFORM_VARS_FILE="${TERRAFORM_DIR}/envs/$ENVIRONMENT/terraform.tfvars"
TERRAFORM_PLAN_DIR="${TERRAFORM_DIR}/plan"
TERRAFORM_PLAN_FILE="${TERRAFORM_PLAN_DIR}/$ENVIRONMENT.plan"

# Check if Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "Error: Terraform directory '$TERRAFORM_DIR' not found. Please check your project structure."
  exit 1
fi

# Check if Terraform variables file exists for the environment
if [ ! -f "$TERRAFORM_VARS_FILE" ]; then
  echo "Error: Terraform variables file '$TERRAFORM_VARS_FILE' not found for environment '$ENVIRONMENT'. Create it."
  exit 1
fi

echo "Navigating to Terraform directory: $TERRAFORM_DIR"
# Change directory without pushing to stack, operate directly
cd "$TERRAFORM_DIR"

echo "Initializing Terraform backend..."
terraform init \
    -backend-config="bucket=$TF_BACKEND_BUCKET" \
    -backend-config="key=$TF_BACKEND_KEY" \
    -backend-config="region=$TF_BACKEND_REGION" \
    -backend-config="dynamodb_table=$TF_AWS_LOCK_DYNAMODB_TABLE"

echo "Selecting or creating Terraform workspace: $ENVIRONMENT"
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

if [ "$ACTION" == "apply" ]; then
  echo "Planning Terraform infrastructure..."
  mkdir -p "$TERRAFORM_PLAN_DIR" # Ensure plan directory exists
  terraform plan \
      -var-file="${TERRAFORM_VARS_FILE}" \
      -var="account_username=$USERNAME" \
      -var="project=$TF_BACKEND_KEY" \
      -var="key_name=$SSH_KEY_NAME" \
      -out="$TERRAFORM_PLAN_FILE"

  echo "Applying Terraform infrastructure..."
  terraform apply "$TERRAFORM_PLAN_FILE"

elif [ "$ACTION" == "destroy" ]; then
  echo "Destroying Terraform infrastructure..."
  terraform destroy \
      -var-file="${TERRAFORM_VARS_FILE}" \
      -var="account_username=$USERNAME" \
      -var="project=$TF_BACKEND_KEY" \
      -var="key_name=$SSH_KEY_NAME"
fi

# Navigate back to the project root after Terraform is done
cd "${PROJECT_ROOT}"
echo "--- Script execution completed for $ACTION action. Navigated back to project root: ${PROJECT_ROOT} ---"