#!/usr/bin/env bash

# Parent directory of this script
SCRIPT_DIR=$(realpath $(dirname $0))

# Source common function
source "${SCRIPT_DIR}"/common.sh

# Check if a configuration file was given
if [ $# -ge 1 ]; then
  config_file="${1}"
  if ! parse_config "${config_file}"; then
    red "Failed to read configuration from \"${config_file}\". Exiting."
    exit 1
  fi
fi

# Read configuration file if provided (default to environment value if not specified)
if [ -f "${config_file}" ] ;then
  account_name="${config[account_name]:-${ACCOUNT_NAME}}"
  account_id="${config[account_id]:-${ACCOUNT_ID}}"
  aws_role_arn="${config[aws_role_arn]:-${AWS_ROLE_ARN}}"
  aws_profile="${config[aws_profile]:-${AWS_PROFILE}}"
# Otherwise, if running in CI/CD environment
elif [[ "${RUNNING_IN_CICD}" == "true" ]]; then
  account_name="${ACCOUNT_NAME}"
  account_id="${ACCOUNT_ID}"
  aws_role_arn="${AWS_ROLE_ARN}"
# Prompt user for AWS account details
else
  read -r -p "Enter the AWS account name: " account_name
  read -r -p "Enter the AWS account number: " account_id
  read -r -p "Enter the AWS role name: " role_name
  read -r -p "Enter the AWS profile: " profile_name
  # Define the AWS role to assume
  aws_role_arn="arn:aws:iam::${account_id}:role/${role_name}"
  # Define the AWS profile to use
  aws_profile="${profile_name}"
  # Prompt to save the config
  if [[ $(prompt_yn "Save this configuration?") == "y" ]]; then
    config[account_name]="${account_name}"
    config[account_id]="${account_id}"
    config[aws_role_arn]="${aws_role_arn}"
    config[aws_profile]="${aws_profile}"
    save_config default.cfg
  fi
fi

# Function to assume role and execute terraform
assume_role_and_execute_terraform() {
  green "Assuming role for account: ${account_name} (${account_id})"

  # Assume the role
  if [[ "${RUNNING_IN_CICD}" == "true" ]]; then
    credentials=$(aws sts assume-role \
      --role-arn "${aws_role_arn}" \
      --role-session-name "TerraformSession" \
      --output json)
  else
    credentials=$(aws sts assume-role \
      --role-arn "${aws_role_arn}" \
      --role-session-name "TerraformSession" \
      --profile "${aws_profile}" \
      --output json)
  fi

  if ! echo "${credentials}" | jq -e . >/dev/null 2>&1; then
    red "Failed to assume role for account: ${account_name} (${account_id})"
    return 1
  fi

  # Extract credentials
  access_key=$(echo "${credentials}" | jq -r '.Credentials.AccessKeyId')
  secret_key=$(echo "${credentials}" | jq -r '.Credentials.SecretAccessKey')
  session_token=$(echo "${credentials}" | jq -r '.Credentials.SessionToken')

  # Check that credentials were successfully extracted
  if [ -z "${access_key}" -o -z "${secret_key}" -o -z "${session_token}" ]; then
    red "Failed to extract access credentials for ${account_name} (${account_id}). Exiting."
    return 1
  fi

  # Export credentials as environment variables
  export AWS_ACCESS_KEY_ID="${access_key}"
  export AWS_SECRET_ACCESS_KEY="${secret_key}"
  export AWS_SESSION_TOKEN="${session_token}"

  # Check if Terraform workspace exists, create if it does not
  if ! terraform workspace select "${account_name}" 2>/dev/null; then
    yellow "Terraform workspace ${account_name} does not exist. Creating it."
    if ! terraform workspace new "${account_name}"; then
      red "Failed to create Terraform workspace ${account_name}. Exiting."
      return 1
    fi
  fi

  # Execute Terraform commands
  green "Initializing Terraform for account: ${account_name} (${account_id})"
  if ! terraform init --upgrade; then
    red "Terraform initialization failed for account: ${account_name} (${account_id})"
    return 1
  fi

  green "Planning Terraform changes for account: ${account_name} (${account_id})"
  if ! terraform plan -out=tfplan; then
    red "Terraform plan failed for account: ${account_name} (${account_id})"
    return 1
  fi

  continue_apply=$(prompt_yn "Do you want to apply the changes?")

  if [[ "${continue_apply}" == "y" ]]; then
    green "Applying Terraform changes for account: ${account_name} (${account_id})"
    if ! terraform apply -auto-approve tfplan; then
      red "Terraform execution failed for account: ${account_name} (${account_id})"
      return 1
    fi
    green "Terraform execution succeeded for account: ${account_name} (${account_id})"
  else
    yellow "Terraform apply canceled for account: ${account_name} (${account_id})"
  fi

  return 0
}

# Execute the function for the provided account details
if ! assume_role_and_execute_terraform; then
  yellow "Warning: Issues encountered for account: ${account_name} (${account_id})"
fi

# Unset the AWS credentials to avoid accidental misuse
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
