resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "eks-pod-identity-agent"
  addon_version = "v1.3.0-eksbuild.1"
}

data "aws_iam_policy_document" "cluster-autoscaler-assume-role-policy" {
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


resource "aws_iam_role" "cluster-autoscaler" {
  name = "${local.default_name}-eks-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.cluster-autoscaler-assume-role-policy.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "cluster-autoscaler-policy" {
  name = "${local.default_name}-eks-autoscaler-role-policy"
  policy = data.aws_iam_policy_document.cluster_autoscaler.json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster-autoscaler-policy.arn
  role       =  aws_iam_role.cluster-autoscaler.name
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name = aws_eks_cluster.eks.name
  namespace = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn = aws_iam_role.cluster-autoscaler.arn
}

resource "helm_release" "cluster_autoscaler" {
  chart = "cluster-autoscaler"
  name  = "autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  namespace = "kube-system"
  version = "9.37.0"

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name = "awsRegion"
    value = var.region
  }

  depends_on = [helm_release.metrics_server]
}