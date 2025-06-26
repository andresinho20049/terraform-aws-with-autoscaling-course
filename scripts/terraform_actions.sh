# scripts/terraform_actions.sh

# Function to execute Terraform apply
# Args:
#   $1: ENVIRONMENT
#   $2: PROJECT_ROOT
#   $3: USERNAME
#   $4: TF_BACKEND_KEY (used as 'project' var)
#   $5: SSH_KEY_NAME
#   $6: TF_BACKEND_BUCKET
#   $7: TF_BACKEND_KEY
#   $8: TF_BACKEND_REGION
#   $9: TF_AWS_LOCK_DYNAMODB_TABLE
#   $10: CREATE_BASTION_HOST
execute_terraform_apply() {
    local env="$1"
    local project_root="$2"
    local username="$3"
    local project_name_var="$4"
    local key_name="$5"
    local bucket="$6"
    local key="$7"
    local region="$8"
    local dynamodb_table="$9"
    local create_bastion="${10}"

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

        tf_init_and_workspace "$env" "$terraform_dir" "$bucket" "$key" "$region" "$dynamodb_table"

        echo "Planning Terraform infrastructure..."
        mkdir -p "$terraform_plan_dir"
        terraform plan \
            -var-file="${terraform_vars_file}" \
            -var="account_username=$username" \
            -var="project=$project_name_var" \
            -var="key_name=$key_name" \
            -var="create_bastion_host=$create_bastion" \
            -out="$terraform_plan_file"

        echo "Applying Terraform infrastructure..."
        terraform apply "$terraform_plan_file"
    )
    echo "Terraform apply completed."
}

# Function to execute Terraform destroy
# Args:
#   $1: ENVIRONMENT
#   $2: PROJECT_ROOT
#   $3: USERNAME
#   $4: TF_BACKEND_KEY (used as 'project' var)
#   $5: SSH_KEY_NAME
#   $6: TF_BACKEND_BUCKET
#   $7: TF_BACKEND_KEY
#   $8: TF_BACKEND_REGION
#   $9: TF_AWS_LOCK_DYNAMODB_TABLE
#   $10: CREATE_BASTION_HOST
execute_terraform_destroy() {
    local env="$1"
    local project_root="$2"
    local username="$3"
    local project_name_var="$4" # This is TF_BACKEND_KEY, used as 'project' var
    local key_name="$5"
    local bucket="$6"
    local key="$7"
    local region="$8"
    local dynamodb_table="$9"
    local create_bastion="${10}"

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

        tf_init_and_workspace "$env" "$terraform_dir" "$bucket" "$key" "$region" "$dynamodb_table"

        echo "Destroying Terraform infrastructure..."
        # Pass create_bastion_host=0 for destroy to explicitly target bastion removal if it exists.
        terraform destroy \
            -var-file="${terraform_vars_file}" \
            -var="account_username=$username" \
            -var="project=$project_name_var" \
            -var="key_name=$key_name" \
            -var="create_bastion_host=$create_bastion" \
            -auto-approve # Auto-approve for simpler destroy via script
    )
    echo "Terraform destroy completed."
}