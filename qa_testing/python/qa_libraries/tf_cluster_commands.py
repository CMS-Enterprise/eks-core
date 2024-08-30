###########################################################
#
# 1: git cloning
# 2: main.tf changes
#    - setup environment parameters
# 3: remaining steps from the ticket
# 4: finally, update-kubeconfig
#
#
# 1: $git clone git@github.com:CMS-Enterprise/Energon-Kube.git
# 2: cd /Energon-Kube/example
# 3: execute the below env
# export AWS_PROFILE="batcave-impl-breakglass"
# export KUBECONFIG="${HOME}/.kube/config-batcave-impl"
#
# 4: confirm you are still in /example dir, run below.
# $terraform init
# $terraform apply
#
# Note: type 'yes' for the below
# Do you want to perform these actions?
#   Terraform will perform the actions described above.
#   Only 'yes' will be accepted to approve.
#
# 5: On how to destroy && clean up cache.
# terraform destroy && rm -rf .terraform
#
#

import configparser
from datetime import datetime
from git import Repo, InvalidGitRepositoryError
import json
import os
import shutil
import subprocess
import sys
from typing import Optional

from qa_libraries.logger import log


def get_repo_root() -> str:
    """
    Get the root directory of the git repository.
    :return: The absolute path to the repository root.
    """
    try:
        repo = Repo(os.getcwd(), search_parent_directories=True)
        return repo.git.rev_parse("--show-toplevel")
    except InvalidGitRepositoryError as e:
        log.error("Not a git repository.")
        raise Exception("Not a git repository.") from e


def read_config_value(config_path: str, key: str) -> str:
    """
    Read a value from the configuration file.
    :param config_path: Path to the configuration file.
    :param key: Key to retrieve the value for.
    :return: The value for the specified key.
    """
    config = configparser.ConfigParser()
    config.read(config_path)

    try:
        value = config['DEFAULT'][key]
        return value
    except KeyError as e:
        log.error(f"Key '{key}' not found in the configuration file: {config_path}")
        raise KeyError(f"Key '{key}' not found in the configuration file: {config_path}") from e


def check_tf_state_files_exist(cluster_dir: str) -> list:
    """
    Check if terraform.tfstate or terraform.tfstate.backup files exist in the specified directory.

    :param cluster_dir: The directory to check for Terraform state files.
    :return: A list of state file paths found, or an empty list if none found.
    """
    tfstate_file = os.path.join(cluster_dir, "terraform.tfstate")
    tfstate_backup_file = os.path.join(cluster_dir, "terraform.tfstate.backup")

    existing_files = []

    if os.path.exists(tfstate_file):
        existing_files.append(tfstate_file)
    if os.path.exists(tfstate_backup_file):
        existing_files.append(tfstate_backup_file)

    if not existing_files:
        log.warning(f"No Terraform state files found in directory: {cluster_dir}")

    return existing_files


def extract_cluster_name(tf_state_file: str, cluster_dir: str) -> Optional[str]:
    """
    Extract the cluster name from a Terraform state file.

    :param tf_state_file: The path to the Terraform state file.
    :param cluster_dir: The directory containing the state file.
    :return: The cluster name associated with the state file, or None if not found.
    """
    full_path = os.path.join(cluster_dir, tf_state_file)
    try:
        with open(full_path, 'r') as file:
            state_data = json.load(file)

            # Look for the cluster name in aws_eks_cluster and aws_ec2_tag resources
            resources = state_data.get('resources', [])
            for resource in resources:
                if resource.get('type') == 'aws_eks_cluster':
                    instances = resource.get('instances', [])
                    for instance in instances:
                        attributes = instance.get('attributes', {})

                        # Check for 'name' attribute under aws_eks_cluster
                        if 'name' in attributes:
                            cluster_name = attributes['name']
                            log.info(f"Cluster name '{cluster_name}' extracted from '{tf_state_file}'.")
                            return cluster_name

                elif resource.get('type') == 'aws_ec2_tag':
                    instances = resource.get('instances', [])
                    for instance in instances:
                        attributes = instance.get('attributes', {})
                        key = attributes.get('key', '')

                        # Extract the cluster name from the key if it matches the pattern
                        if key.startswith('kubernetes.io/cluster/'):
                            cluster_name = key.split('/')[-1]
                            log.info(f"Cluster name '{cluster_name}' extracted from '{tf_state_file}' via aws_ec2_tag.")
                            return cluster_name

    except (FileNotFoundError, json.JSONDecodeError):
        log.error(f"Failed to read or parse '{tf_state_file}'.")
        return None

    log.warning(f"No valid cluster name found in '{tf_state_file}'.")
    return None


