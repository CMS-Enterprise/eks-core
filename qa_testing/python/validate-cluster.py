missing_packages = []

# Local Imports
try:
    from check_aws_env import check_env, \
        get_kube_context_and_cluster, \
        get_aws_account_id, \
        get_requested_project, \
        get_all_aws_vpc_envs
except ModuleNotFoundError:
    missing_packages.append("check_aws_env (local)")

try:
    from utils import *
except ModuleNotFoundError:
    missing_packages.append("utils (local)")

#####################################################################
# INSTRUCTIONS: to run script
# Python Version >= 3.10
#
# RUN:
# - python3 -m pip install -r .../batcave-landing-zone/scripts/requirements.txt
# - from .../batcave-landing-zone/infra/project/env/
#       python3 ../../../scripts/validate_cluster.py -p project -e env ...
#
if not verify_min_python_version(3, 10):
    sys.exit(1)

# Builtin Imports
try:
    import argparse
    from argparse import Namespace
except ModuleNotFoundError:
    missing_packages.append("argparse")

try:
    from datetime import datetime
except ModuleNotFoundError:
    missing_packages.append("datetime")

try:
    import lzma
except ModuleNotFoundError:
    missing_packages.append("lzma")

try:
    import os
except ModuleNotFoundError:
    missing_packages.append("os")

try:
    import pickle
except ModuleNotFoundError:
    missing_packages.append("pickle")

try:
    import re
except ModuleNotFoundError:
    missing_packages.append("re")

try:
    from typing import List, Dict, Optional, Set, Union, Any, Tuple
except ModuleNotFoundError:
    missing_packages.append("typing")

#####################################################################
# Currently I'm using `sudo` pip install into my OS env,
#   WARNING: Running pip as the 'root' user can result in broken
#   permissions and conflicting behaviour with the system package
#   manager. It is recommended to use a virtual environment instead:
#   https://pip.pypa.io/warnings/venv
#
# TODO: Incorporate venv & wheel / poetry into repo, script launch
#       Add Poetry management
#       https://python-poetry.org/


#####################################################################
# Python The AWS SDK
#   https://pypi.org/project/boto3/
#   pip install boto3
#

try:
    import boto3
except ModuleNotFoundError:
    missing_packages.append("boto3")

#####################################################################
# Python Kubernetes Libraries
#   https://github.com/kubernetes-client/python
#   https://www.velotio.com/engineering-blog/kubernetes-python-client
#
#   pip install kubernetes
#

try:
    from kubernetes import config, client
    from kubernetes.client import V1StatefulSet, V1Deployment, V1DaemonSet
    from kubernetes.client.rest import ApiException
except ModuleNotFoundError:
    missing_packages.append("kubernetes")


def parse_input() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--cluster_name', default=None, help='target cluster name.')
    parser.add_argument('-p', '--project', default='batcave', help='target project, i.e. batcave')
    parser.add_argument('-e', '--environment', default='dev', help='target environment, i.e. dev, test, impl, prod')
    parser.add_argument('-f', '--filename', default=None, help='Filename for the stored cluster state')
    parser.add_argument('-s', '--store_cluster_state', action='store_true', help='Store current cluster state')
    parser.add_argument('-r', '--review_cluster_state', action='store_true',
                        help='Review and compare cluster state with stored state')

    args = parser.parse_args()

    # Check if -r and -s are provided, they should not both be invoked at the same time
    if not args.review_cluster_state ^ args.store_cluster_state:
        status_message(f"Either -r or -s parameter is needed but not both.", 'error')
        parser.print_help()
        sys.exit(1)

    # Check if -r is provided without -f
    if args.review_cluster_state and not args.filename:
        status_message(f"Parameter -f is required when using -r.", 'error')
        parser.print_help()
        sys.exit(1)

    return args


def generate_filename(project: str, environment: str) -> str:
    """
    Generates a filename with a timestamp.

    Parameters:
    - project (str): The project name.
    - environment (str): The environment name.

    Returns:
    str: A formatted filename string.
    """
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    return f"{project}_{environment}_{timestamp}.pkl.xz"


def store_cluster_state(cluster_state: Dict, filename: str) -> None:
    """
    Save the cluster state to a compressed file.

    Parameters:
    - cluster_state: Dict - The state to save as a dictionary
    - filename: str - The name of the file to save the state to
    """
    try:
        with lzma.open(filename, 'wb') as file:
            pickle.dump(cluster_state, file)
        status_message(f"Cluster state saved to '{filename}'.", 'success')
    except Exception as e:
        status_message(f"Error: Failed to save cluster state to '{filename}': {str(e)}", 'error')


