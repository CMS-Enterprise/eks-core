[settings.kubernetes]
cluster-name = "${cluster_name}"
api-server = "${cluster_endpoint}"
cluster-certificate = "${cluster_ca_data}"
[settings.kubernetes.node-labels]
${node_labels}
[settings.kubernetes.node-taints]
${node_taints}
[settings.autoscaling]
should-wait = true
