data "aws_iam_policy_document" "lbc" {
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

resource "aws_iam_policy" "lbc_policy" {
  name = "${local.default_name}-eks-lbc-policy"
  policy = file("./iam/aws-lbc.json")
}


resource "aws_iam_role" "aws_lbc_role" {
  name = "${local.default_name}-eks-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.lbc.json
}

resource "aws_iam_role_policy_attachment" "lbc" {
  policy_arn = aws_iam_policy.lbc_policy.arn
  role       = aws_iam_role.aws_lbc_role.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name = aws_eks_cluster.eks.name
  namespace = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn = aws_iam_role.aws_lbc_role.arn
}

resource "helm_release" "aws_lbc" {
  name  = "aws-lbc"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  namespace = "kube-system"
  version = "1.7.2"

  set {
    name = "clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [aws_eks_node_group.example]
}