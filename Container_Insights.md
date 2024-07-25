# Container Insights Documentation

## Overview


### Overview of Container Insights and its Purpose

Container Insights is a feature provided by cloud service providers, such as AWS, to help monitor and manage containerized applications. It offers comprehensive monitoring of containers, including their performance, resource utilization, and health status. Container Insights collects, aggregates, and analyzes metrics and logs from container orchestration platforms like Kubernetes and Docker, providing valuable insights into the behavior and performance of containerized workloads.

Purpose:

* Visibility: Provides detailed visibility into the performance and health of containerized applications.
* Troubleshooting: Helps identify and diagnose issues in container environments.
* Optimization: Assists in optimizing resource usage and improving the efficiency of containerized applications.
* Scalability: Supports scaling of applications by monitoring resource usage and performance metrics.
* Security: Helps ensure the security and compliance of containerized environments by monitoring for unusual activity.

### Benefits of Using Container Insights for Monitoring Containerized Applications


1. Improved Performance Monitoring:

    * Real-time monitoring of container metrics and logs.
    * Detection of performance bottlenecks and resource constraints.

2. Enhanced Troubleshooting:

    * Quick identification of issues with detailed logs and metrics.
    * Correlation of metrics and logs for efficient root cause analysis.

3. Resource Optimization:

    * Monitoring of CPU, memory, and storage usage.
    * Identification of underutilized or overutilized resources.

4. Scalability:

    * Automatic scaling based on resource usage and performance metrics.
    * Support for dynamic scaling of containerized applications.

5. Security and Compliance:

    * Monitoring for anomalous behavior and potential security threats.
    * Ensuring compliance with organizational and regulatory standards.

6. Cost Management:

    * Insights into resource consumption and cost optimization opportunities.
    * Reduction of operational costs by optimizing resource allocation.
 
7. User-friendly Dashboards:

    * Intuitive dashboards for visualizing metrics and logs.
    * Customizable views to focus on specific aspects of the container environment.

### Supported Environments and Prerequisites
Supported Environments:

* Amazon EKS (Elastic Kubernetes Service): Managed Kubernetes service on AWS.
* Amazon ECS (Elastic Container Service): Managed container orchestration service.
* Kubernetes: Open-source container orchestration platform.
* Docker: Platform for developing, shipping, and running applications in containers.

Prerequisites:

* CloudWatch Agent: Must be installed on the container instances to collect and send metrics and logs to Amazon CloudWatch.
* IAM Roles and Policies: Proper IAM roles and policies need to be set up to allow the collection and storage of metrics and logs.
* Container Orchestration Platform: A running instance of Kubernetes, Docker, Amazon EKS, or Amazon ECS.
* Configuration: Proper configuration of the CloudWatch Agent and Container Insights to ensure accurate data collection.
* Permissions: Necessary permissions for the CloudWatch Agent to access container metrics and logs.

## Installation
To install Container Insights on your EKS (Elastic Kubernetes Service) cluster, begin by ensuring that the AWS CLI and kubectl are installed and configured. First, install the AWS CLI using the command pip install awscli and configure it with your credentials using aws configure. Next, install kubectl by downloading it from the official Kubernetes release, making it executable, and moving it to your PATH, using commands like:

        curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/<version>/2023-07-05/bin/darwin/amd64/kubectl
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/

After configuring kubectl to communicate with your EKS cluster by running aws eks --region <region> update-kubeconfig --name <cluster_name>, create an IAM role for the CloudWatch agent. This role should have a trust policy allowing EKS to assume the role and attach the CloudWatchAgentServerPolicy. Use the commands:

        aws iam create-role --role-name EKS-CloudWatch-Role --assume-role-policy-document file://trust-policy.json
        aws iam attach-role-policy --role-name EKS-CloudWatch-Role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

Next, deploy the CloudWatch agent and Fluentd daemonsets using the provided YAML files:

        kubectl apply -f https://raw.githubusercontent.com/aws/amazon-cloudwatch-agent/master/eks/container-insights/cloudwatch-agent.yaml
        kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/fluentd/fluentd.yaml

Create a ConfigMap for the CloudWatch agent configuration by applying a YAML configuration file. Finally, restart the CloudWatch agent DaemonSet to apply the new configuration with kubectl rollout restart daemonset cloudwatch-agent -n amazon-cloudwatch.


