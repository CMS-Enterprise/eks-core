# Souce this in other scripts to get common utility function

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
