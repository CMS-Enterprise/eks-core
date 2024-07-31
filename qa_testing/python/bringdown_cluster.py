import argparse
from qa_libraries.tf_cluster_commands import bringdown_cluster

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Bring down an EKS cluster")
    parser.add_argument("-t", "--target", required=True, help="Target cluster name")

    args = parser.parse_args()
    bringdown_cluster(args.target)