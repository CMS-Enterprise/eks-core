eniConfigs:
%{ for subnet in subnets ~}
  - availabilityZone: "${subnet.availability_zone}"
    securityGroups:
      - "${cluster_primary_security_group_id}"
    subnetId: "${subnet.id}"
%{ endfor ~}
