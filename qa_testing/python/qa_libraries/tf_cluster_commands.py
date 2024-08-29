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
import subprocess
import os
import configparser
from git import Repo, InvalidGitRepositoryError
import shutil
import sys
from datetime import datetime
import json


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


def get_current_cluster_name(tfstate_file: str) -> str:
    """
    Extract the cluster name from the Terraform state file.
    :param tfstate_file: Path to the Terraform state file.
    :return: The name of the current cluster, or 'unknown' if not found.
    """
    try:
        with open(tfstate_file, 'r') as file:
            tfstate_data = json.load(file)
            for resource in tfstate_data.get('resources', []):
                for instance in resource.get('instances', []):
                    attributes = instance.get('attributes', {})
                    if 'cluster_custom_name' in attributes:
                        return attributes['cluster_custom_name']
    except (FileNotFoundError, json.JSONDecodeError):
        return 'unknown'
    return 'unknown'


def extract_and_debug_cluster_name(state_data: str, start_marker: str, end_marker: str) -> str:
    """
    Extract the current cluster name from the state data and print debug information.
    :param state_data: The contents of the state file as a string.
    :param start_marker: The marker indicating the start of the cluster name.
    :param end_marker: The marker indicating the end of the cluster name.
    :return: The extracted cluster name.
    """
    start_index = state_data.find(start_marker) + len(start_marker)
    end_index = state_data.find(end_marker, start_index)
    current_cluster_name = state_data[start_index:end_index]

    # Debugging output
    print(f"DEBUG: Extracted current cluster name: '{current_cluster_name}'")

    return current_cluster_name


def manage_cluster_states(target_cluster_name: str, cluster_dir: str) -> str:
    """
    Manage Terraform state files for the specified cluster.
    :param target_cluster_name: The name of the target cluster.
    :param cluster_dir: The directory containing the Terraform files.
    :return: The previous cluster name from the existing state files.
    """
    main_tf_file = os.path.join(cluster_dir, "main.tf")

    # Check if main.tf exists in the current directory
    if not os.path.exists(main_tf_file):
        print(f"Error: 'main.tf' not found in directory '{cluster_dir}'. Please ensure you're in the correct directory.")
        sys.exit(1)

    def extract_cluster_name_from_state(state_file_path: str) -> str:
        """Helper function to extract the cluster name from a state file."""
        if not os.path.exists(state_file_path):
            return None

        with open(state_file_path, 'r') as file:
            state_data = json.load(file)

        # Attempt to locate the cluster name in the JSON structure
        if "resources" in state_data and len(state_data["resources"]) > 0:
            try:
                for resource in state_data["resources"]:
                    if resource["type"] == "aws_eks_cluster_auth" and "instances" in resource:
                        for instance in resource["instances"]:
                            if instance["attributes"]["name"]:
                                return instance["attributes"]["name"]
            except KeyError:
                return None

        return None

    tf_state_file = os.path.join(cluster_dir, "terraform.tfstate")
    tf_backup_file = os.path.join(cluster_dir, "terraform.tfstate.backup")

    # Try to get the current cluster name from the state file or its backup
    current_cluster_name = extract_cluster_name_from_state(tf_state_file) or extract_cluster_name_from_state(tf_backup_file)

    if current_cluster_name:
        print(f"DEBUG: Current cluster in state file: '{current_cluster_name}'")
    else:
        current_cluster_name = "unknown_cluster"
        print(f"DEBUG: Could not determine the current cluster from state files, defaulting to '{current_cluster_name}'.")

    # If the current cluster is different from the target cluster, move the state files
    if current_cluster_name != target_cluster_name:
        backup_dir = os.path.join(cluster_dir, f"tf.state_{current_cluster_name}")
        if not os.path.exists(backup_dir):
            os.makedirs(backup_dir)

        print(f"Moving current Terraform state files to '{backup_dir}' and switching to target cluster '{target_cluster_name}'.")

        for state_file in ["terraform.tfstate", "terraform.tfstate.backup"]:
            state_file_path = os.path.join(cluster_dir, state_file)
            if os.path.exists(state_file_path):
                dest_path = os.path.join(backup_dir, os.path.basename(state_file_path))
                if os.path.exists(dest_path):
                    print(f"Warning: Destination path '{dest_path}' already exists. Overwriting the file.")
                    os.remove(dest_path)  # Remove the existing file before moving the new one
                shutil.move(state_file_path, backup_dir)

        # Move the target cluster's state files into the current directory
        target_backup_dir = os.path.join(cluster_dir, f"tf.state_{target_cluster_name}")
        if os.path.exists(target_backup_dir):
            for state_file in os.listdir(target_backup_dir):
                shutil.move(os.path.join(target_backup_dir, state_file), cluster_dir)

        return current_cluster_name

    # If no state file exists or no cluster name is found, just return the target cluster name
    return target_cluster_name


def extract_cluster_name_from_state(state_data: str) -> str:
    """
    Extract the cluster name from the Terraform state data.
    :param state_data: The content of the Terraform state file.
    :return: The extracted cluster name.
    """
    try:
        # Attempt to load the state data as JSON and extract the cluster name
        state_json = json.loads(state_data)
        resources = state_json.get('resources', [])
        for resource in resources:
            if resource.get('type') == 'aws_eks_cluster':
                instances = resource.get('instances', [])
                for instance in instances:
                    cluster_name = instance.get('attributes', {}).get('name')
                    if cluster_name:
                        return cluster_name
    except json.JSONDecodeError:
        pass  # Fallback to manual extraction

    # Fallback in case JSON parsing doesn't work
    start_marker = '  cluster_custom_name = "'
    end_marker = '"'
    start_index = state_data.find(start_marker) + len(start_marker)
    end_index = state_data.find(end_marker, start_index)
    return state_data[start_index:end_index]


