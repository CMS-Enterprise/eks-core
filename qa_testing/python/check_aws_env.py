"""
Purpose: This Python script is designed to validate the current AWS environment and Kubernetes context against
         expected values for a given project and environment. It aims to ensure that operations such as deployments
         are performed in the correct cloud environment, thereby preventing accidental changes in the wrong AWS account
         or Kubernetes cluster. The script checks AWS account ID, VPC settings, and the active Kubernetes context.
         It can be run in an interactive mode for manual checks or integrated into automation workflows in a
         non-interactive mode.

Usage:
    Direct invocation:
        python3 check_aws_env.py -p <project> -e <environment>

    Integration in Python scripts:
        from argparse import Namespace
        from check_aws_env import check_env
        args = Namespace(caller='caller-script-name.py',
                         project='project',
                         environment='environment',
                         non_interactive=True)
        check_env(args)

    Integration in Bash scripts:
        python3 $(dirname "$0")/check_aws_env.py -c "$0" -p "$PROJ_NAME" -e "$ENV_DIR"
"""

# Check for missing required packages and attempt to import them
missing_packages = []

# Attempt to import local utility functions
try:
    from utils import *
except ModuleNotFoundError:
    missing_packages.append("utils (local)")

if not verify_min_python_version(3, 10):
    sys.exit(1)

# Import standard Python libraries, noting any that are missing
try:
    import argparse
    from argparse import Namespace
except ModuleNotFoundError:
    missing_packages.append("argparse")

try:
    import json
except ModuleNotFoundError:
    missing_packages.append("json")

try:
    import re
except ModuleNotFoundError:
    missing_packages.append("re")

try:
    import sys
except ModuleNotFoundError:
    missing_packages.append("sys")

try:
    import time
except ModuleNotFoundError:
    missing_packages.append("time")

# Attempt to import third-party libraries, specifically
# boto3 for AWS interactions and the Kubernetes client for
# cluster context checks
try:
    import boto3
except ModuleNotFoundError:
    missing_packages.append("boto3")

try:
    from kubernetes.config import list_kube_config_contexts
except ModuleNotFoundError:
    missing_packages.append("kubernetes")

# If any packages are missing, inform the user which ones
# need to be installed and exit
if missing_packages:
    print("Missing required Python packages:")
    for package in missing_packages:
        print(f"  - {package}")
    print(f"[!] Please review 'Batcave Landing Zone Python Script Dependencies'"
          f"    in the BLZ/docs/onboarding/Onboarding-and-Prerequisits.md")
    sys.exit(1)


# Define a function to parse command-line arguments
def parse_arguments():
    """
    Parses command-line arguments passed to the script.
    """
    parser = argparse.ArgumentParser(description="Check current AWS environment.")
    parser.add_argument("-c", "--caller", default="<script.sh>", help="Caller script name")
    parser.add_argument("-p", "--project", default="", help="Requested project")
    parser.add_argument("-e", "--environment", default="", help="Requested environment")
    parser.add_argument("-n", "--non_interactive", action='store_true', help="executes without any prompts")

    args = parser.parse_args()
    return args


def check_cluster_set():
    """
    Check if the CLUSTER_NAME environment variable is set.
    """
    cluster_name = get_os_environment_variable('CLUSTER_NAME', verbose=True)

    if not cluster_name:
        status_message(f"No CLUSTER_NAME shell environment variable, exiting!\n"
                       f"\n"
                       f"    CLUSTER_NAME needs set when using dev or k3d environments.\n"
                       f"    Recommend using {color_text(f'.envrc', ['t_d_yellow'])} "
                       f"to configured {color_text(f'export CLUSTER_NAME=', ['t_l_yellow'])}"
                       f"{color_text(f'your-cluster-name', ['t_aqua'])}\n"
                       f"\n"
                       f"    Dependency for following command:\n"
                       f'    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region us-east-1\n',
                       'error')
        sys.exit(1)
    return cluster_name