def load_cluster_state(filename: str, args: argparse.Namespace) -> Optional[Dict]:
    """
    Load a previously saved cluster state from a compressed file.

    Parameters:
    - filename: str - The name of the file containing the saved state

    Returns:
    Optional[Dict] - The cluster state as a dictionary if successful, or None if there's an error.
    """

    # Check if file exists
    if not os.path.exists(filename):
        status_message(f"Error: File '{filename}' does not exist.", 'error')
        sys.exit(1)

    try:
        # Check if file is loadable as expected
        with lzma.open(filename, 'rb') as file:
            data = pickle.load(file)

        # Basic validation on loaded data
        if validate_cluster_data(data, args):
            return data

    except (pickle.UnpicklingError, lzma.LZMAError):
        # Specific errors related to corrupted pickle or lzma data
        status_message(f"Error: Data in '{filename}' is corrupted or not properly pickled/lzma compressed.", 'error')
        sys.exit(1)
    except Exception as e:
        status_message(f"Error: Unexpected error occurred while loading file '{filename}': {str(e)}", 'error')
        sys.exit(1)


def get_cluster_metadata(args: argparse.Namespace) -> Dict[str, Any]:
    """
    Retrieves metadata information about the current cluster.

    Returns:
    Dict[str, Any]: A dictionary containing metadata about the cluster.
    """
    # AWS initialization and data gathering
    aws_client = boto3.client('sts')
    aws_ec2 = boto3.resource('ec2')

    cluster_metadata = {
        "timestamp": datetime.now().strftime('%Y%m%d-%H%M%S'),
        "project": args.project,  # Ensure 'args' is accessible within this function
        "environment": args.environment,  # Ensure 'args' is accessible within this function
        "aws_account_id": aws_client.get_caller_identity()['Account'],
        "aws_vpc_names": get_all_aws_vpc_envs(),
        "aws_vpcs": [vpc.vpc_id for vpc in aws_ec2.vpcs.all()],
        "kube_context": get_kube_context_and_cluster()
    }

    return cluster_metadata


def validate_cluster_data(data, args: argparse.Namespace):
    """
    Validate the structure and contents of the loaded cluster data.

    Parameters:
    - data: The cluster state data

    Returns:
    True if the data is valid, False otherwise.
    """
    # Check if data is not None
    if data is None:
        status_message(f"Error: Loaded data is None.", 'error')
        return False

    # Perform some rudimentary checks on the loaded data
    required_keys = ["metadata",
                     "nodes",
                     "pods",
                     "services",
                     "statefulsets",
                     "deployments",
                     "daemonsets",
                     "helm_releases",
                     "virtual_services"]

    for key in required_keys:
        if key not in data:
            status_message(f"Error: Key '{key}' missing from loaded data.", 'error')
            return False

    # Additional checks on metadata to ensure it matches with the current cluster data
    current_cluster_metadata = get_cluster_metadata(args)

    for key in current_cluster_metadata:
        # Skip comparing timestamp as it's expected to change
        if key == "timestamp":
            continue

        if data["metadata"].get(key) != current_cluster_metadata[key]:
            status_message(f"Metadata mismatch for {key}.", 'error')
            return False

    status_message(f"Cluster data validated", 'success')
    return True


def get_ami_date(ami_id: str, region: str) -> str:
    """
    Retrieves the creation date of an Amazon Machine Image (AMI).

    Parameters:
    - ami_id: The AMI ID.
    - region: The AWS region.

    Returns:
    The creation date of the AMI or "Unknown Date" if not found.
    """
    ec2 = boto3.client('ec2', region_name=region)
    ami_info = ec2.describe_images(ImageIds=[ami_id])
    if ami_info['Images']:
        return ami_info['Images'][0]['CreationDate']
    return "Unknown Date"


