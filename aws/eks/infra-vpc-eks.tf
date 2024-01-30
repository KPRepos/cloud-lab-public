

locals {
  public_ip = jsondecode(data.http.my_public_ip.body).ip
}

# Get Availability zones in the Region
data "aws_availability_zones" "AZ" {}


# Get My Public IP
data "http" "my_public_ip" {
  url = "https://ipinfo.io/json"
  request_headers = {
    Accept = "application/json"
  }
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

locals {
  # name   = "lab-${replace(basename(path.cwd), "_", "-")}"
  name   = var.env_name
  region = var.region

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Example    = local.name
    GithubRepo = "terraform-aws-eks"
    GithubOrg  = "terraform-aws-modules"
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source                               = "./modules/terraform-aws-eks"
  cluster_version                      = var.cluster_version
  cluster_name                         = var.cluster-name
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = concat(var.cluster_endpoint_public_access_cidrs, ["${local.public_ip}/32"])

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  iam_role_additional_policies = {
    additional = aws_iam_policy.additional.arn
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets


  ### https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1986
  ### failed to ensure load balancer: Multiple tagged security groups found for instance
  node_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = null
  }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
    ingress_source_security_group_id = {
      description = "Ingress from another IP in private subnet"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.0.0.0/16"]
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Test: https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2319
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }


  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.instance_types
    capacity_type  = var.capacity_type

    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.additional.id, aws_security_group.alb_security_group_eks_custom.id]

    iam_role_additional_policies = {
      additional = aws_iam_policy.additional.arn
    }
  }

  eks_managed_node_groups = {
    # blue = {}
    ng1 = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      labels = {
        Environment = var.env_name
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      taints = {
        # dedicated = {
        #   key    = "dedicated"
        #   value  = "gpuGroup"
        #   effect = "NO_SCHEDULE"
        # }
      }

      update_config = {
        max_unavailable_percentage = 33 # or set `max_unavailable`
      }

      # tags = {
      #   ExtraTag = "example"
      # }
    }
  }

  # aws-auth configmap
  manage_aws_auth_configmap = false


  tags = local.tags
}

################################################################################
# Supporting resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }

  tags = local.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${local.name}-additional"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = merge(local.tags, { Name = "${local.name}-additional" })
}

resource "aws_iam_policy" "additional" {
  name = "${local.name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "1.1.0"

  aliases               = ["eks/${local.name}"]
  description           = "${local.name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = local.tags
}


module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.env_name}_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

resource "helm_release" "lb" {
  count      = var.deploy_eks_alb_controller == "yes" ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service-account
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
}


# resource "aws_ec2_tag" "private_subnet_cluster_tag_1" {
#   # for_each    = toset(module.vpc.private_subnets
#   resource_id = module.vpc.private_subnets[0]
#   key         = "kubernetes.io/role/internal-elb"
#   value       = 1
# }

# resource "aws_ec2_tag" "private_subnet_cluster_tag_2" {
#   # for_each    = toset(module.vpc.private_subnets
#   resource_id = module.vpc.private_subnets[1]
#   key         = "kubernetes.io/role/internal-elb"
#   value       = 1
# }

# resource "aws_ec2_tag" "public_subnet_cluster_tag_1" {
#   # for_each    = toset(module.vpc.public_subnets)
#   resource_id = module.vpc.public_subnets[0]
#   key         = "kubernetes.io/role/elb"
#   value       = 1
# }


# resource "aws_ec2_tag" "public_subnet_cluster_tag_2" {
#   # for_each    = toset(module.vpc.public_subnets)
#   resource_id = module.vpc.public_subnets[1]
#   key         = "kubernetes.io/role/elb"
#   value       = 1
# }


resource "aws_security_group" "alb_security_group_eks_custom" {
  # ... other configuration ...
  ingress {
    description = "port 80 Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "alb_security_group_eks_custom"
  }
}


resource "aws_security_group_rule" "Custom_Security_Group_Rule_for_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_security_group_eks_custom.id
  security_group_id        = module.eks.cluster_security_group_id
}



data "tls_certificate" "cluster" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_role" "eks-service-account-role" {
  name = "${var.cluster-name}-workload_sa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
      },
    ]
  })

  inline_policy {
    name = "eks_service_account_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["s3:GetBucket", "s3:GetObject", "s3:PutObject"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

