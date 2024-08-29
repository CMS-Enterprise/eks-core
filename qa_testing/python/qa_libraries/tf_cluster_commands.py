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
#
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
from typing import List, Optional


def get_repo_root() -> str:
    """
    Get the root directory of the git repository.
    :return: The absolute path to the repository root.
    """
    try:
        repo = Repo(os.getcwd(), search_parent_directories=True)
        return repo.git.rev_parse("--show-toplevel")
    except InvalidGitRepositoryError:
        raise Exception("Not a git repository.")


def read_config_value(config_path: str, key: str) -> str:
    """
    Read a value from the configuration file.
    :param config_path: Path to the configuration file.
    :param key: Key to retrieve the value for.
    :return: The value for the specified key.
    """
    config = configparser.ConfigParser()
    config.read(config_path)
    return config['DEFAULT'][key]


def check_tf_state_files_exist(cluster_dir: str) -> list:
    """
    Check if terraform.tfstate or terraform.tfstate.backup files exist in the specified directory.

    :param cluster_dir: The directory to check for Terraform state files.
    ::return: A list of state file paths found, or an empty list if none found.
    """
    tfstate_file = os.path.join(cluster_dir, "terraform.tfstate")
    tfstate_backup_file = os.path.join(cluster_dir, "terraform.tfstate.backup")

    existing_files = []
    if os.path.exists(tfstate_file):
        existing_files.append(tfstate_file)
    if os.path.exists(tfstate_backup_file):
        existing_files.append(tfstate_backup_file)

    return existing_files


def extract_cluster_name(tf_state_file: str, cluster_dir: str) -> str:
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

            # Look for the cluster name in the state data
            resources = state_data.get('resources', [])
            for resource in resources:
                instances = resource.get('instances', [])
                for instance in instances:
                    attributes = instance.get('attributes', {})

                    # Check for 'name' attribute (used by aws_eks_cluster)
                    if 'name' in attributes:
                        return attributes['name']

                    # Check for 'cluster_custom_name' attribute
                    if 'cluster_custom_name' in attributes:
                        return attributes['cluster_custom_name']
    except (FileNotFoundError, json.JSONDecodeError):
        return None

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
        cluster_names.append(cluster_name)

    # Remove None entries and verify that all state files have the same cluster name
    cluster_names = [name for name in cluster_names if name is not None]
    unique_cluster_names = set(cluster_names)

    if len(unique_cluster_names) != 1:
        raise ValueError("Inconsistent cluster names found in state files, please review tf state files manually.")

    # Return the validated cluster name
    return unique_cluster_names.pop()


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
        print(f"Created subdirectory: {subdir_path}")
    else:
        print(f"Subdirectory already exists: {subdir_path}")

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
        return None

    # Step 2-3: Validate and extract the current cluster name from state files
    current_tfstate_cluster_name = validate_current_tfstate_cluster_name(state_files, cluster_dir)

    # Step 4: If always_backup is True or the current cluster differs from the target cluster, perform backup
    if always_backup or (current_tfstate_cluster_name and current_tfstate_cluster_name != target_cluster):
        # Step 5: Create a backup directory and move the state files
        backup_dir = create_tf_state_subdir(current_tfstate_cluster_name, cluster_dir)
        for state_file in state_files:
            shutil.move(os.path.join(cluster_dir, state_file), backup_dir)

        return backup_dir

    return None


def restore_tfstate_files(target_cluster_name: str, previous_tfstate_backup_dir: str, cluster_dir: str):
    """
    Restore the Terraform state files from the backup and ensure no files are lost.

    :param target_cluster_name: The name of the target cluster.
    :param previous_tfstate_backup_dir: The backup directory containing the previous state files.
    :param cluster_dir: The directory containing the Terraform files.
    """
    # Step 1: Always back up the current state files before restoring the previous ones
    _ = backup_tfstate_files(target_cluster_name, cluster_dir, always_backup=True)

    # Step 2: Move the previous state files back to the main directory
    for state_file in check_tf_state_files_exist(previous_tfstate_backup_dir):
        shutil.move(os.path.join(previous_tfstate_backup_dir, state_file), cluster_dir)

    # Step 3: Remove the backup directory after restoration
    shutil.rmtree(previous_tfstate_backup_dir)
    print(f"Restored previous state files from '{previous_tfstate_backup_dir}'")