def get_asg_name_from_instance_tags(instance_id: str, region: str) -> str:
    """
    Retrieves the name of the Auto Scaling Group (ASG) from an EC2 instance's tags.

    Parameters:
    - instance_id: The ID of the EC2 instance.
    - region: The AWS region.

    Returns:
    The name of the ASG or "N/A" if not found.
    """
    ec2 = boto3.client('ec2', region_name=region)
    instance_details = ec2.describe_instances(InstanceIds=[instance_id])
    tags = instance_details['Reservations'][0]['Instances'][0].get('Tags', [])

    for tag in tags:
        if tag['Key'] == 'aws:autoscaling:groupName':
            return tag['Value']
    return "N/A"


def get_ami_id_from_instance_id(instance_id: str, region: str) -> str:
    """
    Retrieves the AMI ID of an EC2 instance.

    Parameters:
    - instance_id: The ID of the EC2 instance.
    - region: The AWS region.

    Returns:
    The AMI ID associated with the instance or "N/A" if not found.
    """
    ec2 = boto3.client('ec2', region_name=region)
    instances = ec2.describe_instances(InstanceIds=[instance_id])
    if instances['Reservations']:
        return instances['Reservations'][0]['Instances'][0].get('ImageId', 'N/A')
    return "N/A"


def get_node_info(kube_client: client.CoreV1Api) -> List[Dict[str, str]]:
    """
    Retrieves detailed information about each node in a Kubernetes cluster.

    Parameters:
    - kube_client: A Kubernetes client instance (CoreV1Api).

    Returns:
    A list of dictionaries, each containing detailed information about a node.
    """
    nodes_info = []
    for node in kube_client.list_node().items:
        provider_id = node.spec.provider_id
        node_info = {
            "instance_id": "N/A",
            "name": node.metadata.name,
            "asg": "N/A",
            "availability_zone": "N/A",
            "ami_id": "N/A",
            "ami_date": "Unknown Date"
        }

        if provider_id and 'aws' in provider_id:
            _, region_zone, instance_id = provider_id.split('/')[-3:]
            region = region_zone[:-1]

            node_info['instance_id'] = instance_id
            node_info['availability_zone'] = region_zone
            node_info['ami_id'] = get_ami_id_from_instance_id(instance_id, region)
            node_info['ami_date'] = get_ami_date(node_info['ami_id'], region)
            node_info['asg'] = get_asg_name_from_instance_tags(instance_id, region)

        nodes_info.append(node_info)

    return nodes_info


def get_custom_resources(group: str, version: str, plural: str) -> List[Dict]:
    """
    General function to retrieve Kubernetes CustomResources.

    Parameters:
    - group: The group of the custom resource.
    - version: The version of the custom resource.
    - plural: The plural name of the custom resource.

    Returns:
    A list of dictionaries, each representing a Kubernetes CustomResource.
    """
    # Initialize the CustomObjects API client
    api_instance = client.CustomObjectsApi()
    # Fetch CustomResource objects across all namespaces
    custom_resources_list = api_instance.list_cluster_custom_object(group, version, plural)

    return custom_resources_list['items']


def get_helm_releases() -> List[Dict]:
    """
    Retrieves HelmRelease custom resources from the Kubernetes cluster.

    Returns:
    A list of dictionaries, each containing information about a HelmRelease,
    including its namespace, name, readiness status, and status message.
    """
    helm_releases = get_custom_resources('helm.toolkit.fluxcd.io', 'v2beta1', 'helmreleases')

    releases = []
    for release in helm_releases:
        # Default values
        ready_status = "Unknown"
        status_message = "N/A"

        # Check for the presence of 'conditions'
        conditions = release["status"].get("conditions", [])

        # Loop through conditions and find the 'Ready' type condition
        for condition in conditions:
            if condition.get("type") == "Ready":
                ready_status = condition.get("status", "Unknown")
                status_message = condition.get("message", "N/A")
                break  # Once we find the 'Ready' condition, exit the loop

        release_info = {
            "namespace": release["metadata"]["namespace"],
            "name": release["metadata"]["name"],
            "ready": ready_status,
            "status": status_message
        }
        releases.append(release_info)

    return releases


def get_virtual_services() -> List[Dict]:
    """
    Retrieves Istio VirtualService custom resources from the Kubernetes cluster.

    Returns:
    A list of dictionaries, each containing information about a VirtualService,
    including its namespace, name, associated gateways, and hosts.
    """
    virtual_services_list = get_custom_resources('networking.istio.io', 'v1alpha3', 'virtualservices')

    virtual_services = []
    for vs in virtual_services_list:
        vs_info = {
            "namespace": vs["metadata"]["namespace"],
            "name": vs["metadata"]["name"],
            "gateways": vs["spec"].get("gateways", []),
            "hosts": vs["spec"].get("hosts", [])
        }
        virtual_services.append(vs_info)

    return virtual_services


