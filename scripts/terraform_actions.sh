# scripts/terraform_actions.sh

# Function to execute Terraform apply
# Args:
#   $1: CREATE_BASTION_HOST (opcional, default: false)
execute_terraform_apply() {
    local create_bastion="${1:-false}"

    local env="$TF_VAR_ENVIRONMENT"
    local project_root="${PROJECT_ROOT:-$PWD}"

    local terraform_dir="${project_root}/infra"
    local terraform_vars_file="${terraform_dir}/envs/$env/terraform.tfvars"
    local terraform_plan_dir="${terraform_dir}/plan"
    local terraform_plan_file="${terraform_plan_dir}/$env.plan"

    echo "--- Executing Terraform Apply ---"

    if [ ! -d "$terraform_dir" ]; then
      echo "Error: Terraform directory '$terraform_dir' not found."
      exit 1
    fi

    if [ ! -f "$terraform_vars_file" ]; then
      echo "Error: Terraform variables file '$terraform_vars_file' not found for environment '$env'. Create it."
      exit 1
    fi

    echo "Navigating to Terraform directory: $terraform_dir"
    (
        cd "$terraform_dir" || exit 1

        tf_init_and_workspace

        echo "Planning Terraform infrastructure..."
        mkdir -p "$terraform_plan_dir"
        terraform plan \
            -var-file="${terraform_vars_file}" \
            -var="account_username=${TF_VAR_USERNAME}" \
            -var="project=${TF_VAR_PROJECT_NAME}" \
            -var="region=${TF_VAR_REGION}" \
            -var="create_bastion_host=$create_bastion" \
            -out="$terraform_plan_file"

        echo "Applying Terraform infrastructure..."
        terraform apply "$terraform_plan_file"
    )
    echo "Terraform apply completed."
}

# Function to execute Terraform destroy
# Args:
#   $1: CREATE_BASTION_HOST (opcional, default: false)
execute_terraform_destroy() {
    local create_bastion="${1:-false}"

    local env="$TF_VAR_ENVIRONMENT"
    local project_root="${PROJECT_ROOT:-$PWD}"

    local terraform_dir="${project_root}/infra"
    local terraform_vars_file="${terraform_dir}/envs/$env/terraform.tfvars"

    echo "--- Executing Terraform Destroy ---"

    if [ ! -d "$terraform_dir" ]; then
      echo "Error: Terraform directory '$terraform_dir' not found."
      exit 1
    fi

    if [ ! -f "$terraform_vars_file" ]; then
      echo "Error: Terraform variables file '$terraform_vars_file' not found for environment '$env'. Create it."
      exit 1
    fi

    echo "Navigating to Terraform directory: $terraform_dir"
    (
        cd "$terraform_dir" || exit 1

        tf_init_and_workspace

        echo "Destroying Terraform infrastructure..."
        terraform destroy \
            -var-file="${terraform_vars_file}" \
            -var="account_username=${TF_VAR_USERNAME}" \
            -var="project=${TF_VAR_PROJECT_NAME}" \
            -var="region=${TF_VAR_REGION}" \
            -var="create_bastion_host=$create_bastion" \
            -auto-approve
    )
    echo "Terraform destroy completed."
}