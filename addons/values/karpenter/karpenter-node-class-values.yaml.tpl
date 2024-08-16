nodeClass:
  metadata:
    name: "${name}"
  spec:
    amiFamily: "${amiFamily}"
    deviceName: "${deviceName}"
    volumeSize: "${volumeSize}"
    volumeType: "${volumeType}"
    deleteOnTermination: ${deleteOnTermination}
    encrypted: ${encrypted}
    kmsKeyId: "${ebs_kms_key_id}"
    instanceProfile: "${instanceProfile}"
    amiSelectorId: "${amiSelectorId}"
    subnetTag: "${subnetTag}"
    securityGroupIDs:
%{ for sg_id in securityGroupIDs ~}
      - "${sg_id}"
%{ endfor ~}
%{ if preBootstrapUserData != "" ~}
    preBootstrapUserData: "${preBootstrapUserData}"
%{ endif ~}
%{ if bootstrapExtraArgs != "" ~}
    bootstrapExtraArgs: "${bootstrapExtraArgs}"
%{ endif ~}
%{ if postBootstrapUserData != "" ~}
    postBootstrapUserData: "${postBootstrapUserData}"
%{ endif ~}
    b64ClusterCA: "${b64ClusterCA}"
    clusterEndpoint: "${clusterEndpoint}"
    clusterName: "${clusterName}"
    clusterIpFamily: "${clusterIpFamily}"
    clusterCIDR: "${clusterCIDR}"
    tags:
%{ for key, value in tags ~}
      ${key}: ${value}
%{ endfor ~}