def get_requested_project(args: Namespace):
    """
    Get the expected cluster and stack names based on the requested project and environment.
    """
    cluster_name = check_cluster_set()
    expected_cluster = ''
    expected_stack = ''

    # Load the project map from the file batcave-accounts.txt in the scripts directory
    project_env_namespace_map = {}
    script_dir = os.path.dirname(os.path.abspath(__file__))
    accounts_file_path = os.path.join(script_dir, 'batcave-accounts.txt')
    project_file = open(accounts_file_path, 'r')
    project_file_lines = project_file.readlines()
    for line in project_file_lines:
        fields = line.split(' ')
        project_name, directory_name, region, vpc_name, aws_profile_name = fields
        generated_cluster_name = f"{project_name}-{directory_name}"
        if generated_cluster_name in ["batcave-dev","batcave-test"]:
            generated_cluster_name=cluster_name
        project_env_namespace_map.setdefault(project_name,{})[directory_name]=([generated_cluster_name, vpc_name])

    try:
        expected_cluster = project_env_namespace_map[args.project][args.environment][0]
        expected_stack = project_env_namespace_map[args.project][args.environment][1]
    except KeyError:
        if args.project and args.environment:
            expected_cluster = args.project + '-' + args.environment
            expected_stack = expected_cluster

    return expected_cluster, expected_stack


# ########## AWS Login State Values ########################
# Very important to verify the correct environment, especially for a production
# environment.  The following commands query the current environment information
# from different sources of information.

# Get current logged in AWS Account ID
def get_aws_account_id(max_retries=5, wait_seconds=10):
    """
    Get the current AWS account ID.
    """
    for attempt in range(max_retries):
        try:
            sts_client = boto3.client('sts')
            response = sts_client.get_caller_identity()
            return response['Account']

        except json.decoder.JSONDecodeError:
            if attempt < max_retries - 1:  # i.e. not the last attempt
                status_message(
                    f"Encountered an issue while trying to fetch AWS account ID. "
                    f"Please check your network or VPN connection.", 'error')
                wait(wait_seconds)
                continue
            else:
                status_message(
                    "There seems to be a connectivity issue. Please check your network or VPN connection.",
                    'error')
                return None
        except Exception as e:  # Generic exception handler for other unexpected issues.
            status_message(f"Unexpected error: {e}", 'error')
            return None


# Get current logged in AWS environment parameters
def get_all_aws_vpc_envs():
    """
    Get all VPC names from the AWS account.
    """
    ec2_client = boto3.client('ec2')
    response = ec2_client.describe_vpcs()
    vpc_name_tag_values = [tag['Value'] for vpc in response['Vpcs'] for tag in vpc['Tags'] if tag['Key'] == 'Name']
    return vpc_name_tag_values


def get_kube_context_and_cluster(status: bool = False):
    """
    Get the current kubectl context and cluster name from the kubeconfig file.
    """
    kube_config = get_os_environment_variable('KUBECONFIG', verbose=status)

    def print_kube_error():
        cf_kube_config = color_text(kube_config, ['t_d_yellow'])
        cf_kube_cfg_env_var = color_text(f'$KUBECONFIG', ['t_d_yellow'])
        cf_kube_cfg_path = color_text(f'~/.kube/config', ['t_d_yellow'])
        cf_kube_cmd = color_text(f'aws eks update-kubeconfig --name "$CLUSTER_NAME" --region us-east-1',
                                       ['t_d_yellow'])

        status_message(f"Unable to get the current kubectl context.\n"
                       f"    Check that the {cf_kube_cfg_env_var} environment variable is set or "
                       f"the default {cf_kube_cfg_path} file exists, and has a current context specified.\n"
                       f"    {cf_kube_cfg_env_var} : {cf_kube_config}\n"
                       f"\n"
                       f"    You may need to run: \n"
                       f"    {cf_kube_cmd}", 'error')

    try:
        contexts, active_context = list_kube_config_contexts()
        kube_context = active_context['name']
        kube_config_cluster = active_context['context']['cluster']

        if not kube_context:
            print_kube_error()

        return kube_config_cluster.split('/')[-1]
    except Exception as e:
        print_kube_error()
        sys.exit(1)


