terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }

    helm = {
      source = "hashicorp/helm"
      version = ">= 2.12.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }
  }
}

