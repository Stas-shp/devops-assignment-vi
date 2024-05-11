data "tls_certificate" "eks-cert" {
  url = aws_eks_cluster.vi_eks_cluster.identity[0].oidc[0].issuer
}

data "aws_kms_key" "env-kms-key" {
  key_id = "alias/eks-encryption-key"
}

resource "aws_iam_openid_connect_provider" "eks-aws-iam-openid-connect-provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.vi_eks_cluster.identity[0].oidc[0].issuer
  tags = {
    Name = "eks-ca-oidc-provider"
  }
}

output "eks_cluster_oidc_arn" {
  value = aws_iam_openid_connect_provider.eks-aws-iam-openid-connect-provider.arn
}

resource "aws_iam_role" "eks-nodes-role" {
  name = "vi-node-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "vi-cluster-role"
  assume_role_policy = jsonencode({
    Statement : [{
      Action : "sts:AssumeRole"
      Effect : "Allow",
      Principal : {
        Service : "eks.amazonaws.com"
      },
    }]
    Version : "2012-10-17"
  })
}

resource "aws_iam_role" "eks-cluster-secret-manager-sa" {
  name = "vi-get-sectets-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks-aws-iam-openid-connect-provider.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
      },
    ]
  })
}

resource "aws_iam_policy" "custom_secret_manager_policy" {
  name        = "vi-secret-manager-policy"
  description = "Custom policy for EKS worker nodes"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      Resource = "arn:aws:secretsmanager:${var.model_aws_region}:851725552187:secret:vi*"
      },
      {
        Effect : "Allow",
        Action : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        Resource : [
          data.aws_kms_key.env-kms-key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-node-policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])
  role       = aws_iam_role.eks-nodes-role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ])
  role       = aws_iam_role.eks-cluster-role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "eks-cluster-secret-manager-sa-attach-policy" {
  role       = aws_iam_role.eks-cluster-secret-manager-sa.name
  policy_arn = aws_iam_policy.custom_secret_manager_policy.arn
}

resource "kubernetes_service_account" "create-cluster-secret-manager-sa" {
  metadata {
    name      = "secret-manager-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks-cluster-secret-manager-sa.arn
    }
  }

  automount_service_account_token = true
}
