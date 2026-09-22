variable "project_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t4g.small"
}

variable "data_subnet_ids" {
  description = "2 subredes privadas Data (una por AZ). Solo se usa data_subnet_ids[0] (AZ1a) para la instancia MySQL; la subred de AZ1b queda reservada en la VPC para segmentacion Multi-AZ y una eventual ampliacion futura."
  type        = list(string)
}

variable "sg_data_id" {
  type = string
}

variable "lab_instance_profile_name" {
  type    = string
  default = "LabInstanceProfile"
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

variable "db_root_password" {
  type      = string
  default   = "root123"
  sensitive = true
}

variable "init_sql_content" {
  description = "Contenido completo de init.sql (se inyecta tal cual desde el repo)."
  type        = string
}