def validate_current_tfstate_cluster_name(state_files: list, cluster_dir: str) -> str:
    """
    Extract and validate the cluster name from Terraform state files.

    :param state_files: List of Terraform state files to check.
    :param cluster_dir: The directory containing the Terraform state files.
    :return: The validated cluster name extracted from the state files.
    :raises ValueError: If the state files contain inconsistent cluster names.
    """
    # Extract cluster names from the state files
    cluster_names = []
    for state_file in state_files:
        cluster_name = extract_cluster_name(state_file, cluster_dir)
        if cluster_name:
            log.info(f"Cluster name '{cluster_name}' extracted from '{state_file}'.")
        else:
            log.warning(f"No cluster name found in '{state_file}'.")
        cluster_names.append(cluster_name)

    # Remove None entries and verify that all state files have the same cluster name
    cluster_names = [name for name in cluster_names if name is not None]
    unique_cluster_names = set(cluster_names)

    if len(unique_cluster_names) != 1:
        log.error("Inconsistent cluster names found in state files.")
        raise ValueError("Inconsistent cluster names found in state files. Please review the tf state files manually.")

    # Log the validated cluster name
    validated_cluster_name = unique_cluster_names.pop()
    log.info(f"Validated current terraform.tfstate cluster name: '{validated_cluster_name}'")

    return validated_cluster_name


def create_tf_state_subdir(current_tf_statefile_cluster_name: str, cluster_dir: str) -> str:
    """
    Create a subdirectory named 'tf.state_<current_tf_statefile_cluster_name>' in the specified directory.

    :param current_tf_statefile_cluster_name: The cluster name extracted from the Terraform state file.
    :param cluster_dir: The directory where the subdirectory will be created.
    :return: The path to the created subdirectory.
    """
    # Construct the subdirectory name
    subdir_name = f"tf.state_{current_tf_statefile_cluster_name}"
    subdir_path = os.path.join(cluster_dir, subdir_name)

    # Create the subdirectory if it doesn't already exist
    if not os.path.exists(subdir_path):
        os.makedirs(subdir_path)
        log.info(f"Created subdirectory: {subdir_path}")
    else:
        log.warning(f"Subdirectory already exists: {subdir_path}")

    return subdir_path


def backup_tfstate_files(target_cluster: str, cluster_dir: str, always_backup: bool = False) -> str:
    """
    Back up existing Terraform state files if the current cluster differs from the target cluster or if always_backup is True.

    :param target_cluster: The target cluster name for which the Terraform state files are being set up.
    :param cluster_dir: The directory containing the Terraform files.
    :param always_backup: Optional boolean flag to force a backup regardless of cluster matching. Default is False.
    :return: The name of the backup directory created, or None if no backup was needed.
    """
    # Step 1: Check if any Terraform state files exist
    state_files = check_tf_state_files_exist(cluster_dir)
    if not state_files:
        log.info("No Terraform state files found; no backup needed.")
        return None

    # Step 2-3: Validate and extract the current cluster name from state files
    current_tfstate_cluster_name = validate_current_tfstate_cluster_name(state_files, cluster_dir)

    # Step 4: If always_backup is True or the current cluster differs from the target cluster, perform backup
    if always_backup or (current_tfstate_cluster_name and current_tfstate_cluster_name != target_cluster):
        # Step 5: Create a backup directory and move the state files
        backup_dir = create_tf_state_subdir(current_tfstate_cluster_name, cluster_dir)
        for state_file in state_files:
            shutil.move(os.path.join(cluster_dir, state_file), backup_dir)
        log.info(f"Backed up Terraform state files to {backup_dir}.")

        return backup_dir

    log.info("No backup was needed; the target cluster matches the current state.")
    return None


def restore_tfstate_files(previous_tfstate_backup_dir: str, cluster_dir: str):
    """
    Restore the Terraform state files from the backup directory to the main directory.

    :param previous_tfstate_backup_dir: The backup directory containing the previous state files.
    :param cluster_dir: The directory containing the Terraform files.
    """
    state_files = check_tf_state_files_exist(previous_tfstate_backup_dir)
    if not state_files:
        log.warning(f"No state files found in the backup directory '{previous_tfstate_backup_dir}'.")
        return

    for state_file in state_files:
        shutil.copy2(os.path.join(previous_tfstate_backup_dir, state_file), cluster_dir)
    log.info(f"Restored state files to '{cluster_dir}' from '{previous_tfstate_backup_dir}'.")


