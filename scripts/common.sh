# Source this in other scripts to get common utility function

# Set logging functions for colored output
red() { echo -e "\033[0;31m${*}\033[0m"; } >&2
green() { echo -e "\033[0;32m${*}\033[0m"; } >&2
yellow() { echo -e "\033[0;33m${*}\033[0m"; } >&2

# Prompt a user for a yes/no response, defaulting to yes in a CI/CD environment
# Any arguments will be used to form the prompt string
prompt_yn() {
  local reply="unset"
  local prompt="Proceed?"

  # automatically return y if in the CI/CD environment
  if [[ "${RUNNING_IN_CICD}" == "true" ]]; then
    echo "y"
    return 0
  fi

  # Build the prompt if arguments were given
  if [ ${#} -gt 0 ]; then
    prompt=$(echo -e "${*}")
  fi

  # Prompt for a response and wait for a valid
  while [ ${reply} != "y" -a ${reply} != "n" ]; do
    read -r -p "${prompt} (y/n): " reply
    reply=$(echo "${reply:0:1}" | tr '[:upper:]' '[:lower:]')
  done

  # Print the caller's reply
  echo "${reply}"

  # Set the return code to 0 on 'y' and 1 on 'n'
  [ "${reply}" = "y" ]
}

# Handle configuration files
declare -A config

# Parse the configuration file
parse_config() {
  # abort if no file passed
  if [ ${#} -eq 0 ]; then
    return 0
  fi

  # error if file not readable (or not a regular file)
  if ! [ -r "${1}" ]; then
    echo "Cannot read configuration from \"${1}\"" >&2
    return 1
  fi

  # Read each line in the file splitting on the first =
  while IFS= read -r line; do
    local key=$(echo ${line} | cut -d= -f1)
    local value=$(echo ${line} | cut -d= -f2-)
    config["${key}"]="${value}"
  # While reading strip lines that are empty, only whitespace, or comments
  done < <(grep -vE '^[[:space:]]*(#|$)' "${1}")
}

# Save configuration to the specified file
save_config() {
  if [ ${#} -lt 1 ]; then
    red "No configuration file path provided. Configuration not saved."
    return 1
  fi

  local output_file="${1}"

  echo "# Auto-generated configuration file - Created $(date +%FT%T)" > "${output_file}"
  if [ ${?} -ne 0 ]; then
    red "Could not write to \"${config_file}\". Configuration not saved,"
    return 1
  fi

  # Save each value in the configuration array
  for key in "${!config[@]}"; do
    echo "${key}=${config[${key}]}" >> "${output_file}"
  done
}
