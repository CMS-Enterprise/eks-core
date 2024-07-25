global:
  domain: "${argocd_sub_domain}.${domain_name}"
configs:
  params:
    server.insecure: true
  cm:
    create: ${argocd_use_sso}
    oidc.config: |
      name: Okta
      issuer: ${okta_issuer}
      clientID: ${okta_client_id}
      clientSecret: ${okta_client_secret}
      requestedScopes: ["openid", "profile", "email"]
  rbac:
    create: ${argocd_use_sso}
    policy.matchMode: "glob"
    scopes: "[groups, batcave-groups]"
    policy.default: 'role:helloargouser'
    policy.csv: 'g, Impact Level 2 Authorized, role:admin'        
server:
  autoscaling:
    enabled: true
    minReplicas: 2
  service:
    type: NodePort
  ingress:
    enabled: true
    controller: aws
    ingressClassName: alb
    annotations:
      alb.ingress.kubernetes.io/actions.ssl-redirect: >-
        {"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}
      alb.ingress.kubernetes.io/scheme: internal
      alb.ingress.kubernetes.io/load-balancer-name: ${k8s_alb_name}
      alb.ingress.kubernetes.io/certificate-arn: ${argocd_cert_arn}
      alb.ingress.kubernetes.io/security-groups: ${alb_security_group_id}
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}, {"HTTP": 80}]'
      alb.ingress.kubernetes.io/ssl-redirect: 443
      alb.ingress.kubernetes.io/ip-address-type: ipv4
      alb.ingress.kubernetes.io/target-type: instance
      alb.ingress.kubernetes.io/group.name: core
      alb.ingress.kubernetes.io/success-codes: 200-399
      alb.ingress.kubernetes.io/conditions.argocd-server-grpc: >-
        [{"field":"http-header","httpHeaderConfig":{"httpHeaderName": "Content-Type", "values":["application/grpc"]}}]
    aws:
      serviceType: NodePort
      backendProtocolVersion: HTTP2
    service:
      servicePortHttpName: http
      servicePortHttp: 8080
redis-ha:
  enabled: true
controller:
  replicas: 1
repoServer:
  autoscaling:
    enabled: true
    minReplicas: 2
applicationSet:
  replicas: 2