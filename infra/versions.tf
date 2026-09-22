terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.31, < 6.0"
    }
  }

  # AWS Academy Learner Lab no permite crear buckets S3 nuevos de forma
  # confiable entre sesiones (el rol expira). Se usa backend local por
  # simplicidad academica. terraform.tfstate queda EXCLUIDO del repo
  # via .gitignore. Si se requiere backend remoto, descomentar y ajustar:
  #
  # backend "s3" {
  #   bucket = "TU-BUCKET-EXISTENTE"
  #   key    = "freshbox/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
