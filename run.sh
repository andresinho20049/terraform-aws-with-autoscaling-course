#!/bin/bash

# --- Configuration ---
set -euo pipefail

# --- Define Project Root ---
SCRIPT_DIR=$(unset CDPATH && cd "$(dirname "$0")" && pwd)
PROJECT_ROOT="${SCRIPT_DIR}"

echo "Project root detected at: ${PROJECT_ROOT}"

# --- Source Common Utilities and Action Scripts ---
# Carrega funções de utilidade
source "${PROJECT_ROOT}/scripts/utils.sh"
# Carrega as lógicas de ação
source "${PROJECT_ROOT}/scripts/packer_actions.sh"
source "${PROJECT_ROOT}/scripts/terraform_actions.sh"
source "${PROJECT_ROOT}/scripts/efs_actions.sh"


# Define script usage (now includes more actions)
usage() {
  echo "Usage: $0 <action> [options]"
  echo "Actions:"
  echo "  apply             - Builds AMI with Packer and applies Terraform infrastructure."
  echo "  destroy           - Destroys Terraform infrastructure."
  echo "  up-bastion        - Creates the temporary bastion host using Terraform."
  echo "  down-bastion      - Destroys the temporary bastion host using Terraform."
  echo "  update-efs-file   - Updates a specified file on EFS via the bastion host."
  echo "                      Usage: $0 update-efs-file <local_file_path> <efs_relative_path>"
  echo "                      <local_file_path>: Path to the local file to upload (e.g., 'web/index.html')"
  echo "                      <efs_relative_path>: Relative path on EFS (e.g., 'terraform-aws-with-autoscaling-course/html/index.html')"
  echo "                      Note: This action will automatically create the bastion if it doesn't exist, and tear it down afterwards."
  exit 1
}

# Check if an argument is provided or help is requested
if [ -z "${1:-}" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
fi

ACTION="$1"
shift # Remove the action from arguments, so remaining arguments are for the action

# --- 1. Environment Preparation ---
echo "--- 1. Preparing the Environment ---"

# Check for .env file and load variables
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  echo "Error: .env file not found. Please rename .env.example to .env and configure it."
  exit 1
fi
echo "Loading environment variables from .env..."
set -a # Export all variables
source "${PROJECT_ROOT}/.env"
set +a # Disable auto-export

# Validate required environment variables
REQUIRED_VARS=("ENVIRONMENT" "TF_BACKEND_BUCKET" "TF_BACKEND_KEY" "TF_BACKEND_REGION" "TF_AWS_LOCK_DYNAMODB_TABLE" "USERNAME" "SSH_KEY_NAME")
for VAR_NAME in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR_NAME:-}" ]; then
    echo "Error: Required environment variable '$VAR_NAME' is not set in .env"
    exit 1
  fi
done

echo "Environment variables loaded successfully."

# --- Main Action Logic ---
case "$ACTION" in
  apply)
    execute_packer_build "$ENVIRONMENT" "$PROJECT_ROOT"
    execute_terraform_apply "$ENVIRONMENT" "$PROJECT_ROOT" "$USERNAME" "$PROJECT_NAME" "$SSH_KEY_NAME" \
                            "$TF_BACKEND_BUCKET" "$TF_BACKEND_KEY" "$TF_BACKEND_REGION" "$TF_AWS_LOCK_DYNAMODB_TABLE" false
    ;;

  destroy)
    execute_terraform_destroy "$ENVIRONMENT" "$PROJECT_ROOT" "$USERNAME" "$PROJECT_NAME" "$SSH_KEY_NAME" \
                              "$TF_BACKEND_BUCKET" "$TF_BACKEND_KEY" "$TF_BACKEND_REGION" "$TF_AWS_LOCK_DYNAMODB_TABLE" false
    ;;

  up-bastion)
    execute_terraform_apply "$ENVIRONMENT" "$PROJECT_ROOT" "$USERNAME" "$PROJECT_NAME" "$SSH_KEY_NAME" \
                            "$TF_BACKEND_BUCKET" "$TF_BACKEND_KEY" "$TF_BACKEND_REGION" "$TF_AWS_LOCK_DYNAMODB_TABLE" true
    ;;

  down-bastion)
    execute_terraform_apply "$ENVIRONMENT" "$PROJECT_ROOT" "$USERNAME" "$PROJECT_NAME" "$SSH_KEY_NAME" \
                            "$TF_BACKEND_BUCKET" "$TF_BACKEND_KEY" "$TF_BACKEND_REGION" "$TF_AWS_LOCK_DYNAMODB_TABLE" false
    ;;

  update-efs-file)
    execute_efs_file_update "$@" "$PROJECT_ROOT" "$ENVIRONMENT" "$PROJECT_NAME" "$TF_BACKEND_REGION" \
                            "$TF_BACKEND_BUCKET" "$TF_BACKEND_KEY" "$TF_AWS_LOCK_DYNAMODB_TABLE"
    ;;

  *)
    echo "Error: Invalid action '$ACTION'."
    usage
    ;;
esac

echo "--- Script execution completed for $ACTION action. ---"