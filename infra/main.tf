# =====================================================================
# FreshBox SpA - Arquitectura Cloud EP1 - main.tf (orquestador de modulos)
# =====================================================================

data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  # Lee el init.sql real del repo (raiz del repo: /sql/init.sql) para no
  # duplicar el esquema de base de datos dentro del codigo Terraform.
  init_sql_content = file("${path.root}/../sql/init.sql")
}

module "network" {
  source             = "./modules/network"
  project_name       = var.project_name
  single_nat_gateway = var.single_nat_gateway
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  sg_alb_id         = module.security.sg_alb_id
}

# Base de datos: instancia UNICA (AZ1a) + AWS Backup, segun guia del docente.
module "database" {
  source            = "./modules/database"
  project_name      = var.project_name
  data_subnet_ids   = module.network.data_subnet_ids
  sg_data_id        = module.security.sg_data_id
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  db_root_password  = var.db_root_password
  init_sql_content  = local.init_sql_content
}

# Capa App: Auto Scaling Group (min:2/max:4), segun exige la pauta de evaluacion.
module "compute" {
  source               = "./modules/compute"
  project_name         = var.project_name
  aws_region           = var.aws_region
  app_subnet_ids       = module.network.app_subnet_ids
  sg_app_id            = module.security.sg_app_id
  target_group_arns    = [module.alb.target_group_arn]
  ecr_registry         = local.ecr_registry
  db_host              = module.database.primary_private_ip
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
  asg_desired_capacity = var.asg_desired_capacity

  depends_on = [module.database]
}
