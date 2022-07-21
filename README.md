# aws-eks-notes

## Private Networked Cluster

The annotation `service.beta.kubernetes.io/aws-load-balancer-internal: "true"` is required for services of type load-balancer. When using the AWS Load Balancer Controller, the `service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"` annotation is [preferred](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/#lb-scheme).

## AWS Load Balancer Controller

[Resources (v2.4) adapted for terraform](./aws-load-balancer-controller/v2_4_1_full.tf) from the example manifests found in the AWS Load Balancer Controller kuberentes sig's [installation guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/)

The ALB Controller reference yaml manifests are reliant on [cert-manager](https://cert-manager.io/) which can be prohibitively difficult to run in a private networked EKS cluster running on Fargate. In this case, the webhook's TLS certificate can be provisioned locally with Terraform, similar to how Helm would install a local TLS cert into the k8s secret with the `--set enableCertManager=false` paramter configured.
[./aws-load-balancer-controller/webhook-tls.tf](./aws-load-balancer-controller/webhook-tls.tf) will need to be updated with the correct dns names, common names, and namespaces for the cluster. The [terraform resources for the alb controller](./aws-load-balancer-controller/v2_4_1_full.tf) can then be adapted to remove the cert-manager manifests, create the secret, and update the webhook manifests by setting `webhooks.clientConfig.caBundle` to the CA cert.