### Configuration Options and Best Practices for Setup
When configuring Container Insights, several options and best practices can enhance the setup. Start by defining the metrics collection interval and specifying which metrics to collect, such as CPU and memory usage. Ensure that the CloudWatch agent has appropriate IAM permissions to collect and send metrics and logs.

Best practices include using dedicated namespaces for monitoring components, optimizing resource usage by monitoring the agent itself, setting up CloudWatch Alarms to be notified of potential issues, and ensuring security by following least-privilege principles for IAM roles. Additionally, configure log retention policies to manage storage costs effectively.

### Examples of Installation Commands and Configuration Files
Here are some example commands and configuration files for installing and configuring Container Insights:

1. Installing AWS CLI and kubectl:

        pip install awscli
        aws configure
        curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/<version>/2023-07-05/bin/darwin/amd64/kubectl
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/
        aws eks --region <region> update-kubeconfig --name <cluster_name>

2. Creating IAM Role for CloudWatch Agent:

        {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
             "Principal": {
              "Service": "eks.amazonaws.com"
              },
             "Action": "sts:AssumeRole"
            }
          ]
        }

        aws iam create-role --role-name EKS-CloudWatch-Role --assume-role-policy-document file://trust-policy.json
        aws iam attach-role-policy --role-name EKS-CloudWatch-Role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

3. Deploying CloudWatch Agent and Fluentd Daemonsets:

        kubectl apply -f https://raw.githubusercontent.com/aws/amazon-cloudwatch-agent/master/eks/container-insights/cloudwatch-agent.yaml
        kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/fluentd/fluentd.yaml





## Verify Install

### Verification of Successful Installation of Container Insights
To verify the successful installation of Container Insights on your EKS cluster, start by checking the status of the CloudWatch agent and Fluentd DaemonSets. Use the command kubectl get daemonset -n amazon-cloudwatch to ensure these DaemonSets are running without issues. Next, navigate to the CloudWatch console to verify that logs and metrics from your EKS cluster are being collected. You can also use the AWS CLI with a command like aws cloudwatch get-metric-data --metric-name <metric-name> --start-time <start-time> --end-time <end-time> --namespace <namespace> to retrieve specific metric data.

Inspect the log groups and log streams in the CloudWatch console by going to Logs and ensuring that the log groups and log streams corresponding to your EKS cluster are present and contain data. Additionally, check the logs of the CloudWatch agent to confirm it is running correctly and collecting data by executing kubectl logs -n amazon-cloudwatch daemonset/cloudwatch-agent.

### Ensuring Correct Data Collection and Display
To ensure Container Insights is collecting and displaying data correctly, use the CloudWatch console to view the Container Insights metrics dashboard. You should see metrics such as CPU, memory usage, and disk I/O. List available metrics with aws cloudwatch list-metrics --namespace ContainerInsights. Navigate to the Container Insights section in the CloudWatch console to review default dashboards for cluster performance, pod performance, and node performance. Setting up CloudWatch alarms on critical metrics can help verify that alarms trigger correctly based on the collected data. Use the command aws cloudwatch describe-alarms --alarm-names <alarm-name> to describe alarms.

Run queries on your log data using CloudWatch Logs Insights to ensure logs from your containers are being ingested and can be queried. Start a query with aws logs start-query --log-group-name <log-group-name> --start-time <start-time> --end-time <end-time> --query-string "fields @timestamp, @message". Check the status and statistics of the CloudWatch agent by executing kubectl exec -it -n amazon-cloudwatch <cloudwatch-agent-pod> -- /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status.

### Troubleshooting Common Verification Issues
If the CloudWatch agent or Fluentd DaemonSets are not running, check for errors in the pod descriptions with kubectl describe pod -n amazon-cloudwatch <pod-name> and review the logs using kubectl logs -n amazon-cloudwatch <pod-name>. Missing metrics or logs can often be attributed to IAM role permission issues or misconfigurations in the CloudWatch agent configuration file. Ensure the IAM role has necessary permissions by checking with aws iam get-role-policy --role-name EKS-CloudWatch-Role --policy-name CloudWatchAgentServerPolicy. Verify the configuration file is correctly formatted and applied by describing the config map: kubectl describe configmap -n amazon-cloudwatch cwagentconfig.

