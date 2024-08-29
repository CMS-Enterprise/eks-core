import argparse
import configparser
import os
from qa_libraries.tf_cluster_commands import bringdown_cluster, get_repo_root, read_config_value

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bring down an EKS cluster")
    parser.add_argument("-t", "--target", help="Target cluster name")

    args = parser.parse_args()

    if args.target:
        target_cluster_name = args.target
    else:
        try:
            repo_root = get_repo_root()
            config_path = os.path.join(repo_root, "qa_testing", "python", "configs", "setup.cfg")
            target_cluster_name = read_config_value(config_path, "Target_Cluster_Name")
            print(f"No target cluster specified, defaulting to the setup.cfg value: {target_cluster_name}")
        except KeyError as e:
            print(f"Error: {e}. No target cluster specified and no default found in setup.cfg.")
            parser.print_help()
            raise ValueError("A target cluster name must be specified or present in setup.cfg.")

    bringdown_cluster(target_cluster_name)