def capture_cluster_state(args: Namespace) -> Dict:
    """
    Capture the current state of the Kubernetes cluster and related AWS resources.

    Parameters:
    - args (Namespace): Parsed arguments from argparse.

    Returns:
    Dict: A dictionary containing the state of the Kubernetes cluster and AWS resources.
    """
    try:
        status_message(f"Capturing cluster state.", 'execution')

        # Kubernetes client setup
        kube_client = client.CoreV1Api()
        kube_apps_api = client.AppsV1Api()

        # Collate the state data
        cluster_state = {
            "metadata": get_cluster_metadata(args),
            "nodes": get_node_info(kube_client),
            "pods": kube_client.list_pod_for_all_namespaces().items,
            "services": kube_client.list_service_for_all_namespaces().items,
            "statefulsets": kube_apps_api.list_stateful_set_for_all_namespaces().items,
            "deployments": kube_apps_api.list_deployment_for_all_namespaces().items,
            "daemonsets": kube_apps_api.list_daemon_set_for_all_namespaces().items,
            "helm_releases": get_helm_releases(),
            "virtual_services": get_virtual_services()
        }

        return cluster_state

    except Exception as e:
        status_message(f"An error occurred while capturing the cluster state: {e}",
                       'error')
        return {}


def is_statefulset_ready(statefulset: V1StatefulSet) -> bool:
    """
    Check if a Kubernetes StatefulSet is ready.

    Parameters:
    - statefulset (V1StatefulSet): A Kubernetes StatefulSet object.

    Returns:
    bool: True if the StatefulSet is ready, False otherwise.
    """
    ready_count = getattr(statefulset.status, 'ready_replicas', 0) or 0
    total_count = getattr(statefulset.status, 'replicas', 0) or 0
    is_ready = ready_count == total_count

    return is_ready


def is_deployment_ready(deployment: V1Deployment) -> bool:
    """
    Check if a Kubernetes Deployment is ready.

    Parameters:
    - deployment (V1Deployment): A Kubernetes Deployment object.

    Returns:
    bool: True if the Deployment is ready, False otherwise.
    """
    ready_count = getattr(deployment.status, 'ready_replicas', 0) or 0
    total_count = getattr(deployment.status, 'replicas', 0) or 0
    is_ready = ready_count == total_count

    return is_ready


def is_daemonset_ready(daemonset: V1DaemonSet) -> bool:
    """
    Check if a Kubernetes DaemonSet is ready.

    Parameters:
    - daemonset (V1DaemonSet): A Kubernetes DaemonSet object.

    Returns:
    bool: True if the DaemonSet is ready, False otherwise.
    """
    ready_count = getattr(daemonset.status, 'numberReady', 0) or 0
    total_count = getattr(daemonset.status, 'desiredNumberScheduled', 0) or 0
    is_ready = ready_count == total_count

    return is_ready


def get_all_non_ready_workloads(cluster_state: Dict[str, List[Any]]) -> Dict[str, List[Dict[str, Union[bool, str]]]]:
    """
    Gets a list of all non-ready workloads from the given cluster state, organized by workload type.

    Parameters:
    - cluster_state: The state of the cluster.

    Returns:
    A dictionary containing lists of non-ready workloads, keyed by workload type.
    Each workload is represented as a dictionary with 'name' and 'is_ready' keys.
    """
    non_ready_workloads = {
        "statefulsets": [],
        "deployments": [],
        "daemonsets": [],
        "helm_releases": []
    }

    # Helper function to check and append non-ready workloads
    def check_and_append(workload_type: str, name: str, is_ready: bool):
        if not is_ready:
            non_ready_workloads[workload_type].append({"name": name, "is_ready": is_ready})

    # For StatefulSets, Deployments, and DaemonSets
    for workload_type in ["statefulsets", "deployments", "daemonsets"]:
        for item in cluster_state[workload_type]:
            is_ready = False
            if workload_type == "statefulsets":
                is_ready = is_statefulset_ready(item)
            elif workload_type == "deployments":
                is_ready = is_deployment_ready(item)
            elif workload_type == "daemonsets":
                is_ready = is_daemonset_ready(item)
            check_and_append(workload_type, item.metadata.name, is_ready)

    # For HelmReleases
    for item in cluster_state["helm_releases"]:
        is_ready = item.get('ready', 'False').lower() == 'true'
        check_and_append("helm_releases", item["name"], is_ready)

    # Sorting each workload list by name
    for workload_type in non_ready_workloads:
        non_ready_workloads[workload_type].sort(key=lambda x: x["name"])

    return non_ready_workloads


