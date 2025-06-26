# scripts/efs_actions.sh

# Function to update a file on EFS via bastion host
# Args:
#   $@: All arguments passed to update-efs-file (local_file_path efs_relative_path)
#   $LAST_ARG_IS_PROJECT_ROOT: PROJECT_ROOT
#   $LAST_ARG_IS_ENVIRONMENT: ENVIRONMENT
#   $LAST_ARG_IS_PROJECT_NAME: PROJECT_NAME
#   $LAST_ARG_IS_REGION: TF_BACKEND_REGION
#   $LAST_ARG_IS_BUCKET: TF_BACKEND_BUCKET
#   $LAST_ARG_IS_KEY: TF_BACKEND_KEY
#   $LAST_ARG_IS_DYNAMODB: TF_AWS_LOCK_DYNAMODB_TABLE
execute_efs_file_update() {
    # Extract arguments passed from run.sh
    local local_file_path="$1"
    local efs_relative_path="$2"
    # Shift twice to get remaining arguments, then extract specific ones
    shift 2
    local project_root="$1"
    local env="$2"
    local project_name="$3"
    local region="$4"
    local bucket="$5"
    local key="$6"
    local dynamodb_table="$7"

    if [ -z "$local_file_path" ] || [ -z "$efs_relative_path" ]; then
      echo "Error: Missing arguments for 'update-efs-file' action."
      usage # Call usage from run.sh
    fi

    echo "--- Updating file on EFS via Bastion Host ---"

    # Resolve full path of the local file
    local_file_full_path="${project_root}/${local_file_path}"
    if [ ! -f "$local_file_full_path" ]; then
      echo "Error: Local file not found at '$local_file_full_path'."
      exit 1
    fi

    # Determine EFS mount point on the EC2 instance
    EFS_MOUNT_POINT_ON_EC2="/mnt/efs"
    EFS_TARGET_FULL_PATH="${EFS_MOUNT_POINT_ON_EC2}/${project_name}/${efs_relative_path}"

    local bastion_id=""
    if ! bastion_id=$(get_bastion_instance_id_from_tf "$project_root" "$env" "$bucket" "$key" "$region" "$dynamodb_table"); then
      echo "Bastion host not found. Creating temporary bastion host..."
      # Call the up-bastion action directly from the main run.sh logic
      # Using a subshell to avoid changing main script's directory/state
      (
          "${project_root}/run.sh" up-bastion
      )
      
      echo "Waiting for bastion host to become available (up to 60 seconds)..."
      local max_attempts=12
      local attempt=0
      local found_bastion=false
      while [ "$attempt" -lt "$max_attempts" ]; do
          if bastion_id=$(get_bastion_instance_id_from_tf "$project_root" "$env" "$bucket" "$key" "$region" "$dynamodb_table"); then
              echo "Bastion host is now available: $bastion_id"
              found_bastion=true
              break
          fi
          echo "Still waiting for bastion host... (attempt $((attempt+1))/$max_attempts)"
          sleep 5
          attempt=$((attempt+1))
      done

      if [ "$found_bastion" = false ]; then
          echo "Critical Error: Bastion host was not created or its ID could not be obtained after multiple attempts."
          exit 1
      fi
    fi

    echo "Using bastion host ID: $bastion_id"
    echo "Local file: $local_file_full_path"
    echo "Target EFS path on bastion: $EFS_TARGET_FULL_PATH"

    # 1. Copy the local file to the EC2 instance's /tmp directory
    echo "Copying '$local_file_full_path' to '$bastion_id':/tmp/$(basename "$local_file_full_path")..."
    aws ssm scp "${local_file_full_path}" "${bastion_id}":/tmp/ --region "${region}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy file to bastion instance using ssm scp."
        exit 1
    fi

    # 2. Execute commands on the bastion instance to move the file to EFS, set permissions, and restart Nginx
    echo "Moving file to EFS and adjusting permissions/owner on bastion host, then restarting Nginx..."
    aws ssm send-command \
        --instance-ids "$bastion_id" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\
            \"sudo mkdir -p $(dirname "$EFS_TARGET_FULL_PATH")\", \
            \"sudo mv /tmp/$(basename "$local_file_full_path") $EFS_TARGET_FULL_PATH\", \
            \"sudo chmod 644 $EFS_TARGET_FULL_PATH\", \
            \"sudo chown nginx:nginx $EFS_TARGET_FULL_PATH\", \
            \"sudo systemctl daemon-reload && sudo systemctl restart nginx\"\
        ]" \
        --region "${region}" \
        --output text
    if [ $? -ne 0 ]; then
        echo "Error: Failed to execute commands on bastion instance via ssm send-command."
        exit 1
    fi

    echo "File updated on EFS and Nginx restarted successfully via bastion host."

    # Step 3: Tear down the bastion host after the operation
    echo "Tearing down the bastion host after the operation..."
    (
        "${project_root}/run.sh" down-bastion
    )
}