nodeClass:
  metadata:
    name: "default"
    annotations:
      description: "EC2NodeClass for running Amazon Linux 2 nodes with custom user data"

  spec:
    amiFamily: ${amiFamily}
    blockDeviceMappings:
      - deviceName: "/dev/xvda"
        ebs:
          volumeType: "gp3"
          volumeSize: 5
          deleteOnTermination: true
      - deviceName: "/dev/xvdb"
        ebs:
          volumeType: "gp3"
          volumeSize: 100
          deleteOnTermination: true
    role: ${iamRole}
    subnetTag: ${subnetTag}
    securityGroupID: ${securityGroupID}   
    tags:
      ${tags}

nodePool:
  metadata:
    name: "default" 
    annotations:
      kubernetes.io/description: "General purpose NodePool for generic workloads"
  spec:
    template:
      spec:
        requirements:
          - key: "kubernetes.io/arch"
            operator: "In"
            values: ["amd64"]
          - key: "kubernetes.io/os"
            operator: "In"
            values: ["linux"]
          - key: "karpenter.sh/capacity-type"
            operator: "In"
            values: ["on-demand"]
          - key: "karpenter.k8s.aws/instance-category"
            operator: "In"
            values: ["c", "m", "r"]
          - key: "karpenter.k8s.aws/instance-generation"
            operator: "Gt"
            values: ["5"]
          - key: "usage"
            operator: "In"
            values: ["application", "system"]
        nodeClassRef:
          apiVersion: "karpenter.k8s.aws/v1beta1"
          kind: "EC2NodeClass"
          name: "default"