def revert_tfstate_files(target_cluster_name: str, previous_tfstate_backup_dir: str, cluster_dir: str):
    """
    Revert the Terraform state files to the previous state by backing up the current files
    and restoring the old ones from the backup directory.

    :param target_cluster_name: The name of the target cluster.
    :param previous_tfstate_backup_dir: The backup directory containing the previous state files.
    :param cluster_dir: The directory containing the Terraform files.
    """
    # Step 1: Always back up the current state files before restoring the previous ones
    log.info(f"Backing up current state files before restoring from {previous_tfstate_backup_dir}.")
    _ = backup_tfstate_files(target_cluster_name, cluster_dir, always_backup=True)

    # Step 2: Restore the previous state files
    restore_tfstate_files(previous_tfstate_backup_dir, cluster_dir)


def set_target_cluster(target_cluster_name: str) -> (str, str):
    """
    Set up the environment for the target cluster by changing directories and updating the main.tf file.
    :param target_cluster_name: The name of the cluster to set.
    :return: A tuple containing the initial cluster name from main.tf and the cluster directory path.
    """
    if not target_cluster_name:
        log.error("Cluster name must be provided.")
        raise ValueError("Cluster name must be provided.")

    repo_root = get_repo_root()
    config_path = os.path.join(repo_root, "qa_testing", "configs", "setup.cfg")
    cluster_dir_name = read_config_value(config_path, "Target_Cluster_Dir")
    cluster_dir = os.path.join(repo_root, cluster_dir_name)
    main_tf_file = os.path.join(cluster_dir, "main.tf")

    # Change directory to "Energon-Kube/cluster_dir"
    os.chdir(cluster_dir)

    # Attempt to read and write the "main.tf" file
    try:
        with open(main_tf_file, 'r+') as file:
            data = file.read()

            # Extract the current cluster name from the file
            start_marker = '  cluster_custom_name = "'
            end_marker = '"'
            start_index = data.find(start_marker) + len(start_marker)
            end_index = data.find(end_marker, start_index)
            initial_main_tf_cluster_setting = data[start_index:end_index]

            # Prompt user if there is a mismatch
            if initial_main_tf_cluster_setting != target_cluster_name:
                log.warning(f"Cluster mismatch: main.tf has '{initial_main_tf_cluster_setting}', but target is '{target_cluster_name}'.")
                response = input(f"Cluster mismatch: main.tf has '{initial_main_tf_cluster_setting}', but target is '{target_cluster_name}'. Do you want to change the main.tf to the target cluster '{target_cluster_name}'? (yes/no): ")
                if response.lower() != 'yes':
                    log.info("Operation aborted by the user.")
                    raise SystemExit("Operation aborted by the user.")

                # Replace the line with the new cluster name
                data = data.replace(f'{start_marker}{initial_main_tf_cluster_setting}{end_marker}', f'{start_marker}{target_cluster_name}{end_marker}')

                # Write updated data back to the file
                file.seek(0)
                file.write(data)
                file.truncate()

        return initial_main_tf_cluster_setting, cluster_dir

    except FileNotFoundError:
        log.error(f"File '{main_tf_file}' not found.")
        raise FileNotFoundError(f"File '{main_tf_file}' not found.")
    except PermissionError as e:
        log.error(f"Permission error: {e}")
        raise PermissionError(f"Permission error: {e}")
    except Exception as e:
        log.error(f"An error occurred: {e}")
        raise RuntimeError(f"An error occurred: {e}")


def revert_target_cluster(initial_main_tf_cluster_setting: str, cluster_dir: str) -> None:
    """
    Revert the cluster name in main.tf to its original value.
    :param initial_main_tf_cluster_setting: The original cluster name to revert to.
    :param cluster_dir: The directory containing the main.tf file.
    :return: None
    """
    def revert_file(file_path: str):
        """
        Revert a specific file in the repository to its last committed state.
        :param file_path: The relative path to the file to revert.
        """
        try:
            # Locate the repository root
            repo = Repo(os.getcwd(), search_parent_directories=True)

            # Revert the file to its last committed state
            repo.git.checkout('--', file_path)
            print(f"Reverted file: {file_path}")

        except Exception as e:
            print(f"An error occurred: {e}")

    revert_file(os.path.join(cluster_dir, 'main.tf'))
    print(f"Cluster setting reverted to '{initial_main_tf_cluster_setting}' in the main.tf")


