#!/usr/bin/env bash

# This script is used to check the current AWS environment
# and Kubernetes context to ensure the correct environment
# is being targeted. This script is intended to be sourced
# by other scripts to ensure the correct environment is
# being used.

load_check_aws_env() {
  # Declare local variables
  local SCRIPT_LOCATION
  local CALLER_NAME
  local REQUESTED_PRJ
  local REQUESTED_ENV
  local EXPECTED_CLUSTER
  local EXPECTED_STACK
  local CURRENT_AWSID
  local CURRENT_AWS_VPC_ENV
  local KUBE_CONTEXT
  local CLUSTER
  local KUBE_CONTEXT_PARTS

  SCRIPT_LOCATION=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]:-$0}")")" &> /dev/null && pwd)

  # Source shared global generic library of functions and
  # variables for QA Testing environment
  source "${SCRIPT_LOCATION}/gen_lib_funcs_vars.sh"

  MSG_EXEC "Checking current AWS environment."

  if [ $# -eq 3 ]; then
    CALLER_NAME="$1"
    REQUESTED_PRJ="$2"
    REQUESTED_ENV="$3"
  elif [ $# -eq 2 ]; then
    CALLER_NAME="<script.sh>"
    REQUESTED_PRJ="$1"
    REQUESTED_ENV="$2"
  else
    CALLER_NAME="<script.sh>"
    REQUESTED_PRJ=""
    REQUESTED_ENV=""
  fi

  # Function to check if CLUSTER_NAME is set for dev or test environments
  check_cluster_set() {
    if [[ -z "${CLUSTER_NAME}" ]]; then
      MSG_ERRR "No CLUSTER_NAME shell environment variable, exiting!"
      printf ""
      MSG_WARN "CLUSTER_NAME needs set when using dev or test environments."
      MSG_NONE "Recommend using .envrc to configured 'export CLUSTER_NAME=yourcluster'"
      printf ""
      MSG_WARN "Dependency for following command:"
      MSG_NONE "$(txt_yellow 'aws eks update-kubeconfig --name "$CLUSTER_NAME" --region us-east-1')"
      printf ""
      exit 1
    fi
  }

  # Determine the expected cluster and stack based on project and environment
  case ${REQUESTED_PRJ} in
    batcave)
      case ${REQUESTED_ENV} in
        dev|test)
          check_cluster_set
          EXPECTED_CLUSTER="${CLUSTER_NAME}"
          EXPECTED_STACK="${REQUESTED_PRJ}-${REQUESTED_ENV}"
          ;;
        impl|prod)
          EXPECTED_CLUSTER="${REQUESTED_PRJ}-${REQUESTED_ENV}"
          EXPECTED_STACK="${REQUESTED_PRJ}-${REQUESTED_ENV}"
          ;;
      esac
      ;;
    # Additional project cases follow a similar pattern
    *)
      EXPECTED_CLUSTER="${REQUESTED_PRJ}-${REQUESTED_ENV}"
      EXPECTED_STACK="${REQUESTED_PRJ}-${REQUESTED_ENV}"
      ;;
  esac

  # Check current AWS and Kubernetes context to ensure correct environment
  CURRENT_AWSID="$(aws sts get-caller-identity --query Account --output text)"
  CURRENT_AWS_VPC_ENV="$(aws ec2 describe-vpcs --query 'Vpcs[].Tags[?Key==`Name`][].Value' --output text | sed 's/east-//')"
  KUBE_CONTEXT="$(kubectl config current-context 2> /dev/null || echo '')"
  if [[ "${KUBE_CONTEXT}" == "" ]]; then
    MSG_ERRR "Unable to get the current kubectl context."
    MSG_WARN "Check that '$(txt_yellow "${KUBECONFIG}:-~/.kube/config")' exists, and has a current context specified."
    MSG_NONE "You may need to run: '$(txt_yellow "aws eks update-kubeconfig --name \"$CLUSTER_NAME\" --region us-east-1")'"
    exit 1
  fi

  IFS='/' read -ra KUBE_CONTEXT_PARTS <<< "${KUBE_CONTEXT}"
  CLUSTER="${KUBE_CONTEXT_PARTS[$((${#KUBE_CONTEXT_PARTS[@]}-1))]}"

  # Ensure an environment is specified
  if [[ -z ${REQUESTED_ENV} ]]; then
    MSG_ERRR "Missing environment argument, exiting!"
    MSG_INFO "Syntax:"
    MSG_NONE "    '$(txt_yellow "${CALLER_NAME} <project> <environment>")'"
    exit 1
  fi

  display_current_env() {
    ########### Display Current Environment ###################
    MSG_NONE "Requested Project:        $(txt_teal "${REQUESTED_PRJ}")"
    MSG_NONE "Requested Environment:    $(txt_teal "${REQUESTED_ENV}")"
    MSG_NONE "AWS Account ID:           $(txt_teal "${CURRENT_AWSID}")"
    MSG_NONE "Expected AWS Env:         $(txt_teal "${EXPECTED_STACK}")"
    MSG_NONE "AWS EC2 VPC Env:          $(txt_teal "${CURRENT_AWS_VPC_ENV}")"
    MSG_NONE "Expected Cluster:         $(txt_teal "${EXPECTED_CLUSTER}")"
    MSG_NONE "Kubectl Config Cluster:   $(txt_teal "${CLUSTER}")"
  }

  # Verify Kubernetes cluster matches the expected target
  if [ "${CLUSTER}" != "${EXPECTED_CLUSTER}" ]; then
    MSG_ERRR "Conflicting parameters!"
    display_current_env
    MSG_ERRR "Current Kubernetes cluster \"${CLUSTER}\" does not match the expected target: \"${EXPECTED_CLUSTER}\""
    exit 1
  fi

  MSG_SUCS "All parameters check out."
  display_current_env
  if [ "${CALLER_NAME}" != "<script.sh>" ]; then
    MSG_QUES "\nYou are about to run $(txt_teal "${CALLER_NAME}") in the $(txt_teal "${REQUESTED_PRJ}") project for the $(txt_teal "${REQUESTED_ENV}") environment on the $(txt_teal "${CLUSTER}") k8s cluster in the $(txt_teal "${EXPECTED_STACK}") account."
    continue_yes_no
  fi

  exit 0
}

#######################################################
# load the check_aws_env script
load_check_aws_env "$@"
