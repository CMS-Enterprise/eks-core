#!/usr/bin/env bash

#######################################################
# Load the KubeLibrary repository as a dependency
# for the QA Testing environment

load_use_KubeLibrary() {

  local CURRENT_DIR
  local PACKAGE_NAME
  local GIT_ORIGIN
  local DEFAULT_BRANCH

  CURRENT_DIR=$(pwd)

  source "$(git rev-parse --show-toplevel)/qa_testing/scripts/gen_lib_funcs_vars.sh"

  PACKAGE_NAME="KubeLibrary"
  GIT_ORIGIN="https://github.com/devopsspiral/KubeLibrary.git"
  DEFAULT_BRANCH="main"  # Change to "master" if your repository uses the "master" branch

  MSG_EXEC "Loading Dependency Library: '$(txt_teal "${PACKAGE_NAME}")'"

  cd "${QA_THIRD_PARTY_DIR}" || { MSG_ERRR "Failed to change directory to QA_THIRD_PARTY_DIR: '$(txt_d_yellow "${QA_THIRD_PARTY_DIR}")'"; exit 1; }

  # Check if the repository directory already exists
  if [ -d "${PACKAGE_NAME}" ]; then
      MSG_EXEC "Repository '$(txt_teal "${PACKAGE_NAME}")' already exists, updating from $(txt_yellow "${GIT_ORIGIN}")..."
      cd "${PACKAGE_NAME}" || { MSG_ERRR "Failed to change directory to '$(txt_d_yellow "${PACKAGE_NAME}")'"; exit 1; }
      git pull origin "${DEFAULT_BRANCH}"
  else
      MSG_EXEC "Cloning '$(txt_teal "${PACKAGE_NAME}")' from $(txt_yellow "${GIT_ORIGIN}")..."
      git clone "${DEFAULT_BRANCH}" "${GIT_ORIGIN}"
  fi

  cd "${CURRENT_DIR}" || { MSG_ERRR "Failed to change directory back to '$(txt_d_yellow "${CURRENT_DIR}")'"; exit 1; }
  MSG_SUCS "Repo cloned or updated complete..."

}

#######################################################
# Load the KubeLibrary repository as a dependency
load_use_KubeLibrary
