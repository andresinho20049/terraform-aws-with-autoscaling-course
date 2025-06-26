# scripts/packer_actions.sh

# Function to execute Packer build
# Args:
#   $1: ENVIRONMENT
#   $2: PROJECT_ROOT
execute_packer_build() {
    local env="$1"
    local project_root="$2"
    local packer_dir="${project_root}/packer/ami-templates/nginx-webserver"
    local packer_vars_file="${project_root}/packer/envs/$env/$env.pkrvars.hcl"

    echo "--- Executing Packer ---"

    if [ ! -d "$packer_dir" ]; then
      echo "Error: Packer directory '$packer_dir' not found. Please check your project structure."
      exit 1
    fi

    if [ ! -f "$packer_vars_file" ]; then
      echo "Error: Packer variables file '$packer_vars_file' not found for environment '$env'. Create it."
      exit 1
    fi

    echo "Navigating to Packer directory: $packer_dir"
    ( # Subshell to avoid changing directory for the main script
        cd "$packer_dir" || exit 1
        echo "Initializing Packer..."
        packer init .

        echo "Building AMI with Packer for environment: $env"
        packer build -var-file="${packer_vars_file}" .
    )
    echo "Packer execution completed."
}