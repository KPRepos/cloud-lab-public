###
region                               = "us-west-2"
cluster-name                         = "eks-labv4"
env_name                             = "cloud-lab-public"
cluster_endpoint_public_access_cidrs = [] #Public IP of terminal will already add to whitelist, Add additional IP's here, Adding "0.0.0.0/0" provides Wide Public API Access
cluster_endpoint_public_access       = true
cluster_version                      = "1.28"

###EKS NodeGroup Sizing
min_size                  = 1
max_size                  = 2
desired_size              = 2
instance_types            = ["t3.small"]
deploy_eks_alb_controller = "yes"
capacity_type             = "SPOT" #To save Cloud bill while testing
nodegroup-name            = "ng1"  #node name will be nodegroup-name+Clustername


##IRSA
deploy_pod_service_account      = true                        #default access is for ec2* list - Chnage this to more granular for testing
sample_pod_service_account_name = "ngnix-pod-service-account" #makes sure deploymenet spec is updated with annotation - serviceAccountName: ngnix-pod_service_account

##POD-Identity
deploy_pod_identity    = true                    #default access is for ec2* list - Chnage this to more granular for testing
pod_identity_role_name = "eks-pod-identity-role" #makes sure deploymenet spec is updated with annotation - serviceAccountName: ngnix-pod_service_account


## CD
enable_argocd_helm_release = true # min nodes have to be 2 for small nodes
auto_deploy_sample_apps    = true
