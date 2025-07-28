# scripts/efs_actions.sh

# Function to update files/directories on EFS via bastion host
# Args:
#   $1: local_source_path (can be a file or a directory, relative to project_root)
#   $2: efs_base_target_path (base directory on EFS, relative to /mnt/efs/<project_name>/)
execute_efs_file_update() {
    if [ $# -lt 2 ]; then
        echo "Error: Missing arguments for 'update-efs-file' action. Usage: ./run.sh update-efs-file <local_path> <efs_target_path>" >&2
        exit 1
    fi
    local local_source_path="$1"
    local efs_base_target_path="$2"
    
    shift 2 # Remove the first two arguments to access remaining ones
    local project_root="${PROJECT_ROOT:-$PWD}"
    local env="$TF_VAR_ENVIRONMENT"
    local project_name="$TF_VAR_PROJECT_NAME"
    local username="$TF_VAR_USERNAME"
    local region="$TF_VAR_REGION"
    
    if [ -z "$local_source_path" ] || [ -z "$efs_base_target_path" ]; then
      echo "Error: Missing arguments for 'update-efs-file' action. Usage: ./run.sh update-efs-file <local_path> <efs_target_path>" >&2
      exit 1
    fi

    echo "--- Updating content on EFS via Bastion Host ---"

    # Resolve full path of the local source (file or directory)
    local_full_source_path="${project_root}/${local_source_path}"
    if [ ! -e "$local_full_source_path" ]; then # Use -e for existence of file or directory
      echo "Error: Local source path not found at '$local_full_source_path'." >&2
      exit 1
    fi

    # Determine EFS mount point on the EC2 instance
    local EFS_MOUNT_POINT_ON_EC2="/mnt/efs"
    # The base path on EFS will be /mnt/efs/<project_name>/<efs_base_target_path>
    local EFS_FINAL_BASE_PATH="${EFS_MOUNT_POINT_ON_EC2}/${project_name}/${efs_base_target_path}"

    local local_file_md5=""
    if [ -f "$local_full_source_path" ]; then
        if command -v md5sum >/dev/null 2>&1; then
            local_file_md5=$(md5sum "$local_full_source_path" | awk '{print $1}')
            echo "Local file MD5: $local_file_md5"
        elif command -v md5 >/dev/null 2>&1; then # macOS compatibility
            local_file_md5=$(md5 "$local_full_source_path" | awk '{print $NF}')
            echo "Local file MD5 (macOS): $local_file_md5"
        else
            echo "Warning: md5sum or md5 command not found. Cannot perform MD5 hash check for idempotency for single files." >&2
        fi
    fi

    local bastion_id=""
    # Attempt to get bastion ID. If not found, create it.
    if ! bastion_id=$(get_bastion_instance_id_from_tf); then
      echo "Bastion host not found. Creating temporary bastion host..."
      (
          # Execute up-bastion in a subshell to avoid affecting current script's directory/state
          "${project_root}/run.sh" up-bastion
      )
      
      echo "Waiting for bastion host to become available (up to 60 seconds)..."
      local max_attempts=12
      local attempt=0
      local found_bastion=false
      while [ "$attempt" -lt "$max_attempts" ]; do
          if bastion_id=$(get_bastion_instance_id_from_tf); then
              echo "Bastion host is now available: $bastion_id"
              found_bastion=true
              break
          fi
          attempt=$((attempt+1))
          echo "Still waiting for bastion host... (attempt $((attempt))/$max_attempts)" >&2
          sleep 5
      done

      if [ "$found_bastion" = false ]; then
          echo "Critical Error: Bastion host was not created or its ID could not be obtained after multiple attempts." >&2
          exit 1
      fi
    fi

    echo "Using bastion host ID: $bastion_id"
    echo "Local source path: $local_full_source_path"
    echo "Target EFS base path: $EFS_FINAL_BASE_PATH"

    # Define temporary S3 bucket and key prefix for upload
    local s3_temp_bucket="${username}.${region}.s3.bhc-temp.${env}"
    local s3_key_prefix="efs-temp/${project_name}/$(date +%s)/" # Prefix for the temporary S3 directory

    # --- START: S3 Bucket Existence Check (Performed BEFORE upload) ---
    echo "Checking if temporary S3 bucket '$s3_temp_bucket' exists..."
    if ! aws s3api head-bucket --bucket "$s3_temp_bucket" --region "$region" 2>/dev/null; then
        echo "Error: Temporary S3 bucket '$s3_temp_bucket' does not exist or you don't have permissions." >&2
        echo "Please ensure the bucket is created and your AWS credentials have s3:ListBucket and s3:HeadBucket permissions." >&2
        exit 1
    fi
    echo "Temporary S3 bucket exists."
    # --- END: S3 Bucket Existence Check ---

    echo "Uploading local content to temporary S3 bucket: s3://$s3_temp_bucket/$s3_key_prefix"

    # Conditional upload based on source type (directory or file)
    if [ -d "$local_full_source_path" ]; then
        aws s3 sync "$local_full_source_path" "s3://$s3_temp_bucket/$s3_key_prefix" --region "$region"
        if [ $? -ne 0 ]; then
            echo "Error uploading directory to S3." >&2
            exit 1
        fi
        echo "Directory uploaded successfully to S3."
    elif [ -f "$local_full_source_path" ]; then
        aws s3 cp "$local_full_source_path" "s3://$s3_temp_bucket/${s3_key_prefix}$(basename "$local_full_source_path")" --region "$region"
        if [ $? -ne 0 ]; then
            echo "Error uploading file to S3." >&2
            exit 1
        fi
        echo "File uploaded successfully to S3."
    else
        echo "Error: local_source_path '$local_full_source_path' is neither a file nor a directory." >&2
        exit 1
    fi

    local remote_commands=""
    local remote_efs_target_path_escaped="\\\"$EFS_FINAL_BASE_PATH\\\""

    # Construct remote commands based on source type for idempotency
    if [ -d "$local_full_source_path" ]; then
        # For directories, 'aws s3 sync' handles idempotency by only copying changed files.
        # Ensure target directory and permissions are correct.
        remote_commands="sudo mkdir -p ${remote_efs_target_path_escaped}; \\
            aws s3 sync \\\"s3://$s3_temp_bucket/$s3_key_prefix\\\" ${remote_efs_target_path_escaped}; \\
            sudo chmod -R 644 ${remote_efs_target_path_escaped}; \\
            sudo find ${remote_efs_target_path_escaped} -type d -exec sudo chmod 755 {} +; \\
            sudo chown -R nginx:nginx ${remote_efs_target_path_escaped}; \\
            aws s3 rm \\\"s3://$s3_temp_bucket/$s3_key_prefix\\\" --recursive"
    elif [ -f "$local_full_source_path" ]; then
        local remote_efs_file_path="${EFS_FINAL_BASE_PATH}" # This now represents the full path including filename on EFS
        local remote_s3_file_url="s3://$s3_temp_bucket/${s3_key_prefix}$(basename "$local_full_source_path")"
        
        # Commands to check MD5 on EFS and then copy if different, ensuring idempotency
        remote_commands="
            LOCAL_FILE_MD5=\"$local_file_md5\";
            EFS_FILE_PATH=\\\"$remote_efs_file_path\\\";
            S3_FILE_URL=\\\"$remote_s3_file_url\\\";
            
            # Ensure target directory on EFS exists
            sudo mkdir -p \\\"$(dirname "$remote_efs_file_path")\\\";

            # Get MD5 of file on EFS, if it exists, suppress errors if file not found
            EFS_CURRENT_MD5=\"\$(sudo md5sum \"\$EFS_FILE_PATH\" 2>/dev/null | awk '{print \$1}')\";

            if [ \"\$LOCAL_FILE_MD5\" = \"\$EFS_CURRENT_MD5\" ]; then
                echo \\\"File on EFS is already up to date (\$LOCAL_FILE_MD5). Skipping copy.\\\";
            else
                echo \\\"File on EFS is different or does not exist. Copying from S3... (Local MD5: \\\"\$LOCAL_FILE_MD5\\\", EFS MD5: \\\"\${EFS_CURRENT_MD5}\\\")\\\";
                aws s3 cp \"\$S3_FILE_URL\" \"\$EFS_FILE_PATH\";
                sudo chmod 644 \"\$EFS_FILE_PATH\";
                sudo chown nginx:nginx \"\$EFS_FILE_PATH\";
            fi;
            aws s3 rm \"\$S3_FILE_URL\"; # Clean up S3 temporary file regardless of copy
        "
        # Escaping inner quotes for the SSM command
        remote_commands=$(echo "$remote_commands" | sed 's/"/\\\"/g')
    fi

    if [ -z "$remote_commands" ]; then
        echo "Error: No remote commands generated. Check local_source_path type." >&2
        exit 1
    fi

    echo "Running remote commands on bastion to download from S3, move to EFS, adjust permissions, and clean up S3..."

    # Send command and capture CommandId
    local ssm_output
    ssm_output=$(aws ssm send-command \
        --instance-ids "$bastion_id" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$remote_commands\"]" \
        --region "$region" \
        --output json)
    if [ $? -ne 0 ]; then
        echo "Error running commands on bastion via SSM." >&2
        exit 1
    fi
    local command_id
    command_id=$(echo "$ssm_output" | grep -oP '"CommandId":\s*"\K[^"]+')
    if [ -z "$command_id" ]; then
        echo "Error: Could not retrieve SSM CommandId." >&2
        exit 1
    fi

    echo "Waiting for SSM command ($command_id) to complete on bastion..."
    local status="Pending"
    local max_wait=60
    local waited=0
    while [ "$status" = "Pending" ] || [ "$status" = "InProgress" ]; do
        status=$(aws ssm list-command-invocations \
            --command-id "$command_id" \
            --details \
            --region "$region" \
            --query "CommandInvocations[0].Status" \
            --output text)
        if [ "$status" = "Success" ]; then
            break
        elif [ "$status" = "Failed" ] || [ "$status" = "Cancelled" ] || [ "$status" = "TimedOut" ]; then
            echo "Error: SSM command failed with status: $status" >&2
            exit 1
        fi
        sleep 2
        waited=$((waited+2))
        if [ $waited -ge $max_wait ]; then
            echo "Error: SSM command did not complete within $max_wait seconds." >&2
            exit 1
        fi
    done

    echo "Content updated on EFS via bastion host using temporary S3 bucket."

    echo "--- Starting Instance Refresh for the Auto Scaling Group ---"
    local asg_name=""
    if ! asg_name=$(get_asg_name_from_tf); then
        echo "Critical Error: Could not retrieve Auto Scaling Group name. Skipping instance refresh." >&2
    else
        echo "Triggering instance refresh for ASG: $asg_name"
        aws autoscaling start-instance-refresh \
            --auto-scaling-group-name "$asg_name" \
            --region "$region" \
            --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 180}'
        
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to start instance refresh for ASG '$asg_name'. Please check AWS console." >&2
        else
            echo "Instance refresh started successfully. New instances will be launched to replace old ones."
        fi
    fi

    # Tear down the bastion host after the operation
    echo "Tearing down the bastion host after the operation..."
    (
        "${project_root}/run.sh" down-bastion
    )
}