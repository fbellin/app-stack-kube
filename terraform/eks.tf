provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_version = "1.17"
  cluster_name    = var.cluster_name
  vpc_id           = module.vpc.vpc_id
  subnets          = module.vpc.private_subnets
  enable_irsa	    = true
  write_kubeconfig = false
  
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # workers_group_defaults = {
  #   subnets              = module.vpc.private_subnets
  #   asg_min_size         = 1
  #   asg_max_size         = 1
  #   asg_desired_capacity = 1
  #   instance_type        = "t2.medium"
  #   key_name             = "fbellin"
  # }
}

resource "aws_eks_node_group" "main" {
    cluster_name    = var.cluster_name
    node_group_name = "eks-fbe-ng-main"
    # node_role_arn   = aws_iam_role.example.arn
    node_role_arn = module.eks.worker_iam_role_arn
    subnet_ids      = module.vpc.private_subnets
    instance_types = ["t2.micro"]

    scaling_config {
      desired_size = 2
      max_size     = 3
      min_size     = 1
    }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
    # depends_on = [
    #   aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    #   aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    #   aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
    # ]
  }
# resource "aws_iam_role" "example" {
#   name = "eks-node-group-example"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }

# resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.example.name
# }

# resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.example.name
# }

# resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.example.name
# }
#   node_groups_defaults = {}

#   node_groups = {
#     main = {
#       desired_capacity = 2
#       max_capacity     = 3
#       min_capacity     = 1

#       instance_types = ["t2.micro"]
#       capacity_type  = "ON_DEMAND"
#       k8s_labels = {
#         Environment = "test-fbe"
#       }
#       additional_tags = {
#         ExtraTag = "fbe-extra-tag"
#       }
#     }
#   }

#   # worker_groups = [
#   #   {
#   #     name                 = "worker-group-1"
#   #     instance_type        = "t2.medium"
#   #     asg_min_size         = 2
#   #     asg_max_size         = 3
#   #     asg_desired_capacity = 2
#   #     tags = [
#   #       {
#   #         "key"                 = "k8s.io/cluster-autoscaler/enabled"
#   #         "propagate_at_launch" = "false"
#   #         "value"               = "true"
#   #       },
#   #       {
#   #         "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
#   #         "propagate_at_launch" = "false"
#   #         "value"               = "true"
#   #       }
#   #     ]
#   #   }
#   # ]
# }

# resource "aws_eks_node_group" "main" {
#   cluster_name    = var.cluster_name
#   node_group_name = "${var.cluster_name}-main-ng" 
#   node_role_arn   = module.eks.worker_iam_role_arn
#   subnet_ids      = data.aws_subnet_ids.private[*].id

#   scaling_config {
#     desired_size = 2
#     max_size     = 3
#     min_size     = 1
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   # depends_on = [
#   #   aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
#   #   aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
#   #   aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
#   # ]

#       tags = [
#         {
#           "key"                 = "k8s.io/cluster-autoscaler/enabled"
#           "propagate_at_launch" = "false"
#           "value"               = "true"
#         },
#         {
#           "key"                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
#           "propagate_at_launch" = "false"
#           "value"               = "true"
#         }
#       ]
# }


module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "fbe-cluster-autoscaler"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.cluster_autoscaler_irsa.namespace}:${var.cluster_autoscaler_irsa.sa_name}"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}