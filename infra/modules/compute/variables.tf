variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  description = "t4g.small (ARM/Graviton) segun diseño de clase y README del proyecto. Requiere AMI ARM64."
  type        = string
  default     = "t4g.small"
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "sg_app_id" {
  type = string
}

variable "target_group_arns" {
  type = list(string)
}

variable "ecr_registry" {
  description = "URL base del registro ECR, ej: 123456789012.dkr.ecr.us-east-1.amazonaws.com"
  type        = string
}

variable "db_host" {
  description = "IP privada (o DNS interno) de la instancia MySQL Primary."
  type        = string
}

variable "db_name" {
  type    = string
  default = "freshbox"
}

variable "db_user" {
  type    = string
  default = "alumno"
}

variable "db_password" {
  type      = string
  default   = "alumno123"
  sensitive = true
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 4
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "lab_instance_profile_name" {
  description = "Nombre del Instance Profile pre-creado por AWS Academy Learner Lab. NO se puede crear uno propio (permisos restringidos)."
  type        = string
  default     = "LabInstanceProfile"
}
