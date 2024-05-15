###
region                                   = "us-west-2"
cluster-name                             = "eks1"
env_name                                 = "dev"         # >= 7 charecter length
cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"] #Public IP of terminal will already add to whitelist, Add additional IP's here, Adding "0.0.0.0/0" provides Wide Public API Access
cluster_endpoint_public_access           = true
create_iam_role                          = false
cluster_version                          = "1.28"
enable_karpenter                         = true
authentication_mode                      = "API_AND_CONFIG_MAP"
enable_cluster_creator_admin_permissions = "true" # Auto Add creater of Cluster as Cluster Admin, if false, make sure Admin Accoun is part of below access_entries
policy_arn                               = "eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"


# Uncomment and Update IAm Role in Principal_arn below to provide EKS Access to IAM Predefined Roles. 
# access_entries = {
#   # One access entry with a policy associated
#   EKS-Admin-Cluster = {
#     kubernetes_groups = []
#     principal_arn     = "arn:aws:sts::1234567890:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSAdministratorAccess_21xxxxxxxx"

#     policy_associations = {
#       EKS-Admin-Cluster = {
#         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#         access_scope = {
#           type = "cluster"
#         }
#       }
#     }
#   },
#   EKS-Admin-Global = {
#     kubernetes_groups = []
#     principal_arn     = "arn:aws:iam::1234567890:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_EKS-Admin-Global_3bxxxxxxxx"

#     policy_associations = {
#       EKS-Admin-Global = {
#         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#         access_scope = {
#           namespaces = ["*"]
#           type       = "namespace"
#         }
#       }
#     }
#   },
#   EKS-Admin-Global-kube-system = {
#     kubernetes_groups = []
#     principal_arn     = "arn:aws:iam::1234567890:role/aws-reserved/sso.amazonaws.com/us-west-2/AWSReservedSSO_AWSPowerUserAccess_79xxxxxxxx"

#     policy_associations = {
#       EKS-Admin-Global-kube-system = {
#         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#         access_scope = {
#           namespaces = ["kube-system"]
#           type       = "namespace"
#         }
#       }
#     }
#   }
# }


##EKS NodeGroup Sizing
min_size                  = 1
max_size                  = 2
desired_size              = 2
instance_types            = ["t3.small"]
deploy_eks_alb_controller = "yes"
capacity_type             = "SPOT" #To save Cloud bill while testing
nodegroup-name            = "ng1"  #node name will be nodegroup-name+Clustername


##IRSA
deploy_pod_service_account      = false                       #default access is for ec2* list - Chnage this to more granular for testing
sample_pod_service_account_name = "ngnix-pod-service-account" #makes sure deploymenet spec is updated with annotation - serviceAccountName: ngnix-pod_service_account

##POD-Identity
deploy_pod_identity    = false                   #default access is for ec2* list - Chnage this to more granular for testing
pod_identity_role_name = "eks-pod-identity-role" #makes sure deploymenet spec is updated with annotation - serviceAccountName: ngnix-pod_service_account


tags = {
  GithubOrg_ref = "terraform-aws-modules"
}

