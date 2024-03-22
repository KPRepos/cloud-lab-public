###
region                      = "us-west-2"
env_name                    = "k8-unmanaged"
worker_instance_type        = "t3.small"
control_panel_instance_type = "t3.small"
capacity_type               = "spot"
vpc_cidr                    = "10.0.0.0/16"
worker_nodes_count          = 1 #this is number under ASG

add_user_local_ip_to_lb     = true #default setting
allowed_cidrs_k8_public_dns = []

#Advanced/Draft
# if any errors with kubectl, use --insecure-skip-tls-verify=true
