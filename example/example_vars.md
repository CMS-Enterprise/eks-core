# EKS

---
### Access Entries
```hcl
eks_access_entries = {
    techAdmin = {
      principal_arn = "arn:aws:iam::123456789012:role/techadmin"
      type          = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    },
    readOnly = {
      kubernetes_groups = []
      principal_arn = "arn:aws:iam::123456789012:role/readonly"
      type          = "STANDARD"
      policy_associations = {
        readonly = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default", "kube-system"]
            type = "namespace"
          }
        }
      }
    }
}
```

### Security Group Additional Rules
```hcl
eks_security_group_additional_rules = {
    rule1 = {
      description = "Allow inbound HTTP and HTTPS traffic"
      protocol    = "TCP"
      type        = "inbound"
      from_port   = 80
      to_port     = 443
      cidr_blocks = ["0.0.0.0/0"]
    }
}
```

# EKS Node Group

---

### Node Labels
```hcl
node_labels = {
  cluster = "some-cluster-name"
  type = "gpu"
}
```

### Node Taints
```hcl
node_taints = {
  key = "gpu"
  value = "true"
  effect = "NoSchedule"
}
```