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
from git import Repo, InvalidGitRepositoryError
import sys
from datetime import datetime


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


def set_target_cluster(target_cluster_name: str) -> str:
    """
    Set up the environment for the target cluster by changing directories and updating the main.tf file.
    :param target_cluster_name: The name of the cluster to set.
    :return: The initial cluster name from main.tf.
    """
    if not target_cluster_name:
        raise ValueError("Cluster name must be provided.")

    repo_root = get_repo_root()
    example_dir = os.path.join(repo_root, "example")
    main_tf_file = os.path.join(example_dir, "main.tf")

    # Change directory to "Energon-Kube/example"
    os.chdir(example_dir)

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

        return initial_main_tf_cluster_setting

    except FileNotFoundError:
        print(f"File '{main_tf_file}' not found.")
        sys.exit(1)
    except PermissionError as e:
        print(f"Permission error: {e}")
        sys.exit(1)


def revert_target_cluster(initial_main_tf_cluster_setting: str) -> None:
    """
    Revert the cluster name in main.tf to its original value.
    :param initial_main_tf_cluster_setting: The original cluster name to revert to.
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

    revert_file('example/main.tf')

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
    initial_main_tf_cluster_setting = set_target_cluster(target_cluster_name)

    try:
        commands = [
            f"aws eks update-kubeconfig --name {target_cluster_name} --region us-east-1",
            "terraform init",
            "terraform apply -auto-approve",
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
        revert_target_cluster(initial_main_tf_cluster_setting)


def bringdown_cluster(target_cluster_name: str):
    """
    Bring down the cluster with the specified name.
    :param target_cluster_name: The name of the cluster to bring down.
    :return: None
    """
    initial_main_tf_cluster_setting = set_target_cluster(target_cluster_name)

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
        revert_target_cluster(initial_main_tf_cluster_setting)
