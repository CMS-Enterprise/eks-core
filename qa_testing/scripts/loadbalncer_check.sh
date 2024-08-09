#!/bin/bash

# Test Case: Verify Load Balancer

# Input parameter for the EKS cluster name
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME=$1
LOADBALANCER_NAME=$CLUSTER_NAME-captain

echo "Testcase name: Loadbalancer verificaiton"
# Define YAML files
cat <<EOF > app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  labels:
    app: app-label
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app-label
  template:
    metadata:
      labels:
        app: app-label
    spec:
      containers:
      - name: app-container
        image: nginx:latest
        ports:
        - containerPort: 80
EOF

cat <<EOF > app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  externalTrafficPolicy: Local
  type: NodePort
  selector:
    app: app-label
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF

# Retrieve security group IDs from AWS EKS
security_groups=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text)

cat <<EOF > app-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "$LOADBALANCER_NAME"
  annotations:
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/load-balancer-name: "$LOADBALANCER_NAME"
    alb.ingress.kubernetes.io/security-groups: "$security_groups"
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/ip-address-type: ipv4
    alb.ingress.kubernetes.io/target-type: instance
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: ImplementationSpecific
        backend:
          service:
            name: app-service
            port:
              number: 80
EOF
sleep 5

# Apply the YAML files
kubectl apply -f app-deployment.yaml > /dev/null 2>&1
kubectl apply -f app-service.yaml > /dev/null 2>&1
kubectl apply -f app-ingress.yaml > /dev/null 2>&1
sleep 5

#get POD_NAME, NODE_NAME, NODE_IP, PORT.
POD_NAME=$(kubectl get pods -l app=app-label -o jsonpath='{.items[0].metadata.name}')
NODE_NAME=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.nodeName}')
NODE_IP=$(kubectl get node $NODE_NAME -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
PORT=$(kubectl get svc app-service -o jsonpath='{.spec.ports[0].nodePort}')

#Retry logic for curl
max_retries=10
retry_interval=10
retry_count=0

while [ $retry_count -lt $max_retries ]; do
  #echo "Testing the endpoint (Attempt $((retry_count + 1))/$max_retries)..."
  response=$(curl -s http://$NODE_IP:$PORT)

  if echo "$response" | grep -q "Welcome to nginx"; then
    echo "Successfully received 'Welcome to nginx' message."
    break
  fi

  echo "Response did not match. Retrying in $retry_interval seconds..."
  sleep $retry_interval
  retry_count=$((retry_count + 1))
done

# Clean up YAML files
kubectl delete -f app-deployment.yaml > /dev/null 2>&1
kubectl delete -f app-service.yaml > /dev/null 2>&1
kubectl delete -f app-ingress.yaml > /dev/null 2>&1
rm app-deployment.yaml app-service.yaml app-ingress.yaml > /dev/null 2>&1

if [ $retry_count -eq $max_retries ]; then
  echo "FAIL: To get 'Welcome to nginx' message after $max_retries attempts."
  exit 1
fi
echo "PASS: LoadBalancer test passed"