def print_node_ami_info(nodes_info: List[Dict[str, str]]) -> None:
    """
    Prints information about nodes and their associated AMI IDs.

    Parameters:
    - nodes_info: List of dictionaries containing information about each node.
    """

    # Aggregate AMI information
    ami_info = {}
    for node in nodes_info:
        ami_id = node['ami_id']
        if ami_id not in ami_info:
            ami_info[ami_id] = node['ami_date']

    # Print AMI information
    print("\nCluster AMI Info:")
    print("AMI ID:                   Date:")
    for ami_id, ami_date in ami_info.items():
        print(f"{ami_id:<25} {ami_date}")

    # Group nodes by Availability Zone and ASG
    az_asg_nodes = {}
    for node in nodes_info:
        az = node['availability_zone']
        asg = node['asg']
        az_asg_key = (az, asg)

        if az_asg_key not in az_asg_nodes:
            az_asg_nodes[az_asg_key] = []
        az_asg_nodes[az_asg_key].append(node)

    # Print nodes grouped by Availability Zone and ASG
    for (az, asg), nodes in az_asg_nodes.items():
        print(f"\nAvailability Zone: {az}")
        print(f"    ASG: {asg}")
        print("    Node:                               AMI ID:")
        for node in nodes:
            print(f"    {node['name']:<35} {node['ami_id']}")


def old_group_nodes_by_az_and_asg(current_node_info: List[Dict[str, str]], previous_node_info: List[Dict[str, str]]) -> Dict:
    az_asg_nodes = {}
    prev_node_dict = {node['name']: node for node in previous_node_info}

    for node in current_node_info:
        az = node.get('availability_zone')
        asg = node.get('asg')

        if az is None or asg is None:
            continue

        az_asg_key = (az, asg)
        if az_asg_key not in az_asg_nodes:
            az_asg_nodes[az_asg_key] = []

        prev_node = prev_node_dict.get(node['name'])
        if prev_node and prev_node['ami_id'] != node['ami_id']:
            node['prev_ami_id'] = prev_node['ami_id']

        az_asg_nodes[az_asg_key].append(node)

    return az_asg_nodes


def group_nodes_by_az_and_asg(current_node_info: List[Dict[str, str]], previous_node_info: List[Dict[str, str]]) -> Dict:
    az_asg_nodes = {}
    prev_node_dict = {node['name']: node for node in previous_node_info}

    # Process current nodes
    for node in current_node_info:
        az, asg = node.get('availability_zone'), node.get('asg')
        if az is None or asg is None:
            continue

        az_asg_key = (az, asg)
        az_asg_nodes.setdefault(az_asg_key, [])

        prev_node = prev_node_dict.get(node['name'])
        if prev_node and prev_node['ami_id'] != node['ami_id']:
            node['prev_ami_id'] = prev_node['ami_id']

        az_asg_nodes[az_asg_key].append(node)

    # Process old nodes from previous state
    for node in previous_node_info:
        if node['name'] not in {current_node['name'] for current_node in current_node_info}:
            az, asg = node.get('availability_zone'), node.get('asg')
            if az is None or asg is None:
                continue

            az_asg_key = (az, asg)
            az_asg_nodes.setdefault(az_asg_key, []).append(node)

    return az_asg_nodes


def aggregate_and_sort_ami_info(current_node_info: List[Dict[str, str]], previous_node_info: List[Dict[str, str]]) -> Dict[str, str]:
    """
    Aggregates AMI information from current and previous node data and sorts them by date.

    Parameters:
    - current_node_info: List of dictionaries containing current node information.
    - previous_node_info: List of dictionaries containing previous node information.

    Returns:
    A dictionary of AMI IDs sorted by their creation date.
    """
    ami_info = {}
    for node_list in [current_node_info, previous_node_info]:
        for node in node_list:
            # Ensure ami_id exists in the node dictionary
            ami_id = node.get('ami_id')
            if ami_id:
                ami_date = node.get('ami_date', 'Unknown Date')
                ami_info[ami_id] = ami_date

    # Sorting AMIs by date
    sorted_ami_info = dict(sorted(ami_info.items(), key=lambda item: item[1]))
    return sorted_ami_info


