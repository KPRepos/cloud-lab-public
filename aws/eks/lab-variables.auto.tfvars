###
region                               = "us-west-2"
cluster-name                         = "eks-lab2"
env_name                             = "test"
cluster_endpoint_public_access_cidrs = [] #Public IP of terminal will already add to whitelist, Add additional IP's here, Adding "0.0.0.0/0" provides Public API Access
cluster_endpoint_public_access       = true
cluster_version                      = "1.28"

###EKS NodeGroup Sizing
min_size                  = 1
max_size                  = 2
desired_size              = 1
instance_types            = ["t3.medium", "t3.small"]
deploy_eks_alb_controller = "yes"
capacity_type             = "SPOT" #To save Cloud bill while learning

