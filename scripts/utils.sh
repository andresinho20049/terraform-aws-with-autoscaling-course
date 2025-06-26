# scripts/utils.sh

# Função para inicializar o Terraform backend e selecionar o workspace.
# Esta função deve ser chamada no ESCOPO PRINCIPAL do script (ou antes de qualquer operação Terraform
# que precise do estado inicializado).
# Args:
#   $1: ENVIRONMENT
#   $2: TERRAFORM_DIR (diretório onde main.tf está)
#   $3: TF_BACKEND_BUCKET
#   $4: TF_BACKEND_KEY
#   $5: TF_BACKEND_REGION
#   $6: TF_AWS_LOCK_DYNAMODB_TABLE
tf_init_and_workspace() {
    local env="$1"
    local tf_dir="$2"
    local bucket="$3"
    local key="$4"
    local region="$5"
    local dynamodb_table="$6"

    # verify if required arguments are provided
    cd "$tf_dir" || { echo "Erro: Não foi possível navegar para $tf_dir" >&2; return 1; }

    echo "Inicializando Terraform backend para o ambiente '$env'..."
    
    if ! terraform init \
        -reconfigure \
        -backend-config="bucket=$bucket" \
        -backend-config="key=$key" \
        -backend-config="region=$region" \
        -backend-config="dynamodb_table=$dynamodb_table" \
        -input=false \
        -no-color; then
      echo "Erro: terraform init falhou para o ambiente '$env'." >&2
      return 1
    fi

    echo "Selecionando ou criando Terraform workspace: $env..."
    
    if ! terraform workspace select "$env" -no-color > /dev/null 2>&1; then
      if ! terraform workspace new "$env" -no-color > /dev/null 2>&1; then
        echo "Erro: Não foi possível selecionar nem criar o workspace '$env'." >&2
        return 1
      fi
      echo "Workspace '$env' criado e selecionado."
    else
      echo "Workspace '$env' selecionado."
    fi

    return 0 # Indica sucesso
}


# Args:
#   $1: PROJECT_ROOT
#   $2: ENVIRONMENT
#   $3: TF_BACKEND_BUCKET
#   $4: TF_BACKEND_KEY
#   $5: TF_BACKEND_REGION
#   $6: TF_AWS_LOCK_DYNAMODB_TABLE
get_bastion_instance_id_from_tf() {
    local project_root="$1"
    local env="$2"
    local bucket="$3"
    local key="$4"
    local region="$5"
    local dynamodb_table="$6"
    local terraform_dir="${project_root}/infra"
    local bastion_id=""
    local return_code=1 # Default to failure

    bastion_id=$(
        cd "$terraform_dir" || { echo "Erro: Não foi possível navegar para $terraform_dir dentro de get_bastion_instance_id_from_tf." >&2; exit 1; }

        if ! terraform init \
            -reconfigure \
            -backend-config="bucket=$bucket" \
            -backend-config="key=$key" \
            -backend-config="region=$region" \
            -backend-config="dynamodb_table=$dynamodb_table" \
            -input=false \
            -no-color > /dev/null 2>&1; then
            echo "Erro: terraform init falhou dentro de get_bastion_instance_id_from_tf." >&2
            exit 1 # Sai do subshell com erro
        fi

        if ! terraform workspace select "$env" -no-color > /dev/null 2>&1; then
            # Tenta criar se não existe, mas aqui o workspace já deveria existir
            # se a infra principal foi aplicada.
            # Se for um erro de verdade, propaga.
            echo "Erro: terraform workspace select $env falhou dentro de get_bastion_instance_id_from_tf." >&2
            exit 1 # Sai do subshell com erro
        fi

        terraform output -raw bastion_instance_id 2>/dev/null || echo ""
    )

    if [ -z "$bastion_id" ]; then
        echo "Bastion host instance ID not found in Terraform outputs. It might not be created yet." >&2
        return 1 # Indica falha
    fi

    echo "Found bastion instance ID: $bastion_id"
    echo "$bastion_id" 
    return 0 
}