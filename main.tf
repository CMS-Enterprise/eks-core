# TODO: Bottlerocket is not approved by SecOps. Don’t include it as a feature, as doing so might lead to further discussions with SecOps. They will either tell us to remove it or require extra documentation. For now, we have to comply with CMS golden images only.

# TODO: I see a lot of tags per resource but not default tags on all resources. Please create default tags and merge tags for resources if necessary. This will allow the team to have a common tag on all resources and only apply additional tags if needed. In most cases, default tags are the only ones used, but we can support an extra layer of tags.

# TODO: Deploy all the instances in one auto-scaling group because EBS volumes are AZ-specific. This will prevent instances from running into volume node affinity issues and causing compute waste. For example, if one EBS volume is created in one AZ, instances will have to be created in that same AZ just to honor that volume.

# TODO: All names should include “cms-eks—<ENV><ADO-Name>”.

# TODO: All prefixes should contain "cos-eks-env-ado_name" as default.

# TODO: All module versions need to be parameterized.

# TODO: Default rotation is 365 days.

# TODO: We need outputs that include module outputs and resource outputs for downstream consumption.

# TODO: EFS should use TLS by default.

# TODO: Turn off logging on the logging S3 bucket to avoid recursive logging.
