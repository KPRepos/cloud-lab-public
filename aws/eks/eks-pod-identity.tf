resource "aws_eks_addon" "eks-pod-identity" {
  count        = var.deploy_pod_identity ? 1 : 0
  cluster_name = module.eks.cluster_name
  addon_name   = "eks-pod-identity-agent"
}


data "aws_iam_policy_document" "assume_role_policy_eks_pod_identity" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}


data "aws_iam_policy_document" "ec2_policy_doc" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
    effect    = "Allow"
  }
}


resource "aws_iam_policy" "ec2_policy_policy" {
  count       = var.deploy_pod_identity ? 1 : 0
  name        = "ec2-policy"
  description = "ec2 describe policy"
  policy      = data.aws_iam_policy_document.ec2_policy_doc.json
}


resource "aws_iam_role" "eks-pod-identity-role" {
  count              = var.deploy_pod_identity ? 1 : 0
  name               = var.pod_identity_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_eks_pod_identity.json
}


resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment_pod_identity" {
  count      = var.deploy_pod_identity ? 1 : 0
  role       = aws_iam_role.eks-pod-identity-role[0].name
  policy_arn = aws_iam_policy.ec2_policy_policy[0].arn
}


resource "aws_eks_pod_identity_association" "aws_eks_pod_identity_role_association" {
  count           = var.deploy_pod_identity ? 1 : 0
  cluster_name    = module.eks.cluster_name
  namespace       = "nginx-apps-ns-podidentity"
  service_account = "ngnix-pod-identity-service-account"
  role_arn        = aws_iam_role.eks-pod-identity-role[0].arn
}
