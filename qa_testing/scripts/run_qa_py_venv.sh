#!/usr/bin/env bash

#######################################################
# This script is used to run Python scripts from the
# QA Testing environment. The script will activate the
# virtual environment and run the Python scripts from the
# specified test file.

load_run_qa_py_venv() {

  local SCRIPT_LOCATION
  local CALLER_DIR
  local VENV_NAME
  local VENV_PATH

  SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)
  CALLER_DIR=$(pwd)

  # Source shared global generic library of functions and
  # variables
  source "${SCRIPT_LOCATION}/gen_lib_funcs_vars.sh"

  # Set the name of the virtual environment and its path
  VENV_NAME=".venv_qa_testing"
  VENV_PATH="${QA_DIR}/${VENV_NAME}"

  # Function to display help message
  usage_run_qa_py_venv() {
      printf "Usage: %s [OPTION]... [SCRIPT] [SCRIPT_ARGS]...\n\n" "$(get_this_python_script_name)"
      printf "Options:\n"
      printf "  -l, --list    Display a list of Python scripts that can be called\n"
      printf "  -h, --help    Display this help message and exit\n\n"
      printf "Example:\n"
      printf "  %s run_qa_py_venv bringup_cluster.py -t temp-test\n\n" "$(get_this_python_script_name)"
      exit 0
  }

  # List Python files in the scripts directory
  list_python_scripts() {
      cd "${QA_PYTHON_DIR}" || { MSG_ERRR "Failed to change directory to QA_PYTHON_DIR: ${QA_PYTHON_DIR}"; exit 1; }
      MSG_INFO "Available Python scripts:"
      ls *.py
      cd "${CALLER_DIR}" || { MSG_ERRR "Failed to return to the original directory"; exit 1; }
      exit 0
  }

  # Function to check if the virtual environment already
  # exists and that all the modules have been installed
  # that are in the requirements.txt
  check_for_venv() {
    MSG_EXEC "Checking virtual environment: ${VENV_NAME} is setup..."
    if [ ! -d "${VENV_PATH}" ]; then
      MSG_WARN "Virtual environment: ${VENV_NAME} not found..."
      setup_venv
    else
      # Ensure the virtual environment is using the correct packages
      MSG_EXEC "Virtual environment ${VENV_NAME} found, updating..."
      source "${VENV_PATH}/bin/activate"
      # Ensure pip is up to date and suppress already satisfied messages
      pip install --upgrade pip | grep -v 'Requirement already satisfied'
      pip install -r "${QA_PYTHON_DIR}/requirements.txt" | grep -v 'Requirement already satisfied'
      deactivate
    fi
  }

  # Function to verify that the script is in the virtual environment
  is_activated_venv() {
    if [ "$VIRTUAL_ENV" == "${VENV_PATH}" ]; then
      MSG_SUCS "Virtual environment ${VENV_NAME} has been activated."
    else
      MSG_ERRR "Failed to activate virtual environment ${VENV_NAME}."
      exit 1
    fi
  }

  # Function to verify that the script has exited the virtual environment
  is_deactivated_venv() {
    if [ -z "$VIRTUAL_ENV" ]; then
      MSG_SUCS "Virtual environment ${VENV_NAME} has been deactivated."
    else
      MSG_ERRR "Failed to deactivate virtual environment ${VENV_NAME}."
      exit 1
    fi
  }

  setup_venv() {
    cd "${QA_DIR}" || { MSG_ERRR "Failed to change directory to REPO_ROOT: ${QA_DIR}"; exit 1; }
    MSG_EXEC "Creating virtual environment: ${VENV_NAME} ..."
    python3 -m venv "${VENV_NAME}" || { MSG_ERRR "Failed to create virtual environment"; exit 1; }
    source "${VENV_PATH}/bin/activate"
    is_activated_venv
    python3 -m pip install --upgrade pip
    python3 -m pip install -r "${QA_PYTHON_DIR}/requirements.txt" || { MSG_ERRR "Failed to install dependencies"; exit 1; }
    deactivate
    is_deactivated_venv
    cd "${CALLER_DIR}" || { MSG_ERRR "Failed to return to the original directory"; exit 1; }
    MSG_SUCS "QA Testing Python Scripts: Successfully configured with all dependencies in virtual environment: ${VENV_NAME}"
  }

  # Function to activate the virtual environment and run a Python script
  run_python_script() {
    local python_script_name=$1
    shift
    source "${VENV_PATH}/bin/activate"
    is_activated_venv
    if [ ! -f "${QA_PYTHON_DIR}/${python_script_name}" ]; then
      MSG_ERRR "Script '$(txt_teal "${python_script_name}")' not found in $(txt_yellow "${QA_PYTHON_DIR}")."
      deactivate
      is_deactivated_venv
      exit 1
    fi

    # Run the script from the current working directory
    (cd "$(pwd)" && python3 "${QA_PYTHON_DIR}/${python_script_name}" "$@")
    local status=$?
    deactivate
    is_deactivated_venv
    return $status
  }

  # Function to run the main execution code
  run_qa_py_venv_main() {
    if [ $# -eq 0 ] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage_run_qa_py_venv
    fi
    if [[ "$1" == "-l" ]] || [[ "$1" == "--list" ]]; then
        list_python_scripts
    fi
    check_for_venv
    run_python_script "$@"
  }

  ###########################################################
  # Code that should only run when not being sourced by
  # another script
  if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
      run_qa_py_venv_main "$@"
  fi

}


#######################################################
# Load the run_qa_py_venv function
load_run_qa_py_venv "$@"
