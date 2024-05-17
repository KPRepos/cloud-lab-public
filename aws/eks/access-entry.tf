
data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

locals {

  partition = data.aws_partition.current.partition

  cluster_role = try(module.eks.cluster_iam_role_arn, var.iam_role_arn)

}



################################################################################
# Access Entry
################################################################################

# locals {
#   create = var.create
#   merged_access_entries = merge(
#     var.access_entries,
#     {}
#   )
# }


locals {
  create = var.create
}

resource "aws_eks_access_entry" "this" {
  for_each = { for k, v in var.access_entries : k => v if local.create }

  cluster_name      = module.eks.cluster_name
  kubernetes_groups = try(each.value.kubernetes_groups, null)
  principal_arn     = each.value.principal_arn
  type              = try(each.value.type, "STANDARD")
  user_name         = try(each.value.user_name, null)

  tags = merge(var.tags, try(each.value.tags, {}))
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_eks_access_policy_association" "this" {
  for_each = var.access_entries

  access_scope {
    namespaces = try(each.value.policy_associations.EKS-Admin-Cluster.access_scope.namespaces, [])
    type       = each.value.association_access_scope_type
  }

  cluster_name = module.eks.cluster_name

  policy_arn    = each.value.policy_associations.EKS-Admin-Cluster.policy_arn
  principal_arn = each.value.principal_arn

  depends_on = [
    aws_eks_access_entry.this,
  ]
  lifecycle {
    create_before_destroy = true
  }
}
