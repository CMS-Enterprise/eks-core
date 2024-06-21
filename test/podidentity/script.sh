echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}' > trust-policy.json

# Save the inline policy to a file
echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "s3:GetObject",
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::S3_BUCKET_NAME/*",
            "Sid": "PodIdentity"
        }
    ]
}' > inline-policy.json

# Create the role
aws iam create-role \
    --role-name IAM_ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json \
    --path /delegatedadmin/developer/ \
    --permissions-boundary arn:aws:iam::111594127594:policy/cms-cloud-admin/ct-ado-poweruser-permissions-boundary-policy

# Attach the inline policy
aws iam put-role-policy \
    --role-name IAM_ROLE_NAME \
    --policy-name MyEKSInlinePolicy \
    --policy-document file://inline-policy.json


aws eks create-pod-identity-association \
  --cluster-name EKS_CLUSTER_NAME \
  --service-account pod-identity \
  --role-arn arn:aws:iam::111594127594:role/delegatedadmin/developer/IAM_ROLE_NAME \
  --namespace default

## follow https://chariotsolutions.com/blog/post/hands-on-with-eks-pod-identity/  ( create s3 and rds and change the policy as needed)
