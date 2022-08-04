variable "aws_region" {
  default     = "eu-west-3"
  description = "AWS region"
}

data "aws_availability_zones" "available" {}

variable "cluster_name" {
  default = "eks-fbe"
  description = "Name of the k8s cluster, for training only"
}

variable "cluster_autoscaler_irsa" {
  description = "Configuration for the cluster-autoscaler-irsa terraform script"
  type = object({
    namespace = string
    sa_name   = string
  })

  default = {
    namespace = "kube-system"
    sa_name   = "cluster-autoscaler-aws-cluster-autoscaler-chart"
  }
}
