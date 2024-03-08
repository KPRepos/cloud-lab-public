### Deploy

`Update variables if needed form lab-variables.auto.tfvars`

`Update provider-backend.tf file to use s3 backend`

`terraform init`
`terraform apply`



### Connect to EKS Cluster 

aws eks --region us-west-2 update-kubeconfig --name eks-lab2



Ref:-

1) https://github.com/terraform-aws-modules/terraform-aws-eks