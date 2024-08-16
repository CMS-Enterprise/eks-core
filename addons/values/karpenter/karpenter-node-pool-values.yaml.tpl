nodePool:
  metadata:
    name: "${name}"
  spec:
    template:
      spec:
        nodeClassRef:
          name: "${ec2nodeclass_name}"
        requirements:
          - key: "karpenter.sh/capacity-type"
            operator: "In"
            values: ["on-demand"]
          - key: "karpenter.k8s.aws/instance-category"
            operator: "In"
            values: ["c"]
          - key: "karpenter.k8s.aws/instance-family"
            operator: "In"
            values: ["c5"]
          - key: "karpenter.k8s.aws/instance-cpu"
            operator: "In"
            values: ["4", "8"]
          - key: "topology.kubernetes.io/zone"
            operator: "In"
            values: [${join(", ", formatlist("\"%s\"", available_availability_zones))}]
%{ if length(karpenter_nodepool_taints) > 0 ~}
        taints:
%{ for taint in karpenter_nodepool_taints ~}
          - key: "${taint.key}"
            value: "${taint.value}"
            effect: "${taint.effect}"
%{ endfor ~}
%{ endif ~}


