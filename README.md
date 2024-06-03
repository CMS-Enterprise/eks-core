# Terraform EKS Deployment README

## Overview

This guide provides step-by-step instructions to deploy an Amazon EKS (Elastic Kubernetes Service) cluster using Terraform and a deployment bash script. The deployment includes IAM roles, KMS keys, S3 buckets, VPC configuration, and various EKS add-ons.

## Prerequisites

Before you begin, ensure you have the following:

1. **AWS CLI**: Installed and configured.
2. **Terraform**: Installed and configured.
3. **jq**: Installed for JSON processing.
4. **AWS Account**: With necessary permissions to create resources.
5. **IAM Role**: With permissions to assume roles and deploy resources.
6. **S3 Bucket**: For Terraform state management.
7. **DynamoDB Table**: For Terraform state locking.

## Step-by-Step Instructions

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure AWS CLI

Ensure your AWS CLI is configured with the necessary credentials:

```bash
aws configure
```

### 3. Provision S3 Bucket and DynamoDB Table

If you do not have an S3 bucket and DynamoDB table for Terraform state management, follow these steps to create them:

#### Create S3 Bucket

1. Open the AWS Management Console.
2. Navigate to the S3 service.
3. Click on "Create bucket".
4. Provide a unique bucket name (e.g., `terraform-state-bucket`). **Note**: The bucket name must be globally unique across all existing bucket names in AWS. This means no other AWS user in any region can have a bucket with the same name.
5. Choose the appropriate region.
6. Configure any additional settings as needed.
7. Click "Create bucket".

#### Create DynamoDB Table

1. Open the AWS Management Console.
2. Navigate to the DynamoDB service.
3. Click on "Create table".
4. Set the table name to `terraform-locks`.
5. Set the partition key to `LockID` with type `String`.
6. Configure any additional settings as needed.
7. Click "Create table".

### 4. Edit Terraform Configuration

Edit the `main.tf` file to provide the Terraform bucket name and DynamoDB table name:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"  # Replace with your S3 bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"               # Replace with your bucket's region
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Edit the `settings.tf` file to provide the Terraform bucket name:

```hcl
locals {
  ################################## Main Settings ##################################
  aws_region            = "us-east-1"
  terraform_bucket_name = "terraform-state-bucket"  # Replace with your S3 bucket name
  role_to_assume        = "arn:aws:iam::000000000000:role/terraform-test"
  role_name             = split("/", local.role_to_assume)[1]

  # ... other settings ...
}
```

### 5. Customize Secrets (Optional)

To store secrets in AWS Secrets Manager, you need to fill out the `secrets` variable in your Terraform configuration. This variable expects a map of key-value pairs where the key is the secret name and the value is the secret value.

Edit the `variables.tf` file to include your secrets:

```hcl
variable "secrets" {
  description = "The secrets to store in AWS Secrets Manager"
  type        = map(string)
  default     = {
    "mySecretName1" = "mySecretValue1"
    "mySecretName2" = "mySecretValue2"
    # Add more secrets as needed
  }
}
```

### ⚠️ **Important Security Warning**

**DO NOT** commit sensitive values such as secrets to the repository. This can lead to security vulnerabilities and exposure of sensitive information.

**Highly Recommended:** Set the secret values in your CI environment to mask the values and keep them secure. For example, in a GitHub Actions workflow, you can set the secrets as environment variables:

```yaml
env:
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  MY_SECRET_NAME1: ${{ secrets.MY_SECRET_NAME1 }}
  MY_SECRET_NAME2: ${{ secrets.MY_SECRET_NAME2 }}
```

### 6. Customize Settings (Optional)

You may edit other values in the `settings.tf` file to customize the infrastructure according to your needs. However, please proceed with caution. Making changes without fully understanding their implications can lead to:

- **Technical Errors**: Changes might prevent resources from functioning correctly or deploying successfully.
- **Increased Costs**: Certain configurations might cause a significant increase in AWS costs.

Only make changes if you are confident in your understanding of the settings and their impact.

### 7. Review the Deployment Script

The deployment script `deploy.sh` automates the process of assuming a role, initializing Terraform, planning, and applying the changes. It also handles the creation of the Terraform workspace if it does not exist.

You can view the deployment script [here](./deploy.sh).

### 8. Execute the Deployment Script

Run the deployment script to deploy the EKS cluster:

```bash
./deploy.sh
```

### What the Deployment Script Does

1. **Assumes the AWS Role**: The script assumes the specified AWS role to gain the necessary permissions to create resources.
2. **Initializes Terraform**: It initializes Terraform, downloading the required providers and modules.
3. **Checks and Creates Terraform Workspace**: It checks if the Terraform workspace exists and creates it if it does not.
4. **Plans Terraform Changes**: It generates and reviews the execution plan.
5. **Applies Terraform Changes**: It applies the changes to create the resources.

## Common Questions

### Q1: What is Terraform?

**A1**: Terraform is an open-source infrastructure as code software tool that enables you to safely and predictably create, change, and improve infrastructure.

### Q2: What is EKS?

**A2**: Amazon Elastic Kubernetes Service (EKS) is a managed Kubernetes service that makes it easy to run Kubernetes on AWS without needing to install and operate your own Kubernetes control plane or nodes.

### Q3: What should I do if the deployment script fails?

**A3**: If the deployment script fails, review the error messages, correct any issues, and re-run the script.

### Q4: How do I destroy the resources created by Terraform?

**A4**: To destroy the resources created by Terraform, run the following command:

```bash
terraform destroy
```

### Q5: Do I need to manually create the IAM roles and policies?

**A5**: No, the IAM roles and policies are defined in the Terraform configuration files and will be created automatically when you run the deployment script.

### Q6: What is the `RUNNING_IN_CICD` variable?

**A6**: The `RUNNING_IN_CICD` variable is used to indicate if the script is running in a CI/CD pipeline. If set to `true`, it bypasses user prompts and uses predefined variables.

### Q7: How do I set the `RUNNING_IN_CICD` variable?

**A7**: You can set the `RUNNING_IN_CICD` variable in your CI/CD pipeline configuration. For example, in a GitHub Actions workflow, you can set it as follows:

```yaml
env:
  RUNNING_IN_CICD: true
  ACCOUNT_NAME: "<account-name>"
  ACCOUNT_ID: "<account-id>"
  AWS_ROLE_ARN: "<aws-role-arn>"
```

### Q8: What are the prerequisites for running the deployment script?

**A8**: The deployment script requires the following:
- `aws-cli` installed and configured.
- `jq` installed for JSON processing.

### Q9: How do I customize the EKS cluster name?

**A9**: You can customize the EKS cluster name by setting the `cluster_custom_name` variable in the `variables.tf` file or by passing it as a command-line argument:

```bash
terraform apply -var="cluster_custom_name=my-cluster-name"
```

## Conclusion

By following this guide, you should be able to deploy an EKS cluster using Terraform. If you encounter any issues or have further questions, refer to the common questions section or consult the Terraform and AWS documentation.