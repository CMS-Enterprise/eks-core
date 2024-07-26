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
# $terraform plan
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


def set_target_cluster(cluster_name: str) -> str:
    """
    Set up the environment for the target cluster by changing directories and updating the main.tf file.
    :param cluster_name: The name of the cluster to set.
    :return: The path to the example directory.
    """
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
    example_dir = os.path.join(repo_root, "example")
    main_tf_file = os.path.join(example_dir, "main.tf")

    # Change directory to "Energon-Kube/example"
    os.chdir(example_dir)

    # Read and edit the "main.tf" file
    with open(main_tf_file, 'r') as file:
        data = file.read()

    new_line = f'  cluster_custom_name = "{cluster_name}"'
    if new_line not in data:
        data = data.replace('  cluster_custom_name = "temp-test"', new_line)

    with open(main_tf_file, 'w') as file:
        file.write(data)

    return example_dir


def run_command(command: str) -> subprocess.CompletedProcess:
    """
    Run a shell command and return the completed process.
    :param command: Command to run.
    :return: Completed process.
    """
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    print(f"Running: {command}")
    print("Output:", result.stdout)
    print("Error:", result.stderr)
    result.check_returncode()  # Raise CalledProcessError if the command failed
    return result


def bringup_cluster(cluster_name: str):
    """
    Bring up the cluster with the specified name.
    :param cluster_name: The name of the cluster to bring up.
    :return: None
    """
    try:
        set_target_cluster(cluster_name)

        commands = [
            f"aws eks update-kubeconfig --name {cluster_name} --region us-east-1",
            "terraform init",
            "terraform plan",
            "terraform apply -auto-approve",
            "aws eks list-clusters --query clusters"
        ]

        for command in commands:
            run_command(command)

    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print("Output:", e.stdout)
        print("Error:", e.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")


def bringdown_cluster(cluster_name: str):
    """
    Bring down the cluster with the specified name.
    :param cluster_name: The name of the cluster to bring down.
    :return: None
    """
    try:
        set_target_cluster(cluster_name)

        commands = [
            "terraform destroy -auto-approve",
            "aws eks list-clusters --query clusters"
        ]

        for command in commands:
            run_command(command)

    except subprocess.CalledProcessError as e:
        print(f"Command '{e.cmd}' failed with return code {e.returncode}")
        print("Output:", e.stdout)
        print("Error:", e.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")