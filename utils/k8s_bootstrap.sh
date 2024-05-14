#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <EKS_CLUSTER_NAME> <AWS_REGION> <ASSUME_ROLE>"
    exit 1
fi

KUBECONFIG_FILE_NAME="kube-temp"
EKS_CLUSTER_NAME=$1
AWS_REGION=$2
ASSUME_ROLE=$3

ASSUME_ROLE_OUTPUT=$(aws sts assume-role --role-arn "${ASSUME_ROLE}" --role-session-name eksUpdateKubeconfigSession --region "${AWS_REGION}")

export AWS_ACCESS_KEY_ID=$(echo "${ASSUME_ROLE_OUTPUT}" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "${ASSUME_ROLE_OUTPUT}" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "${ASSUME_ROLE_OUTPUT}" | jq -r '.Credentials.SessionToken')

aws eks update-kubeconfig --region "${AWS_REGION}" --name "${EKS_CLUSTER_NAME}" --kubeconfig "${KUBECONFIG_FILE_NAME}"
export KUBECONFIG="${KUBECONFIG_FILE_NAME}"

kubectl delete storageclass gp2

rm -f "${KUBECONFIG}"
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN KUBECONFIG