def determine_ami_color(current_node_info: List[Dict[str, str]], previous_node_info: List[Dict[str, str]], ami_colors: Dict[str, str]) -> Dict[str, str]:
    """
    Determines the color coding for AMI IDs based on their presence in the current and previous node information.

    Parameters:
    - current_node_info: List of dictionaries containing information about the current state of nodes.
    - previous_node_info: List of dictionaries containing information about the previous state of nodes.

    Returns:
    A dictionary mapping AMI IDs to their respective color codes.
    """
    ami_color_mapping = {}

    # Extract AMI IDs from both sets of node info
    current_amis = {node['ami_id'] for node in current_node_info}
    previous_amis = {node['ami_id'] for node in previous_node_info}

    # All unique AMIs
    all_amis = current_amis.union(previous_amis)

    for ami_id in all_amis:
        if ami_id in current_amis and ami_id not in previous_amis:
            ami_color_mapping[ami_id] = ami_colors['UPDATED']  # New AMIs
        elif ami_id in current_amis:
            ami_color_mapping[ami_id] = ami_colors['CURRENT']  # Current AMIs
        else:
            ami_color_mapping[ami_id] = ami_colors['REMOVED']  # Old AMIs

    return ami_color_mapping


def determine_az_color(prev_node_info: List[Dict[str, str]], curr_node_info: List[Dict[str, str]]) -> Dict[str, str]:
    """
    Determines the color coding for Availability Zones (AZs) based on their presence in the current and previous node information.

    Parameters:
    - prev_node_info: List of dictionaries containing information about the previous state of nodes.
    - curr_node_info: List of dictionaries containing information about the current state of nodes.

    Returns:
    A dictionary mapping AZs to their respective color codes.
    """
    az_color_mapping = {}

    # Extract AZs from both sets of node info
    prev_azs = {node['availability_zone'] for node in prev_node_info}
    curr_azs = {node['availability_zone'] for node in curr_node_info}

    # All unique AZs
    all_azs = prev_azs.union(curr_azs)

    for az in all_azs:
        if az in prev_azs and az in curr_azs:
            az_color_mapping[az] = 't_teal'
        elif az in prev_azs:
            az_color_mapping[az] = 't_grey'
        else:
            az_color_mapping[az] = 't_aqua'

    return az_color_mapping


def determine_asg_color(prev_node_info: List[Dict[str, str]], curr_node_info: List[Dict[str, str]]) -> Dict[str, str]:
    """
    Determines the color coding for Auto Scaling Groups (ASGs) based on their presence in the current and previous node information.

    Parameters:
    - prev_node_info: List of dictionaries containing information about the previous state of nodes.
    - curr_node_info: List of dictionaries containing information about the current state of nodes.

    Returns:
    A dictionary mapping ASGs to their respective color codes.
    """
    asg_color_mapping = {}

    # Extract ASGs from both sets of node info
    prev_asgs = {node['asg'] for node in prev_node_info}
    curr_asgs = {node['asg'] for node in curr_node_info}

    # All unique ASGs
    all_asgs = prev_asgs.union(curr_asgs)

    for asg in all_asgs:
        if asg in prev_asgs and asg in curr_asgs:
            asg_color_mapping[asg] = 't_teal'
        elif asg in prev_asgs:
            asg_color_mapping[asg] = 't_grey'
        else:
            asg_color_mapping[asg] = 't_aqua'

    return asg_color_mapping


def determine_node_ami_colors(node: Dict[str, str],
                              current_node_info: List[Dict[str, str]],
                              previous_node_info: List[Dict[str, str]],
                              node_colors: Dict[str, str],
                              ami_usage_colors: Dict[str, str],
                              ami_color_mapping: Dict[str, str]) -> Tuple[str, str, Optional[str]]:
    """
    Determines the color coding for a node and its associated AMI based on its presence and changes in current and previous node info.
    """
    node_name = node['name']
    current_ami = node['ami_id']
    previous_ami = None

    # Find if this node was present in the previous node info and get its AMI ID
    for prev_node in previous_node_info:
        if prev_node['name'] == node_name:
            previous_ami = prev_node['ami_id']
            break

    # Determine node color
    if node_name in {n['name'] for n in previous_node_info} and node_name not in {n['name'] for n in current_node_info}:
        node_color = node_colors['OLD']
    elif node_name in {n['name'] for n in current_node_info} and node_name in {n['name'] for n in previous_node_info}:
        node_color = node_colors['BOTH']
    else:
        node_color = node_colors['NEW']

    # Determine AMI color based on overall usage of AMI IDs
    ami_color = ami_color_mapping.get(current_ami, ami_usage_colors['CURRENT'])

    prev_ami_color = ami_usage_colors['PREVIOUS'] if previous_ami and current_ami != previous_ami else None

    return node_color, ami_color, prev_ami_color


