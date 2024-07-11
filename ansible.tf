resource "null_resource" "install_ansible_collections" {
  depends_on = [module.eks, module.main_nodes, module.eks_addons, module.eks_base]
  provisioner "local-exec" {
    command = <<EOT
      ansible-galaxy collection install -r ./ansible/argocd/requirements.yml
    EOT
  }
}

resource "ansible_playbook" "playbook" {
  depends_on = [null_resource.install_ansible_collections, module.eks, module.main_nodes, module.eks_addons, module.eks_base]
  playbook   = "./ansible/argocd/playbook.yml"
  name       = "localhost"
  replayable = true

  extra_vars = {
    aws_region           = data.aws_region.current.name
    argocd_install       = "present"
    argocd_k8s_namespace = "argocd"
    cluster_name         = local.cluster_name
    project              = var.project
    env                  = var.env
    domain               = "${var.project}-${var.env}.internal.cms.gov"
    repo                 = "https://github.com:CMS-Enterprise/Energon-Kube.git"
    dest_server          = "https://kubernetes.default.svc"

  }
}