def debug_log(message: str):
    """
    Print debug messages to the console.
    :param message: The debug message to print.
    """
    print(f"DEBUG: {message}")


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
                    print("Operation aborted by the user.")
                    sys.exit(0)  # Exit the program gracefully

                # Replace the line with the new cluster name
                data = data.replace(f'{start_marker}{initial_main_tf_cluster_setting}{end_marker}', f'{start_marker}{target_cluster_name}{end_marker}')

                # Write updated data back to the file
                file.seek(0)
                file.write(data)
                file.truncate()

        return initial_main_tf_cluster_setting, cluster_dir

    except FileNotFoundError:
        print(f"File '{main_tf_file}' not found.")
        sys.exit(1)
    except PermissionError as e:
        print(f"Permission error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


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


def run_command(command: str) -> str:
    """
    Run a shell command and return the captured output.
    :param command: Command to run.
    :return: Captured output.
    """
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    stdout_stderr_cache = ""
    while True:
        output = process.stdout.readline()
        if output == "" and process.poll() is not None:
            break
        if output:
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
            line = f"{timestamp} stdout: {output.strip()}"
            print(line)
            stdout_stderr_cache += line + "\n"

    stderr = process.communicate()[1]
    if stderr:
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        line = f"{timestamp} stderr: {stderr.strip()}"
        print(line)
        stdout_stderr_cache += line + "\n"

    return stdout_stderr_cache, process.returncode


def bringup_cluster(target_cluster_name: str):
    """
    Bring up the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring up.
    :return: None
    """
    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)

    previous_cluster_name = manage_cluster_states(target_cluster_name, cluster_dir)

    try:
        commands = [
            "terraform init",
            "terraform apply -auto-approve",
            f"aws eks update-kubeconfig --name {target_cluster_name} --region us-east-1",
            "aws eks list-clusters --query clusters"
        ]

        stdout_stderr_cache = ""
        for command in commands:
            stdout_stderr_out, return_code = run_command(command)
            stdout_stderr_cache += stdout_stderr_out
            if return_code != 0:
                raise subprocess.CalledProcessError(return_code, command)

    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print("Output:", e.stdout)
        print("Error:", e.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)
        manage_cluster_states(previous_cluster_name, cluster_dir)


def check_cluster_exists(cluster_name: str) -> bool:
    """
    Check if the target cluster exists.
    :param cluster_name: The name of the cluster to check.
    :return: True if the cluster exists, False otherwise.
    """
    stdout_stderr_cache, return_code = run_command("aws eks list-clusters --query clusters")
    if return_code != 0:
        print("Failed to retrieve the list of clusters.")
        sys.exit(1)

    # Extract the JSON part from the output
    try:
        json_lines = []
        for line in stdout_stderr_cache.splitlines():
            if "stdout:" in line:
                json_part = line.split('stdout: ')[1].strip()
                json_lines.append(json_part)

        json_output = ''.join(json_lines)
        clusters = json.loads(json_output)
    except (json.JSONDecodeError, IndexError) as e:
        print(f"Failed to parse clusters JSON: {e}")
        sys.exit(1)

    return cluster_name in clusters


def bringdown_cluster(target_cluster_name: str):
    """
    Bring down the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring down.
    :return: None
    """
    # Check if the target cluster exists
    if not check_cluster_exists(target_cluster_name):
        print(f"Cluster: {target_cluster_name} not found, no cluster to bring down.")

        # Retrieve and print the list of available clusters
        available_clusters, return_code = run_command("aws eks list-clusters --query clusters --output text")
        if return_code == 0:
            print("Available clusters in the current AWS account:")
            for cluster in available_clusters.split():
                print(f"  - {cluster}")
        else:
            print("Failed to retrieve the list of available clusters.")

        return

    initial_main_tf_cluster_setting, cluster_dir = set_target_cluster(target_cluster_name)

    previous_cluster_name = manage_cluster_states(target_cluster_name, cluster_dir)

    try:
        commands = [
            "terraform init -upgrade",  # Initialize Terraform to update cache before destroying
            "terraform destroy -auto-approve",
            "aws eks list-clusters --query clusters"
        ]

        stdout_stderr_cache = ""
        for command in commands:
            stdout_stderr_out, return_code = run_command(command)
            stdout_stderr_cache += stdout_stderr_out
            if return_code != 0:
                raise subprocess.CalledProcessError(return_code, command)

    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print("Output:", e.stdout)
        print("Error:", e.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        # Revert the main.tf cluster setting
        revert_target_cluster(initial_main_tf_cluster_setting, cluster_dir)

        # Restore the previous state files
        manage_cluster_states(previous_cluster_name, cluster_dir)

        # Delete the state directory of the destroyed cluster
        destroyed_state_dir = os.path.join(cluster_dir, f"tf.state_{target_cluster_name}")
        if os.path.exists(destroyed_state_dir):
            shutil.rmtree(destroyed_state_dir)
            print(f"Deleted the state directory for cluster '{target_cluster_name}' at '{destroyed_state_dir}'.")
