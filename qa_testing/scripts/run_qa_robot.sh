#!/usr/bin/env bash

################################################################
# This script is used to run Robot Framework tests from the
# QA Testing environment. The script will activate the virtual
# environment and run the Robot Framework tests from the
# specified test file.

load_run_qa_robot() {

  local SCRIPT_LOCATION
  local SCRIPT_NAME
  local CALLER_DIR
  local VENV_NAME
  local VENV_PATH

  # Determine directory of this script directory
  SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)
  SCRIPT_NAME=$(basename -- "$0")
  CALLER_DIR=$(pwd)

  # Source shared global generic library of functions and
  # variables
  source "${SCRIPT_LOCATION}/gen_lib_funcs_vars.sh"

  # Source the run_qa_py_venv.sh script
  source "${QA_SCRIPTS_DIR}/run_qa_py_venv.sh"

  # Set the name of the virtual environment and its path
  VENV_NAME=".venv_qa_testing"
  VENV_PATH="${QA_DIR}/${VENV_NAME}"

  # Function to display help message
  usage_run_qa_robot() {
      printf "Usage: %s [ROBOT_TEST_FILE]" "${SCRIPT_NAME}"
      printf "Example: %s example.robot\n" "${SCRIPT_NAME}"
      printf "Options:\n"
      printf "  --pretest (executes KubeLibrary prerelease testcases)\n\n"
      exit 0
  }

kubelibrary_prerelease_testcases() {
  MSG_EXEC "Running KubeLibrary prerelease testcases..."
  cd "$QA_THIRD_PARTY_DIR/KubeLibrary" || { MSG_ERRR "Failed to change directory to KubeLibrary"; exit 1; }
  robot -e prerelease testcases
  local status=$?
  cd "${CALLER_DIR}" || { MSG_ERRR "Failed to return to the original directory"; exit 1; }
  return $status
}

  # Function to activate the virtual environment and run Robot Framework tests
  run_robot_tests() {
    local status

    # Setup dependencies:
    cd "$QA_THIRD_PARTY_DIR" || { MSG_ERRR "Failed to change directory to ${QA_THIRD_PARTY_DIR}"; exit 1; }
    ./use_KubeLibrary.sh
    cd "${CALLER_DIR}" || { MSG_ERRR "Failed to return to the original directory"; exit 1; }

    source "${VENV_PATH}/bin/activate"
    is_activated_venv

    # Check if --pretest argument is passed
    if [ "$1" == "--pretest" ]; then
      kubelibrary_prerelease_testcases
      status=$?
    else
      local test_file=$1
      shift
      if [ ! -f "${QA_ROBOT_DIR}/${test_file}" ]; then
        MSG_ERRR "Test file  '$(txt_teal "${test_file}")' not found in $(txt_yellow "${QA_ROBOT_DIR}")."
        deactivate
        is_deactivated_venv
        exit 1
      fi

      # Run the Robot Framework tests from the robot directory
      MSG_EXEC "Running Robot Framework tests $(txt_hotpink "${test_file}")..."
      (cd "${QA_ROBOT_DIR}" && robot -P "$QA_THIRD_PARTY_DIR" "${test_file}")
      status=$?
    fi
    deactivate
    is_deactivated_venv
    return $status
  }

  # Main function to orchestrate the steps
  main() {
    if [ $# -eq 0 ] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage_run_qa_robot
    fi

    check_for_venv
    run_robot_tests "$@"
  }

  # Execute the main function with all passed arguments
  main "$@"

}


################################################################
# Code that should only run when not being sourced by
# another script
load_run_qa_robot "$@"