def set_target_cluster(target_cluster_name: str) -> (str, str):
    """
    Set up the environment for the target cluster by changing directories and updating the main.tf file.
    :param target_cluster_name: The name of the cluster to set.
    :return: A tuple containing the initial cluster name from main.tf and the cluster directory path.
    """
    if not target_cluster_name:
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
                response = input(f"Cluster mismatch: main.tf has '{initial_main_tf_cluster_setting}', but target is '{target_cluster_name}'. Do you want to change the main.tf to the target cluster '{target_cluster_name}'? (yes/no): ")
                if response.lower() != 'yes':
                    print(f"Operation aborted by the user.")
                    sys.exit(0)  # Exit the program gracefully

                # Replace the line with the new cluster name
                data = data.replace(f'{start_marker}{initial_main_tf_cluster_setting}{end_marker}', f'{start_marker}{target_cluster_name}{end_marker}')

                # Write updated data back to the file
                file.seek(0)
                file.write(data)
                file.truncate()

        return initial_main_tf_cluster_setting, cluster_dir

    except FileNotFoundError:
        raise FileNotFoundError(f"File '{main_tf_file}' not found.")
    except PermissionError as e:
        raise PermissionError(f"Permission error: {e}")
    except Exception as e:
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
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
            line = f"{timestamp} stdout: {output.strip()}"
            print(line)
            stdout_cache += line + "\n"

    stderr = process.communicate()[1]
    if stderr:
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        line = f"{timestamp} stderr: {stderr.strip()}"
        print(line)
        stderr_cache += line + "\n"

    return stdout_cache, stderr_cache, process.returncode


def bringup_cluster(target_cluster_name: str):
    """
    Bring up the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring up.
    :return: None
    """
    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)
    previous_tfstate_backup_dir = backup_tfstate_files(target_cluster_name, cluster_dir)

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
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print(f"Output: {e.output}")
        print(f"Error: {e.stderr}")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)

        if previous_tfstate_backup_dir:
            restore_tfstate_files(target_cluster_name, previous_tfstate_backup_dir, cluster_dir)


def check_cluster_exists(cluster_name: str) -> bool:
    """
    Check if the target cluster exists.
    :param cluster_name: The name of the cluster to check.
    :return: True if the cluster exists, False otherwise.
    """
    stdout, stderr, return_code = run_command("aws eks list-clusters --query clusters")
    if return_code != 0:
        print(f"Failed to retrieve the list of clusters.")
        raise ValueError(f"Unable to list clusters from AWS: {stderr}")

    try:
        clusters = json.loads(stdout)
    except json.JSONDecodeError as e:
        print(f"Failed to parse clusters JSON: {e}")
        raise ValueError(f"Error parsing cluster data: {stderr}")

    return cluster_name in clusters


def bringdown_cluster(target_cluster_name: str):
    """
    Bring down the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring down.
    :return: None
    """
    if not check_cluster_exists(target_cluster_name):
        print(f"Cluster: {target_cluster_name} not found, no cluster to bring down.")
        available_clusters, _, return_code = run_command("aws eks list-clusters --query clusters --output text")
        if return_code == 0:
            print(f"Available clusters in the current AWS account:")
            for cluster in available_clusters.split():
                print(f"  - {cluster}")
        else:
            print(f"Failed to retrieve the list of available clusters.")
        return

    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)
    previous_tfstate_backup_dir = backup_tfstate_files(target_cluster_name, cluster_dir)

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
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print(f"Output: {e.output}")
        print(f"Error: {e.stderr}")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)

        if previous_tfstate_backup_dir:
            restore_tfstate_files(target_cluster_name, previous_tfstate_backup_dir, cluster_dir)

        destroyed_state_dir = os.path.join(cluster_dir, f"tf.state_{target_cluster_name}")
        if os.path.exists(destroyed_state_dir):
            shutil.rmtree(destroyed_state_dir)
            print(f"Deleted the state directory for cluster '{target_cluster_name}' at '{destroyed_state_dir}'.")
