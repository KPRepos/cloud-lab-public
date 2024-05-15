### Deploy

Optional:- 

`Update provider-backend.tf file to use s3 backend`

`mv lab-variables.sample.tfvars lab-variables.auto.tfvars`

`Update variables if needed form lab-variables.auto.tfvars`

Run:- 

`terraform init`

`terraform apply`


### Connect to EKS Cluster 

Ex:- 

`aws eks --region us-west-2 update-kubeconfig --name eks-labv4`


Ref:-

1) https://github.com/terraform-aws-modules/terraform-aws-eks

Notes:- 

1) AmazonEKSClusterAdminPolicy is hardcoded in module and runs, if  enable_cluster_creator_admin_permissions is true