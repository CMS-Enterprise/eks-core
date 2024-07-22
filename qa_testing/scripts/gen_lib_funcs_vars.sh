#!/usr/bin/env bash

###########################################################
# This script defines global variables and functions to be
# sourced in other scripts for QA Testing.

# ShellCheck directive to suppress unused variable warnings
# shellcheck disable=SC2034

load_gen_lib_color_formats() {

  # Functions for determining script parameters, file name,
  # directory of script
  get_this_file_location() {
    cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd
  }

  # Dynamically get the absolute path to the current
  # repository root
  get_repo_root() {
    git rev-parse --show-toplevel
  }

  REPO_ROOT="$(get_repo_root)"

  # Target Directories used by this repo that QA Testing will
  # test against
  ROBOT_DIR="${REPO_ROOT}/robot"
  SCRIPTS_DIR="${REPO_ROOT}/scripts"
  THIRD_PARTY_DIR="${REPO_ROOT}/.3rd_party_tools"

  # QA Testing Directories used to perform testing against
  # the repo
  QA_DIR_NAME="qa_testing"
  QA_DIR="${REPO_ROOT}/${QA_DIR_NAME}"
  QA_ROBOT_DIR="${QA_DIR}/robot"
  QA_PYTHON_DIR="${QA_DIR}/python"
  QA_SCRIPTS_DIR="${QA_DIR}/scripts"
  QA_THIRD_PARTY_DIR="${QA_DIR}/.3rd_party_tools"

  # Source shared global general library of functions and
  # variables for QA Testing
  source "$(get_this_file_location)/gen_lib_color_formats.sh"

  # Command Status Legend
  MSG_NONE() { printf "%s %s\n" "   " "$1"; }
  MSG_INFO() { printf "%s %s\n" "[$(txt_yellow '*')] $(txt_yellow 'Info:')" "$1"; }
  MSG_EXEC() { printf "%s %s\n" "[$(txt_l_orange 'x')] $(txt_l_orange 'Execution:')" "$1"; }
  MSG_WARN() { printf "%s %s\n" "[$(txt_hotpink '!')] $(txt_hotpink 'Warning:')" "$1"; }
  MSG_ERRR() { printf "%s %s\n" "[$(txt_red '!')] $(txt_red 'Error:')" "$1"; }
  MSG_QUES() { printf "%s %s\n" "[$(txt_purple '?')] $(txt_purple 'Question:')" "$1"; }
  MSG_SUCS() { printf "%s %s\n" "[$(txt_b_green '+')] $(txt_b_green 'Success:')" "$1"; }

  # Function to pause execution and wait for user input
  pause() {
    read -s -n 1 -p "$(MSG_INFO "Press any key to continue . . . ")" && echo
  }

  # Function to prompt the user to continue or abort the script
  continue_yes_no() {
    local yn
    while true; do
      read -p "$(MSG_QUES "Do you wish proceed? (y/n)  ")" yn
      case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) MSG_WARN "Please answer yes or no.";;
      esac
    done
  }

  verify_bash() {
    MIN_BASH_VER="5"
    MSG_EXEC "Verifying script running in bash"
    # Check if the script is running in Bash
    if [ -z "$BASH_VERSION" ]; then
      MSG_ERRR "This script must be run using Bash."
      exit 1
    fi

    # Check if the Bash version is at least 5
    bash_major_version="${BASH_VERSION%%.*}"
    if [ "$bash_major_version" -lt 5 ]; then
      MSG_ERRR "This script requires Bash version $MIN_BASH_VER or higher. Current version is $BASH_VERSION."
      exit 1
    fi
  }
}

###########################################################
# Load the general libraries for QA Testing
load_gen_lib_color_formats
