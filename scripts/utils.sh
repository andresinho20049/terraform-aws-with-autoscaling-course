# scripts/utils.sh

# Function to initialize the Terraform backend and select the workspace.
# This function should be called in the MAIN SCOPE of the script (or before any Terraform operation
# that needs the state initialized).
tf_init_and_workspace() {
    local project_root="${PROJECT_ROOT:-$PWD}"
    local env="$TF_VAR_ENVIRONMENT"
    local backend_s3_region="$TF_BACKEND_REGION"
    local backend_s3_bucket="$TF_BACKEND_BUCKET" 
    local backend_s3_key="$TF_BACKEND_KEY"    
    local dynamodb_table="$TF_AWS_LOCK_DYNAMODB_TABLE"
    local tf_dir="${project_root}/infra"

    # verify if required arguments are provided
    cd "$tf_dir" || { echo "Error: Could not navigate to $tf_dir" >&2; return 1; }

    echo "Initializing Terraform backend for environment '$env'..."
    
    if ! terraform init \
        -reconfigure \
        -backend-config="bucket=$backend_s3_bucket" \
        -backend-config="key=$backend_s3_key" \
        -backend-config="region=$backend_s3_region" \
        -backend-config="dynamodb_table=$dynamodb_table" \
        -input=false \
        -no-color; then
      echo "Error: terraform init failed for environment '$env'." >&2
      return 1
    fi

    echo "Selecting or creating Terraform workspace: $env..."
    
    if ! terraform workspace select "$env" -no-color > /dev/null 2>&1; then
      if ! terraform workspace new "$env" -no-color > /dev/null 2>&1; then
        echo "Error: Could not select or create workspace '$env'." >&2
        return 1
      fi
      echo "Workspace '$env' created and selected."
    else
      echo "Workspace '$env' selected."
    fi

    return 0 # Indicates success
}

get_bastion_instance_id_from_tf() {
    local project_root="${PROJECT_ROOT:-$PWD}"
    local env="$TF_VAR_ENVIRONMENT"
    local backend_s3_region="$TF_BACKEND_REGION"
    local backend_s3_bucket="$TF_BACKEND_BUCKET" 
    local backend_s3_key="$TF_BACKEND_KEY"    
    local dynamodb_table="$TF_AWS_LOCK_DYNAMODB_TABLE"
    local terraform_dir="${project_root}/infra"
    local bastion_id=""

    bastion_id=$( 
        cd "$terraform_dir" || { echo "Error: Could not navigate to $terraform_dir inside get_bastion_instance_id_from_tf." >&2; exit 1; }

        if ! terraform init \
            -reconfigure \
            -backend-config="bucket=$backend_s3_bucket" \
            -backend-config="key=$backend_s3_key" \
            -backend-config="region=$backend_s3_region" \
            -backend-config="dynamodb_table=$dynamodb_table" \
            -input=false \
            -no-color > /dev/null 2>&1; then
            echo "Error: terraform init failed inside get_bastion_instance_id_from_tf." >&2
            exit 1
        fi

        if ! terraform workspace select "$env" -no-color > /dev/null 2>&1; then
            echo "Error: terraform workspace select $env failed inside get_bastion_instance_id_from_tf." >&2
            exit 1
        fi

        terraform output -raw bastion_instance_id 2>/dev/null || echo ""
    )

    if [ -z "$bastion_id" ]; then
        echo "Bastion host instance ID not found in Terraform outputs. It might not be created yet." >&2
        return 1
    fi

    echo "Found bastion instance ID: $bastion_id" >&2
    echo "$bastion_id" 
    return 0 
}

get_asg_name_from_tf() {
    local project_root="${PROJECT_ROOT:-$PWD}"
    local env="$TF_VAR_ENVIRONMENT"
    local backend_s3_region="$TF_BACKEND_REGION"
    local backend_s3_bucket="$TF_BACKEND_BUCKET" 
    local backend_s3_key="$TF_BACKEND_KEY"    
    local dynamodb_table="$TF_AWS_LOCK_DYNAMODB_TABLE"
    local terraform_dir="${project_root}/infra"
    local asg_name=""

    asg_name=$( 
        cd "$terraform_dir" || { echo "Error: Could not navigate to $terraform_dir inside get_asg_name_from_tf." >&2; exit 1; }

        # Initialization is required to ensure backend and workspace are correct
        # before trying to read the output.
        terraform init \
            -reconfigure \
            -backend-config="bucket=$backend_s3_bucket" \
            -backend-config="key=$backend_s3_key" \
            -backend-config="region=$backend_s3_region" \
            -backend-config="dynamodb_table=$dynamodb_table" \
            -input=false -no-color > /dev/null 2>&1

        if ! terraform workspace select "$env" -no-color > /dev/null 2>&1; then
            echo "Error: terraform workspace select $env failed inside get_asg_name_from_tf." >&2
            exit 1
        fi

        terraform output -raw autoscaling_group_name 2>/dev/null || echo ""
    )

    if [ -z "$asg_name" ]; then
        echo "Error: Auto Scaling Group name not found in Terraform outputs." >&2
        return 1 # Indicates failure
    fi

    echo "Found Auto Scaling Group name: $asg_name"
    echo "$asg_name"
    return 0
}