def run_command(command: str) -> (str, str, int):
    """
    Run a shell command and return the captured output and error separately.
    :param command: Command to run.
    :return: A tuple containing captured stdout, stderr, and the return code.
    """
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    stdout_cache = ""
    stderr_cache = ""
    while True:
        output = process.stdout.readline()
        if output == "" and process.poll() is not None:
            break
        if output:
            log.info(output.strip())
            stdout_cache += output

    stderr = process.communicate()[1]
    if stderr:
        log.error(stderr.strip())  # Using ERROR to log stderr messages
        stderr_cache += stderr

    return stdout_cache, stderr_cache, process.returncode


def bringup_cluster(target_cluster_name: str):
    """
    Bring up the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring up.
    :return: None
    """
    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)
    previous_tfstate_backup_dir = backup_tfstate_files(target_cluster_name, cluster_dir)

    if not previous_tfstate_backup_dir:
        log.info("No previous state files found; proceeding with cluster setup.")

    try:
        commands = [
            "terraform init",
            "terraform apply -auto-approve",
            f"aws eks update-kubeconfig --name {target_cluster_name} --region us-east-1",
            "aws eks list-clusters --query clusters"
        ]

        stdout_stderr_cache = ""
        for command in commands:
            stdout, stderr, return_code = run_command(command)
            stdout_stderr_cache += stdout + stderr
            if return_code != 0:
                raise subprocess.CalledProcessError(return_code, command, output=stdout, stderr=stderr)

    except subprocess.CalledProcessError as e:
        log.error(f"Command '{e.cmd}' failed with return code {e.returncode}")
        log.error(f"Output: {e.output}")
        log.error(f"Error: {e.stderr}")
    except Exception as e:
        log.error(f"An error occurred: {e}")
    finally:
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)

        if previous_tfstate_backup_dir:
            revert_tfstate_files(target_cluster_name, previous_tfstate_backup_dir, cluster_dir)


def check_cluster_exists(cluster_name: str) -> bool:
    """
    Check if the target cluster exists.
    :param cluster_name: The name of the cluster to check.
    :return: True if the cluster exists, False otherwise.
    """
    stdout, stderr, return_code = run_command("aws eks list-clusters --query clusters")
    if return_code != 0:
        log.error("Failed to retrieve the list of clusters.")
        raise ValueError(f"Unable to list clusters from AWS: {stderr}")

    try:
        clusters = json.loads(stdout)
    except json.JSONDecodeError as e:
        log.error(f"Failed to parse clusters JSON: {e}")
        raise ValueError(f"Error parsing cluster data: {stderr}")

    return cluster_name in clusters


def bringdown_cluster(target_cluster_name: str):
    """
    Bring down the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring down.
    :return: None
    """
    if not check_cluster_exists(target_cluster_name):
        log.warning(f"Cluster: {target_cluster_name} not found, no cluster to bring down.")
        available_clusters, _, return_code = run_command("aws eks list-clusters --query clusters --output text")
        if return_code == 0:
            log.info("Available clusters in the current AWS account:")
            for cluster in available_clusters.split():
                log.info(f"  - {cluster}")
        else:
            log.error("Failed to retrieve the list of available clusters.")
        return

    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)
    previous_tfstate_backup_dir = backup_tfstate_files(target_cluster_name, cluster_dir)

    if not previous_tfstate_backup_dir:
        restore_tfstate_files(target_cluster_name, cluster_dir)

    try:
        commands = [
            "terraform init -upgrade",  # Initialize Terraform to update cache before destroying
            "terraform destroy -auto-approve",
            "aws eks list-clusters --query clusters"
        ]

        stdout_stderr_cache = ""
        for command in commands:
            stdout, stderr, return_code = run_command(command)
            stdout_stderr_cache += stdout + stderr
            if return_code != 0:
                raise subprocess.CalledProcessError(return_code, command, output=stdout, stderr=stderr)

    except subprocess.CalledProcessError as e:
        log.error(f"Command '{e.cmd}' failed with return code {e.returncode}")
        log.error(f"Output: {e.output}")
        log.error(f"Error: {e.stderr}")
    except Exception as e:
        log.error(f"An error occurred: {e}")
    finally:
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)

        if previous_tfstate_backup_dir:
            revert_tfstate_files(target_cluster_name, previous_tfstate_backup_dir, cluster_dir)