# Main function to orchestrate environment checks based on passed arguments
def check_env(args: Namespace = None):
    """
    Main function to check the current AWS and Kubernetes environment against expected configurations.
    """
    status_message(f"Checking current AWS environment.", 'execution')
    if not args:
        args = parse_arguments()
    CALLER_NAME = color_text(args.caller, ['t_teal'])
    REQUESTED_PRJ = color_text(args.project, ['t_teal'])
    REQUESTED_ENV = color_text(args.environment, ['t_teal'])

    CURRENT_AWSID = get_aws_account_id()
    if CURRENT_AWSID is None:
        status_message("Failed to get AWS account ID after multiple attempts.", 'error')
        sys.exit(1)
    else:
        CURRENT_AWSID = color_text(CURRENT_AWSID, ['t_teal'])

    EXPECTED_CLUSTER, EXPECTED_STACK = get_requested_project(args)
    EXPECTED_STACK = color_text(EXPECTED_STACK, ['t_teal'])
    EXPECTED_CLUSTER = color_text(EXPECTED_CLUSTER, ['t_teal'])
    CURRENT_AWS_VPC_ENVS = color_list(get_all_aws_vpc_envs(), ['t_teal'])
    KUBE_CONFIG_CLUSTER = color_text(get_kube_context_and_cluster(True), ['t_teal'])
    KUBE_CONFIG_CMD = color_text("aws eks update-kubeconfig --name \"$CLUSTER_NAME\" --region us-east-1", ['t_d_yellow'])

    def display_current_env():
        print("")
        status_message(f"Current Environment:\n"
                       f"    Requested Project:      {REQUESTED_PRJ}\n"
                       f"    Requested Environment:  {REQUESTED_ENV}\n"
                       f"    AWS Account ID:         {CURRENT_AWSID}\n"
                       f"    Expected AWS Env:       {EXPECTED_STACK}\n"
                       f"    AWS EC2 VPC Envs:       {', '.join(CURRENT_AWS_VPC_ENVS)}\n"
                       f"    Expected Cluster:       {EXPECTED_CLUSTER}\n"
                       f"    Kube Context:           {KUBE_CONFIG_CLUSTER}\n",
                       'info')

    if not REQUESTED_ENV:
        display_current_env()
        status_message(f"Missing environment argument, exiting!", 'error')
        sys.exit(1)

    if EXPECTED_STACK == "sssa-dev" or EXPECTED_STACK == "bcmt-prod":
        pass
    elif EXPECTED_STACK not in CURRENT_AWS_VPC_ENVS:
        EXPECTED_STACK = color_text(EXPECTED_STACK, ['t_red'])
        CURRENT_AWS_VPC_ENVS = color_list(CURRENT_AWS_VPC_ENVS, ['t_aqua'])

        display_current_env()
        status_message(f"AWS login and requested environment mismatch, exiting!", 'error')
        sys.exit(1)

    if EXPECTED_CLUSTER != KUBE_CONFIG_CLUSTER:
        EXPECTED_CLUSTER = color_text(EXPECTED_CLUSTER, ['t_red'])
        KUBE_CONFIG_CLUSTER = color_text(KUBE_CONFIG_CLUSTER, ['t_aqua'])

        display_current_env()
        status_message(f"Current kubernetes cluster \"{KUBE_CONFIG_CLUSTER}\" does not match the expected target: "
                       f"\"{EXPECTED_CLUSTER}\"\n", 'error')

        status_message(f"You May need to run the following to set your kubeconfig properly:\n"
                       f"    {KUBE_CONFIG_CMD}", 'info')

        sys.exit(1)

    status_message(f"All parameters check out.", 'success')
    display_current_env()

    if CALLER_NAME != "<script.sh>":
        cf_caller_cmd = color_text(f"{EXPECTED_STACK}-login", ['t_d_yellow'])
        cf_vpn_cmd = color_text(f"cms-vpn-connect", ['t_d_yellow'])

        status_message(f"You are about to run {CALLER_NAME} in the \"{REQUESTED_PRJ}\" project for the"
                       f" \"{REQUESTED_ENV}\" environment on the \"{KUBE_CONFIG_CLUSTER}\" k8s cluster in the"
                       f" \"{EXPECTED_STACK}\" account.", 'warning')

    if not args.non_interactive:
        continue_prompt()


if __name__ == "__main__":
    check_env()
