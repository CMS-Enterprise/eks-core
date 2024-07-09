# Ansible : Playbook ArgoCD

This playbook deploys ArgoCD on a Kubernetes cluster.

### Prerequisites

What things you need to run this Ansible playbook :

*   A running Kubernetes cluster (locally or on cloud)
*   Download the Ansible requirements:

```bash
$ ansible-galaxy collection install -r requirements.yml
```

#### Deployment

To deploy ArgoCd on Kubernetes cluster, just run this command :

```bash
$ ansible-playbook playbook.yml
```

If everything run as expected, you should access ArgoCD dashboard depending on the Kubernetes port attribution.

#### Destroy

To destroy the ArgoCD resources created, just follow these steps :

```yaml
# First change the Ansible variable in the vars/vars.yml file

# Action
argocd_install: absent
```

Save the change and run the Ansible playbook :

```bash
$ ansible-playbook argocd.yml
```