Inspect the logs of the CloudWatch agent for errors indicating issues with data collection or transmission by running kubectl logs -n amazon-cloudwatch daemonset/cloudwatch-agent. Confirm that network policies and security groups allow outbound traffic to CloudWatch endpoints to avoid network communication issues. Ensure that the CloudWatch agent and Fluentd are not constrained by resource limits (CPU/memory) and adjust resource requests and limits if necessary with kubectl edit daemonset -n amazon-cloudwatch cloudwatch-agent and kubectl edit daemonset -n amazon-cloudwatch fluentd.

## Using Container Insights

### Navigating the Container Insights Dashboard
Navigating the Container Insights dashboard is straightforward and intuitive. Begin by logging into the AWS Management Console and navigating to the CloudWatch service. From there, select "Container Insights" from the left-hand menu. The dashboard will present an overview of your containerized applications, including clusters, nodes, and pods. You can view high-level metrics at a glance, such as CPU and memory usage, along with more detailed information by selecting specific clusters or nodes. The dashboard provides a variety of pre-configured views and filters that allow you to drill down into the performance and health of your containers. You can also customize the time range for the metrics displayed, making it easier to diagnose issues and monitor trends over specific periods.

### Explanation of Key Metrics and Data Visualizations
Container Insights provides a wealth of metrics and data visualizations that help you monitor the performance and health of your containerized applications. Key metrics include CPU and memory usage, which are critical for ensuring your applications have enough resources to run efficiently. Disk I/O metrics help monitor storage performance, while network metrics track data transfer rates and identify potential bottlenecks. Visualizations such as time series graphs display these metrics over time, making it easier to spot trends and anomalies. Heat maps and histograms provide additional context by showing the distribution of metrics across your containers, helping you identify outliers and resource usage patterns. By understanding these key metrics and visualizations, you can better manage your containerized environment and ensure optimal performance.

### Examples of Common Tasks: Setting Up Alerts, Creating Dashboards, and Analyzing Logs
* Setting Up Alerts: To set up alerts, navigate to the "Alarms" section in CloudWatch. Click on "Create Alarm" and select the metric you want to monitor, such as CPU utilization. Define the threshold that will trigger the alarm and specify the actions to be taken when the alarm state changes, such as sending a notification via SNS (Simple Notification Service). Configuring alerts helps you stay proactive in managing your containerized applications by getting notified of potential issues before they impact performance.

* Creating Dashboards: Creating a custom dashboard in CloudWatch allows you to visualize the most relevant metrics for your environment in one place. Navigate to the "Dashboards" section and click on "Create Dashboard." Add widgets to display various metrics, such as line graphs for CPU usage or bar charts for memory utilization. Customize the layout to suit your monitoring needs. By aggregating key metrics into a single view, you can more easily track the health and performance of your containers.

* Analyzing Logs: To analyze logs, go to the "Logs" section in CloudWatch and select the log group associated with your containerized applications. Use CloudWatch Logs Insights to run queries and filter log data based on specific criteria, such as error messages or response times. For example, a query like fields @timestamp, @message | filter @message like /error/ can help you identify error logs quickly. Analyzing logs enables you to troubleshoot issues, monitor application behavior, and gain insights into the operational aspects of your containers.

## Use Case: Viewing Metrics

### Viewing Metrics for a Specific Namespace in Container Insights on EKS
To view metrics for a specific namespace in Container Insights on your EKS cluster, follow these steps. First, log into the AWS Management Console and navigate to the CloudWatch service. In the CloudWatch console, select "Container Insights" from the navigation pane on the left. Once in the Container Insights section, choose the "Performance Monitoring" tab. Here, you can filter the metrics by namespace. Click on the "Namespace" dropdown menu and select the specific namespace you want to monitor. This will update the dashboard to display metrics only for the selected namespace. You can further refine your view by adjusting the time range using the time selector at the top of the dashboard.

### Explanation of the Metrics Displayed and How to Interpret Them
The Container Insights dashboard displays several key metrics that provide insights into the performance and health of your containers within the specified namespace. These metrics include CPU usage, memory usage, disk I/O, and network statistics.

