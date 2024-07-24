#Karpenter Terraform
module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name                      = var.eks_cluster_name
  create_access_entry               = false
  create_node_iam_role              = false
  create_pod_identity_association   = true
  enable_pod_identity               = true
  enable_spot_termination           = true
  iam_policy_name                   = "${var.eks_cluster_name}-karpenter-policy"
  iam_policy_path                   = var.iam_path
  iam_role_path                     = var.iam_path
  iam_role_permissions_boundary_arn = var.iam_permissions_boundary_arn
  namespace                         = local.karpenter_namespace
  node_iam_role_arn                 = var.eks_node_iam_role_arn
  service_account                   = local.karpenter_service_account_name


  tags = var.karpenter_base_tags
}

#Karpenter HELM
resource "helm_release" "karpenter-crd" {
  atomic           = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  create_namespace = true
  namespace        = local.karpenter_namespace
  wait             = true

  values = [
    local.kp_values
  ]

  set {
    name  = "serviceAccount.name"
    value = local.karpenter_service_account_name
  }
  set {
    name  = "settings.isolatedVPC"
    value = true
  }

  depends_on = [module.karpenter]
}

resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = var.karpenter_nodepool_name == "" ? "default" : var.karpenter_nodepool_name
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            apiVersion = "karpenter.k8s.aws/v1beta1"
            kind       = "EC2NodeClass"
            name       = var.karpenter_ec2nodeclass_name == "" ? "default" : var.karpenter_ec2nodeclass_name
          }
          taints = [for key, value in var.karpenter_nodepool_taints : {
            key    = key
            effect = value
          }]
          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-category"
              operator = "In"
              values   = ["c"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["c5"]
            },
            {
              key      = "karpenter.k8s.aws/instance-cpu"
              operator = "In"
              values   = ["4", "8"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = var.available_availability_zones
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
        }
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "160h"
      }
    }
  })

  depends_on = [helm_release.karpenter-crd]
}

resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = var.karpenter_ec2nodeclass_name == "" ? "default" : var.karpenter_ec2nodeclass_name
    }
    spec = {
      amiFamily = var.gold_image_ami_id != "" ? "Custom" : "AL2"
      subnetSelectorTerms = [
        {
          tags = {
            Name = "${var.ado}-*-${var.env}-private-*"
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          id = var.eks_node_security_group_id
        }
      ]
      instanceProfile = local.iam_instance_profile_name[0]
      amiSelectorTerms = [
        {
          id = var.gold_image_ami_id != "" ? var.gold_image_ami_id : var.custom_ami
        }
      ]
      userData = templatefile("${path.module}/linux_bootstrap.tpl", local.user_data)
      tags     = merge(var.karpenter_base_tags, { Name = "eks-karpenter-${var.eks_cluster_name}" })
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize          = "300G"
            volumeType          = "gp3"
            deleteOnTermination = true
            encrypted           = true
            kmsKeyId            = var.ebs_kms_key_id
          }
        }
      ]
    }
  })

  depends_on = [helm_release.karpenter-crd]
}
