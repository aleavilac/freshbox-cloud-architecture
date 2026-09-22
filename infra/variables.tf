variable "project_name" {
  description = "Nombre base del proyecto (prefijo de todos los recursos)."
  type        = string
  default     = "freshbox"
}

variable "aws_region" {
  description = "AWS Academy Learner Lab normalmente restringe la region a us-east-1."
  type        = string
  default     = "us-east-1"
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

variable "single_nat_gateway" {
  description = "true = 1 NAT Gateway (recomendado para Academy Lab, menor costo). false = 1 por AZ."
  type        = bool
  default     = true
}
