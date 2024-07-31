import argparse
from qa_libraries.tf_cluster_commands import bringup_cluster

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bring up an EKS cluster")
    parser.add_argument("-t", "--target", required=True, help="Target cluster name")

    args = parser.parse_args()
    bringup_cluster(args.target)