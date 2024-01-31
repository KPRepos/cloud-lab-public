
## Deploys GCP VPC and GKE infra for GKE lab 

### Copy -  modify terraform.tfvars and update values



#### Example commands

gcloud container clusters get-credentials kp-lab-k8 --region us-west1 --project project-1

kubectl get pods -A
kubectl apply -f sample-apps/nginx.yaml 
kubectl get deployment nginx-deployment
kubectl get pods -l app=nginx
kubectl get service lb-nginx-service


Ref used:- 

https://github.com/gruntwork-io/terraform-google-gke/blob/v0.10.0/modules/gke-cluster/main.tf
https://registry.terraform.io/providers/hashicorp/google/5.4.0/docs/resources/container_cluster