* CPU Usage: Displayed as a percentage, this metric shows the amount of CPU resources consumed by your containers. High CPU usage may indicate that your applications are CPU-bound and might need optimization or scaling.
* Memory Usage: This metric shows the memory consumption of your containers, also as a percentage. Monitoring memory usage helps identify memory leaks or inadequate memory allocation.
* Disk I/O: These metrics include read and write operations per second, providing insights into the storage performance of your containers. High disk I/O can indicate intensive read/write operations, which may require storage optimization.
* Network Statistics: These include metrics such as network packets sent and received, and data transfer rates. Monitoring network metrics can help identify network bottlenecks or issues with connectivity.

### Tips for Customizing Views and Filtering Data for Namespaces
Customizing views and filtering data for specific namespaces in Container Insights can greatly enhance your monitoring and troubleshooting capabilities. Start by creating custom dashboards in the CloudWatch console. Navigate to the "Dashboards" section and click "Create Dashboard." Add widgets for the metrics you want to monitor, such as line graphs for CPU usage or bar charts for memory utilization. Use the "Add Widget" button to include metrics specific to your namespace by selecting the appropriate namespace from the filter options.

To filter data more effectively, use CloudWatch Logs Insights. Navigate to the "Logs" section in CloudWatch and select the log group associated with your namespace. Use query filters to drill down into specific logs. For example, you can filter logs by keyword, log level, or timestamp. An example query might be:

        fields @timestamp, @message
        | filter kubernetes.namespace_name = "your-namespace"
        | sort @timestamp desc
        | limit 20


## TroubleShooting

### Common Issues Encountered While Using Container Insights
Using Container Insights can sometimes present challenges, which can be broadly categorized into deployment, configuration, and data collection issues. One common issue is the CloudWatch agent or Fluentd DaemonSets not running, which might result from insufficient permissions, incorrect configurations, or resource constraints on the nodes. Another frequent problem is missing or incomplete metrics and logs, often caused by misconfigured CloudWatch agent configuration files or network connectivity issues between the EKS cluster and CloudWatch. Additionally, users might face IAM permission errors, leading to failure in data collection or transmission. Performance bottlenecks due to high resource consumption by the monitoring agents can also occur, impacting the overall performance of the EKS cluster.

### Links to AWS Troubleshooting Documentation and Resources
To address these issues, AWS provides comprehensive troubleshooting documentation and resources:

* [Amazon CloudWatch Container Insights Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html): This provides an overview, setup instructions, and detailed guidance on using Container Insights.
* [EKS Troubleshooting Guide](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html): This guide offers solutions to common EKS issues, which can indirectly affect Container Insights.
* [AWS Support Center](https://aws.amazon.com/premiumsupport/): Access to AWS Support plans and resources for personalized assistance.
* [AWS Forums](https://repost.aws/): A community resource where users can ask questions and share solutions related to AWS services.

### Steps to Resolve Frequent Problems and Errors
Resolving common issues with Container Insights typically involves a few key steps. For DaemonSets not running, check the pod descriptions and logs using commands like kubectl describe pod -n amazon-cloudwatch <pod-name> and kubectl logs -n amazon-cloudwatch <pod-name>. These commands help identify configuration errors or resource limitations. If metrics or logs are missing, ensure that the CloudWatch agent configuration file is correctly formatted and applied by describing the ConfigMap with kubectl describe configmap -n amazon-cloudwatch cwagentconfig. Verify that the IAM role has the necessary permissions by inspecting the policies attached to the role using aws iam get-role-policy --role-name EKS-CloudWatch-Role --policy-name CloudWatchAgentServerPolicy.

For network-related issues, confirm that security groups and network policies allow outbound traffic to CloudWatch endpoints. Check CloudWatch agent logs for errors indicating data collection or transmission problems by running kubectl logs -n amazon-cloudwatch daemonset/cloudwatch-agent. Additionally, ensure that the monitoring agents are not constrained by resource limits. Adjust resource requests and limits if necessary by editing the DaemonSet configuration with kubectl edit daemonset -n amazon-cloudwatch cloudwatch-agent.

## FAQ
For more detailed and up-to-date frequently asked questions about Container Insights, you can visit the AWS FAQ page directly:

[AWS Container Insights FAQ](https://aws.amazon.com/cloudwatch/faqs/#Container_Insights)

## Further Reading and References
1. [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
2. [Amazon CloudWatch Logs Insights Documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)
3. [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
4. [AWS Observability Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
5. [CloudWatch Metrics and Dimensions Reference](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html)


