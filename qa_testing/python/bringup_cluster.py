from qa_libraries.tf_cluster_commands import bringup_cluster

if __name__ == "__main__":
    cluster_name = "newcluster"  # Replace with the desired cluster name
    bringup_cluster(cluster_name)