def print_node_ami_info_compared(current_node_info: List[Dict[str, str]],
                                 previous_node_info: List[Dict[str, str]]) -> None:
    """
    Prints the AMI information of nodes comparing the current state with the previous state, and displays nodes grouped by Availability Zone and ASG.

    Parameters:
    - current_node_info: List of dictionaries containing information about nodes in the current state.
    - previous_node_info: List of dictionaries containing information about nodes in the previous state.
    """
    # Define color mappings
    node_colors = {'OLD': 't_grey', 'BOTH': 't_white', 'NEW': 't_l_blue'}
    ami_colors = {'REMOVED': 't_grey', 'CURRENT': 't_neon', 'UPDATED': 't_aqua'}
    ami_color_mapping = determine_ami_color(current_node_info, previous_node_info, ami_colors)

    # Sort AMIs by date and determine unique/new AMIs
    sorted_ami_info = aggregate_and_sort_ami_info(current_node_info, previous_node_info)

    # Determine color mappings
    ami_color_mapping = determine_ami_color(current_node_info, previous_node_info, ami_colors)
    az_color_mapping = determine_az_color(previous_node_info, current_node_info)
    asg_color_mapping = determine_asg_color(current_node_info, previous_node_info)

    # Create ami colored header text
    ami_id_header = f"AMI ID:  {color_text('REMOVED', [ami_colors['REMOVED']])} | {color_text('CURRENT', [ami_colors['CURRENT']])} | {color_text('UPDATED', [ami_colors['UPDATED']])}"

    # Create color-coded headers
    node_header = f"Node:  {color_text('OLD', [node_colors['OLD']])} | {color_text('BOTH', [node_colors['BOTH']])} | {color_text('NEW', [node_colors['NEW']])}"
    ami_header = f"AMI ID:  {color_text('CURRENT', [ami_colors['CURRENT']])} | {color_text('UPDATED', [ami_colors['UPDATED']])}"
    prev_ami_header = f"Previous AMI ID:  {color_text('PREVIOUS', ['t_grey'])}"

    # Print the AMI information
    print("\nCluster AMI Info:")

    print(f"{ami_id_header:<{83}} {'Date:'}")
    for ami_id, ami_date in sorted_ami_info.items():
        color = ami_color_mapping.get(ami_id, 't_neon')
        print(f"{color_text(ami_id, [color]):<{54}} {ami_date}")

    # Group nodes by Availability Zone and ASG, considering both current and previous states
    az_asg_nodes = group_nodes_by_az_and_asg(current_node_info, previous_node_info)

    # Print nodes grouped by Availability Zone and ASG
    for (az, asg), nodes in az_asg_nodes.items():
        az_color = az_color_mapping.get(az, 't_neon')
        asg_color = asg_color_mapping.get(asg, 't_neon')
        print(f"\nAvailability Zone: {color_text(f'{az}', [az_color])}")
        print(f"    ASG: {color_text(f'{asg}', [asg_color])}")
        print(f"    {node_header:<83} {ami_header:<60} {prev_ami_header}")

        for node in nodes:
            # Call determine_node_ami_colors with both node_colors and ami_color_mapping
            node_color, ami_color, prev_ami_color = determine_node_ami_colors(node, current_node_info, previous_node_info, node_colors, ami_colors, ami_color_mapping)
            print(f"    {color_text(node['name'], [node_color]):<54} {color_text(node['ami_id'], [ami_color]):<50} {color_text(node.get('prev_ami_id', ''), [prev_ami_color])}")


