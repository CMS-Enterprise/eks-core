#!/usr/bin/env bash

#######################################################
# Load the bash-my-aws repository as a dependency
# for the QA Testing environment

load_use_bash-my-aws() {

  local CURRENT_DIR
  local PACKAGE_NAME
  local GIT_ORIGIN

  CURRENT_DIR=$(pwd)

  source "$(git rev-parse --show-toplevel)/qa_testing/scripts/gen_lib_funcs_vars.sh"

  PACKAGE_NAME="bash-my-aws"
  GIT_ORIGIN="https://github.com/bash-my-aws/bash-my-aws.git"
  MSG_EXEC "Loading Dependency Library: '$(txt_teal "${PACKAGE_NAME}")'"

  BMA_HOME="${QA_THIRD_PARTY_DIR}/${PACKAGE_NAME}"
  export PATH="$PATH:${BMA_HOME}/bin"
  # Disables columns display output because it's running in
  # a non-interactive shell, output to be formatted in
  # columns (which can be difficult to parse programmatically)
  export BMA_COLUMNISE_ONLY_WHEN_TERMINAL_PRESENT=false
  source "${BMA_HOME}"/aliases

  cd "${QA_THIRD_PARTY_DIR}" || { MSG_ERRR "Failed to change directory to QA_THIRD_PARTY_DIR: '$(txt_d_yellow "${QA_THIRD_PARTY_DIR}")'"; exit 1; }

  # Check if the repository directory already exists
  if [ -d "${PACKAGE_NAME}" ]; then
      MSG_EXEC "Repository '$(txt_teal "${PACKAGE_NAME}")' already exists, updating from $(txt_yellow "${GIT_ORIGIN}")..."
      cd "${PACKAGE_NAME}" || { MSG_ERRR "Failed to change directory to '$(txt_d_yellow "${PACKAGE_NAME}")'"; exit 1; }
      # Check if repo origin matches the expected origin, then pull
      if [ "$(git remote -v | grep 'origin.*fetch' | awk '{print $2}')" != "${GIT_ORIGIN}" ]; then
        MSG_WARN "Expected origin does not match specified $(txt_yellow "${GIT_ORIGIN}")..."
      fi
      git pull origin master
  else
      MSG_EXEC "Cloning '$(txt_teal "${PACKAGE_NAME}")' from $(txt_yellow "${GIT_ORIGIN}")..."
      git clone "${GIT_ORIGIN}" "${BMA_HOME}"
      source "${BMA_HOME}/bash_completion.sh"
  fi

  cd "${CURRENT_DIR}" || { MSG_ERRR "Failed to change directory back to '$(txt_d_yellow "${CURRENT_DIR}")'"; exit 1; }

}

#######################################################
# Load the bash-my-aws repository as a dependency
load_use_bash-my-aws
