# Documentation: Comprehensive Guide to Upgrading an EKS Cluster 

Upgrading an Amazon EKS (Elastic Kubernetes Service) cluster is a critical task that requires meticulous planning and careful execution to ensure compatibility across your Kubernetes environment and minimal disruption to services. The process involves several stages, including assessing the current cluster state, ensuring compatibility, performing backups, planning a maintenance window, and updating tools and IAM policies. This documentation provides a detailed, step-by-step guide for a successful EKS version upgrade. 


## Reviewing the EKS Version Deprecation Schedule 

Before planning an EKS version upgrade, it is essential to review the EKS version deprecation schedule. AWS typically supports three Kubernetes versions at any given time, and older versions are deprecated and eventually removed. The deprecation schedule outlines the timeline for when a version will no longer be supported, providing a clear deadline for upgrades. 

To review the EKS version deprecation schedule, visit the AWS EKS Kubernetes Versions page (https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html). This page details the currently supported versions, upcoming deprecation dates, and any special considerations for transitioning to newer versions. Regularly reviewing this schedule helps you plan upgrades in a timely manner and ensures that your cluster remains compliant with AWS support policies. It also provides valuable insights into the features and improvements available in newer versions, aiding in strategic planning for your Kubernetes environment. 

## Identifying API Version Compatibility Checks 

When upgrading your EKS cluster, ensuring API version compatibility is crucial to avoid disruptions in your applications. Kubernetes periodically deprecates and removes older API versions, which can affect resources and controllers using those APIs. 

To identify API version compatibility: 