def identify_new_cluster_issues(prev_state: Dict[str, List[Dict[str, str]]],
                                current_state: Dict[str, List[Dict[str, str]]],
                                args: Namespace) -> None:
    """
    Identifies ongoing and new non-ready workloads introduced in the cluster after maintenance,
    prints them in a formatted manner, and compares node AMI information between the current and previous state.

    Parameters:
    - prev_state: Dictionary representing the cluster state before maintenance.
    - current_state: Dictionary representing the cluster state after maintenance.
    - args: Namespace object containing command-line arguments.
    """
    status_message(f"Reviewing and comparing cluster state with saved data: {args.filename}", 'execution')

    # Identify new issues
    new_issues = {
        "statefulsets": [],
        "deployments": [],
        "daemonsets": [],
        "helm_releases": []
    }

    # Get non-ready workloads for current and previous states
    prev_non_ready = get_all_non_ready_workloads(prev_state)
    curr_non_ready = get_all_non_ready_workloads(current_state)

    # Find the longest workload name in the previous state
    max_prev_name_length = 0
    for workload_type in prev_non_ready:
        for workload in prev_non_ready[workload_type]:
            max_prev_name_length = max(max_prev_name_length, len(workload['name']))

    for key in curr_non_ready:
        current_workloads = {w['name'] for w in curr_non_ready[key]}
        previous_workloads = {w['name'] for w in prev_non_ready[key]} if key in prev_non_ready else set()
        difference = current_workloads.difference(previous_workloads)
        new_issues[key] = list(difference)

    color_text_padding = 15
    new_conditions_text = color_text("NEW", ['t_orange'])
    preexisting_conditions_text = color_text("PREEXISTING", ['t_grey'])

    print("\nNon-Ready Workloads:")
    print("---------------------")
    print(f"{'Type:':<15} {'Previous Conditions':<{max_prev_name_length + 4}} Current Conditions: {preexisting_conditions_text} | {new_conditions_text}\n")

    workload_types = ["statefulsets", "deployments", "daemonsets", "helm_releases"]

    for workload_type in workload_types:
        prev_workloads = sorted({w['name'] for w in prev_non_ready.get(workload_type, [])})
        curr_workloads = sorted({w['name'] for w in curr_non_ready.get(workload_type, [])})

        # Combine and sort workloads from both states
        all_workloads = sorted(set(prev_workloads + curr_workloads))

        for workload in all_workloads:
            prev_status = workload in prev_workloads
            curr_status = workload in curr_workloads
            new_issue = workload in new_issues[workload_type]

            # Determine color based on status
            prev_color = "t_grey" if prev_status else None
            curr_color = "t_orange" if new_issue else "t_grey" if curr_status else None

            prev_workload_str = color_text(workload, [prev_color]) if prev_status else ""
            curr_workload_str = color_text(workload, [curr_color]) if curr_status else ""

            # Adjust the padding for colored text
            prev_col_padding = max_prev_name_length + 4 + (color_text_padding if prev_status else 0)
            curr_col_padding = 35 + (color_text_padding if curr_status else 0)

            print(
                f"{workload_type.capitalize():<15} {prev_workload_str:<{prev_col_padding}} {curr_workload_str:<{curr_col_padding}}"
            )

    print("---------------------\n")

    # print_node_ami_info(current_state["nodes"])
    print_node_ami_info_compared(current_state["nodes"], prev_state["nodes"])


def store_state(args: Namespace) -> None:
    """Store the current state of the Kubernetes cluster."""
    current_cluster_data = capture_cluster_state(args)
    filename = generate_filename(args.project, args.environment)
    store_cluster_state(current_cluster_data, filename)
    saved_data = load_cluster_state(filename, args)
    if not validate_cluster_data(saved_data, args):
        print("Error: Validation of saved cluster data failed.")
        sys.exit(1)


def review_state(args: Namespace) -> None:
    """Review the state of the Kubernetes cluster against saved data."""
    saved_data = load_cluster_state(args.filename, args)
    if not validate_cluster_data(saved_data, args):
        print("Error: Validation of saved cluster data failed.")
        sys.exit(1)

    current_cluster_data = capture_cluster_state(args)
    identify_new_cluster_issues(saved_data, current_cluster_data, args)


def main():
    """Main function to parse input and execute appropriate actions."""
    args = parse_input()
    args.caller = 'validate-cluster.py'
    args.non_interactive = True
    check_env(args)
    config.load_kube_config()

    if args.store_cluster_state:
        store_state(args)
    elif args.review_cluster_state:
        review_state(args)


if __name__ == '__main__':
    main()
