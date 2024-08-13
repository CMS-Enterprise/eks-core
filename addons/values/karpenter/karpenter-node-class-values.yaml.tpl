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
    securityGroupSelectorTerms:
%{ for sg_id in securityGroupIDs ~}
      - id: "${sg_id}"
%{ endfor ~}
    userData: "${userData}"
    tags:
%{ for key, value in tags ~}
      ${key}: ${value}
%{ endfor ~}
