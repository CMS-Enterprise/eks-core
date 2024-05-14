# Main
This is terraform code used to manage a base kubernetes infrastructure.

## Getting Started
There are some prerequisites to get started with this project.
You must create the following resources in AWS before you can run the terraform code.
These resources are not, and will not be, managed by terraform.

1. Create Terraform IAM User Policies
    1. Configuration:
       1. Go to ***IAM*** in the AWS console.
       2. Click on ***Policies***.
       3. Click on ***Create policy***.
       4. Click on the ***JSON*** tab.
       5. Copy the contents of the `terraform-iam-user-policy.json` file into the text box.
       6. Click on ***Next***.
       7. Enter the following values:
          1. Name: terraform-iam-user-policy
       8. Click on ***Create policy***.
2. Terraform Role (This role is assumed to run terraform code by the terraform user)
   1. Configuration:
      1. Go to IAM in the AWS console.
      2. Click on ***Roles***.
      3. Click on ***Create role***.
      4. Click on ***Custom trust policy***.
      5. Copy the `terraform_role_policy.json` from the `conf` directory into the text box.
      6. Click on ***Next***.
      7. Click the box next to ***AdministratorAccess***
      8. Click on ***Next***.
      9. Enter the following values:
         1. Role name: terraform
      10. Click on ***Create role***.
3. AWS S3 Bucket (This bucket will be used to store the terraform state file.)
   1. Configuration:
      1. Go to S3 in the AWS console.
      2. Click on ***Create bucket***.
      3. Enter the following values:
         1. Bucket name: mb-aws-terraform[^1]
         2. Region: US East (N. Virginia) us-east-1
         3. Click on ***Create bucket***.
4. AWS DynamoDB Table (This table will be used to lock the terraform state file.)
   1. Configuration:
      1. Go to DynamoDB in the AWS console.
      2. Click on ***Create table***.
      3. Enter the following values:
         1. Table name: terraform-locks[^1]
         2. Partition key: LockID
         3. Partition key type: String
         4. Click on ***Create table***.

## Graph Representation
1. Add the following env variables for the graph representation[^2]:
   1. AWS_ACCESS_KEY_ID
   2. AWS_SECRET_ACCESS_KEY
2. Run the following script:
    1. `util/graph.sh`

[^1]: This name must be globally unique. If you must use a different value, make sure you change the appropriate value in the `settings.tf` file, and you MUST change the policies in the `conf` directory to reference the updated value.
[^2]: This will only work if you have graphviz installed on your machine. Also, the graph generation from this script is rather messy. Looking for alternatives to make it much cleaner.