1. Review API Deprecation Notices: Check the Kubernetes API Changes and Deprecations page for the version you are upgrading to (https://kubernetes.io/docs/reference/using-api/deprecation-guide/). This guide lists deprecated API versions, recommended replacements, and the timeline for removal. 

2. Audit Your Cluster Resources: Use kubectl to audit resources for deprecated APIs. Run the command kubectl get --all-namespaces -o yaml | grep -E 'apiVersion: [^/]+/v[0-9]+' to list API versions in use. Identify any resources using deprecated versions and update them to supported versions. 

3. Test API Compatibility: Deploy a test environment that mimics your production setup. Apply your existing configurations and observe for any compatibility issues. Use tools like kube-score or pluto to scan for deprecated API versions and get recommendations for replacements. 

4. Consult Third-Party Documentation: Review the documentation for third-party tools and add-ons in your cluster to ensure they are compatible with the new Kubernetes version. Vendors often provide specific guidance for upgrades and compatibility checks. 

Examples of Third-Party Tools with Kubernetes API Compatibility Documentation:

* Helm - Helm is a package manager for Kubernetes. When upgrading Kubernetes, it is essential to ensure that Helm charts are compatible with the new version. Check the [Helm documentation](https://helm.sh/docs/topics/kubernetes_apis/) for guidance on API version compatibility and upgrading Helm charts.

* Prometheus - Prometheus is a monitoring and alerting toolkit. The Prometheus Operator manages Prometheus clusters atop Kubernetes. Ensure that your Prometheus configuration and CRDs (Custom Resource Definitions) are compatible with the new Kubernetes version. Refer to the [Prometheus Operator documentation](https://prometheus-operator.dev/docs/getting-started/compatibility/) for details.

* Istio - Istio is a service mesh that provides a way to control how microservices share data. Check the [Istio documentation](https://istio.io/latest/docs/releases/supported-releases/) for API compatibility and upgrade instructions.

* Fluent Bit - Fluent Bit is a logging and data collection tool. Ensure that your Fluent Bit configuration is compatible with the new Kubernetes version by reviewing the [Fluent Bit documentation](https://docs.fluentbit.io/manual/v/1.1/installation/kubernetes).

* Argo CD - Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes. The [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/tested-kubernetes-versions/) provides guidance on API version compatibility and upgrading Argo CD.

By proactively checking and updating API versions, you ensure that your applications and infrastructure remain stable and compatible with the new Kubernetes version, preventing unexpected failures and downtime. 

## Documenting Breaking Changes for the EKS Version Upgrade 

Understanding and documenting breaking changes is a critical step in the EKS upgrade process. Breaking changes can significantly impact your applications and infrastructure, and failing to address them can lead to service disruptions. 

### Identifying Breaking Changes 

1. Review Kubernetes Release Notes: Each Kubernetes version upgrade comes with a set of changes, including potential breaking changes. Review the Kubernetes release notes for the version you are upgrading to, paying particular attention to sections on deprecated features, removed APIs, and changes in behavior. 

2. Assess Impact on Cluster Components: Evaluate how the breaking changes affect key components of your cluster, such as nodes, workloads, networking, and storage. Consider dependencies and integrations that might be impacted, including third-party tools and custom scripts. 

3. Test Changes in a Staging Environment: Before applying the upgrade to your production cluster, test the upgrade in a staging environment. This helps identify and mitigate issues related to breaking changes. Document any modifications or fixes required to accommodate these changes. 

4. Consult AWS and Community Documentation: AWS provides specific guidance on EKS upgrades. Review the AWS EKS Release Notes for details on how changes affect EKS clusters. Also, refer to community forums and documentation for additional insights and experiences from other users. 

### Documenting Breaking Changes 

1. Create a Detailed Change Log: Document each breaking change identified, including a description of the change, affected components, and the potential impact. Include references to official documentation and release notes. 

2. Outline Mitigation Strategies: For each breaking change, provide strategies for mitigating the impact. This may include updating configurations, replacing deprecated APIs, or modifying code to accommodate new behaviors. 

3. Develop Test Cases: Create test cases to validate the changes and ensure that mitigations are effective. Document these tests and their outcomes as part of your upgrade process. 

4. Communicate Changes to Stakeholders: Share the documented breaking changes and mitigation plans with all relevant stakeholders, including development, operations, and support teams. Ensure that everyone is aware of the changes and understands the necessary steps to address them. 

Documenting breaking changes helps ensure that you are prepared for the upgrade and can effectively manage any issues that arise. It provides a clear record of what changes were made, why they were necessary, and how they were handled. 

## Planning the EKS Version Upgrade 

The first step in the upgrade process is to assess the current state of your cluster. This involves checking the existing Kubernetes version using the AWS CLI command aws eks describe-cluster --name <cluster-name> --query 'cluster.version' --region <region>. It is also essential to list all managed and self-managed node groups by running aws eks list-nodegroups --cluster-name <cluster-name> --region <region>. Additionally, you should identify all installed Kubernetes add-ons, such as CoreDNS and kube-proxy, as well as any third-party tools in use. Reviewing the applications and workloads running on the cluster will help you understand the potential impact of the upgrade. 

Next, it is crucial to verify compatibility and understand the requirements for the new Kubernetes version. Consulting the AWS EKS Upgrade Documentation will provide necessary insights into changes and deprecations in the new version. Identifying any deprecated features or API changes is essential to ensure the continued functionality of your applications. It is also vital to verify the compatibility of third-party tools and custom scripts with the new Kubernetes version. 

Preparation also involves taking comprehensive backups and creating snapshots. For self-managed clusters, backing up the ETCD datastore is crucial. You should also back up application data, configurations, and secrets, and take snapshots of critical EBS volumes to safeguard against data loss. Choosing an appropriate maintenance window with minimal traffic is essential to reduce the impact of the upgrade. Informing all relevant stakeholders and teams about the planned maintenance ensures that everyone is prepared for potential downtime. 

Before proceeding with the upgrade, review and update IAM policies to ensure that they provide the necessary permissions for the EKS upgrade. Additionally, updating AWS CLI, eksctl, and kubectl to the latest versions is crucial for compatibility with the new Kubernetes version. Finally, perform a pre-upgrade health check by running commands such as kubectl get nodes and kubectl get pods --all-namespaces to identify any existing issues that might interfere with the upgrade process. 

## Executing the EKS Version Upgrade 

The actual upgrade process begins with upgrading the EKS control plane. First, identify the available Kubernetes versions for upgrade using the command aws eks describe-cluster --name <cluster-name> --query 'cluster.version' --region <region>. Then, initiate the control plane upgrade with the command aws eks update-cluster-version --name <cluster-name> --kubernetes-version <version> --region <region>, or use eksctl with eksctl upgrade cluster --name <cluster-name> --version <version> --region <region>. Monitoring the upgrade process is essential and can be done via the AWS Management Console or by using aws eks describe-update --name <cluster-name> --update-id <update-id> --region <region>. 

Following the control plane upgrade, it is necessary to upgrade the managed node groups. This involves listing the node groups with aws eks list-nodegroups --cluster-name <cluster-name> --region <region> and initiating the upgrade using aws eks update-nodegroup-version --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --kubernetes-version <version> --region <region>. For self-managed nodes, updating the AMI and rolling out new instances is crucial. This can be achieved by updating the launch template and initiating an instance refresh for the auto-scaling group. 

Upgrading add-ons and third-party tools is another critical step. For example, you can upgrade CoreDNS by applying the necessary configuration file with kubectl apply -f <url> and update kube-proxy using eksctl utils update-kube-proxy --cluster <cluster-name> --region <region>. Ensuring that third-party tools like Prometheus and Grafana are compatible with the new version is also important, and following vendor documentation for upgrades is recommended. 

## Rollback Plan

Upgrading an Amazon EKS (Elastic Kubernetes Service) cluster involves careful planning and execution. Despite thorough preparation, issues may arise that necessitate a rollback to a previous, stable version. This document outlines the steps to create and execute a rollback plan for an EKS version upgrade.

### Preparation Steps
1. Backup and Snapshot
Before starting the upgrade, create backups and snapshots of your critical data and configurations:

* Etcd Data Backup: Ensure that the etcd data (Kubernetes cluster state) is backed up.
* EBS Snapshots: Take snapshots of EBS volumes attached to the nodes.
* Database Backups: Backup any databases running on your cluster.
* Resource Manifests: Export all current resource manifests to YAML files.
2. Review Application State
* Document the state of all running applications, including their deployment configurations, services, and persistent volumes.
* Ensure that all applications are running in a healthy state before proceeding with the upgrade.

### Upgrade Procedures
1. Notify Stakeholders
Inform all stakeholders about the planned upgrade, the expected downtime, and the rollback plan.

2. Execute the Upgrade
Follow the EKS upgrade steps as per the official AWS documentation.

### Validation Steps
1. Post-Upgrade Testing
* Validate the state of applications.
* Verify that all services are functioning as expected.
* Check the cluster for any deprecated or incompatible API versions.

### Rollback Plan
1. Evaluate the Need for Rollback

   Determine if the upgrade issues warrant a rollback:

* Severe application downtime.
* Incompatibility issues that cannot be quickly resolved.
* Critical errors in the cluster state.
2. Execute the Rollback
Step-by-Step Rollback Process
* Restore EBS Snapshots:

   The rollback process involves several critical steps to ensure that the EKS cluster is restored to its pre-upgrade state. Start by restoring the EBS volumes from the snapshots taken before the upgrade. This can be done by using the AWS CLI to describe the snapshots and create volumes from these snapshots. Once the EBS volumes are restored, revert the resource manifests by applying the backup resource manifests to ensure that all configurations are back to their original state. If necessary, recreate the EKS cluster using the saved configuration and backup data to ensure all settings are correctly restored. This step might involve using tools like eksctl to re-establish the cluster according to the pre-upgrade specifications. Next, restore your databases from the backups. This could involve using database-specific tools or commands to import the backup files into the databases. Finally, re-deploy the applications using the pre-upgrade deployment configurations. This ensures that all applications are restored to their previous state and are running correctly. By meticulously following these steps, you can effectively rollback the EKS cluster to a stable state, minimizing downtime and maintaining operational integrity.

## Validating Core Resources 

After upgrading your EKS cluster, it is crucial to validate all core resources to ensure the cluster's stability and performance. This includes checking the health and functionality of nodes, pods, services, and networking components. Follow these steps to validate core resources: 

1. Nodes: 

        Run kubectl get nodes to list all nodes and their statuses. Ensure all nodes are in a Ready state. 

        Check the kubectl describe node <node-name> output for each node to review conditions and resource usage. 

2. Pods: 

        Use kubectl get pods --all-namespaces to list all pods. Look for any pods that are not in a Running or Completed state. 

        Check logs for critical pods using kubectl logs <pod-name> -n <namespace> to identify any issues or errors. 

3. Services: 

        List services using kubectl get svc --all-namespaces. Ensure all services are running and their endpoints are correctly configured. 

        Verify that internal and external services are accessible and functioning as expected. 

4. Networking: 

        Check the status of network policies with kubectl get networkpolicies --all-namespaces. Ensure policies are applied correctly. 

        Validate the ingress and egress rules for your applications and services to ensure proper traffic flow. 

5. Storage: 

        List Persistent Volume Claims (PVCs) using kubectl get pvc --all-namespaces. Ensure they are bound and available. 

        Verify that Persistent Volumes (PVs) are correctly configured and accessible. 

6. ConfigMaps and Secrets: 

        List ConfigMaps using kubectl get configmaps --all-namespaces and Secrets using kubectl get secrets --all-namespaces. 

        Ensure they are correctly applied and being used by the respective applications. 

By validating these core resources, you can ensure that your EKS cluster is functioning correctly after the upgrade and address any issues that might affect the cluster's stability or performance. 

## Post-Upgrade Reviews 

Once the upgrade is complete, ongoing monitoring is crucial to ensure the continued health of the cluster. Use CloudWatch or Prometheus to monitor key metrics and review application and cluster logs for any issues. It is also important to audit and update security settings to ensure that the cluster remains secure. Evaluating and optimizing cluster configurations, such as node sizes and scaling policies, can lead to improved performance and efficiency. 

Updating documentation to reflect the changes made during the upgrade is another critical post-upgrade step. Documenting the upgrade process, any issues encountered, and the resolutions helps create a comprehensive record for future reference. Finally, planning for the next maintenance or upgrade cycle and considering the adoption of new Kubernetes features introduced in the upgrade ensures that your cluster remains up-to-date and capable of supporting your workloads effectively. 

 