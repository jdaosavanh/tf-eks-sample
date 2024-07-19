data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.eks.token
  }
}

resource "helm_release" "metrics_server" {
  name  = "metrics"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart = "metrics-server"
  namespace = "kube-system"
  version = "3.12.1"
  values = [file("${path.module}/values/metrics-server.yaml")]
  depends_on = [aws_eks_node_group.example]
}

resource "helm_release" "ingress-nginx" {
  name  = "ingress-nginx-chart"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  namespace = "ingress"
  create_namespace = true
  version = "4.10.1"
  values = [file("${path.module}/values/ingress-nginx.yaml")]
  depends_on = [helm_release.aws_lbc]
}

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install ingress-nginx ingress-nginx/ingress-nginx

resource "helm_release" "cert_manager" {
  name  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart = "cert-manager"
  namespace = "cert-manager"
  create_namespace = true
  version = "v1.14.5"
  set {
    name = "installCRDs"
    value = "true"
  }
  depends_on = [helm_release.ingress-nginx]
}